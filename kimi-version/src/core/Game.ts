import * as THREE from 'three'
import { FIXED_DT, PhysicsWorld } from '../physics/PhysicsWorld'
import { Stone } from '../physics/stone'
import { Player } from '../physics/player'
import { StoneMesh } from '../render/StoneMesh'
import { buildMountainMesh } from '../world/mountainMesh'
import { Sky } from '../world/sky'
import { Lighting } from '../world/lighting'
import { TUNING } from './tuning'
import { IDLE_INTENT, type InputIntent } from './input'
import { sampleHeight } from '../world/heightfield'

export interface InputSource {
  poll(dt: number): InputIntent
}

export class Game {
  readonly renderer: THREE.WebGLRenderer
  readonly scene = new THREE.Scene()
  readonly camera: THREE.PerspectiveCamera
  readonly pw = new PhysicsWorld()
  readonly stone: Stone
  readonly player: Player
  private readonly stoneMesh = new StoneMesh()
  private readonly sky: Sky
  private readonly lighting: Lighting
  private acc = 0
  private last = 0

  constructor(parent: HTMLElement, private readonly source: InputSource) {
    this.renderer = new THREE.WebGLRenderer({ antialias: true })
    this.renderer.setSize(innerWidth, innerHeight)
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 2))
    this.renderer.shadowMap.enabled = true
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap
    parent.appendChild(this.renderer.domElement)

    this.camera = new THREE.PerspectiveCamera(TUNING.camera.fov, innerWidth / innerHeight, 0.08, 900)
    this.scene.add(buildMountainMesh())
    this.sky = new Sky(this.scene)
    this.lighting = new Lighting(this.scene)

    const sz = TUNING.mountain.frontLength - 4
    this.stone = new Stone(this.pw, 0, sampleHeight(0, sz) + TUNING.stone.radius + 0.05, sz)
    this.player = new Player(this.pw, 0, sz + 6)
    this.scene.add(this.stoneMesh)

    addEventListener('resize', () => {
      this.camera.aspect = innerWidth / innerHeight
      this.camera.updateProjectionMatrix()
      this.renderer.setSize(innerWidth, innerHeight)
    })
  }

  start(): void {
    requestAnimationFrame((t) => {
      this.last = t
      const frame = (t: number) => {
        this.acc += Math.min((t - this.last) / 1000, 0.1)
        this.last = t
        while (this.acc >= FIXED_DT) {
          this.fixedStep(FIXED_DT)
          this.acc -= FIXED_DT
        }
        this.render()
        requestAnimationFrame(frame)
      }
      requestAnimationFrame(frame)
    })
  }

  fixedStep(dt: number): void {
    const intent = this.source.poll(dt) ?? IDLE_INTENT
    this.player.move(this.pw, { ...intent, engaged: false, stonePos: null }, dt)
    this.stone.applyResistance(false)
    this.pw.step()
  }

  render(): void {
    const p = this.player.pose.pos
    const sp = this.stone.position()
    this.stoneMesh.position.set(sp.x, sp.y, sp.z)
    const rq = this.stone.body.rotation()
    this.stoneMesh.quaternion.set(rq.x, rq.y, rq.z, rq.w)
    this.camera.position.set(p.x, p.y + TUNING.player.eyeHeight, p.z)
    this.camera.rotation.set(0, this.player.pose.bodyYaw, 0, 'YXZ')
    this.lighting.follow(p.x, p.z)
    this.sky.mesh.position.copy(this.camera.position)
    this.renderer.render(this.scene, this.camera)
  }
}

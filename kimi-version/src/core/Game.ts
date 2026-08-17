import * as THREE from 'three'
import { FIXED_DT, PhysicsWorld } from '../physics/PhysicsWorld'
import { Stone } from '../physics/stone'
import { Player } from '../physics/player'
import { StoneMesh } from '../render/StoneMesh'
import { buildMountainMesh } from '../world/mountainMesh'
import { Sky } from '../world/sky'
import { Lighting } from '../world/lighting'
import { BodyRig } from '../body/BodyRig'
import { CameraRig } from '../camera/CameraRig'
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
  readonly rig = new BodyRig()
  private readonly stoneMesh = new StoneMesh()
  private readonly sky: Sky
  private readonly lighting: Lighting
  private acc = 0
  private last = 0

  constructor(parent: HTMLElement, private readonly source: InputSource, readonly camRig: CameraRig = new CameraRig()) {
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
    this.scene.add(this.rig)

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

  /** Machine-readable snapshot for the capture script and debugging. */
  debugState() {
    const p = this.player.pose.pos
    const s = this.stone.position()
    return {
      player: { x: +p.x.toFixed(2), y: +p.y.toFixed(2), z: +p.z.toFixed(2), yaw: +this.player.pose.bodyYaw.toFixed(2) },
      stone: { x: +s.x.toFixed(2), y: +s.y.toFixed(2), z: +s.z.toFixed(2), speed: +this.stone.speed().toFixed(2) },
      leftBlend: +this.rig.hands[-1].sm.blend.toFixed(2),
      rightBlend: +this.rig.hands[1].sm.blend.toFixed(2),
      leftPhase: this.rig.hands[-1].sm.phase,
      rightPhase: this.rig.hands[1].sm.phase,
    }
  }

  fixedStep(dt: number): void {
    const intent = this.source.poll(dt) ?? IDLE_INTENT
    const engaged = this.rig.engageAmount() > 0.5
    this.player.move(this.pw, { ...intent, engaged, stonePos: this.stone.position() }, dt)
    const pressing = this.rig.pose(
      dt,
      this.player.pose.pos,
      this.player.pose.bodyYaw,
      this.stone.position(),
      TUNING.stone.radius,
      { [-1]: intent.leftHand, [1]: intent.rightHand },
    )
    this.stone.applyPush(pressing)
    this.stone.applyResistance(pressing.length > 0)
    this.pw.step()
  }

  render(): void {
    const p = this.player.pose.pos
    const sp = this.stone.position()
    this.stoneMesh.position.set(sp.x, sp.y, sp.z)
    const rq = this.stone.body.rotation()
    this.stoneMesh.quaternion.set(rq.x, rq.y, rq.z, rq.w)
    this.camera.position.set(p.x, p.y + TUNING.player.eyeHeight, p.z)
    this.camRig.update(FIXED_DT, this.camera, p, this.player.pose.bodyYaw, this.rig.engageAmount(), this.rig.currentContact())
    this.lighting.follow(p.x, p.z)
    this.sky.mesh.position.copy(this.camera.position)
    this.renderer.render(this.scene, this.camera)
  }
}

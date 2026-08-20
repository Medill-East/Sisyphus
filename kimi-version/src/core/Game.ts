import * as THREE from 'three'
import { FIXED_DT, PhysicsWorld } from '../physics/PhysicsWorld'
import { Stone } from '../physics/stone'
import { Player } from '../physics/player'
import { StoneMesh } from '../render/StoneMesh'
import { buildMountainMesh } from '../world/mountainMesh'
import { buildScatter } from '../world/scatter'
import { buildDistantRidges } from '../world/distantRidges'
import { Sky } from '../world/sky'
import { Lighting } from '../world/lighting'
import { BodyRig } from '../body/BodyRig'
import { BodyView } from '../body/BodyView'
import { CameraRig } from '../camera/CameraRig'
import { LoopDirector } from '../game/LoopDirector'
import { buildCrestMarker } from '../world/crestMarker'
import { Dust } from '../render/dust'
import { Trail } from '../world/trail'
import { ScrapeAudio } from '../audio/scrape'
import { rumble } from './rumble'
import type { Vec3 } from '../physics/vec3'
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
  private readonly bodyView = new BodyView()
  private readonly stoneMesh = new StoneMesh()
  private readonly sky: Sky
  private readonly lighting: Lighting
  private acc = 0
  private last = 0
  private bobPhase = 0
  private lastBobPos: { x: number; z: number } | null = null
  readonly director = new LoopDirector()
  readonly scrape = new ScrapeAudio()
  private warmthSmoothed = 0
  private readonly dust = new Dust()
  private readonly trail = new Trail()
  private wasHeld = false

  constructor(parent: HTMLElement, private readonly source: InputSource, readonly camRig: CameraRig = new CameraRig()) {
    this.renderer = new THREE.WebGLRenderer({ antialias: true })
    this.renderer.setSize(innerWidth, innerHeight)
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 2))
    this.renderer.shadowMap.enabled = true
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping
    this.renderer.toneMappingExposure = 1.08
    parent.appendChild(this.renderer.domElement)

    this.camera = new THREE.PerspectiveCamera(TUNING.camera.fov, innerWidth / innerHeight, 0.08, 1400)
    this.scene.add(buildMountainMesh())
    this.scene.add(buildScatter())
    this.scene.add(buildDistantRidges())
    this.scene.add(buildCrestMarker())
    this.scene.add(this.dust)
    this.scene.add(this.trail.mesh)
    this.sky = new Sky(this.scene)
    this.lighting = new Lighting(this.scene)

    const sz = TUNING.mountain.frontLength - 4
    this.stone = new Stone(this.pw, 0, sampleHeight(0, sz) + TUNING.stone.radius + 0.05, sz)
    this.player = new Player(this.pw, 0, sz + 6)
    this.scene.add(this.stoneMesh)
    this.scene.add(this.rig)
    this.scene.add(this.bodyView)

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
      loop: this.director.run,
    }
  }

  /** Debug reset (R / Start): stone and player return to the current climb-side foot. */
  private resetRun(): void {
    const M = TUNING.mountain
    const side = this.director.run.climbSide
    const z = side > 0 ? M.frontLength - 4 : -(M.backLength - 4)
    this.stone.body.setTranslation({ x: 0, y: sampleHeight(0, z) + TUNING.stone.radius + 0.05, z }, true)
    this.stone.body.setLinvel({ x: 0, y: 0, z: 0 }, true)
    this.stone.body.setAngvel({ x: 0, y: 0, z: 0 }, true)
    this.player.teleport(0, z + side * 6, 0)
  }

  fixedStep(dt: number): void {
    ;(this.source as { sense?: (s: Vec3, p: Vec3) => void }).sense?.(this.stone.position(), this.player.pose.pos)
    const intent = this.source.poll(dt) ?? IDLE_INTENT
    if (intent.reset) this.resetRun()
    const engaged = this.rig.engageAmount() > 0.5
    this.player.move(this.pw, { ...intent, engaged, stonePos: this.stone.position(), headYaw: this.camRig.yaw }, dt)
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
    // The record of labor: stamp the trail wherever the stone truly rolls.
    {
      const sp = this.stone.position()
      if (this.stone.speed() > 0.15) this.trail.record(sp.x, sp.z)
    }
    // Breakaway beat: held → moving under force puffs grit at the stronger hand.
    if (this.wasHeld && !this.stone.held && pressing.length > 0) {
      const stronger = pressing.reduce((a, b) => (a.magnitude >= b.magnitude ? a : b))
      this.dust.burst(stronger.point)
    }
    this.wasHeld = this.stone.held
    const av = this.stone.body.angvel()
    this.scrape.update(Math.hypot(av.x, av.y, av.z), this.stone.speed() > 0.02)
    const totalForce = pressing.reduce((sum, h) => sum + h.magnitude, 0)
    this.scrape.setStrain(totalForce / (TUNING.push.maxForcePerHand * 2))
    if (pressing.length > 0) rumble(intent.leftHand, intent.rightHand)
    this.director.update(dt, this.stone.position(), this.stone.speed(), this.player.pose.pos, this.rig.engageAmount() > 0.5, this.rig.anyPressing())
    this.warmthSmoothed += (this.director.warmth() - this.warmthSmoothed) * dt * 0.8
  }

  render(): void {
    const p = this.player.pose.pos
    const sp = this.stone.position()
    this.stoneMesh.position.set(sp.x, sp.y, sp.z)
    const rq = this.stone.body.rotation()
    this.stoneMesh.quaternion.set(rq.x, rq.y, rq.z, rq.w)
    // Step bob: phase advances with horizontal distance actually traveled.
    if (this.lastBobPos) {
      const dist = Math.hypot(p.x - this.lastBobPos.x, p.z - this.lastBobPos.z)
      this.bobPhase += dist * ((Math.PI * 2) / 0.75)
    }
    this.lastBobPos = { x: p.x, z: p.z }
    const bobAmount = Math.min(this.player.smoothedSpeed / TUNING.player.walkSpeed, 1)
    this.bodyView.pose(p, this.player.pose.bodyYaw, this.bobPhase, bobAmount, this.rig.engageAmount())
    this.camRig.update(FIXED_DT, this.camera, p, this.player.pose.bodyYaw, this.rig.engageAmount(), this.rig.anyPressing(), this.bobPhase, bobAmount)
    this.sky.setWarmth(this.warmthSmoothed)
    this.dust.update(FIXED_DT)
    this.lighting.follow(p.x, p.z)
    this.sky.mesh.position.copy(this.camera.position)
    this.renderer.render(this.scene, this.camera)
  }
}

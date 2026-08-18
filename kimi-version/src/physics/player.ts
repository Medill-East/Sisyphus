import RAPIER from '@dimforge/rapier3d-compat'
import { TUNING } from '../core/tuning'
import { sampleHeight } from '../world/heightfield'
import { computeNextPose, type PlayerPose } from './playerMath'
import type { PhysicsWorld } from './PhysicsWorld'

export class Player {
  readonly body: RAPIER.RigidBody
  private readonly collider: RAPIER.Collider
  private readonly ctrl: RAPIER.KinematicCharacterController
  /** Feet position (ground contact); the kinematic capsule rides CENTER_OFFSET above it. */
  pose: PlayerPose
  /** Smoothed speed (m/s) — gives the body mass: starts and stops are not instant. */
  smoothedSpeed = 0
  /** Smoothed ground height — kills ratcheting from path micro relief. */
  private smoothY: number | null = null

  private static readonly CENTER_OFFSET = 0.9 + TUNING.player.radius + 0.04

  constructor(pw: PhysicsWorld, x: number, z: number) {
    this.pose = { pos: { x, y: sampleHeight(x, z), z }, bodyYaw: 0 }
    this.body = pw.world.createRigidBody(
      RAPIER.RigidBodyDesc.kinematicPositionBased().setTranslation(x, this.pose.pos.y + Player.CENTER_OFFSET, z),
    )
    this.collider = pw.world.createCollider(
      RAPIER.ColliderDesc.capsule(0.9, TUNING.player.radius),
      this.body,
    )
    this.ctrl = pw.world.createCharacterController(0.02)
    this.ctrl.setApplyImpulsesToDynamicBodies(false) // pushing only happens through hands
  }

  /** Teleport (debug reset): resets pose and all smoothing state. */
  teleport(x: number, z: number, yaw = 0): void {
    const y = sampleHeight(x, z)
    this.pose = { pos: { x, y, z }, bodyYaw: yaw }
    this.smoothY = null
    this.smoothedSpeed = 0
  }

  /** Move with collision; body contact never shoves the stone. */
  move(
    pw: PhysicsWorld,
    intent: { move: { x: number; z: number }; engaged: boolean; stonePos: { x: number; y: number; z: number } | null; headYaw: number },
    dt: number,
  ): void {
    const base = intent.engaged ? TUNING.player.engagedWalkSpeed : TUNING.player.walkSpeed
    const moveLen = Math.min(Math.hypot(intent.move.x, intent.move.z), 1)
    const desired = base * moveLen
    const rate = desired > this.smoothedSpeed ? 7 : 11 // accelerate slower than braking: weight
    this.smoothedSpeed += (desired - this.smoothedSpeed) * (1 - Math.exp(-rate * dt))
    const next = computeNextPose({
      pos: this.pose.pos,
      bodyYaw: this.pose.bodyYaw,
      headYaw: intent.headYaw,
      speedScale: base > 0 ? this.smoothedSpeed / base : 0,
      groundY: sampleHeight,
      dt,
      tuning: TUNING.player,
      intent,
    })
    // Vertical follow is smoothed: micro relief must not ratchet the walk.
    if (this.smoothY === null) this.smoothY = next.pos.y
    this.smoothY += (next.pos.y - this.smoothY) * Math.min(14 * dt, 1)
    next.pos.y = this.smoothY
    const delta = {
      x: next.pos.x - this.pose.pos.x,
      y: next.pos.y - this.pose.pos.y,
      z: next.pos.z - this.pose.pos.z,
    }
    this.ctrl.computeColliderMovement(this.collider, delta)
    const m = this.ctrl.computedMovement()
    this.pose = {
      pos: { x: this.pose.pos.x + m.x, y: this.pose.pos.y + m.y, z: this.pose.pos.z + m.z },
      bodyYaw: next.bodyYaw,
    }
    this.body.setNextKinematicTranslation({
      x: this.pose.pos.x,
      y: this.pose.pos.y + Player.CENTER_OFFSET,
      z: this.pose.pos.z,
    })
  }
}

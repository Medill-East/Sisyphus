import RAPIER from '@dimforge/rapier3d-compat'
import { TUNING } from '../core/tuning'
import { sampleHeight } from '../world/heightfield'
import { computeNextPose, type PlayerPose } from './playerMath'
import type { PhysicsWorld } from './PhysicsWorld'

export class Player {
  readonly body: RAPIER.RigidBody
  private readonly collider: RAPIER.Collider
  private readonly ctrl: RAPIER.KinematicCharacterController
  pose: PlayerPose

  constructor(pw: PhysicsWorld, x: number, z: number) {
    this.pose = { pos: { x, y: sampleHeight(x, z), z }, bodyYaw: 0 }
    this.body = pw.world.createRigidBody(
      RAPIER.RigidBodyDesc.kinematicPositionBased().setTranslation(x, this.pose.pos.y, z),
    )
    this.collider = pw.world.createCollider(
      RAPIER.ColliderDesc.capsule(0.9, TUNING.player.radius),
      this.body,
    )
    this.ctrl = pw.world.createCharacterController(0.02)
    this.ctrl.setApplyImpulsesToDynamicBodies(false) // pushing only happens through hands
  }

  /** Move with collision; body contact never shoves the stone. */
  move(
    pw: PhysicsWorld,
    intent: { move: { x: number; z: number }; engaged: boolean; stonePos: { x: number; y: number; z: number } | null },
    dt: number,
  ): void {
    const next = computeNextPose({
      pos: this.pose.pos,
      bodyYaw: this.pose.bodyYaw,
      groundY: sampleHeight,
      dt,
      tuning: TUNING.player,
      intent,
    })
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
    this.body.setNextKinematicTranslation(this.pose.pos)
  }
}

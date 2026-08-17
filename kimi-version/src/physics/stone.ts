import RAPIER from '@dimforge/rapier3d-compat'
import { TUNING } from '../core/tuning'
import { FIXED_DT, type PhysicsWorld } from './PhysicsWorld'

const S = TUNING.stone
const G = 9.81

export interface PushForce {
  point: { x: number; y: number; z: number }
  dir: { x: number; y: number; z: number }
  magnitude: number
}

export class Stone {
  readonly body: RAPIER.RigidBody
  private readonly pw: PhysicsWorld
  /** True while the static hold keeps the stone parked. */
  held = false

  constructor(pw: PhysicsWorld, x: number, y: number, z: number) {
    this.pw = pw
    this.body = pw.world.createRigidBody(
      RAPIER.RigidBodyDesc.dynamic()
        .setTranslation(x, y, z)
        .setLinearDamping(S.linearDamping)
        .setAngularDamping(S.angularDamping),
    )
    pw.world.createCollider(
      RAPIER.ColliderDesc.ball(S.radius)
        .setFriction(S.friction)
        .setRestitution(S.restitution)
        .setMass(S.mass),
      this.body,
    )
  }

  position(): { x: number; y: number; z: number } {
    return this.body.translation()
  }

  velocity(): { x: number; y: number; z: number } {
    return this.body.linvel()
  }

  speed(): number {
    const v = this.body.linvel()
    return Math.hypot(v.x, v.y, v.z)
  }

  /** Ground slope in degrees under the stone (0 when airborne). */
  groundSlopeDeg(): number {
    const p = this.body.translation()
    const probe = this.pw.groundProbe(p.x, p.y, p.z, this.body)
    if (!probe) return 0
    return (Math.acos(Math.min(Math.max(probe.normalY, -1), 1)) * 180) / Math.PI
  }

  /**
   * Rolling resistance + static hold. Call once per fixed step.
   * `pushing` = any hand currently applying force this step.
   * Static: slow stone on a slope below holdSlopeDeg is parked.
   * Kinetic: resistance opposes horizontal velocity.
   */
  applyResistance(pushing: boolean): void {
    const v = this.body.linvel()
    const hSpeed = Math.hypot(v.x, v.z)
    const slope = this.groundSlopeDeg()
    if (!pushing && hSpeed < S.holdSpeedEps && slope < S.holdSlopeDeg) {
      this.held = true
      this.body.setLinvel({ x: 0, y: v.y, z: 0 }, true)
      this.body.setAngvel({ x: 0, y: 0, z: 0 }, true)
      return
    }
    this.held = false
    if (hSpeed > 1e-4) {
      // Rolling resistance as deceleration (m/s²): a = k · g, capped to never reverse.
      const decel = S.kineticResistance * G * FIXED_DT
      const scale = Math.min(decel, hSpeed) / hSpeed
      this.body.applyImpulse({ x: -v.x * S.mass * scale, y: 0, z: -v.z * S.mass * scale }, true)
    }
  }

  /**
   * Apply this step's per-hand push forces at their contact points.
   * From rest, the static breakaway threshold is subtracted first — a
   * stalled stone needs visible effort before it starts moving.
   */
  applyPush(hands: PushForce[]): void {
    let scale = 1
    if (this.speed() < S.holdSpeedEps) {
      const total = hands.reduce((sum, h) => sum + h.magnitude, 0)
      const net = Math.max(total - S.staticBreakawayForce, 0)
      scale = total > 1e-6 ? net / total : 0
    }
    for (const h of hands) {
      const impulse = h.magnitude * scale * FIXED_DT
      this.body.applyImpulseAtPoint(
        { x: h.dir.x * impulse, y: h.dir.y * impulse, z: h.dir.z * impulse },
        h.point,
        true,
      )
    }
  }
}

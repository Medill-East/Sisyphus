import type { Vec3 } from './vec3'

export interface PlayerStepInput {
  pos: Vec3
  bodyYaw: number
  /** Current head yaw — in free mode the body simply matches it (FPS scheme). */
  headYaw: number
  groundY: (x: number, z: number) => number
  dt: number
  tuning: { walkSpeed: number; engagedWalkSpeed: number; turnLerp: number }
  intent: {
    move: { x: number; z: number }
    engaged: boolean
    stonePos: Vec3 | null
  }
}

export interface PlayerPose {
  pos: Vec3
  bodyYaw: number
}

const wrapAngle = (a: number) => Math.atan2(Math.sin(a), Math.cos(a))

/**
 * One movement step. Free mode: body yaw = head yaw (the mouse steers the
 * body; WASD is gaze-relative). Engaged: body squares to the stone instead.
 * Move intent rotates by body yaw: forward = (−sin yaw, 0, −cos yaw),
 * right = (cos yaw, 0, −sin yaw).
 */
export function computeNextPose(input: PlayerStepInput): PlayerPose {
  const { pos, intent, tuning, dt } = input
  const speed = intent.engaged ? tuning.engagedWalkSpeed : tuning.walkSpeed

  let targetYaw = input.headYaw
  if (intent.engaged && intent.stonePos) {
    targetYaw = Math.atan2(-(intent.stonePos.x - pos.x), -(intent.stonePos.z - pos.z))
  }
  const k = 1 - Math.exp(-tuning.turnLerp * dt)
  const yaw = input.bodyYaw + wrapAngle(targetYaw - input.bodyYaw) * (intent.engaged ? k : 1)

  const fwd = { x: -Math.sin(yaw), z: -Math.cos(yaw) }
  const right = { x: Math.cos(yaw), z: -Math.sin(yaw) }
  const mx = intent.move.x
  const mz = intent.move.z
  const len = Math.hypot(mx, mz)
  const nx = len > 1 ? mx / len : mx
  const nz = len > 1 ? mz / len : mz
  const dx = (right.x * nx + fwd.x * -nz) * speed * dt
  const dz = (right.z * nx + fwd.z * -nz) * speed * dt
  const x = pos.x + dx
  const z = pos.z + dz

  return { pos: { x, y: input.groundY(x, z), z }, bodyYaw: yaw }
}

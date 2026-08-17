import type { Vec3 } from './vec3'

export interface PlayerStepInput {
  pos: Vec3
  bodyYaw: number
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
 * One movement step. Body-relative move intent is rotated by body yaw:
 * forward = (−sin yaw, 0, −cos yaw), right = (cos yaw, 0, −sin yaw).
 * Engaged: body squares to the stone; free: body follows the move direction.
 */
export function computeNextPose(input: PlayerStepInput): PlayerPose {
  const { pos, bodyYaw, intent, tuning, dt } = input
  const speed = intent.engaged ? tuning.engagedWalkSpeed : tuning.walkSpeed
  const fwd = { x: -Math.sin(bodyYaw), z: -Math.cos(bodyYaw) }
  const right = { x: Math.cos(bodyYaw), z: -Math.sin(bodyYaw) }
  const mx = intent.move.x
  const mz = intent.move.z
  const len = Math.hypot(mx, mz)
  const nx = len > 1 ? mx / len : mx
  const nz = len > 1 ? mz / len : mz
  const dx = (right.x * nx + fwd.x * -nz) * speed * dt
  const dz = (right.z * nx + fwd.z * -nz) * speed * dt
  const x = pos.x + dx
  const z = pos.z + dz

  let targetYaw = bodyYaw
  if (intent.engaged && intent.stonePos) {
    targetYaw = Math.atan2(-(intent.stonePos.x - pos.x), -(intent.stonePos.z - pos.z))
  } else if (len > 0.01) {
    targetYaw = Math.atan2(-dx, -dz)
  }
  const k = 1 - Math.exp(-tuning.turnLerp * dt)
  const yaw = bodyYaw + wrapAngle(targetYaw - bodyYaw) * k

  return { pos: { x, y: input.groundY(x, z), z }, bodyYaw: yaw }
}

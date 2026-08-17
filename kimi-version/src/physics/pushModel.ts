import { add, normalize, scale, sub, type Vec3 } from './vec3'

export interface PushTuningLike {
  reachDistance: number
  shoulderHeight: number
  shoulderHalfWidth: number
}

/**
 * Shoulder world position.
 * Convention (locked by tests/pushModel.test.ts): yaw 0 faces −z, so
 * forward = (−sin yaw, 0, −cos yaw) and right = (cos yaw, 0, −sin yaw).
 * side −1 = left hand, +1 = right hand.
 */
export function computeShoulder(playerPos: Vec3, bodyYaw: number, side: -1 | 1, P: PushTuningLike): Vec3 {
  const right = { x: Math.cos(bodyYaw), y: 0, z: -Math.sin(bodyYaw) }
  return add(playerPos, {
    x: side * P.shoulderHalfWidth * right.x,
    y: P.shoulderHeight,
    z: side * P.shoulderHalfWidth * right.z,
  })
}

export interface HandContact {
  /** Point on the sphere surface where the palm lands. */
  point: Vec3
  /** Push direction (unit): shoulder → sphere center. Also the surface normal at `point`. */
  dir: Vec3
}

export function computeHandContact(center: Vec3, radius: number, shoulder: Vec3): HandContact {
  const dir = normalize(sub(center, shoulder))
  return { point: sub(center, scale(dir, radius)), dir }
}

/** Chest-to-surface reach check (horizontal distance to the surface). */
export function withinReach(center: Vec3, radius: number, chest: Vec3, reach: number): boolean {
  return Math.hypot(chest.x - center.x, chest.z - center.z) - radius < reach
}

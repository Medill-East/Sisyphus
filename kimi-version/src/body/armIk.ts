import { add, dot, length, normalize, scale, sub, type Vec3 } from '../physics/vec3'

export interface IkResult {
  elbow: Vec3
  wrist: Vec3
}

/**
 * Analytic two-bone IK. The elbow lies in the plane spanned by
 * (shoulder→target) and the pole direction, bowed toward the pole.
 * Out-of-reach targets clamp to just under full extension.
 */
export function solveTwoBoneIK(shoulder: Vec3, target: Vec3, l1: number, l2: number, pole: Vec3): IkResult {
  const toTarget = sub(target, shoulder)
  const maxReach = l1 + l2 - 1e-3
  const dist = Math.min(length(toTarget), maxReach)
  const dir = normalize(toTarget)

  // Law of cosines: how far along dir the elbow's projection sits.
  const cosA = (l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * Math.max(dist, 1e-6))
  const along = l1 * Math.min(Math.max(cosA, -1), 1)
  const up = Math.sqrt(Math.max(l1 * l1 - along * along, 0))

  // Bend direction: component of pole perpendicular to dir.
  const bend = normalize(sub(pole, scale(dir, dot(pole, dir))))
  const elbow = add(shoulder, add(scale(dir, along), scale(bend, up)))
  const wrist = add(shoulder, scale(dir, dist))
  return { elbow, wrist }
}

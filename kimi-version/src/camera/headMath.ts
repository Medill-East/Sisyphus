export interface NeckLimits {
  yawDeg: number
  pitchUpDeg: number
  pitchDownDeg: number
}

const wrap = (a: number) => Math.atan2(Math.sin(a), Math.cos(a))
const clamp = (v: number, lo: number, hi: number) => Math.min(Math.max(v, lo), hi)
const rad = (d: number) => (d * Math.PI) / 180

/** Clamp an absolute head yaw/pitch to neck limits measured from body yaw. */
export function clampHead(headYaw: number, pitch: number, bodyYaw: number, L: NeckLimits): { yaw: number; pitch: number } {
  const rel = wrap(headYaw - bodyYaw)
  return {
    yaw: bodyYaw + clamp(rel, -rad(L.yawDeg), rad(L.yawDeg)),
    pitch: clamp(pitch, -rad(L.pitchDownDeg), rad(L.pitchUpDeg)),
  }
}

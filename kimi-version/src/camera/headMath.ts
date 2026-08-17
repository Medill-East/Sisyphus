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

/**
 * Gentle gaze bias while engaged: pull the head pitch toward the contact
 * area (you naturally watch your hands on the stone), but never steeper
 * than −25° so the path over the stone's top stays in frame.
 * Returns the pitch delta to apply this frame; weak enough that user look
 * input overrides it.
 */
export function engagePitchBias(
  eyeY: number,
  eyeToContact: { x: number; y: number; z: number },
  currentPitch: number,
  engage: number,
  strength = 1.6,
): number {
  const flat = Math.hypot(eyeToContact.x, eyeToContact.z)
  if (flat < 1e-4 || engage <= 0) return 0
  const raw = Math.atan2(eyeToContact.y - eyeY, flat) // negative = look down
  const targetPitch = Math.max(raw, -0.44)
  return (targetPitch - currentPitch) * Math.min(strength * engage, 1)
}

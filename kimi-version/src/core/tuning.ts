/** Every gameplay/visual tunable in one place. Distances in meters, forces in newtons. */
export const TUNING = {
  stone: {
    radius: 1.0,
    mass: 220,
    friction: 0.9,
    restitution: 0,
    angularDamping: 0.05,
    linearDamping: 0.02,
    /** Below this ground slope (deg) a slow stone is statically held. */
    holdSlopeDeg: 8,
    /** Speed (m/s) under which the static hold may engage. */
    holdSpeedEps: 0.18,
    /** Kinetic rolling resistance coefficient (force = k * m * g). */
    kineticResistance: 0.02,
    /** Extra static resistance force (N) that must be overcome to break away. */
    staticBreakawayForce: 260,
  },
  push: {
    /** Force per fully-pressed hand (N). */
    maxForcePerHand: 950,
    /** Chest-to-surface distance (m) within which hands may engage. */
    reachDistance: 0.72,
    /** Hysteresis multiplier for staying engaged. */
    reachHysteresis: 1.18,
    shoulderHeight: 1.32,
    shoulderHalfWidth: 0.24,
  },
  player: {
    eyeHeight: 1.62,
    radius: 0.34,
    walkSpeed: 3.4,
    engagedWalkSpeed: 1.9,
    turnLerp: 10,
  },
  camera: {
    fov: 62,
    engagedFov: 55,
    neckYawLimitDeg: 120,
    neckPitchUpDeg: 55,
    neckPitchDownDeg: 40,
    engageEase: 4.5,
  },
  mountain: {
    ridgeHeight: 16,
    frontLength: 85,
    backLength: 65,
    pathHalfWidth: 2.2,
    bankRise: 2.6,
    noiseAmplitude: 0.22,
    worldHalfX: 40,
  },
  loop: {
    releaseWatchSeconds: 3.0,
    restSpeedEps: 0.25,
    restHoldSeconds: 1.5,
    resultDistance: 3.0,
  },
} as const

export type Tuning = typeof TUNING

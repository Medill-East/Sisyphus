/** Every gameplay/visual tunable in one place. Distances in meters, forces in newtons. */
export const TUNING = {
  stone: {
    radius: 1.1,
    mass: 220,
    friction: 0.9,
    restitution: 0,
    angularDamping: 0.05,
    linearDamping: 0.02,
    /** Below this ground slope (deg) a slow stone is statically held. */
    holdSlopeDeg: 3.5,
    /** Speed (m/s) under which the static hold may engage. */
    holdSpeedEps: 0.18,
    /** Kinetic rolling resistance coefficient (decel = k · g); balances gravity at ~atan(k) ≈ 2°. */
    kineticResistance: 0.035,
    /** Extra static resistance force (N) that must be overcome to break away. */
    staticBreakawayForce: 700,
  },
  push: {
    /** Force per fully-pressed hand (N); two hands ≈ 1.2× the steepest-pitch hold need. */
    maxForcePerHand: 380,
    /** The heave: push direction is tilted up along the stone's surface (deg). */
    heaveDeg: 35,
    /** Hand speed limit (m/s): push force fades as the stone outruns the hands. */
    handSpeedMax: 1.2,
    /** Fade band (m/s) above handSpeedMax down to zero force. */
    handSpeedFade: 0.9,
    /** Chest-to-surface distance (m) within which hands may engage. */
    reachDistance: 0.72,
    /** Hysteresis multiplier for staying engaged. */
    reachHysteresis: 1.18,
    shoulderHeight: 1.32,
    /** Wider shoulders give single-hand correction real lateral authority. */
    shoulderHalfWidth: 0.3,
  },
  player: {
    eyeHeight: 1.62,
    /** Capsule radius doubles as the push-stance standoff from the stone surface. */
    radius: 0.45,
    walkSpeed: 3.4,
    engagedWalkSpeed: 2.1,
    turnLerp: 10,
  },
  camera: {
    fov: 62,
    engagedFov: 55,
    neckYawLimitDeg: 120,
    neckPitchUpDeg: 55,
    neckPitchDownDeg: 40,
    /** Engage/disengage camera blend speed — slow enough to feel continuous. */
    engageEase: 2.2,
  },
  mountain: {
    ridgeHeight: 16,
    frontLength: 85,
    backLength: 72,
    pathHalfWidth: 2.2,
    /** Low berm lip at the track's edge (the worn track guides, not walls). */
    bermRise: 0.5,
    noiseAmplitude: 0.22,
    /** On-path micro relief (m): makes the stone wander, demands hand correction. */
    pathNoiseAmplitude: 0.04,
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

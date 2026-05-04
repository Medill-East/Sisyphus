export type GamePhase = 'approach' | 'ascent' | 'release' | 'descent' | 'complete'

export type CameraMode =
  | 'third-person'
  | 'close-third-person'
  | 'first-person'
  | 'wide-third-person'

export type Vector3Tuple = [number, number, number]

export interface TuningConfig {
  rockMass: number
  rockFriction: number
  pushForce: number
  slopeGrade: number
  windResistance: number
  cameraBlendDistance: number
  humClarity: number
  trailGrowthStrength: number
  targetAscentSeconds: number
}

export interface RunMetrics {
  ascentSeconds: number
  rollbackCount: number
  stabilityScore: number
  rewardLevel: number
}

export interface HumReward {
  rewardLevel: number
  clarity: number
}

export interface TrailPoint {
  position: Vector3Tuple
  time: number
}

export interface PhaseSignals {
  playerDistanceToRock?: number
  rockHeight?: number
  releaseSeconds?: number
}

export const defaultTuning: TuningConfig = {
  rockMass: 18,
  rockFriction: 0.72,
  pushForce: 48,
  slopeGrade: 0.28,
  windResistance: 0.18,
  cameraBlendDistance: 4.4,
  humClarity: 0.72,
  trailGrowthStrength: 0.8,
  targetAscentSeconds: 180,
}

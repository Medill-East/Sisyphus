import type {
  CameraMode,
  GamePhase,
  HumReward,
  PhaseSignals,
  RunMetrics,
  TrailPoint,
  Vector3Tuple,
} from './types'

export function createInitialRunMetrics(): RunMetrics {
  return {
    ascentSeconds: 0,
    rollbackCount: 0,
    stabilityScore: 1,
    rewardLevel: 0,
  }
}

export function getPhaseLabel(phase: GamePhase): string {
  const labels: Record<GamePhase, string> = {
    approach: 'Approach',
    ascent: 'Ascent',
    release: 'Release',
    descent: 'Descent',
    complete: 'Complete',
  }

  return labels[phase]
}

export function shouldAdvancePhase(
  phase: GamePhase,
  signals: PhaseSignals,
): GamePhase {
  if (phase === 'approach' && (signals.playerDistanceToRock ?? Infinity) <= 1.6) {
    return 'ascent'
  }

  if (phase === 'ascent' && (signals.rockHeight ?? 0) >= 9) {
    return 'release'
  }

  if (phase === 'release' && (signals.releaseSeconds ?? 0) >= 3) {
    return 'descent'
  }

  if (
    phase === 'descent' &&
    (signals.playerDistanceToRock ?? Infinity) <= 1.6 &&
    (signals.rockHeight ?? Infinity) <= 2.2
  ) {
    return 'complete'
  }

  return phase
}

export function getCameraMode(
  phase: GamePhase,
  playerDistanceToRock: number,
  blendDistance = 4.5,
): CameraMode {
  if (phase === 'descent' || phase === 'complete') {
    return 'wide-third-person'
  }

  if (phase === 'ascent' || playerDistanceToRock <= blendDistance * 0.42) {
    return 'first-person'
  }

  if (playerDistanceToRock <= blendDistance) {
    return 'close-third-person'
  }

  return 'third-person'
}

export function calculateHumReward(metrics: RunMetrics): HumReward {
  if (
    metrics.ascentSeconds > 0 &&
    metrics.ascentSeconds <= 95 &&
    metrics.rollbackCount === 0 &&
    metrics.stabilityScore >= 0.9
  ) {
    return { rewardLevel: 3, clarity: 1 }
  }

  if (
    metrics.ascentSeconds > 0 &&
    metrics.ascentSeconds <= 150 &&
    metrics.rollbackCount <= 1 &&
    metrics.stabilityScore >= 0.72
  ) {
    return { rewardLevel: 2, clarity: 0.65 }
  }

  return { rewardLevel: 1, clarity: 0.35 }
}

export function recordTrailPoint(
  trail: TrailPoint[],
  position: Vector3Tuple,
  time: number,
  minDistance: number,
): TrailPoint[] {
  const last = trail.at(-1)

  if (!last || distance(last.position, position) >= minDistance) {
    return [...trail, { position, time }]
  }

  return trail
}

function distance(a: Vector3Tuple, b: Vector3Tuple): number {
  const x = a[0] - b[0]
  const y = a[1] - b[1]
  const z = a[2] - b[2]

  return Math.sqrt(x * x + y * y + z * z)
}

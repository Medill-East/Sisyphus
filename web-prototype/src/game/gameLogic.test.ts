import { describe, expect, it } from 'vitest'
import {
  calculateHumReward,
  createInitialRunMetrics,
  getCameraMode,
  getPhaseLabel,
  recordTrailPoint,
  shouldAdvancePhase,
} from './gameLogic'
import type { GamePhase, TrailPoint } from './types'

describe('game phase flow', () => {
  it('advances through the prototype loop from approach to complete', () => {
    expect(shouldAdvancePhase('approach', { playerDistanceToRock: 1.2 })).toBe(
      'ascent',
    )
    expect(shouldAdvancePhase('ascent', { rockHeight: 9.2 })).toBe('release')
    expect(shouldAdvancePhase('release', { releaseSeconds: 3.1 })).toBe(
      'descent',
    )
    expect(
      shouldAdvancePhase('descent', { playerDistanceToRock: 1.1, rockHeight: 1 }),
    ).toBe('complete')
  })

  it('keeps phase labels concise for the in-game HUD', () => {
    const phases: GamePhase[] = [
      'approach',
      'ascent',
      'release',
      'descent',
      'complete',
    ]

    expect(phases.map(getPhaseLabel)).toEqual([
      'Approach',
      'Ascent',
      'Release',
      'Descent',
      'Complete',
    ])
  })
})

describe('camera mode', () => {
  it('uses distance and phase to blend from third person into first person', () => {
    expect(getCameraMode('approach', 8)).toBe('third-person')
    expect(getCameraMode('approach', 3)).toBe('close-third-person')
    expect(getCameraMode('ascent', 1.2)).toBe('first-person')
    expect(getCameraMode('descent', 6)).toBe('wide-third-person')
  })
})

describe('run metrics and rewards', () => {
  it('rewards fast and stable climbs with clearer humming', () => {
    const metrics = createInitialRunMetrics()

    expect(calculateHumReward({ ...metrics, ascentSeconds: 240 })).toEqual({
      rewardLevel: 1,
      clarity: 0.35,
    })
    expect(
      calculateHumReward({
        ...metrics,
        ascentSeconds: 80,
        rollbackCount: 0,
        stabilityScore: 0.94,
      }),
    ).toEqual({ rewardLevel: 3, clarity: 1 })
  })
})

describe('trail recording', () => {
  it('samples trail points only after the rock moves far enough', () => {
    const trail: TrailPoint[] = []
    const first = recordTrailPoint(trail, [0, 0, 0], 0, 0.6)
    const skipped = recordTrailPoint(first, [0.2, 0, 0.2], 1, 0.6)
    const sampled = recordTrailPoint(skipped, [0.7, 0, 0.2], 2, 0.6)

    expect(first).toHaveLength(1)
    expect(skipped).toHaveLength(1)
    expect(sampled).toHaveLength(2)
    expect(sampled[1]).toMatchObject({ position: [0.7, 0, 0.2], time: 2 })
  })
})

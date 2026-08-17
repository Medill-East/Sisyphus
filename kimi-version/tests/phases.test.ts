import { describe, expect, it } from 'vitest'
import { advancePhase, initialRun, type LoopSignals } from '../src/game/phases'

const base: LoopSignals = {
  stoneZ: 80,
  stoneSpeed: 0,
  playerDistToStone: 3,
  handsRaised: false,
  handsPressing: false,
  secondsInPhase: 0,
}

describe('loop phases', () => {
  it('walks the full beat sequence', () => {
    let run = initialRun()
    expect(run.phase).toBe('approach')
    run = advancePhase(run, { ...base, handsRaised: true })
    expect(run.phase).toBe('engaged')
    run = advancePhase(run, { ...base, handsRaised: true, handsPressing: true, stoneZ: -0.5 }) // over the crest
    expect(run.phase).toBe('release')
    run = advancePhase(run, { ...base, stoneZ: -20, stoneSpeed: 0.1, secondsInPhase: 4 })
    expect(run.phase).toBe('descent')
    run = advancePhase(run, { ...base, stoneZ: -60, stoneSpeed: 0, playerDistToStone: 2 })
    expect(run.phase).toBe('result')
    run = advancePhase(run, { ...base, handsRaised: true }) // hovering alone does not restart
    expect(run.phase).toBe('result')
    run = advancePhase(run, { ...base, handsPressing: true })
    expect(run.phase).toBe('approach') // next loop starts fresh
  })

  it('counts a rollback when the stone retreats more than 2 m from best progress', () => {
    let run = initialRun()
    run = advancePhase(run, { ...base, handsRaised: true }) // engaged, stoneZ tracked
    run = advancePhase({ ...run, bestStoneZ: 40 }, { ...base, handsRaised: true, stoneZ: 43 })
    expect(run.rollbacks).toBe(1)
  })

  it('accumulates ascent time only while pressing', () => {
    let run = initialRun()
    run = advancePhase(run, { ...base, handsRaised: true })
    run = advancePhase(run, { ...base, handsRaised: true })
    expect(run.ascentSeconds).toBe(0)
    run = advancePhase(run, { ...base, handsRaised: true, handsPressing: true })
    expect(run.ascentSeconds).toBeCloseTo(1 / 60)
  })

  it('result carries ascent seconds', () => {
    let run = { ...initialRun(), phase: 'release' as const, ascentSeconds: 95 }
    run = advancePhase(run, { ...base, stoneZ: -20, stoneSpeed: 0.1, secondsInPhase: 4 })
    expect(run.ascentSeconds).toBe(95)
  })
})

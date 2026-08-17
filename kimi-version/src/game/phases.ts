export type LoopPhase = 'approach' | 'engaged' | 'release' | 'descent' | 'result'

export interface RunState {
  phase: LoopPhase
  rollbacks: number
  ascentSeconds: number
  bestStoneZ: number // smallest |z| reached on the climbing side = best progress
  climbSide: 1 | -1 // +1: climbing the front (+z → 0); −1: the back
}

export interface LoopSignals {
  stoneZ: number
  stoneSpeed: number
  playerDistToStone: number
  /** Hands raised onto the stone (engaged stance, not necessarily pressing). */
  handsRaised: boolean
  /** At least one hand actively pressing. */
  handsPressing: boolean
  secondsInPhase: number
}

export const initialRun = (): RunState => ({
  phase: 'approach',
  rollbacks: 0,
  ascentSeconds: 0,
  bestStoneZ: Infinity,
  climbSide: 1,
})

const ROLLBACK_METERS = 2

export function advancePhase(run: RunState, s: LoopSignals): RunState {
  const next = { ...run }
  // Rollback accounting is active whenever climbing on either side.
  if (run.phase === 'engaged') {
    const progress = Math.abs(s.stoneZ)
    if (progress < run.bestStoneZ) next.bestStoneZ = progress
    else if (progress > run.bestStoneZ + ROLLBACK_METERS) {
      next.rollbacks += 1
      next.bestStoneZ = progress
    }
  }
  switch (run.phase) {
    case 'approach':
      if (s.handsRaised) next.phase = 'engaged'
      break
    case 'engaged':
      if (s.handsPressing) next.ascentSeconds += 1 / 60
      // Crest crossed: the stone's z sign flips away from the climb side.
      if (Math.sign(s.stoneZ) !== run.climbSide && Math.abs(s.stoneZ) > 0.3) next.phase = 'release'
      break
    case 'release':
      if (s.secondsInPhase > 3 && s.stoneSpeed < 0.25) next.phase = 'descent'
      break
    case 'descent':
      if (s.playerDistToStone < 3 && s.stoneSpeed < 0.25) next.phase = 'result'
      break
    case 'result':
      if (s.handsPressing) {
        return { ...initialRun(), climbSide: run.climbSide === 1 ? -1 : 1 }
      }
      break
  }
  return next
}

import { advancePhase, initialRun, type RunState } from './phases'
import type { Vec3 } from '../physics/vec3'

/** Feeds world signals into the pure phase machine and exposes run state. */
export class LoopDirector {
  run: RunState = initialRun()
  private secondsInPhase = 0
  private lastPhase = this.run.phase

  update(dt: number, stonePos: Vec3, stoneSpeed: number, playerPos: Vec3, handsRaised: boolean, handsPressing: boolean): void {
    this.secondsInPhase += dt
    this.run = advancePhase(this.run, {
      stoneZ: stonePos.z,
      stoneSpeed,
      playerDistToStone: Math.hypot(playerPos.x - stonePos.x, playerPos.z - stonePos.z),
      handsRaised,
      handsPressing,
      secondsInPhase: this.secondsInPhase,
    })
    if (this.run.phase !== this.lastPhase) {
      this.secondsInPhase = 0
      this.lastPhase = this.run.phase
    }
  }

  /** Descent warmth 0..1 for the sky/lighting. */
  warmth(): number {
    return this.run.phase === 'descent' || this.run.phase === 'result' ? 1 : 0
  }
}

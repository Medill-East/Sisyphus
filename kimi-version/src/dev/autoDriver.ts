import type { InputSource } from '../core/Game'
import { IDLE_INTENT, type InputIntent } from '../core/input'
import type { Vec3 } from '../physics/vec3'

/**
 * Scripted intents for screenshot beats, selected with ?auto=<beat>&t=<seconds>.
 * The game sets window.__beatReady once `t` seconds have elapsed so the
 * capture script can screenshot a stable pose.
 *
 * The driver is a minimally competent pusher: it tracks the stone laterally
 * and stops feeding force while the stone is rolling back (a human would
 * let go and watch).
 */
export class AutoDriver implements InputSource {
  private time = 0
  private stone: Vec3 | null = null
  private self: Vec3 | null = null
  private lastStoneZ: number | null = null
  private rollbackWindow = 0

  constructor(private readonly beat: string, private readonly duration: number) {}

  /** Called by Game each fixed step before poll. */
  sense(stonePos: Vec3, playerPos: Vec3): void {
    this.stone = stonePos
    this.self = playerPos
  }

  private get trackingX(): number {
    if (!this.stone || !this.self) return 0
    return Math.max(-1, Math.min(1, (this.stone.x - this.self.x) * 0.8))
  }

  /** True while the stone is rolling back downhill (>0.8 m in the last second). */
  private get rollingBack(): boolean {
    return this.rollbackWindow > 0.8
  }

  poll(dt: number): InputIntent {
    this.time += dt
    if (this.time >= this.duration) {
      ;(window as unknown as { __beatReady?: boolean }).__beatReady = true
    }
    if (this.stone) {
      if (this.lastStoneZ !== null) {
        const dz = this.stone.z - this.lastStoneZ
        this.rollbackWindow = Math.max(0, this.rollbackWindow * 0.94 + dz * 60 * dt * 0.06 * 60)
      }
      this.lastStoneZ = this.stone.z
    }
    const walkIn = this.time < 1.5
    const x = this.trackingX
    switch (this.beat) {
      case 'approach':
        return { ...IDLE_INTENT, move: { x: 0, z: -1 } }
      case 'hover': // walk into reach, no buttons
        return walkIn ? { ...IDLE_INTENT, move: { x: 0, z: -1 } } : IDLE_INTENT
      case 'press': // walk in, then both hands full while following
        if (walkIn) return { ...IDLE_INTENT, move: { x: 0, z: -1 } }
        if (this.rollingBack) return { ...IDLE_INTENT, move: { x, z: 0 } }
        return { ...IDLE_INTENT, move: { x, z: -1 }, leftHand: 1, rightHand: 1 }
      case 'left': // break away with both, then left hand only — stone visibly deflects right
        if (walkIn) return { ...IDLE_INTENT, move: { x: 0, z: -1 } }
        if (this.time < 2.2) return { ...IDLE_INTENT, move: { x, z: -1 }, leftHand: 1, rightHand: 1 }
        return { ...IDLE_INTENT, move: { x, z: -1 }, leftHand: 1, rightHand: 0 }
      case 'release': // push all the way to the crest
        if (walkIn) return { ...IDLE_INTENT, move: { x: 0, z: -1 } }
        if (this.rollingBack) return { ...IDLE_INTENT, move: { x, z: 0 } }
        return { ...IDLE_INTENT, move: { x, z: -1 }, leftHand: 1, rightHand: 1 }
      case 'descent': // push to the crest, let go, walk on
        if (walkIn) return { ...IDLE_INTENT, move: { x: 0, z: -1 } }
        if (this.time < 55) {
          if (this.rollingBack) return { ...IDLE_INTENT, move: { x, z: 0 } }
          return { ...IDLE_INTENT, move: { x, z: -1 }, leftHand: 1, rightHand: 1 }
        }
        return { ...IDLE_INTENT, move: { x: 0, z: -1 } }
      default:
        return IDLE_INTENT
    }
  }
}

export function autoFromUrl(): AutoDriver | null {
  const q = new URLSearchParams(location.search)
  const beat = q.get('auto')
  if (!beat) return null
  return new AutoDriver(beat, Number(q.get('t') ?? '3'))
}

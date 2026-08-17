import type { InputSource } from '../core/Game'
import { IDLE_INTENT, type InputIntent } from '../core/input'

/**
 * Scripted intents for screenshot beats, selected with ?auto=<beat>&t=<seconds>.
 * The game sets window.__beatReady once `t` seconds have elapsed so the
 * capture script can screenshot a stable pose.
 */
export class AutoDriver implements InputSource {
  private time = 0

  constructor(private readonly beat: string, private readonly duration: number) {}

  poll(dt: number): InputIntent {
    this.time += dt
    if (this.time >= this.duration) {
      ;(window as unknown as { __beatReady?: boolean }).__beatReady = true
    }
    switch (this.beat) {
      case 'approach':
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

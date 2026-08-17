import { describe, expect, it } from 'vitest'
import { computeNextPose } from '../src/physics/playerMath'
import { TUNING } from '../src/core/tuning'

const base = {
  pos: { x: 0, y: 0, z: 10 },
  bodyYaw: 0,
  groundY: () => 0,
  dt: 1 / 60,
  tuning: TUNING.player,
}

describe('playerMath', () => {
  it('walks forward relative to body yaw', () => {
    const next = computeNextPose({ ...base, intent: { move: { x: 0, z: -1 }, engaged: false, stonePos: null } })
    expect(next.pos.z).toBeLessThan(10)
    expect(next.bodyYaw).toBeCloseTo(0, 1)
  })

  it('strafe right (+x intent) moves along the right vector', () => {
    const next = computeNextPose({ ...base, intent: { move: { x: 1, z: 0 }, engaged: false, stonePos: null } })
    expect(next.pos.x).toBeGreaterThan(0)
  })

  it('engaged mode faces the stone and moves slower', () => {
    const stone = { x: 1, y: 1, z: 5 }
    const next = computeNextPose({ ...base, intent: { move: { x: 0, z: -1 }, engaged: true, stonePos: stone } })
    const toStone = Math.atan2(-(stone.x - 0), -(stone.z - 10))
    expect(next.bodyYaw).toBeCloseTo(toStone, 0)
    expect(10 - next.pos.z).toBeLessThan(TUNING.player.walkSpeed / 60 + 1e-6)
  })

  it('clamps to ground height', () => {
    const next = computeNextPose({ ...base, groundY: () => 3.5, intent: { move: { x: 0, z: -1 }, engaged: false, stonePos: null } })
    expect(next.pos.y).toBe(3.5)
  })
})

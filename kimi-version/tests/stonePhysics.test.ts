import { beforeAll, describe, expect, it } from 'vitest'
import RAPIER from '@dimforge/rapier3d-compat'
import { PhysicsWorld } from '../src/physics/PhysicsWorld'
import { Stone } from '../src/physics/stone'
import { sampleHeight } from '../src/world/heightfield'
import { TUNING } from '../src/core/tuning'

beforeAll(async () => {
  await RAPIER.init()
})

/** Step the world n times, applying stone resistance each step (no push input). */
function settle(pw: PhysicsWorld, stone: Stone, steps: number) {
  for (let i = 0; i < steps; i++) {
    stone.applyResistance(false)
    pw.step()
  }
}

function dropAndSettle(pw: PhysicsWorld, x: number, z: number, seconds = 4) {
  const stone = new Stone(pw, x, sampleHeight(x, z) + TUNING.stone.radius + 1.5, z)
  settle(pw, stone, Math.round(seconds * 60))
  return stone
}

describe('stone on terrain', () => {
  it('rests on the surface at drop position height', () => {
    const pw = new PhysicsWorld()
    const z = TUNING.mountain.frontLength - 2 // near foot, gentle
    const stone = dropAndSettle(pw, 0, z)
    const y = stone.position().y
    expect(y).toBeCloseTo(sampleHeight(0, z) + TUNING.stone.radius, 0)
  })

  it('holds still on a gentle grade (below hold slope)', () => {
    const pw = new PhysicsWorld()
    const z = TUNING.mountain.frontLength * 0.92 // grade ~3 deg
    const stone = dropAndSettle(pw, 0, z)
    const start = stone.position()
    settle(pw, stone, 240)
    const end = stone.position()
    expect(Math.hypot(end.x - start.x, end.z - start.z)).toBeLessThan(0.3)
  })

  it('rolls back downhill on a steep grade (above hold slope)', () => {
    const pw = new PhysicsWorld()
    const z = TUNING.mountain.frontLength * 0.5 // mid-slope ~16 deg
    const stone = dropAndSettle(pw, 0, z, 2)
    const z0 = stone.position().z
    let moved = false
    for (let i = 0; i < 360; i++) {
      stone.applyResistance(false)
      pw.step()
      if (stone.position().z > z0 + 1.0) moved = true // downhill on front side is +z
    }
    expect(moved).toBe(true)
  })
})

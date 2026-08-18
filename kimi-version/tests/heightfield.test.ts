import { describe, expect, it } from 'vitest'
import { sampleHeight, slopeDegAt } from '../src/world/heightfield'
import { TUNING } from '../src/core/tuning'

const M = TUNING.mountain

describe('heightfield', () => {
  it('is (nearly) zero at both feet and ridge height at crest', () => {
    expect(Math.abs(sampleHeight(0, M.frontLength))).toBeLessThan(0.01)
    expect(Math.abs(sampleHeight(0, -M.backLength))).toBeLessThan(0.01)
    expect(sampleHeight(0, 0)).toBeCloseTo(M.ridgeHeight, 1)
  })

  it('descends overall away from the ridge on the path (small relief allowed)', () => {
    for (const side of [1, -1]) {
      const L = side > 0 ? M.frontLength : M.backLength
      let prev = Infinity
      for (let i = 0; i <= 20; i++) {
        const h = sampleHeight(0, side * (i / 20) * L)
        expect(h).toBeLessThanOrEqual(prev + 0.06) // micro relief, not real uphill
        prev = h
      }
    }
  })

  it('max path grade stays pushable (10–24 deg) on both sides', () => {
    for (const side of [1, -1]) {
      const L = side > 0 ? M.frontLength : M.backLength
      let maxG = 0
      for (let i = 1; i < 100; i++) {
        maxG = Math.max(maxG, slopeDegAt(0, side * (i / 100) * L))
      }
      expect(maxG).toBeGreaterThan(10)
      expect(maxG).toBeLessThan(24)
    }
  })

  it('worn track: low berm lip at the edge, open fall beyond, small on-path relief', () => {
    const z = M.frontLength * 0.5
    const center = sampleHeight(0, z)
    expect(sampleHeight(M.pathHalfWidth * 1.9, z)).toBeGreaterThan(center + 0.3) // berm lip
    expect(sampleHeight(20, z)).toBeLessThan(center - 5) // open hillside falls away
    expect(Math.abs(sampleHeight(0.5, z) - center)).toBeLessThan(0.1)
  })

  it('noise is deterministic', () => {
    expect(sampleHeight(9.3, 12.7)).toBe(sampleHeight(9.3, 12.7))
  })

  it('collects runaway stones in a basin beyond each foot', () => {
    expect(sampleHeight(0, M.frontLength + 5)).toBeLessThan(-0.8)
    expect(sampleHeight(0, M.frontLength + 9)).toBeGreaterThan(0) // rim
    expect(sampleHeight(0, -M.backLength - 5)).toBeLessThan(-0.8)
  })
})

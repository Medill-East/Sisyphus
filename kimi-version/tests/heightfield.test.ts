import { describe, expect, it } from 'vitest'
import { sampleHeight, slopeDegAt } from '../src/world/heightfield'
import { TUNING } from '../src/core/tuning'

const M = TUNING.mountain

describe('heightfield', () => {
  it('is zero at both feet and ridge height at crest', () => {
    expect(sampleHeight(0, M.frontLength)).toBeCloseTo(0, 3)
    expect(sampleHeight(0, -M.backLength)).toBeCloseTo(0, 3)
    expect(sampleHeight(0, 0)).toBeCloseTo(M.ridgeHeight, 3)
  })

  it('descends monotonically away from the ridge on the path', () => {
    for (const side of [1, -1]) {
      const L = side > 0 ? M.frontLength : M.backLength
      let prev = Infinity
      for (let i = 0; i <= 20; i++) {
        const h = sampleHeight(0, side * (i / 20) * L)
        expect(h).toBeLessThanOrEqual(prev + 1e-6)
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

  it('banks rise beyond the path and noise stays off the path', () => {
    const z = M.frontLength * 0.5
    const center = sampleHeight(0, z)
    expect(sampleHeight(6, z)).toBeGreaterThan(center + 1.0)
    expect(sampleHeight(0.5, z)).toBeCloseTo(sampleHeight(-0.5, z), 6)
  })

  it('noise is deterministic', () => {
    expect(sampleHeight(9.3, 12.7)).toBe(sampleHeight(9.3, 12.7))
  })
})

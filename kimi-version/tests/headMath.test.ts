import { describe, expect, it } from 'vitest'
import { clampHead, tightenNeckLimits, type NeckLimits } from '../src/camera/headMath'

const L: NeckLimits = { yawDeg: 120, pitchUpDeg: 55, pitchDownDeg: 40 }
const rad = (d: number) => (d * Math.PI) / 180

describe('headMath', () => {
  it('passes through look inside neck range', () => {
    const h = clampHead(rad(30), rad(10), 0, L)
    expect(h.yaw).toBeCloseTo(rad(30))
    expect(h.pitch).toBeCloseTo(rad(10))
  })

  it('clamps yaw to the neck limit relative to body yaw', () => {
    const h = clampHead(rad(170), 0, 0, L)
    expect(h.yaw).toBeCloseTo(rad(120))
  })

  it('clamps relative to a turned body', () => {
    const body = rad(90)
    const h = clampHead(body + rad(170), 0, body, L)
    expect(h.yaw).toBeCloseTo(body + rad(120))
  })

  it('clamps pitch both ways', () => {
    expect(clampHead(0, rad(80), 0, L).pitch).toBeCloseTo(rad(55))
    expect(clampHead(0, -rad(80), 0, L).pitch).toBeCloseTo(rad(-40))
  })
})

describe('tightenNeckLimits (pressing a divine boulder: no sightseeing)', () => {
  const FREE: NeckLimits = { yawDeg: 120, pitchUpDeg: 55, pitchDownDeg: 40 }
  const TIGHT: NeckLimits = { yawDeg: 35, pitchUpDeg: 25, pitchDownDeg: 30 }

  it('t=0 keeps free limits, t=1 reaches press limits', () => {
    expect(tightenNeckLimits(FREE, TIGHT, 0)).toEqual(FREE)
    expect(tightenNeckLimits(FREE, TIGHT, 1)).toEqual(TIGHT)
  })

  it('mid-blend is intermediate (no pops)', () => {
    const mid = tightenNeckLimits(FREE, TIGHT, 0.5)
    expect(mid.yawDeg).toBeCloseTo(77.5)
    expect(mid.pitchUpDeg).toBeCloseTo(40)
  })

  it('while pressing, looking far left is clamped to the tight limit', () => {
    const limits = tightenNeckLimits(FREE, TIGHT, 1)
    const h = clampHead(rad(100), rad(50), 0, limits)
    expect(h.yaw).toBeCloseTo(rad(35))
    expect(h.pitch).toBeCloseTo(rad(25))
  })
})

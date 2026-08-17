import { describe, expect, it } from 'vitest'
import { clampHead, engagePitchBias, type NeckLimits } from '../src/camera/headMath'

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

describe('engagePitchBias', () => {
  it('pulls pitch down toward a low contact while engaged', () => {
    const d = engagePitchBias(1.9, { x: 0, y: 1.5, z: -0.4 }, 0, 1)
    expect(d).toBeLessThan(0)
  })

  it('does nothing when disengaged', () => {
    expect(engagePitchBias(1.9, { x: 0, y: 1.5, z: -0.4 }, 0, 0)).toBe(0)
  })
})

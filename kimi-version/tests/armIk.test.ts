import { describe, expect, it } from 'vitest'
import { solveTwoBoneIK } from '../src/body/armIk'
import { length, sub } from '../src/physics/vec3'

const SHOULDER = { x: 0, y: 1.3, z: 0 }
const L1 = 0.3
const L2 = 0.28
const POLE = { x: 0, y: -1, z: -0.3 } // elbows bow down-back

describe('armIk', () => {
  it('reaches a near target with exact segment lengths', () => {
    const target = { x: 0.1, y: 1.2, z: -0.35 }
    const { elbow, wrist } = solveTwoBoneIK(SHOULDER, target, L1, L2, POLE)
    expect(wrist.x).toBeCloseTo(target.x, 3)
    expect(wrist.y).toBeCloseTo(target.y, 3)
    expect(wrist.z).toBeCloseTo(target.z, 3)
    expect(length(sub(elbow, SHOULDER))).toBeCloseTo(L1, 3)
    expect(length(sub(wrist, elbow))).toBeCloseTo(L2, 3)
  })

  it('clamps an out-of-reach target to full extension', () => {
    const target = { x: 0, y: 1.3, z: -5 }
    const { wrist } = solveTwoBoneIK(SHOULDER, target, L1, L2, POLE)
    expect(length(sub(wrist, SHOULDER))).toBeCloseTo(L1 + L2 - 1e-3, 2)
  })

  it('elbow bows toward the pole vector (not up)', () => {
    const target = { x: 0, y: 1.25, z: -0.3 }
    const { elbow } = solveTwoBoneIK(SHOULDER, target, L1, L2, POLE)
    expect(elbow.y).toBeLessThan(SHOULDER.y)
  })
})

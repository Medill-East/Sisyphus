import { describe, expect, it } from 'vitest'
import { computeHandContact, computeShoulder, withinReach } from '../src/physics/pushModel'
import { TUNING } from '../src/core/tuning'

const P = TUNING.push
const CENTER = { x: 0, y: 1.6, z: 0 }
const R = TUNING.stone.radius

// Player stands at +z of the stone, facing −z (yaw 0) — uphill on the front side.
const PLAYER = { x: 0, y: 0, z: 2.0 }
const YAW = 0

describe('pushModel', () => {
  it('places the left shoulder on the player left (−x when facing −z)', () => {
    const l = computeShoulder(PLAYER, YAW, -1, P)
    const r = computeShoulder(PLAYER, YAW, 1, P)
    expect(l.x).toBeLessThan(0)
    expect(r.x).toBeGreaterThan(0)
    expect(l.y).toBeCloseTo(P.shoulderHeight, 3)
  })

  it('contact point lies exactly on the sphere surface', () => {
    for (const side of [-1, 1] as const) {
      const c = computeHandContact(CENTER, R, computeShoulder(PLAYER, YAW, side, P))
      const d = Math.hypot(c.point.x - CENTER.x, c.point.y - CENTER.y, c.point.z - CENTER.z)
      expect(d).toBeCloseTo(R, 3)
    }
  })

  it('left hand pushes rightward through the center; right hand leftward (honest geometry)', () => {
    // Spec-confirmed: pressing with the left hand drives the stone toward +x
    // and the right hand toward −x. Force direction = shoulder → sphere center.
    const l = computeHandContact(CENTER, R, computeShoulder(PLAYER, YAW, -1, P))
    const r = computeHandContact(CENTER, R, computeShoulder(PLAYER, YAW, 1, P))
    expect(l.dir.x).toBeGreaterThan(0)
    expect(r.dir.x).toBeLessThan(0)
    expect(l.dir.z).toBeLessThan(0) // both hands also push forward (−z, uphill)
    expect(r.dir.z).toBeLessThan(0)
  })

  it('withinReach respects reach distance', () => {
    const chest = { x: 0, y: 1.3, z: 1.6 } // 0.6 m from the surface
    expect(withinReach(CENTER, R, chest, P.reachDistance)).toBe(true)
    expect(withinReach(CENTER, R, { x: 0, y: 1.3, z: 5.0 }, P.reachDistance)).toBe(false)
  })
})

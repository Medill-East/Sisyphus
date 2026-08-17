import { describe, expect, it } from 'vitest'
import { HandStateMachine, HandPhase } from '../src/body/BodyRig'

describe('hand state machine', () => {
  it('rises when in reach, presses while input held, lowers when both released', () => {
    const h = new HandStateMachine()
    expect(h.phase).toBe(HandPhase.Off)
    h.update(0.2, { inReach: true, input: 0 }) // near, not pressing
    expect(h.phase).toBe(HandPhase.Raising)
    for (let i = 0; i < 40; i++) h.update(1 / 60, { inReach: true, input: 1 })
    expect(h.phase).toBe(HandPhase.Pressing)
    for (let i = 0; i < 60; i++) h.update(1 / 60, { inReach: true, input: 0 })
    expect(h.phase).toBe(HandPhase.Raising) // hands stay up near the stone, force is zero
    h.update(0.2, { inReach: false, input: 0 })
    expect(h.phase).toBe(HandPhase.Off)
  })

  it('blend amount moves only toward the active target', () => {
    const h = new HandStateMachine()
    h.update(0.05, { inReach: true, input: 1 })
    const a = h.blend
    expect(a).toBeLessThan(1)
    h.update(0.05, { inReach: true, input: 1 })
    expect(h.blend).toBeGreaterThan(a)
  })
})

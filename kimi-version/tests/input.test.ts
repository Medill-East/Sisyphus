import { describe, expect, it } from 'vitest'
import { intentFromKeyboardMouse, intentFromGamepad, mergeIntents, type InputIntent } from '../src/core/input'

describe('keyboard/mouse intent', () => {
  it('maps WASD to move axes (W = forward = −z intent)', () => {
    const i = intentFromKeyboardMouse(new Set(['KeyW']), { dx: 0, dy: 0, left: false, right: false })
    expect(i.move.z).toBeLessThan(0)
    expect(i.move.x).toBe(0)
  })

  it('maps mouse buttons to hands and deltas to look', () => {
    const i = intentFromKeyboardMouse(new Set(), { dx: 12, dy: -4, left: true, right: false })
    expect(i.leftHand).toBe(1)
    expect(i.rightHand).toBe(0)
    expect(i.lookDelta.x).toBe(12)
    expect(i.lookDelta.y).toBe(-4)
  })
})

describe('gamepad intent', () => {
  const pad = {
    axes: [0.5, 0, -0.25, 0],
    buttons: Array.from({ length: 17 }, (_, i) => ({
      pressed: i === 6,
      value: i === 6 ? 0.7 : i === 7 ? 0.3 : 0,
    })),
  } as unknown as Gamepad

  it('maps sticks with deadzone and triggers to analog hands', () => {
    const i = intentFromGamepad(pad)
    expect(i.move.x).toBeCloseTo(0.5, 2)
    expect(i.leftHand).toBeCloseTo(0.7, 2)
    expect(i.rightHand).toBeCloseTo(0.3, 2)
    expect(i.lookDelta.x).toBeCloseTo(-0.25 * 600 * (1 / 60), 1) // stick→look speed per frame
  })

  it('applies stick deadzone', () => {
    const quiet = { ...pad, axes: [0.05, 0, 0, 0] } as unknown as Gamepad
    expect(intentFromGamepad(quiet).move.x).toBe(0)
  })
})

describe('mergeIntents', () => {
  it('takes the stronger hand and summed movement/look', () => {
    const a: InputIntent = { move: { x: 1, z: 0 }, lookDelta: { x: 1, y: 0 }, leftHand: 0.4, rightHand: 0, reset: false }
    const b: InputIntent = { move: { x: 0, z: -1 }, lookDelta: { x: 2, y: 1 }, leftHand: 0, rightHand: 0.9, reset: true }
    const m = mergeIntents(a, b)
    expect(m.leftHand).toBeCloseTo(0.4)
    expect(m.rightHand).toBeCloseTo(0.9)
    expect(m.move).toEqual({ x: 1, z: -1 })
    expect(m.reset).toBe(true)
  })
})

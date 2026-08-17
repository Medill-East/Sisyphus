import { describe, expect, it } from 'vitest'
import { TUNING } from '../src/core/tuning'

describe('scaffold', () => {
  it('loads tuning', () => {
    expect(TUNING.stone.radius).toBeGreaterThan(0)
  })
})

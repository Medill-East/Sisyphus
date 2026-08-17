import { beforeAll, describe, expect, it } from 'vitest'
import RAPIER from '@dimforge/rapier3d-compat'
import { PhysicsWorld } from '../src/physics/PhysicsWorld'
import { Stone, type PushForce } from '../src/physics/stone'
import { computeHandContact, computeShoulder } from '../src/physics/pushModel'
import { sampleHeight } from '../src/world/heightfield'
import { TUNING } from '../src/core/tuning'

beforeAll(async () => {
  await RAPIER.init()
})

const P = TUNING.push
const SPAWN_Z = TUNING.mountain.frontLength - 2 // near-flat foot area

interface Rig {
  pw: PhysicsWorld
  stone: Stone
}

/** Spawn a settled stone at the foot with the "player" standing behind it facing −z. */
function makeRig(): Rig {
  const pw = new PhysicsWorld()
  const stone = new Stone(pw, 0, sampleHeight(0, SPAWN_Z) + TUNING.stone.radius + 0.02, SPAWN_Z)
  for (let i = 0; i < 60; i++) {
    stone.applyResistance(false)
    pw.step()
  }
  return { pw, stone }
}

/** One fixed step with the given per-hand analog inputs (0..1). Player stands 0.55 m behind the surface. */
function pushStep(rig: Rig, left: number, right: number) {
  const c = rig.stone.position()
  const player = { x: 0, y: c.y - P.shoulderHeight, z: c.z + TUNING.stone.radius + 0.55 }
  const hands: PushForce[] = []
  for (const [side, input] of [[-1, left], [1, right]] as const) {
    if (input <= 0) continue
    const contact = computeHandContact(c, TUNING.stone.radius, computeShoulder(player, 0, side, P))
    hands.push({ ...contact, magnitude: input * P.maxForcePerHand })
  }
  rig.stone.applyPush(hands)
  rig.stone.applyResistance(hands.length > 0)
  rig.pw.step()
}

function pushSeconds(rig: Rig, left: number, right: number, seconds: number) {
  for (let i = 0; i < Math.round(seconds * 60); i++) pushStep(rig, left, right)
}

describe('push feel contract', () => {
  it('both hands full force moves the stone uphill (−z)', () => {
    const rig = makeRig()
    const z0 = rig.stone.position().z
    pushSeconds(rig, 1, 1, 3)
    expect(z0 - rig.stone.position().z).toBeGreaterThan(1.5)
  })

  it('left hand only drifts the stone rightward (+x)', () => {
    const rig = makeRig()
    const x0 = rig.stone.position().x
    pushSeconds(rig, 1, 0, 2)
    expect(rig.stone.position().x - x0).toBeGreaterThan(0.3)
  })

  it('right hand only drifts the stone leftward (−x)', () => {
    const rig = makeRig()
    const x0 = rig.stone.position().x
    pushSeconds(rig, 0, 1, 2)
    expect(rig.stone.position().x - x0).toBeLessThan(-0.3)
  })

  it('gentle force from rest cannot break away (static threshold)', () => {
    const rig = makeRig()
    const z0 = rig.stone.position().z
    pushSeconds(rig, 0.1, 0, 1.5) // 95 N < staticBreakawayForce
    expect(z0 - rig.stone.position().z).toBeLessThan(0.15)
  })

  it('once moving, moderate force sustains uphill motion', () => {
    const rig = makeRig()
    pushSeconds(rig, 1, 1, 1.5) // break away first
    const z0 = rig.stone.position().z
    pushSeconds(rig, 0.6, 0.6, 2)
    expect(z0 - rig.stone.position().z).toBeGreaterThan(0.8)
  })

  it('releasing both hands lets the stone coast to a stop, never self-accelerate', () => {
    const rig = makeRig()
    pushSeconds(rig, 1, 1, 2)
    const z0 = rig.stone.position().z
    for (let i = 0; i < 480; i++) {
      rig.stone.applyResistance(false)
      rig.pw.step()
    }
    // Inertia may coast it further uphill on the gentle foot slope, but it
    // must come to rest — no self-sustained climbing.
    expect(rig.stone.speed()).toBeLessThan(0.05)
    expect(z0 - rig.stone.position().z).toBeLessThan(3)
  })
})

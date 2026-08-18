import * as THREE from 'three'
import { TUNING } from '../core/tuning'
import { computeHandContact, computeShoulder, heaveDir } from '../physics/pushModel'
import { solveTwoBoneIK } from './armIk'
import { HandView } from './HandView'
import type { Vec3 } from '../physics/vec3'

export enum HandPhase {
  Off = 'off',
  Raising = 'raising',
  Pressing = 'pressing',
}

const UPPER = 0.3
const FORE = 0.28

/** Per-hand engagement logic; pure enough to unit test without three.js. */
export class HandStateMachine {
  phase = HandPhase.Off
  blend = 0 // 0 lowered → 1 on-stone
  /** Seconds since the current press started (drives the push stroke). */
  pressTime = 0

  update(dt: number, s: { inReach: boolean; input: number }): void {
    if (!s.inReach) {
      this.phase = HandPhase.Off
    } else if (this.phase === HandPhase.Off) {
      this.phase = HandPhase.Raising
    } else if (s.input > 0.05) {
      this.phase = HandPhase.Pressing
    } else if (this.phase === HandPhase.Pressing) {
      this.phase = HandPhase.Raising
    }
    if (this.phase === HandPhase.Pressing && s.input > 0.05) this.pressTime += dt
    else this.pressTime = 0
    const target = this.phase === HandPhase.Off ? 0 : 1
    const rate = this.phase === HandPhase.Off ? 3.5 : 5
    this.blend += Math.min(Math.max(target - this.blend, -rate * dt), rate * dt)
  }
}

const skinMat = new THREE.MeshStandardMaterial({ color: 0xc9a184, roughness: 0.85 })
const clothMat = new THREE.MeshStandardMaterial({ color: 0xd8cbb0, roughness: 0.95 })

function limb(a: THREE.Vector3, b: THREE.Vector3, r: number, mat: THREE.Material): THREE.Mesh {
  const len = a.distanceTo(b)
  const m = new THREE.Mesh(new THREE.CapsuleGeometry(r, len, 3, 8), mat)
  m.position.copy(a).lerp(b, 0.5)
  m.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), b.clone().sub(a).normalize())
  m.castShadow = true
  return m
}

/** First-person body: shoulders anchor on the player pose; hands land on the stone via IK. */
export class BodyRig extends THREE.Group {
  readonly hands: Record<-1 | 1, { sm: HandStateMachine; view: HandView; limbs: THREE.Group; lastContact: Vec3 | null }> = {
    [-1]: { sm: new HandStateMachine(), view: new HandView(true), limbs: new THREE.Group(), lastContact: null },
    [1]: { sm: new HandStateMachine(), view: new HandView(false), limbs: new THREE.Group(), lastContact: null },
  }
  private time = 0

  constructor() {
    super()
    for (const side of [-1, 1] as const) {
      this.add(this.hands[side].limbs)
      this.add(this.hands[side].view)
    }
  }

  /**
   * Pose the rig in world space and return this frame's pressing contacts
   * (already scaled to force magnitudes) for the physics step.
   */
  pose(
    dt: number,
    playerPos: Vec3,
    bodyYaw: number,
    stoneCenter: Vec3,
    stoneRadius: number,
    input: Record<-1 | 1, number>,
  ): { side: -1 | 1; point: Vec3; dir: Vec3; magnitude: number }[] {
    this.time += dt
    const pressing: { side: -1 | 1; point: Vec3; dir: Vec3; magnitude: number }[] = []
    for (const side of [-1, 1] as const) {
      const baseShoulder = computeShoulder(playerPos, bodyYaw, side, TUNING.push)
      const contact = computeHandContact(stoneCenter, stoneRadius, baseShoulder)
      const chestDist = Math.hypot(playerPos.x - stoneCenter.x, playerPos.z - stoneCenter.z) - stoneRadius
      const inReach = chestDist < TUNING.push.reachDistance * TUNING.push.reachHysteresis
      const h = this.hands[side]
      h.sm.update(dt, { inReach, input: input[side] })
      h.lastContact = contact.point
      const load = h.sm.phase === HandPhase.Pressing ? input[side] : 0

      // Under load the body leans in: shoulders drop and push forward slightly.
      const leanF = load * 0.05
      const shoulder = {
        x: baseShoulder.x - Math.sin(bodyYaw) * leanF,
        y: baseShoulder.y - load * 0.06,
        z: baseShoulder.z - Math.cos(bodyYaw) * leanF,
      }

      // Hand target: rest pose at the side of the body (body-relative) ↔
      // on-stone contact, blended. The IK wrist stops 9 cm behind the
      // surface (palm depth); the palm face lands exactly on the contact.
      const fwdX = -Math.sin(bodyYaw)
      const fwdZ = -Math.cos(bodyYaw)
      const rightX = Math.cos(bodyYaw)
      const rightZ = -Math.sin(bodyYaw)
      const rest = new THREE.Vector3(
        playerPos.x + rightX * side * 0.26 + fwdX * 0.1,
        playerPos.y + 0.78,
        playerPos.z + rightZ * side * 0.26 + fwdZ * 0.1,
      )
      const dir = new THREE.Vector3(contact.dir.x, contact.dir.y, contact.dir.z)
      const wristOnStone = new THREE.Vector3(contact.point.x, contact.point.y, contact.point.z).addScaledVector(dir, -0.09)
      const palmOnStone = new THREE.Vector3(contact.point.x, contact.point.y, contact.point.z).addScaledVector(dir, -0.04)
      let target = rest.clone().lerp(wristOnStone, h.sm.blend)
      let palmTarget = rest.clone().lerp(palmOnStone, h.sm.blend)
      // Push stroke: on press, the hand visibly thrusts from in front of the
      // chest up-and-forward onto the stone before sustaining — the "推".
      const STROKE = 0.22
      if (h.sm.phase === HandPhase.Pressing && h.sm.pressTime < STROKE) {
        const guard = new THREE.Vector3(
          playerPos.x + fwdX * 0.28 + rightX * side * 0.16,
          playerPos.y + 0.95,
          playerPos.z + fwdZ * 0.28 + rightZ * side * 0.16,
        )
        const t = h.sm.pressTime / STROKE
        const ease = 1 - Math.pow(1 - t, 3)
        target = guard.clone().lerp(wristOnStone, ease)
        palmTarget = guard.lerp(palmOnStone, ease)
      }
      // Strain tremor: max load makes the arms shiver, subtly.
      if (load > 0) {
        const tremor = (Math.sin(this.time * 43 + side * 7) * 0.006 + Math.sin(this.time * 29) * 0.004) * load
        target.y += tremor
        target.x += tremor * 0.6
      }
      const { elbow } = solveTwoBoneIK(shoulder, target, UPPER, FORE, { x: 0, y: -1, z: 0.25 })

      h.limbs.clear()
      const S = new THREE.Vector3(shoulder.x, shoulder.y, shoulder.z)
      const E = new THREE.Vector3(elbow.x, elbow.y, elbow.z)
      h.limbs.add(limb(S, E, 0.045, clothMat), limb(E, target, 0.038, skinMat))
      h.view.position.copy(palmTarget)
      // Palm faces along the push direction (toward the sphere center).
      h.view.quaternion.setFromRotationMatrix(new THREE.Matrix4().lookAt(new THREE.Vector3(), dir, new THREE.Vector3(0, 1, 0)))
      h.view.setLoad(load)

      if (h.sm.phase === HandPhase.Pressing && input[side] > 0.05) {
        // Force only transmits through arms that actually reach: full force at
        // the natural stance, fading to zero past full extension. You must
        // walk into the stone (W) to keep pushing. Force runs as a heave up
        // the stone's surface, not a horizontal shove.
        const reachFade = Math.min(Math.max((0.75 - chestDist) / 0.2, 0), 1)
        if (reachFade > 0) {
          pressing.push({ side, point: contact.point, dir: heaveDir(contact.dir, TUNING.push.heaveDeg), magnitude: input[side] * TUNING.push.maxForcePerHand * reachFade })
        }
      }
    }
    return pressing
  }

  /** How far the hands are engaged (0..1, max of both) — drives the camera ease. */
  engageAmount(): number {
    return Math.max(this.hands[-1].sm.blend, this.hands[1].sm.blend)
  }

  /** True while at least one hand is actively pressing. */
  anyPressing(): boolean {
    return this.hands[-1].sm.phase === HandPhase.Pressing || this.hands[1].sm.phase === HandPhase.Pressing
  }

  /** Representative contact for the camera gaze bias (the most-engaged hand). */
  currentContact(): Vec3 | null {
    let best: Vec3 | null = null
    let bestBlend = 0.25
    for (const side of [-1, 1] as const) {
      const h = this.hands[side]
      if (h.sm.blend > bestBlend && h.lastContact) {
        best = h.lastContact
        bestBlend = h.sm.blend
      }
    }
    return best
  }
}

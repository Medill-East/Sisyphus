import * as THREE from 'three'
import { solveTwoBoneIK } from './armIk'

const CLOTH = new THREE.MeshStandardMaterial({ color: 0xd8cbb0, roughness: 0.95 })
const CLOTH_DARK = new THREE.MeshStandardMaterial({ color: 0xa89878, roughness: 0.95 })
const SKIN = new THREE.MeshStandardMaterial({ color: 0xc9a184, roughness: 0.85 })
const LEATHER = new THREE.MeshStandardMaterial({ color: 0x7a5c42, roughness: 0.9 })

function capsule(r: number, len: number, mat: THREE.Material): THREE.Mesh {
  const m = new THREE.Mesh(new THREE.CapsuleGeometry(r, len, 3, 8), mat)
  m.castShadow = true
  return m
}

function limb(a: THREE.Vector3, b: THREE.Vector3, r: number, mat: THREE.Material): THREE.Mesh {
  const len = a.distanceTo(b)
  const m = new THREE.Mesh(new THREE.CapsuleGeometry(r, len, 3, 8), mat)
  m.position.copy(a).lerp(b, 0.5)
  m.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), b.clone().sub(a).normalize())
  m.castShadow = true
  return m
}

/**
 * First-person body: chest and shoulders the arms grow out of, a tapered
 * tunic, bare two-piece legs that bend at the knee while stepping, and
 * sandaled feet. Looking down, you see a person — not a puppet ghost.
 */
export class BodyView extends THREE.Group {
  private readonly chest = new THREE.Mesh(new THREE.SphereGeometry(0.19, 10, 8), CLOTH)
  private readonly shoulderCaps: Record<-1 | 1, THREE.Mesh> = {
    [-1]: new THREE.Mesh(new THREE.SphereGeometry(0.075, 8, 6), CLOTH),
    [1]: new THREE.Mesh(new THREE.SphereGeometry(0.075, 8, 6), CLOTH),
  }
  private readonly torso = capsule(0.16, 0.38, CLOTH)
  private readonly hips = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.24, 0.34, 8), CLOTH_DARK)
  private readonly legGroups: Record<-1 | 1, THREE.Group> = { [-1]: new THREE.Group(), [1]: new THREE.Group() }
  private readonly feet: Record<-1 | 1, THREE.Mesh> = {
    [-1]: new THREE.Mesh(new THREE.BoxGeometry(0.1, 0.055, 0.24), LEATHER),
    [1]: new THREE.Mesh(new THREE.BoxGeometry(0.1, 0.055, 0.24), LEATHER),
  }

  constructor() {
    super()
    this.chest.scale.set(1.15, 0.85, 0.75)
    this.chest.castShadow = true
    for (const side of [-1, 1] as const) {
      this.shoulderCaps[side].scale.set(1, 0.8, 0.9)
      this.shoulderCaps[side].castShadow = true
      this.feet[side].castShadow = true
      this.add(this.shoulderCaps[side], this.legGroups[side], this.feet[side])
    }
    ;(this.hips as THREE.Mesh).castShadow = true
    this.add(this.chest, this.torso, this.hips)
  }

  /**
   * Pose the body at the player (local space, rotated by bodyYaw).
   * `stepPhase` advances with distance walked; `speedRatio` 0..1;
   * `engage` leans the torso into the push.
   */
  pose(playerPos: { x: number; y: number; z: number }, bodyYaw: number, stepPhase: number, speedRatio: number, engage: number): void {
    this.position.set(playerPos.x, playerPos.y, playerPos.z)
    this.rotation.set(0, bodyYaw, 0)

    const lean = 0.04 + engage * 0.2
    this.chest.position.set(0, 1.36, 0.02 - lean * 0.12)
    this.chest.rotation.x = lean
    for (const side of [-1, 1] as const) {
      this.shoulderCaps[side].position.set(side * 0.21, 1.34, 0.02 - lean * 0.14)
    }
    this.torso.position.set(0, 1.1, 0.03)
    this.torso.rotation.x = lean * 0.6
    this.hips.position.set(0, 0.84, 0.03)

    // Legs: two-piece with a real knee, stepping in antiphase.
    for (const side of [-1, 1] as const) {
      const phase = stepPhase + (side === -1 ? 0 : Math.PI)
      const swing = Math.sin(phase) * 0.26 * speedRatio
      const lift = Math.max(0, Math.sin(phase + Math.PI / 2)) * 0.1 * speedRatio
      const foot = this.feet[side]
      foot.position.set(side * 0.11, 0.03 + lift, swing)
      foot.rotation.x = -lift * 3.5

      const hip = { x: side * 0.1, y: 0.8, z: 0.02 }
      const ankle = { x: side * 0.11, y: 0.1 + lift, z: swing }
      const { elbow: knee } = solveTwoBoneIK(hip, ankle, 0.42, 0.4, { x: 0, y: 0.15, z: -1 })
      const g = this.legGroups[side]
      g.clear()
      g.add(
        limb(new THREE.Vector3(hip.x, hip.y, hip.z), new THREE.Vector3(knee.x, knee.y, knee.z), 0.085, SKIN),
        limb(new THREE.Vector3(knee.x, knee.y, knee.z), new THREE.Vector3(ankle.x, ankle.y, ankle.z), 0.062, SKIN),
      )
    }
  }
}

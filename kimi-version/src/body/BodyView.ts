import * as THREE from 'three'

const CLOTH = new THREE.MeshStandardMaterial({ color: 0xd8cbb0, roughness: 0.95 })
const CLOTH_DARK = new THREE.MeshStandardMaterial({ color: 0xa89878, roughness: 0.95 })
const SKIN = new THREE.MeshStandardMaterial({ color: 0xc9a184, roughness: 0.85 })
const LEATHER = new THREE.MeshStandardMaterial({ color: 0x7a5c42, roughness: 0.9 })

function capsule(r: number, len: number, mat: THREE.Material): THREE.Mesh {
  const m = new THREE.Mesh(new THREE.CapsuleGeometry(r, len, 3, 8), mat)
  m.castShadow = true
  return m
}

/**
 * First-person body: torso, hips, bare legs and sandaled feet that actually
 * step while walking. Looking down, you see a person — not a puppet ghost.
 */
export class BodyView extends THREE.Group {
  private readonly torso = capsule(0.17, 0.42, CLOTH)
  private readonly hips = new THREE.Mesh(new THREE.CylinderGeometry(0.19, 0.23, 0.3, 8), CLOTH_DARK)
  private readonly legs: Record<-1 | 1, THREE.Mesh> = { [-1]: capsule(0.075, 0.62, SKIN), [1]: capsule(0.075, 0.62, SKIN) }
  private readonly feet: Record<-1 | 1, THREE.Mesh> = {
    [-1]: new THREE.Mesh(new THREE.BoxGeometry(0.1, 0.06, 0.24), LEATHER),
    [1]: new THREE.Mesh(new THREE.BoxGeometry(0.1, 0.06, 0.24), LEATHER),
  }

  constructor() {
    super()
    ;(this.hips as THREE.Mesh).castShadow = true
    for (const side of [-1, 1] as const) {
      this.feet[side].castShadow = true
      this.add(this.legs[side], this.feet[side])
    }
    this.add(this.torso, this.hips)
  }

  /**
   * Pose the body at the player. `stepPhase` advances with distance walked;
   * `speedRatio` 0..1; `engage` leans the torso into the push.
   */
  pose(playerPos: { x: number; y: number; z: number }, bodyYaw: number, stepPhase: number, speedRatio: number, engage: number): void {
    this.position.set(playerPos.x, playerPos.y, playerPos.z)
    this.rotation.set(0, bodyYaw, 0)

    // Torso: rides slightly behind the camera, leans forward under load.
    this.torso.position.set(0, 1.18, 0.02)
    this.torso.rotation.x = 0.06 + engage * 0.22
    this.hips.position.set(0, 0.86, 0.02)

    // Legs and feet: procedural stepping, left/right in antiphase.
    for (const side of [-1, 1] as const) {
      const phase = stepPhase + (side === -1 ? 0 : Math.PI)
      const swing = Math.sin(phase) * 0.26 * speedRatio
      const lift = Math.max(0, Math.sin(phase + Math.PI / 2)) * 0.09 * speedRatio
      const foot = this.feet[side]
      foot.position.set(side * 0.11, 0.03 + lift, swing)
      foot.rotation.x = -lift * 4
      const leg = this.legs[side]
      // One-piece leg from hip to ankle.
      const hip = new THREE.Vector3(side * 0.1, 0.78, 0.01)
      const ankle = new THREE.Vector3(side * 0.11, 0.09 + lift, swing)
      const mid = hip.clone().lerp(ankle, 0.5)
      leg.position.copy(mid)
      const dir = ankle.clone().sub(hip).normalize()
      leg.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), dir)
    }
  }
}

import * as THREE from 'three'
import { TUNING } from '../core/tuning'
import { clampHead } from './headMath'
import type { Vec3 } from '../physics/vec3'

const MOUSE_SENS = 0.0023

/** First-person head: free look inside neck limits; eases into the push stance while engaged. */
export class CameraRig {
  private headYaw = 0
  private pitch = 0
  private ease = 0

  /** Current absolute head yaw — free mode drives the player's body yaw. */
  get yaw(): number {
    return this.headYaw
  }

  applyLook(dx: number, dy: number): void {
    this.headYaw -= dx * MOUSE_SENS
    this.pitch -= dy * MOUSE_SENS
  }

  /** Pose the camera. engage ∈ 0..1 from BodyRig.engageAmount(); look is fully user-owned. */
  update(
    dt: number,
    camera: THREE.PerspectiveCamera,
    playerPos: Vec3,
    bodyYaw: number,
    engage: number,
    bobPhase = 0,
    bobAmount = 0,
  ): void {
    const c = TUNING.camera
    const eyeY = playerPos.y + TUNING.player.eyeHeight
    const clamped = clampHead(this.headYaw, this.pitch, bodyYaw, {
      yawDeg: c.neckYawLimitDeg,
      pitchUpDeg: c.neckPitchUpDeg,
      pitchDownDeg: c.neckPitchDownDeg,
    })
    this.headYaw = clamped.yaw
    this.pitch = clamped.pitch
    this.ease += Math.min(Math.max(engage - this.ease, -c.engageEase * dt), c.engageEase * dt)
    const e = this.ease * this.ease * (3 - 2 * this.ease) // smoothstep: no camera jumps

    // Engage stance: high close-shoulder — pull back and up so the frame keeps
    // hands + stone top + the path ahead, while FOV tightens onto the stone.
    const back = 0.42 * e
    const lift = 0.3 * e
    const fwd = { x: -Math.sin(bodyYaw), z: -Math.cos(bodyYaw) }
    const right = { x: Math.cos(bodyYaw), z: -Math.sin(bodyYaw) }
    // Step weight: gentle vertical bob + lateral sway while walking.
    const bobY = Math.sin(bobPhase * 2) * 0.028 * bobAmount
    const swayX = Math.sin(bobPhase) * 0.02 * bobAmount
    camera.position.set(
      playerPos.x - fwd.x * back + right.x * swayX,
      eyeY + lift + bobY,
      playerPos.z - fwd.z * back + right.z * swayX,
    )
    camera.rotation.set(this.pitch - 0.3 * e, this.headYaw, 0, 'YXZ')
    const fov = c.fov + (c.engagedFov - c.fov) * e
    if (Math.abs(fov - camera.fov) > 0.01) {
      camera.fov = fov
      camera.updateProjectionMatrix()
    }
  }
}

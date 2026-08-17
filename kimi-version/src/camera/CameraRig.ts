import * as THREE from 'three'
import { TUNING } from '../core/tuning'
import { clampHead, engagePitchBias } from './headMath'
import type { Vec3 } from '../physics/vec3'

const MOUSE_SENS = 0.0023

/** First-person head: free look inside neck limits; eases into the push stance while engaged. */
export class CameraRig {
  private headYaw = 0
  private pitch = 0
  private ease = 0

  applyLook(dx: number, dy: number): void {
    this.headYaw -= dx * MOUSE_SENS
    this.pitch -= dy * MOUSE_SENS
  }

  /** Pose the camera. engage ∈ 0..1 from BodyRig.engageAmount(); contact = a hand contact if any. */
  update(
    dt: number,
    camera: THREE.PerspectiveCamera,
    playerPos: Vec3,
    bodyYaw: number,
    engage: number,
    contact: Vec3 | null,
  ): void {
    const c = TUNING.camera
    const eyeY = playerPos.y + TUNING.player.eyeHeight
    if (contact) {
      this.pitch += engagePitchBias(eyeY, { x: contact.x - playerPos.x, y: contact.y, z: contact.z - playerPos.z }, this.pitch, engage) * dt
    }
    const clamped = clampHead(this.headYaw, this.pitch, bodyYaw, {
      yawDeg: c.neckYawLimitDeg,
      pitchUpDeg: c.neckPitchUpDeg,
      pitchDownDeg: c.neckPitchDownDeg,
    })
    this.headYaw = clamped.yaw
    this.pitch = clamped.pitch
    this.ease += Math.min(Math.max(engage - this.ease, -c.engageEase * dt), c.engageEase * dt)

    // Engage stance: high close-shoulder — pull back and up so the frame keeps
    // hands + stone top + the path ahead, while FOV tightens onto the stone.
    const back = 0.42 * this.ease
    const lift = 0.3 * this.ease
    const fwd = { x: -Math.sin(bodyYaw), z: -Math.cos(bodyYaw) }
    camera.position.set(
      playerPos.x - fwd.x * back,
      eyeY + lift,
      playerPos.z - fwd.z * back,
    )
    camera.rotation.set(this.pitch, this.headYaw, 0, 'YXZ')
    const fov = c.fov + (c.engagedFov - c.fov) * this.ease
    if (Math.abs(fov - camera.fov) > 0.01) {
      camera.fov = fov
      camera.updateProjectionMatrix()
    }
  }
}

import * as THREE from 'three'
import { TUNING } from '../core/tuning'
import { clampHead, tightenNeckLimits } from './headMath'
import type { Vec3 } from '../physics/vec3'

const MOUSE_SENS = 0.0023

/**
 * First-person head. Free walking: neck range. On the stone: close framing,
 * the boulder dominates. While pressing: the neck barely turns — a man
 * straining against a divine boulder has no spare attention for sightseeing.
 */
export class CameraRig {
  private headYaw = 0
  private pitch = 0
  private ease = 0
  private pressEase = 0

  /** Current absolute head yaw — free mode drives the player's body yaw. */
  get yaw(): number {
    return this.headYaw
  }

  applyLook(dx: number, dy: number): void {
    this.headYaw -= dx * MOUSE_SENS
    this.pitch -= dy * MOUSE_SENS
  }

  /** Pose the camera. engage/pressing ∈ 0..1 from BodyRig; look is clamped by blended neck limits. */
  update(
    dt: number,
    camera: THREE.PerspectiveCamera,
    playerPos: Vec3,
    bodyYaw: number,
    engage: number,
    pressing: boolean,
    bobPhase = 0,
    bobAmount = 0,
  ): void {
    const c = TUNING.camera
    const eyeY = playerPos.y + TUNING.player.eyeHeight
    this.pressEase += Math.min(Math.max((pressing ? 1 : 0) - this.pressEase, -c.pressEaseRate * dt), c.pressEaseRate * dt)
    const limits = tightenNeckLimits(
      { yawDeg: c.neckYawLimitDeg, pitchUpDeg: c.neckPitchUpDeg, pitchDownDeg: c.neckPitchDownDeg },
      { yawDeg: c.pressYawLimitDeg, pitchUpDeg: c.pressPitchUpDeg, pitchDownDeg: c.pressPitchDownDeg },
      Math.min(this.pressEase, 1),
    )
    const clamped = clampHead(this.headYaw, this.pitch, bodyYaw, limits)
    this.headYaw = clamped.yaw
    this.pitch = clamped.pitch
    this.ease += Math.min(Math.max(engage - this.ease, -c.engageEase * dt), c.engageEase * dt)
    const e = this.ease * this.ease * (3 - 2 * this.ease) // smoothstep: no camera jumps

    // Engage stance: close, low — the stone fills the frame; only slivers of
    // hillside at the sides, sky above, ground below.
    const back = 0.15 * e
    const lift = 0.12 * e
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
    camera.rotation.set(this.pitch - 0.22 * e, this.headYaw, 0, 'YXZ')
    const fov = c.fov + (c.engagedFov - c.fov) * e
    if (Math.abs(fov - camera.fov) > 0.01) {
      camera.fov = fov
      camera.updateProjectionMatrix()
    }
  }
}

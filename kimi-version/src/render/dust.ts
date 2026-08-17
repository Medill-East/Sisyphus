import * as THREE from 'three'

/** One-shot grit puff at a contact point on breakaway. Pool of one; respawn per burst. */
export class Dust extends THREE.Points {
  private life = 0

  constructor() {
    const geo = new THREE.BufferGeometry()
    geo.setAttribute('position', new THREE.BufferAttribute(new Float32Array(24 * 3), 3))
    super(geo, new THREE.PointsMaterial({ color: 0xb9a684, size: 0.09, transparent: true, opacity: 0 }))
  }

  burst(at: { x: number; y: number; z: number }): void {
    const pos = this.geometry.attributes.position as THREE.BufferAttribute
    for (let i = 0; i < pos.count; i++) {
      pos.setXYZ(i, at.x + (Math.random() - 0.5) * 0.5, at.y + Math.random() * 0.2, at.z + (Math.random() - 0.5) * 0.5)
    }
    pos.needsUpdate = true
    this.life = 0.6
  }

  update(dt: number): void {
    if (this.life <= 0) return
    this.life -= dt
    ;(this.material as THREE.PointsMaterial).opacity = Math.max(this.life, 0)
  }
}

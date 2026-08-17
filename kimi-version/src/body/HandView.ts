import * as THREE from 'three'

/** Low-poly but readable hand: palm + four fingers + thumb, grouped at the wrist. */
export class HandView extends THREE.Group {
  readonly palm: THREE.Mesh
  private readonly fingers: THREE.Mesh[] = []

  constructor(mirror: boolean) {
    super()
    const skin = new THREE.MeshStandardMaterial({ color: 0xc9a184, roughness: 0.8 })
    this.palm = new THREE.Mesh(new THREE.BoxGeometry(0.11, 0.035, 0.13), skin)
    this.palm.castShadow = true
    this.add(this.palm)
    for (let i = 0; i < 4; i++) {
      const f = new THREE.Mesh(new THREE.BoxGeometry(0.02, 0.024, 0.085), skin)
      f.position.set(-0.042 + i * 0.028, 0.004, -0.1)
      f.castShadow = true
      this.add(f)
      this.fingers.push(f)
    }
    const thumb = new THREE.Mesh(new THREE.BoxGeometry(0.024, 0.026, 0.07), skin)
    thumb.position.set(mirror ? -0.066 : 0.066, 0, -0.02)
    thumb.rotation.y = mirror ? 0.5 : -0.5
    this.add(thumb)
  }

  /** Curl fingers / compress palm under load: load ∈ 0..1. */
  setLoad(load: number): void {
    for (const f of this.fingers) f.rotation.x = -0.15 - load * 0.35
    this.palm.scale.set(1, 1 - load * 0.18, 1)
  }
}

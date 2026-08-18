import * as THREE from 'three'

/**
 * Low-poly but organic hand: a soft flattened palm, capsule fingers with a
 * natural curl, capsule thumb. Rest state is relaxed; load tightens the curl.
 */
export class HandView extends THREE.Group {
  readonly palm: THREE.Mesh
  private readonly fingers: THREE.Mesh[] = []
  private readonly thumb: THREE.Mesh

  constructor(mirror: boolean) {
    super()
    const skin = new THREE.MeshStandardMaterial({ color: 0xc9a184, roughness: 0.75 })
    this.palm = new THREE.Mesh(new THREE.SphereGeometry(0.062, 10, 8), skin)
    this.palm.scale.set(0.95, 0.45, 1.25)
    this.palm.castShadow = true
    this.add(this.palm)

    const fingerGeo = new THREE.CapsuleGeometry(0.012, 0.055, 3, 6)
    for (let i = 0; i < 4; i++) {
      const f = new THREE.Mesh(fingerGeo, skin)
      f.position.set(-0.038 + i * 0.025, -0.002, -0.085)
      f.castShadow = true
      this.add(f)
      this.fingers.push(f)
    }
    this.thumb = new THREE.Mesh(new THREE.CapsuleGeometry(0.013, 0.05, 3, 6), skin)
    this.thumb.position.set(mirror ? -0.06 : 0.06, -0.005, -0.015)
    this.thumb.castShadow = true
    this.add(this.thumb)
    this.setLoad(0)
  }

  /** Curl fingers / compress palm under load: load ∈ 0..1. */
  setLoad(load: number): void {
    const curl = 0.35 + load * 0.55
    for (const f of this.fingers) {
      f.rotation.x = -curl
      f.position.y = -0.002 + load * 0.006
    }
    this.thumb.rotation.z = (this.thumb.position.x < 0 ? -1 : 1) * (0.5 + load * 0.3)
    this.palm.scale.set(0.95, 0.45 * (1 - load * 0.25), 1.25)
  }
}

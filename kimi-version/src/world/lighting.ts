import * as THREE from 'three'

export class Lighting {
  readonly sun: THREE.DirectionalLight

  constructor(scene: THREE.Scene) {
    scene.add(new THREE.HemisphereLight(0xf2e2c4, 0x6a6250, 0.85))
    this.sun = new THREE.DirectionalLight(0xffd9a8, 2.6)
    this.sun.position.set(45, 38, 30) // low, warm, long shadows
    this.sun.castShadow = true
    this.sun.shadow.mapSize.set(2048, 2048)
    const s = 60
    Object.assign(this.sun.shadow.camera, { left: -s, right: s, top: s, bottom: -s, far: 260 })
    this.sun.shadow.bias = -0.0004
    scene.add(this.sun)
  }

  /** Keep the shadow box centered on the player. */
  follow(x: number, z: number): void {
    this.sun.position.set(x + 45, 38, z + 30)
    this.sun.target.position.set(x, 0, z)
    this.sun.target.updateMatrixWorld()
  }
}

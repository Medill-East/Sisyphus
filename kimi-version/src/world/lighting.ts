import * as THREE from 'three'

export class Lighting {
  readonly sun: THREE.DirectionalLight

  constructor(scene: THREE.Scene) {
    scene.add(new THREE.HemisphereLight(0xcfe5ef, 0x5a5648, 0.9))
    this.sun = new THREE.DirectionalLight(0xfff2dd, 2.4)
    this.sun.position.set(30, 60, 25)
    this.sun.castShadow = true
    this.sun.shadow.mapSize.set(2048, 2048)
    const s = 60
    Object.assign(this.sun.shadow.camera, { left: -s, right: s, top: s, bottom: -s, far: 220 })
    scene.add(this.sun)
  }

  /** Keep the shadow box centered on the player. */
  follow(x: number, z: number): void {
    this.sun.position.set(x + 30, 60, z + 25)
    this.sun.target.position.set(x, 0, z)
    this.sun.target.updateMatrixWorld()
  }
}

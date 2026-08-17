import * as THREE from 'three'
import { TUNING } from '../core/tuning'

/** Icosahedron with deterministic radial jitter — reads as rock, rolls as a sphere. */
export class StoneMesh extends THREE.Mesh {
  constructor() {
    const geo = new THREE.IcosahedronGeometry(TUNING.stone.radius, 3)
    const pos = geo.attributes.position
    const v = new THREE.Vector3()
    for (let i = 0; i < pos.count; i++) {
      v.set(pos.getX(i), pos.getY(i), pos.getZ(i))
      const n = Math.sin(v.x * 12.9) * Math.sin(v.y * 7.7) * Math.sin(v.z * 9.1)
      v.multiplyScalar(1 + n * 0.045)
      pos.setXYZ(i, v.x, v.y, v.z)
    }
    geo.computeVertexNormals()
    super(geo, new THREE.MeshStandardMaterial({ color: 0x8d8578, roughness: 0.95, flatShading: true }))
    this.castShadow = true
    this.receiveShadow = true
  }
}

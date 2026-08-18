import * as THREE from 'three'
import { sampleHeight } from './heightfield'

/**
 * The stone's labor trail: dark crushed-earth stamps left where it actually
 * rolled. Ring buffer; persists for the run. This is the record of labor.
 */
export class Trail {
  private readonly mesh: THREE.InstancedMesh
  private head = 0
  private lastStamp: { x: number; z: number } | null = null
  private readonly CAP = 1800
  private readonly m4 = new THREE.Matrix4()
  private readonly q = new THREE.Quaternion()
  private readonly eu = new THREE.Euler()

  constructor() {
    const geo = new THREE.PlaneGeometry(0.62, 0.85)
    geo.rotateX(-Math.PI / 2)
    const mat = new THREE.MeshStandardMaterial({
      color: 0x57472f,
      roughness: 1,
      polygonOffset: true,
      polygonOffsetFactor: -1,
      polygonOffsetUnits: -2,
    })
    this.mesh = new THREE.InstancedMesh(geo, mat, this.CAP)
    this.mesh.count = 0
    this.mesh.receiveShadow = true
  }

  /** Stamp the ground under the stone when it has rolled far enough since the last stamp. */
  record(x: number, z: number): void {
    if (this.lastStamp && Math.hypot(x - this.lastStamp.x, z - this.lastStamp.z) < 0.28) return
    this.lastStamp = { x, z }
    const y = sampleHeight(x, z) + 0.015
    this.eu.set(0, Math.random() * Math.PI, 0)
    this.q.setFromEuler(this.eu)
    const s = 0.85 + Math.random() * 0.3
    this.m4.compose(new THREE.Vector3(x, y, z), this.q, new THREE.Vector3(s, 1, s))
    this.mesh.setMatrixAt(this.head % this.CAP, this.m4)
    this.head++
    this.mesh.count = Math.min(this.head, this.CAP)
    this.mesh.instanceMatrix.needsUpdate = true
  }
}

import * as THREE from 'three'
import { TUNING } from '../core/tuning'
import { sampleHeight } from './heightfield'

function mulberry(seed: number): () => number {
  let a = seed | 0
  return () => {
    a = (a + 0x6d2b79f5) | 0
    let t = Math.imul(a ^ (a >>> 15), 1 | a)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

/** Scattered slope life: grass tufts, rocks, cypress trees. Deterministic, instanced. */
export function buildScatter(): THREE.Group {
  const M = TUNING.mountain
  const rng = mulberry(20260819)
  const group = new THREE.Group()
  const zMin = -M.backLength - 8
  const zMax = M.frontLength + 8

  // Grass tufts: 3-blade cone clusters, off-track only.
  const tuftGeo = new THREE.ConeGeometry(0.05, 0.42, 4)
  tuftGeo.translate(0, 0.21, 0)
  const tuftMat = new THREE.MeshStandardMaterial({ color: 0x8a8547, roughness: 1 })
  const TUFTS = 900
  const tufts = new THREE.InstancedMesh(tuftGeo, tuftMat, TUFTS * 3)
  const m4 = new THREE.Matrix4()
  const q = new THREE.Quaternion()
  const eu = new THREE.Euler()
  let ti = 0
  for (let i = 0; i < TUFTS; i++) {
    const x = (rng() * 2 - 1) * M.worldHalfX * 0.95
    const z = zMin + rng() * (zMax - zMin)
    if (Math.abs(x) < M.pathHalfWidth * 1.15) continue
    const y = sampleHeight(x, z)
    for (let b = 0; b < 3; b++) {
      eu.set((rng() - 0.5) * 0.5, rng() * Math.PI, (rng() - 0.5) * 0.5)
      q.setFromEuler(eu)
      const s = 0.7 + rng() * 0.9
      m4.compose(
        new THREE.Vector3(x + (rng() - 0.5) * 0.14, y, z + (rng() - 0.5) * 0.14),
        q,
        new THREE.Vector3(s, s, s),
      )
      if (ti < TUFTS * 3) tufts.setMatrixAt(ti++, m4)
    }
  }
  tufts.count = ti
  group.add(tufts)

  // Rocks: jittered icosahedra, a few near the track for scale.
  const rockGeo = new THREE.IcosahedronGeometry(1, 0)
  const rockMat = new THREE.MeshStandardMaterial({ color: 0x8a8074, roughness: 0.95, flatShading: true })
  const ROCKS = 130
  const rocks = new THREE.InstancedMesh(rockGeo, rockMat, ROCKS)
  let ri = 0
  for (let i = 0; i < ROCKS * 3 && ri < ROCKS; i++) {
    const near = rng() < 0.35
    const x = near ? (M.pathHalfWidth + 0.4 + rng() * 2.5) * (rng() < 0.5 ? -1 : 1) : (rng() * 2 - 1) * M.worldHalfX * 0.9
    const z = zMin + rng() * (zMax - zMin)
    if (!near && Math.abs(x) < M.pathHalfWidth * 1.3) continue
    const s = 0.08 + rng() * rng() * 0.55
    eu.set(rng() * Math.PI, rng() * Math.PI, rng() * Math.PI)
    q.setFromEuler(eu)
    m4.compose(new THREE.Vector3(x, sampleHeight(x, z) + s * 0.25, z), q, new THREE.Vector3(s, s * (0.7 + rng() * 0.6), s))
    rocks.setMatrixAt(ri++, m4)
  }
  rocks.count = ri
  rocks.castShadow = true
  group.add(rocks)

  // Cypress trees: trunk + stretched dark cone; clustered at foot, mid-slope, back.
  const trunkGeo = new THREE.CylinderGeometry(0.05, 0.07, 0.9, 5)
  trunkGeo.translate(0, 0.45, 0)
  const crownGeo = new THREE.ConeGeometry(0.55, 2.6, 7)
  crownGeo.translate(0, 0.9 + 1.3, 0)
  const trunkMat = new THREE.MeshStandardMaterial({ color: 0x5c4a36, roughness: 1 })
  const crownMat = new THREE.MeshStandardMaterial({ color: 0x3f5a3a, roughness: 1 })
  const spots: [number, number][] = []
  const clusters: [number, number, number][] = [
    [6.5, M.frontLength - 10, 4],
    [-7.5, M.frontLength - 22, 3],
    [8, M.frontLength * 0.55, 3],
    [-6, M.frontLength * 0.3, 2],
    [7, -M.backLength * 0.5, 3],
    [-8, -M.backLength + 12, 4],
    [5.5, -M.backLength * 0.25, 2],
  ]
  for (const [cx, cz, n] of clusters) {
    for (let i = 0; i < n; i++) {
      spots.push([cx + (rng() - 0.5) * 6, cz + (rng() - 0.5) * 8])
    }
  }
  const trunks = new THREE.InstancedMesh(trunkGeo, trunkMat, spots.length)
  const crowns = new THREE.InstancedMesh(crownGeo, crownMat, spots.length)
  spots.forEach(([x, z], i) => {
    const s = 0.8 + rng() * 0.9
    const y = sampleHeight(x, z)
    eu.set(0, rng() * Math.PI, (rng() - 0.5) * 0.06)
    q.setFromEuler(eu)
    m4.compose(new THREE.Vector3(x, y, z), q, new THREE.Vector3(s, s, s))
    trunks.setMatrixAt(i, m4)
    crowns.setMatrixAt(i, m4)
  })
  trunks.castShadow = true
  crowns.castShadow = true
  group.add(trunks, crowns)

  return group
}

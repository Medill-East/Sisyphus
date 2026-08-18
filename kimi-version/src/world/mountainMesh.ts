import * as THREE from 'three'
import { TUNING } from '../core/tuning'
import { sampleHeight } from './heightfield'

const DRY_GRASS = new THREE.Color(0x9a8f5a)
const DIRT = new THREE.Color(0x8a6f4d)
const WORN = new THREE.Color(0x6f5a40)
const ROCK = new THREE.Color(0x7d7a72)

/** Terrain mesh with vertex colors: worn dirt track, dry-grass slopes, rocky crest. */
export function buildMountainMesh(): THREE.Mesh {
  const M = TUNING.mountain
  const segX = 160
  const segZ = 260
  const width = M.worldHalfX * 2
  const depth = M.frontLength + M.backLength + 20
  const zCenter = (M.frontLength - M.backLength) / 2
  const geo = new THREE.PlaneGeometry(width, depth, segX, segZ)
  geo.rotateX(-Math.PI / 2)
  const pos = geo.attributes.position
  const colors = new Float32Array(pos.count * 3)
  const c = new THREE.Color()
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i)
    const z = pos.getZ(i) + zCenter
    const h = sampleHeight(x, z)
    pos.setY(i, h)
    pos.setZ(i, z)
    const ax = Math.abs(x)
    const pathT = Math.min(ax / M.pathHalfWidth, 1)
    const crestT = Math.min(Math.max(h / M.ridgeHeight, 0), 1)
    // Dry grass base, worn dirt on the track (darkest at the center line).
    c.copy(DRY_GRASS).lerp(DIRT, 1 - pathT * pathT)
    if (pathT < 0.45) c.lerp(WORN, (1 - pathT / 0.45) * 0.55)
    c.lerp(ROCK, Math.max(crestT * 0.55, Math.min(Math.max(ax - M.pathHalfWidth * 2, 0) / 10, 0.35)))
    colors[i * 3] = c.r
    colors[i * 3 + 1] = c.g
    colors[i * 3 + 2] = c.b
  }
  geo.setAttribute('color', new THREE.BufferAttribute(colors, 3))
  geo.computeVertexNormals()
  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 1 }))
  mesh.receiveShadow = true
  return mesh
}

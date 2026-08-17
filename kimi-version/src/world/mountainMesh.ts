import * as THREE from 'three'
import { TUNING } from '../core/tuning'
import { sampleHeight } from './heightfield'

const GRASS = new THREE.Color(0x5d7a4a)
const DIRT = new THREE.Color(0x8a7355)
const ROCK = new THREE.Color(0x6f7076)

/** Terrain mesh with vertex colors: dirt path band, grassy banks, rocky crest. */
export function buildMountainMesh(): THREE.Mesh {
  const M = TUNING.mountain
  const segX = 120
  const segZ = 220
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
    c.copy(GRASS).lerp(DIRT, 1 - pathT * pathT) // dirt inside the path band
    c.lerp(ROCK, Math.max(crestT * 0.6, Math.min(Math.max(ax - M.pathHalfWidth, 0) / 6, 0.5)))
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

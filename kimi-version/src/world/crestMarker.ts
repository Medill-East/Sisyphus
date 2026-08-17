import * as THREE from 'three'
import { TUNING } from '../core/tuning'

/** Faint ridge marker: a slim pale post at the crest, visible from either foot. */
export function buildCrestMarker(): THREE.Group {
  const g = new THREE.Group()
  const post = new THREE.Mesh(
    new THREE.CylinderGeometry(0.06, 0.09, 3.2, 6),
    new THREE.MeshStandardMaterial({ color: 0xd8cfb8, roughness: 0.7, emissive: 0x332d1e }),
  )
  post.position.set(0, TUNING.mountain.ridgeHeight + 1.6, 0)
  post.castShadow = true
  g.add(post)
  return g
}

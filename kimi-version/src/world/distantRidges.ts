import * as THREE from 'three'

/** Far silhouette ridges + a hazy low plain that grounds the horizon. */
export function buildDistantRidges(): THREE.Group {
  const group = new THREE.Group()
  const plain = new THREE.Mesh(
    new THREE.CircleGeometry(1400, 48),
    new THREE.MeshBasicMaterial({ color: 0x9aa06e, fog: true }),
  )
  plain.rotation.x = -Math.PI / 2
  plain.position.y = -14
  group.add(plain)
  const ridges: { x: number; z: number; w: number; h: number; color: number; rot: number }[] = [
    { x: -60, z: 420, w: 700, h: 90, color: 0x5f6b82, rot: 0.2 },
    { x: 120, z: 520, w: 900, h: 130, color: 0x666e84, rot: -0.15 },
    { x: 40, z: -480, w: 800, h: 110, color: 0x6b6780, rot: 0.1 },
    { x: -420, z: 60, w: 700, h: 100, color: 0x5d6a7c, rot: 1.35 },
    { x: 460, z: -40, w: 650, h: 85, color: 0x716d84, rot: -1.2 },
  ]
  for (const r of ridges) {
    const geo = new THREE.ConeGeometry(r.w / 2, r.h, 24, 1, true)
    // Flatten the cone into a ridge line.
    geo.scale(1, 1, 0.22)
    const mat = new THREE.MeshBasicMaterial({ color: r.color, fog: true })
    const mesh = new THREE.Mesh(geo, mat)
    mesh.position.set(r.x, r.h / 2 - 8, r.z)
    mesh.rotation.y = r.rot
    group.add(mesh)
  }
  return group
}

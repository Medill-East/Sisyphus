import RAPIER from '@dimforge/rapier3d-compat'
import { TUNING } from '../core/tuning'
import { sampleHeight } from '../world/heightfield'

const M = TUNING.mountain
const GRID_X = 80 // columns across x
const GRID_Z = 160 // rows along z

/**
 * Heightfield collider generated from the same sampleHeight used for rendering.
 * Rapier layout (verified empirically by scripts/probeAxes.ts): column-major,
 * first (row) index sweeps the LOCAL Z axis, second (column) index sweeps X;
 * increasing indices go from low to high coordinates. So heights[iz + ix*(GRID_Z+1)].
 */
export function buildTerrainCollider(): RAPIER.ColliderDesc {
  const width = M.worldHalfX * 2
  const depth = M.frontLength + M.backLength + 20
  const zMin = -(M.backLength + 10)
  const heights = new Float32Array((GRID_X + 1) * (GRID_Z + 1))
  for (let ix = 0; ix <= GRID_X; ix++) {
    const x = -M.worldHalfX + (ix / GRID_X) * width
    for (let iz = 0; iz <= GRID_Z; iz++) {
      const z = zMin + (iz / GRID_Z) * depth
      heights[iz + ix * (GRID_Z + 1)] = sampleHeight(x, z)
    }
  }
  return RAPIER.ColliderDesc.heightfield(GRID_Z, GRID_X, heights, {
    x: width,
    y: 1,
    z: depth,
  })
    .setTranslation(0, 0, (M.frontLength - M.backLength) / 2)
    .setFriction(1.0)
}

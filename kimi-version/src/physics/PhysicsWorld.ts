import RAPIER from '@dimforge/rapier3d-compat'
import { buildTerrainCollider } from './terrainCollider'

export const FIXED_DT = 1 / 60

export class PhysicsWorld {
  readonly world: RAPIER.World

  constructor() {
    this.world = new RAPIER.World({ x: 0, y: -9.81, z: 0 })
    this.world.timestep = FIXED_DT
    this.world.createCollider(buildTerrainCollider())
  }

  step(): void {
    this.world.step()
  }

  /** Downward ground ray; returns ground normal and hit height, or null. */
  groundProbe(x: number, y: number, z: number, exclude?: RAPIER.RigidBody): { normalY: number; hitY: number } | null {
    const ray = new RAPIER.Ray({ x, y, z }, { x: 0, y: -1, z: 0 })
    const hit = this.world.castRayAndGetNormal(ray, 30, true, undefined, undefined, undefined, exclude)
    if (!hit) return null
    const toi =
      (hit as unknown as { timeOfImpact?: number }).timeOfImpact ??
      (hit as unknown as { toi: number }).toi
    return { normalY: hit.normal.y, hitY: y - toi }
  }
}

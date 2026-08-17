# Kimi Version MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Build a clean-room, physically honest, visually readable first-person push-the-stone MVP loop (`approach → engage → push → ridge release → descent → result`) in `kimi-version/`, per `docs/superpowers/specs/2026-08-18-kimi-version-mvp-design.md`.

**Architecture:** TypeScript + three.js + Rapier (WASM, same binary in Node and browser). Pure-math modules (terrain, push model, IK, state machine) and Rapier physics are unit-tested headlessly in Node via vitest; rendering is verified through a Playwright screenshot harness driving scripted "auto beats". Rendering reads state and never mutates physics; all input devices merge into one `InputIntent`.

**Tech Stack:** Vite, TypeScript (strict), three.js, `@dimforge/rapier3d-compat`, vitest, Playwright.

**Key conventions:**
- World axes: Y up. Ridge at `z = 0`, front foot at `z = +FRONT_LENGTH`, back foot at `z = -BACK_LENGTH`. Pushing always means "toward `z = 0` from the side the stone rests on".
- Fixed physics step `1/60 s`; render interpolation reads the latest state (no extrapolation for MVP).
- Every force on the stone goes through `stone.applyImpulseAtPoint` at a real contact point. No scripted translation, ever.
- All tunables live in `src/core/tuning.ts` as one exported `TUNING` const.

---

### Task 0: Environment check and project scaffold

**Files:**
- Create: `kimi-version/package.json`
- Create: `kimi-version/tsconfig.json`
- Create: `kimi-version/vite.config.ts`
- Create: `kimi-version/vitest.config.ts`
- Create: `kimi-version/index.html`
- Create: `kimi-version/.gitignore`
- Create: `kimi-version/src/main.ts`
- Create: `kimi-version/src/core/tuning.ts`
- Create: `kimi-version/tests/smoke.test.ts`

- [x] **Step 1: Verify toolchain**

Run: `node -v && npm -v`
Expected: Node ≥ 18 (any recent LTS). If missing, stop and report.

- [x] **Step 2: Write scaffold files**

`kimi-version/package.json`:

```json
{
  "name": "sisyphus-kimi-version",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --port 4173",
    "test": "vitest run",
    "capture": "tsx scripts/capture.ts"
  },
  "dependencies": {
    "@dimforge/rapier3d-compat": "^0.14.0",
    "three": "^0.166.0"
  },
  "devDependencies": {
    "@types/three": "^0.166.0",
    "playwright": "^1.45.0",
    "tsx": "^4.16.0",
    "typescript": "^5.5.0",
    "vite": "^5.4.0",
    "vitest": "^2.1.0"
  }
}
```

`kimi-version/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUnusedLocals": true,
    "skipLibCheck": true,
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "types": ["vite/client"],
    "isolatedModules": true,
    "noEmit": true
  },
  "include": ["src", "tests", "scripts"]
}
```

`kimi-version/vite.config.ts`:

```ts
import { defineConfig } from 'vite'

export default defineConfig({
  server: { port: 5178, strictPort: true },
})
```

`kimi-version/vitest.config.ts`:

```ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: { environment: 'node', testTimeout: 30000 },
})
```

`kimi-version/index.html`:

```html
<!doctype html>
<html lang="zh">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>西西弗斯下山 · Kimi Version</title>
    <style>
      html, body { margin: 0; padding: 0; overflow: hidden; background: #0e1216; height: 100%; }
      canvas { display: block; }
    </style>
  </head>
  <body>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

`kimi-version/.gitignore`:

```
node_modules/
dist/
evidence/
```

`kimi-version/src/core/tuning.ts`:

```ts
/** Every gameplay/visual tunable in one place. Distances in meters, forces in newtons. */
export const TUNING = {
  stone: {
    radius: 1.0,
    mass: 220,
    friction: 0.9,
    restitution: 0,
    angularDamping: 0.05,
    linearDamping: 0.02,
    /** Below this ground slope (deg) a slow stone is statically held. */
    holdSlopeDeg: 8,
    /** Speed (m/s) under which the static hold may engage. */
    holdSpeedEps: 0.18,
    /** Kinetic rolling resistance coefficient (force = k * m * g). */
    kineticResistance: 0.02,
    /** Extra static resistance force (N) that must be overcome to break away. */
    staticBreakawayForce: 260,
  },
  push: {
    /** Force per fully-pressed hand (N). */
    maxForcePerHand: 950,
    /** Chest-to-surface distance (m) within which hands may engage. */
    reachDistance: 0.72,
    /** Hysteresis multiplier for staying engaged. */
    reachHysteresis: 1.18,
    shoulderHeight: 1.32,
    shoulderHalfWidth: 0.24,
  },
  player: {
    eyeHeight: 1.62,
    radius: 0.34,
    walkSpeed: 3.4,
    engagedWalkSpeed: 1.9,
    turnLerp: 10,
  },
  camera: {
    fov: 62,
    engagedFov: 55,
    neckYawLimitDeg: 120,
    neckPitchUpDeg: 55,
    neckPitchDownDeg: 40,
    engageEase: 4.5,
  },
  mountain: {
    ridgeHeight: 16,
    frontLength: 85,
    backLength: 65,
    pathHalfWidth: 2.2,
    bankRise: 2.6,
    noiseAmplitude: 0.22,
    worldHalfX: 40,
  },
  loop: {
    releaseWatchSeconds: 3.0,
    restSpeedEps: 0.25,
    restHoldSeconds: 1.5,
    resultDistance: 3.0,
  },
} as const

export type Tuning = typeof TUNING
```

`kimi-version/src/main.ts` (temporary smoke scene; replaced in Task 7):

```ts
import * as THREE from 'three'

const renderer = new THREE.WebGLRenderer({ antialias: true })
renderer.setSize(window.innerWidth, window.innerHeight)
document.body.appendChild(renderer.domElement)
const scene = new THREE.Scene()
const camera = new THREE.PerspectiveCamera(62, innerWidth / innerHeight, 0.1, 400)
camera.position.set(0, 2, 5)
scene.add(new THREE.Mesh(new THREE.BoxGeometry(), new THREE.MeshNormalMaterial()))
renderer.render(scene, camera)
;(window as unknown as { __smoke: boolean }).__smoke = true
```

`kimi-version/tests/smoke.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import { TUNING } from '../src/core/tuning'

describe('scaffold', () => {
  it('loads tuning', () => {
    expect(TUNING.stone.radius).toBeGreaterThan(0)
  })
})
```

- [x] **Step 3: Install and verify**

Run: `cd kimi-version && npm install && npm run test && npm run build`
Expected: vitest 1 passed; vite build succeeds.

- [x] **Step 4: Commit**

```bash
git add kimi-version && git commit -m "feat(kimi-version): 工程脚手架（Vite+TS+three+Rapier+vitest）"
```

---

### Task 1: Mountain height model (pure math)

**Files:**
- Create: `kimi-version/src/world/heightfield.ts`
- Test: `kimi-version/tests/heightfield.test.ts`

The single source of truth for terrain: `sampleHeight(x, z)`. Physics collider (Task 2) and render mesh (Task 7) are both generated from it.

- Ridge at `z = 0` with height `ridgeHeight`; `h = 0` at `z = frontLength` and `z = -backLength`.
- Each side is a cosine profile `h = H * (1 + cos(pi * t)) / 2` with `t = |z| / L` — gentle at foot and crest, steepest mid-slope.
- Banking: for `|x| > pathHalfWidth`, add `bankRise * ((|x| - pathHalfWidth) / pathHalfWidth) ** 1.4`.
- Noise: deterministic value noise, amplitude `noiseAmplitude`, zero inside the path band, fading in by `|x| = 2 * pathHalfWidth`.

- [x] **Step 1: Write the failing test**

`kimi-version/tests/heightfield.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import { sampleHeight, slopeDegAt } from '../src/world/heightfield'
import { TUNING } from '../src/core/tuning'

const M = TUNING.mountain

describe('heightfield', () => {
  it('is zero at both feet and ridge height at crest', () => {
    expect(sampleHeight(0, M.frontLength)).toBeCloseTo(0, 3)
    expect(sampleHeight(0, -M.backLength)).toBeCloseTo(0, 3)
    expect(sampleHeight(0, 0)).toBeCloseTo(M.ridgeHeight, 3)
  })

  it('descends monotonically away from the ridge on the path', () => {
    for (const side of [1, -1]) {
      const L = side > 0 ? M.frontLength : M.backLength
      let prev = Infinity
      for (let i = 0; i <= 20; i++) {
        const h = sampleHeight(0, side * (i / 20) * L)
        expect(h).toBeLessThanOrEqual(prev + 1e-6)
        prev = h
      }
    }
  })

  it('max path grade stays pushable (10–24 deg) on both sides', () => {
    for (const side of [1, -1]) {
      const L = side > 0 ? M.frontLength : M.backLength
      let maxG = 0
      for (let i = 1; i < 100; i++) {
        maxG = Math.max(maxG, slopeDegAt(0, side * (i / 100) * L))
      }
      expect(maxG).toBeGreaterThan(10)
      expect(maxG).toBeLessThan(24)
    }
  })

  it('banks rise beyond the path and noise stays off the path', () => {
    const z = M.frontLength * 0.5
    const center = sampleHeight(0, z)
    expect(sampleHeight(6, z)).toBeGreaterThan(center + 1.0)
    expect(sampleHeight(0.5, z)).toBeCloseTo(sampleHeight(-0.5, z), 6)
  })

  it('noise is deterministic', () => {
    expect(sampleHeight(9.3, 12.7)).toBe(sampleHeight(9.3, 12.7))
  })
})
```

- [x] **Step 2: Run to verify it fails**

Run: `cd kimi-version && npx vitest run tests/heightfield.test.ts`
Expected: FAIL — module not found.

- [x] **Step 3: Implement**

`kimi-version/src/world/heightfield.ts`:

```ts
import { TUNING } from '../core/tuning'

const M = TUNING.mountain

function hash(ix: number, iz: number): number {
  let h = (ix * 374761393 + iz * 668265263) | 0
  h = (h ^ (h >> 13)) | 0
  h = Math.imul(h, 1274126177)
  return ((h ^ (h >> 16)) >>> 0) / 4294967295
}

function valueNoise(x: number, z: number): number {
  const ix = Math.floor(x)
  const iz = Math.floor(z)
  const fx = x - ix
  const fz = z - iz
  const sx = fx * fx * (3 - 2 * fx)
  const sz = fz * fz * (3 - 2 * fz)
  const a = hash(ix, iz)
  const b = hash(ix + 1, iz)
  const c = hash(ix, iz + 1)
  const d = hash(ix + 1, iz + 1)
  return (a + (b - a) * sx + (c - a) * sz + (a - b - c + d) * sx * sz) * 2 - 1
}

/** Cosine slope profile for one side: t = distance from crest normalized to side length. */
function sideProfile(t: number): number {
  return (M.ridgeHeight * (1 + Math.cos(Math.PI * Math.min(Math.max(t, 0), 1)))) / 2
}

/**
 * Terrain height. z > 0 is the front side (foot at z = frontLength),
 * z < 0 the back side (foot at z = -backLength). Ridge crest at z = 0.
 */
export function sampleHeight(x: number, z: number): number {
  const t = z >= 0 ? z / M.frontLength : -z / M.backLength
  let h = sideProfile(t)
  const ax = Math.abs(x)
  if (ax > M.pathHalfWidth) {
    const over = (ax - M.pathHalfWidth) / M.pathHalfWidth
    h += M.bankRise * Math.pow(over, 1.4)
  }
  const noiseFade = Math.min(Math.max((ax - M.pathHalfWidth) / M.pathHalfWidth, 0), 1)
  if (noiseFade > 0) {
    h += M.noiseAmplitude * noiseFade * valueNoise(x * 0.35, z * 0.35)
  }
  return h
}

/** Local path grade in degrees along z (path center). */
export function slopeDegAt(x: number, z: number): number {
  const dz = 0.25
  const dhdz = (sampleHeight(x, z + dz) - sampleHeight(x, z - dz)) / (2 * dz)
  return (Math.atan(Math.abs(dhdz)) * 180) / Math.PI
}
```

- [x] **Step 4: Run tests**

Run: `npx vitest run tests/heightfield.test.ts`
Expected: 5 passed. If max grade falls outside 10–24°, adjust `ridgeHeight`/`frontLength`/`backLength` in `TUNING` and re-run (this is the intended calibration).

- [x] **Step 5: Commit**

```bash
git add kimi-version && git commit -m "feat(kimi-version): 山体高度场模型（双峰余弦坡+挡坡+确定性噪声）"
```

---

### Task 2: Rapier world, terrain collider, stone drop/resistance calibration

**Files:**
- Create: `kimi-version/src/physics/PhysicsWorld.ts`
- Create: `kimi-version/src/physics/terrainCollider.ts`
- Create: `kimi-version/src/physics/stone.ts`
- Test: `kimi-version/tests/stonePhysics.test.ts`

This is the make-or-break calibration: if a Rapier sphere does not rest, hold, and roll back believably on our heightfield, nothing else matters. Rapier's heightfield heights layout (row/column order) is verified empirically by the drop test; if rest heights come out mirrored, transpose the index math inside `terrainCollider.ts` only.

- [x] **Step 1: Write the failing test**

`kimi-version/tests/stonePhysics.test.ts`:

```ts
import { beforeAll, describe, expect, it } from 'vitest'
import RAPIER from '@dimforge/rapier3d-compat'
import { PhysicsWorld } from '../src/physics/PhysicsWorld'
import { Stone } from '../src/physics/stone'
import { sampleHeight } from '../src/world/heightfield'
import { TUNING } from '../src/core/tuning'

beforeAll(async () => {
  await RAPIER.init()
})

/** Step the world n times, applying stone resistance each step (no push input). */
function settle(pw: PhysicsWorld, stone: Stone, steps: number) {
  for (let i = 0; i < steps; i++) {
    stone.applyResistance(false)
    pw.step()
  }
}

function dropAndSettle(pw: PhysicsWorld, x: number, z: number, seconds = 4) {
  const stone = new Stone(pw, x, sampleHeight(x, z) + TUNING.stone.radius + 1.5, z)
  settle(pw, stone, Math.round(seconds * 60))
  return stone
}

describe('stone on terrain', () => {
  it('rests on the surface at drop position height', () => {
    const pw = new PhysicsWorld()
    const z = TUNING.mountain.frontLength - 2 // near foot, gentle
    const stone = dropAndSettle(pw, 0, z)
    const y = stone.position().y
    expect(y).toBeCloseTo(sampleHeight(0, z) + TUNING.stone.radius, 0)
  })

  it('holds still on a gentle grade (below hold slope)', () => {
    const pw = new PhysicsWorld()
    const z = TUNING.mountain.frontLength * 0.92 // grade ~3 deg
    const stone = dropAndSettle(pw, 0, z)
    const start = stone.position()
    settle(pw, stone, 240)
    const end = stone.position()
    expect(Math.hypot(end.x - start.x, end.z - start.z)).toBeLessThan(0.3)
  })

  it('rolls back downhill on a steep grade (above hold slope)', () => {
    const pw = new PhysicsWorld()
    const z = TUNING.mountain.frontLength * 0.5 // mid-slope ~16 deg
    const stone = dropAndSettle(pw, 0, z, 2)
    const z0 = stone.position().z
    let moved = false
    for (let i = 0; i < 360; i++) {
      stone.applyResistance(false)
      pw.step()
      if (stone.position().z > z0 + 1.0) moved = true // downhill on front side is +z
    }
    expect(moved).toBe(true)
  })
})
```

- [x] **Step 2: Run to verify it fails**

Run: `npx vitest run tests/stonePhysics.test.ts`
Expected: FAIL — modules not found.

- [x] **Step 3: Implement**

`kimi-version/src/physics/PhysicsWorld.ts`:

```ts
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
  groundProbe(x: number, y: number, z: number): { normalY: number; hitY: number } | null {
    const ray = new RAPIER.Ray({ x, y, z }, { x: 0, y: -1, z: 0 })
    const hit = this.world.castRayAndGetNormal(ray, 30, true)
    if (!hit) return null
    const toi = (hit as unknown as { timeOfImpact?: number; toi?: number }).timeOfImpact
      ?? (hit as unknown as { toi: number }).toi
    return { normalY: hit.normal.y, hitY: y - toi }
  }
}
```

`kimi-version/src/physics/terrainCollider.ts`:

```ts
import RAPIER from '@dimforge/rapier3d-compat'
import { TUNING } from '../core/tuning'
import { sampleHeight } from '../world/heightfield'

const M = TUNING.mountain
const GRID_X = 80 // columns across x
const GRID_Z = 160 // rows along z

/**
 * Heightfield collider generated from the same sampleHeight used for rendering.
 * NOTE: if the drop test reports mirrored/transposed rest positions, swap the
 * index expression `iz * (GRID_X + 1) + ix` to `ix * (GRID_Z + 1) + iz` —
 * Rapier heightfield storage order is the one thing this builder calibrates.
 */
export function buildTerrainCollider(): RAPIER.ColliderDesc {
  const width = M.worldHalfX * 2
  const depth = M.frontLength + M.backLength + 20
  const heights = new Float32Array((GRID_X + 1) * (GRID_Z + 1))
  for (let iz = 0; iz <= GRID_Z; iz++) {
    const z = M.frontLength + 10 - (iz / GRID_Z) * depth
    for (let ix = 0; ix <= GRID_X; ix++) {
      const x = -M.worldHalfX + (ix / GRID_X) * width
      heights[iz * (GRID_X + 1) + ix] = sampleHeight(x, z)
    }
  }
  return RAPIER.ColliderDesc.heightfield(GRID_Z, GRID_X, heights, {
    x: width,
    y: 1,
    z: depth,
  })
    .setTranslation(0, 0, (M.frontLength + 10 - (M.backLength + 10)) / 2)
    .setFriction(1.0)
}
```

`kimi-version/src/physics/stone.ts`:

```ts
import RAPIER from '@dimforge/rapier3d-compat'
import { TUNING } from '../core/tuning'
import { FIXED_DT, type PhysicsWorld } from './PhysicsWorld'

const S = TUNING.stone
const G = 9.81

export class Stone {
  readonly body: RAPIER.RigidBody
  private readonly pw: PhysicsWorld
  /** True while the static hold keeps the stone parked. */
  held = false

  constructor(pw: PhysicsWorld, x: number, y: number, z: number) {
    this.pw = pw
    this.body = pw.world.createRigidBody(
      RAPIER.RigidBodyDesc.dynamic()
        .setTranslation(x, y, z)
        .setLinearDamping(S.linearDamping)
        .setAngularDamping(S.angularDamping),
    )
    pw.world.createCollider(
      RAPIER.ColliderDesc.ball(S.radius)
        .setFriction(S.friction)
        .setRestitution(S.restitution)
        .setMass(S.mass),
      this.body,
    )
  }

  position(): { x: number; y: number; z: number } {
    return this.body.translation()
  }

  velocity(): { x: number; y: number; z: number } {
    return this.body.linvel()
  }

  speed(): number {
    const v = this.body.linvel()
    return Math.hypot(v.x, v.y, v.z)
  }

  /** Ground slope in degrees under the stone (0 when airborne). */
  groundSlopeDeg(): number {
    const p = this.body.translation()
    const probe = this.pw.groundProbe(p.x, p.y, p.z)
    if (!probe) return 0
    return (Math.acos(Math.min(Math.max(probe.normalY, -1), 1)) * 180) / Math.PI
  }

  /**
   * Rolling resistance + static hold. Call once per fixed step.
   * `pushing` = any hand currently applying force this step.
   * Static: slow stone on a slope below holdSlopeDeg is parked.
   * Kinetic: resistance opposes horizontal velocity; from rest it also
   * subtracts staticBreakawayForce from the driver's job (breakaway beat).
   */
  applyResistance(pushing: boolean): void {
    const v = this.body.linvel()
    const hSpeed = Math.hypot(v.x, v.z)
    const slope = this.groundSlopeDeg()
    if (!pushing && hSpeed < S.holdSpeedEps && slope < S.holdSlopeDeg) {
      this.held = true
      this.body.setLinvel({ x: 0, y: v.y, z: 0 }, true)
      this.body.setAngvel({ x: 0, y: 0, z: 0 }, true)
      return
    }
    this.held = false
    if (hSpeed > 1e-4) {
      const f = S.kineticResistance * S.mass * G
      const scale = Math.min(f * FIXED_DT, hSpeed) / hSpeed // never reverse
      this.body.applyImpulse({ x: -v.x * S.mass * scale, y: 0, z: -v.z * S.mass * scale }, true)
    }
  }

  /** Static breakaway threshold: force (N) a driver must exceed to start from rest. */
  breakawayForce(): number {
    return S.staticBreakawayForce
  }
}
```

`FIXED_DT` import note: `stone.ts` imports it from `PhysicsWorld.ts` (exported there as `export const FIXED_DT = 1 / 60`).

- [x] **Step 4: Run tests and calibrate**

Run: `npx vitest run tests/stonePhysics.test.ts`
Expected: 3 passed. Known calibration points, fix locally and re-run:
- Rest position mirrored/transposed → swap height index order in `terrainCollider.ts` (see its comment).
- Rest Y off by a constant → check `setTranslation` of the heightfield matches the z-offset math `(frontLength - backLength) / 2`.
- Stone never holds on gentle grade → verify `holdSpeedEps` / `holdSlopeDeg` against the actual grade at `frontLength * 0.92` (read with `slopeDegAt`).

- [x] **Step 5: Commit**

```bash
git add kimi-version && git commit -m "feat(kimi-version): Rapier 世界 + 高度场地形 + 石头静置/回滚标定"
```

---

### Task 3: Push model (pure contact math)

**Files:**
- Create: `kimi-version/src/physics/pushModel.ts`
- Create: `kimi-version/src/physics/vec3.ts`
- Test: `kimi-version/tests/pushModel.test.ts`

One pure module owns contact geometry so physics, IK, and tests share it. Conventions: player faces body yaw `θ` (0 = looking toward −Z, i.e. uphill when on the front side); `side = -1` is the left hand, `+1` the right. Push direction = from shoulder through the contact point toward the sphere center. Left hand therefore lands on the stone's left surface and pushes it rightward — the honest geometry confirmed in the spec.

- [x] **Step 1: Write the failing test**

`kimi-version/tests/pushModel.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import { computeHandContact, computeShoulder, withinReach } from '../src/physics/pushModel'
import { TUNING } from '../src/core/tuning'

const P = TUNING.push
const CENTER = { x: 0, y: 1.6, z: 0 }
const R = TUNING.stone.radius

// Player stands at +z of the stone, facing −z (yaw 0) — uphill on the front side.
const PLAYER = { x: 0, y: 0, z: 2.0 }
const YAW = 0

describe('pushModel', () => {
  it('places the left shoulder on the player left (−x when facing −z)', () => {
    const l = computeShoulder(PLAYER, YAW, -1, P)
    const r = computeShoulder(PLAYER, YAW, 1, P)
    expect(l.x).toBeLessThan(0)
    expect(r.x).toBeGreaterThan(0)
    expect(l.y).toBeCloseTo(P.shoulderHeight, 3)
  })

  it('contact point lies exactly on the sphere surface', () => {
    for (const side of [-1, 1] as const) {
      const c = computeHandContact(CENTER, R, computeShoulder(PLAYER, YAW, side, P))
      const d = Math.hypot(c.point.x - CENTER.x, c.point.y - CENTER.y, c.point.z - CENTER.z)
      expect(d).toBeCloseTo(R, 3)
    }
  })

  it('left hand pushes rightward through the center; right hand leftward (honest geometry)', () => {
    // Spec-confirmed: pressing with the left hand drives the stone toward +x
    // and the right hand toward −x. Force direction = shoulder → sphere center.
    const l = computeHandContact(CENTER, R, computeShoulder(PLAYER, YAW, -1, P))
    const r = computeHandContact(CENTER, R, computeShoulder(PLAYER, YAW, 1, P))
    expect(l.dir.x).toBeGreaterThan(0)
    expect(r.dir.x).toBeLessThan(0)
    expect(l.dir.z).toBeLessThan(0) // both hands also push forward (−z, uphill)
    expect(r.dir.z).toBeLessThan(0)
  })

  it('withinReach respects reach distance', () => {
    const chest = { x: 0, y: 1.3, z: 2.0 }
    expect(withinReach(CENTER, R, chest, P.reachDistance)).toBe(true)
    expect(withinReach(CENTER, R, { x: 0, y: 1.3, z: 5.0 }, P.reachDistance)).toBe(false)
  })
})
```

- [x] **Step 2: Run to verify it fails**

Run: `npx vitest run tests/pushModel.test.ts`
Expected: FAIL — module not found.

- [x] **Step 3: Implement**

`kimi-version/src/physics/vec3.ts`:

```ts
export interface Vec3 { x: number; y: number; z: number }
export const add = (a: Vec3, b: Vec3): Vec3 => ({ x: a.x + b.x, y: a.y + b.y, z: a.z + b.z })
export const sub = (a: Vec3, b: Vec3): Vec3 => ({ x: a.x - b.x, y: a.y - b.y, z: a.z - b.z })
export const scale = (a: Vec3, s: number): Vec3 => ({ x: a.x * s, y: a.y * s, z: a.z * s })
export const length = (a: Vec3): number => Math.hypot(a.x, a.y, a.z)
export const normalize = (a: Vec3): Vec3 => {
  const l = length(a)
  return l < 1e-9 ? { x: 0, y: 0, z: 0 } : scale(a, 1 / l)
}
export const dot = (a: Vec3, b: Vec3): number => a.x * b.x + a.y * b.y + a.z * b.z
export const cross = (a: Vec3, b: Vec3): Vec3 => ({
  x: a.y * b.z - a.z * b.y,
  y: a.z * b.x - a.x * b.z,
  z: a.x * b.y - a.y * b.x,
})
```

`kimi-version/src/physics/pushModel.ts`:

```ts
import { add, normalize, scale, sub, type Vec3 } from './vec3'

export interface PushTuningLike {
  reachDistance: number
  shoulderHeight: number
  shoulderHalfWidth: number
}

/**
 * Shoulder world position.
 * Convention (locked by tests/pushModel.test.ts): yaw 0 faces −z, so
 * forward = (−sin yaw, 0, −cos yaw) and right = (cos yaw, 0, −sin yaw).
 * side −1 = left hand, +1 = right hand.
 */
export function computeShoulder(playerPos: Vec3, bodyYaw: number, side: -1 | 1, P: PushTuningLike): Vec3 {
  const right = { x: Math.cos(bodyYaw), y: 0, z: -Math.sin(bodyYaw) }
  return add(playerPos, {
    x: side * P.shoulderHalfWidth * right.x,
    y: P.shoulderHeight,
    z: side * P.shoulderHalfWidth * right.z,
  })
}

export interface HandContact {
  /** Point on the sphere surface where the palm lands. */
  point: Vec3
  /** Push direction (unit): shoulder → sphere center. Also the surface normal at `point`. */
  dir: Vec3
}

export function computeHandContact(center: Vec3, radius: number, shoulder: Vec3): HandContact {
  const dir = normalize(sub(center, shoulder))
  return { point: sub(center, scale(dir, radius)), dir }
}

/** Chest-to-surface reach check (horizontal distance to the surface). */
export function withinReach(center: Vec3, radius: number, chest: Vec3, reach: number): boolean {
  return Math.hypot(chest.x - center.x, chest.z - center.z) - radius < reach
}
```

- [x] **Step 4: Run tests**

Run: `npx vitest run tests/pushModel.test.ts`
Expected: 4 passed.

- [x] **Step 5: Commit**

```bash
git add kimi-version && git commit -m "feat(kimi-version): 推球接触纯数学模型（肩部/接触点/发力方向）"
```

---

### Task 4: Push integration — the numeric feel contract

**Files:**
- Modify: `kimi-version/src/physics/stone.ts` (add `applyPush`)
- Test: `kimi-version/tests/pushContract.test.ts`

This suite is the executable form of the spec's four bars: uphill progress, honest left/right deflection, static breakaway, sustained rolling. All headless in Node.

- [x] **Step 1: Write the failing test**

`kimi-version/tests/pushContract.test.ts`:

```ts
import { beforeAll, describe, expect, it } from 'vitest'
import RAPIER from '@dimforge/rapier3d-compat'
import { PhysicsWorld, FIXED_DT } from '../src/physics/PhysicsWorld'
import { Stone, type PushForce } from '../src/physics/stone'
import { computeHandContact, computeShoulder } from '../src/physics/pushModel'
import { sampleHeight } from '../src/world/heightfield'
import { TUNING } from '../src/core/tuning'

beforeAll(async () => {
  await RAPIER.init()
})

const P = TUNING.push
const SPAWN_Z = TUNING.mountain.frontLength - 2 // near-flat foot area

interface Rig {
  pw: PhysicsWorld
  stone: Stone
}

/** Spawn a settled stone at the foot with the "player" standing behind it facing −z. */
function makeRig(): Rig {
  const pw = new PhysicsWorld()
  const stone = new Stone(pw, 0, sampleHeight(0, SPAWN_Z) + TUNING.stone.radius + 0.02, SPAWN_Z)
  for (let i = 0; i < 60; i++) {
    stone.applyResistance(false)
    pw.step()
  }
  return { pw, stone }
}

/** One fixed step with the given per-hand analog inputs (0..1). Player stands 0.55 m behind the surface. */
function pushStep(rig: Rig, left: number, right: number) {
  const c = rig.stone.position()
  const player = { x: 0, y: c.y - P.shoulderHeight, z: c.z + TUNING.stone.radius + 0.55 }
  const hands: PushForce[] = []
  for (const [side, input] of [[-1, left], [1, right]] as const) {
    if (input <= 0) continue
    const contact = computeHandContact(c, TUNING.stone.radius, computeShoulder(player, 0, side, P))
    hands.push({ ...contact, magnitude: input * P.maxForcePerHand })
  }
  rig.stone.applyPush(hands)
  rig.stone.applyResistance(hands.length > 0)
  rig.pw.step()
}

function pushSeconds(rig: Rig, left: number, right: number, seconds: number) {
  for (let i = 0; i < Math.round(seconds * 60); i++) pushStep(rig, left, right)
}

describe('push feel contract', () => {
  it('both hands full force moves the stone uphill (−z)', () => {
    const rig = makeRig()
    const z0 = rig.stone.position().z
    pushSeconds(rig, 1, 1, 3)
    expect(z0 - rig.stone.position().z).toBeGreaterThan(1.5)
  })

  it('left hand only drifts the stone rightward (+x)', () => {
    const rig = makeRig()
    const x0 = rig.stone.position().x
    pushSeconds(rig, 1, 0, 2)
    expect(rig.stone.position().x - x0).toBeGreaterThan(0.3)
  })

  it('right hand only drifts the stone leftward (−x)', () => {
    const rig = makeRig()
    const x0 = rig.stone.position().x
    pushSeconds(rig, 0, 1, 2)
    expect(rig.stone.position().x - x0).toBeLessThan(-0.3)
  })

  it('gentle force from rest cannot break away (static threshold)', () => {
    const rig = makeRig()
    const z0 = rig.stone.position().z
    pushSeconds(rig, 0.1, 0, 1.5) // 95 N < staticBreakawayForce
    expect(z0 - rig.stone.position().z).toBeLessThan(0.15)
  })

  it('once moving, moderate force sustains uphill motion', () => {
    const rig = makeRig()
    pushSeconds(rig, 1, 1, 1.5) // break away first
    const z0 = rig.stone.position().z
    pushSeconds(rig, 0.6, 0.6, 2)
    expect(z0 - rig.stone.position().z).toBeGreaterThan(0.8)
  })

  it('releasing both hands on a slope lets the stone roll back', () => {
    const rig = makeRig()
    pushSeconds(rig, 1, 1, 2)
    const z0 = rig.stone.position().z
    for (let i = 0; i < 240; i++) {
      rig.stone.applyResistance(false)
      rig.pw.step()
    }
    // foot area is gentle: stone may stop, but must not keep climbing on its own
    expect(rig.stone.position().z).toBeGreaterThan(z0 - 0.5)
  })
})
```

- [x] **Step 2: Run to verify it fails**

Run: `npx vitest run tests/pushContract.test.ts`
Expected: FAIL — `applyPush` / `PushForce` not exported.

- [x] **Step 3: Implement `applyPush` in `stone.ts`**

Add to `kimi-version/src/physics/stone.ts` (after `breakawayForce`):

```ts
export interface PushForce {
  point: { x: number; y: number; z: number }
  dir: { x: number; y: number; z: number }
  magnitude: number
}
```

and inside `Stone`:

```ts
  /**
   * Apply this step's per-hand push forces at their contact points.
   * From rest, the static breakaway threshold is subtracted first — a
   * stalled stone needs visible effort before it starts moving.
   */
  applyPush(hands: PushForce[]): void {
    let scale = 1
    if (this.speed() < S.holdSpeedEps) {
      const total = hands.reduce((sum, h) => sum + h.magnitude, 0)
      const net = Math.max(total - S.staticBreakawayForce, 0)
      scale = total > 1e-6 ? net / total : 0
    }
    for (const h of hands) {
      const impulse = h.magnitude * scale * FIXED_DT
      this.body.applyImpulseAtPoint(
        { x: h.dir.x * impulse, y: h.dir.y * impulse, z: h.dir.z * impulse },
        h.point,
        true,
      )
    }
  }
```

- [x] **Step 4: Run tests and calibrate**

Run: `npx vitest run tests/pushContract.test.ts`
Expected: 6 passed. Calibration if a threshold fails: adjust `maxForcePerHand`, `staticBreakawayForce`, or `kineticResistance` in `TUNING` — keep the *directional* assertions (tests 2–4) sacred; only magnitudes may move.

- [x] **Step 5: Commit**

```bash
git add kimi-version && git commit -m "feat(kimi-version): 推球手感数值契约（上行/左右偏转/静息起动/持续）"
```

---

### Task 5: Player kinematic controller and input intent layer

**Files:**
- Create: `kimi-version/src/core/input.ts`
- Create: `kimi-version/src/physics/playerMath.ts`
- Create: `kimi-version/src/physics/player.ts`
- Test: `kimi-version/tests/input.test.ts`
- Test: `kimi-version/tests/playerMath.test.ts`

All devices merge into one `InputIntent`. Movement math is pure and tested; the Rapier wrapper is a thin shell over `playerMath`.

- [x] **Step 1: Write the failing tests**

`kimi-version/tests/input.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import { intentFromKeyboardMouse, intentFromGamepad, mergeIntents, type InputIntent } from '../src/core/input'

describe('keyboard/mouse intent', () => {
  it('maps WASD to move axes (W = forward = −z intent)', () => {
    const i = intentFromKeyboardMouse(new Set(['KeyW']), { dx: 0, dy: 0, left: false, right: false })
    expect(i.move.z).toBeLessThan(0)
    expect(i.move.x).toBe(0)
  })

  it('maps mouse buttons to hands and deltas to look', () => {
    const i = intentFromKeyboardMouse(new Set(), { dx: 12, dy: -4, left: true, right: false })
    expect(i.leftHand).toBe(1)
    expect(i.rightHand).toBe(0)
    expect(i.lookDelta.x).toBe(12)
    expect(i.lookDelta.y).toBe(-4)
  })
})

describe('gamepad intent', () => {
  const pad = {
    axes: [0.5, 0, 0, -0.25],
    buttons: Array.from({ length: 17 }, (_, i) => ({
      pressed: i === 6,
      value: i === 6 ? 0.7 : i === 7 ? 0.3 : 0,
    })),
  } as unknown as Gamepad

  it('maps sticks with deadzone and triggers to analog hands', () => {
    const i = intentFromGamepad(pad)
    expect(i.move.x).toBeCloseTo(0.5, 2)
    expect(i.leftHand).toBeCloseTo(0.7, 2)
    expect(i.rightHand).toBeCloseTo(0.3, 2)
    expect(i.lookDelta.x).toBeCloseTo(-0.25 * 600 * (1 / 60), 1) // stick→look speed per frame
  })

  it('applies stick deadzone', () => {
    const quiet = { ...pad, axes: [0.05, 0, 0, 0] } as unknown as Gamepad
    expect(intentFromGamepad(quiet).move.x).toBe(0)
  })
})

describe('mergeIntents', () => {
  it('takes the stronger hand and summed movement/look', () => {
    const a: InputIntent = { move: { x: 1, z: 0 }, lookDelta: { x: 1, y: 0 }, leftHand: 0.4, rightHand: 0, reset: false }
    const b: InputIntent = { move: { x: 0, z: -1 }, lookDelta: { x: 2, y: 1 }, leftHand: 0, rightHand: 0.9, reset: true }
    const m = mergeIntents(a, b)
    expect(m.leftHand).toBeCloseTo(0.4)
    expect(m.rightHand).toBeCloseTo(0.9)
    expect(m.move).toEqual({ x: 1, z: -1 })
    expect(m.reset).toBe(true)
  })
})
```

`kimi-version/tests/playerMath.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import { computeNextPose } from '../src/physics/playerMath'
import { TUNING } from '../src/core/tuning'

const base = {
  pos: { x: 0, y: 0, z: 10 },
  bodyYaw: 0,
  groundY: (x: number, z: number) => 0,
  dt: 1 / 60,
  tuning: TUNING.player,
}

describe('playerMath', () => {
  it('walks forward relative to body yaw', () => {
    const next = computeNextPose({ ...base, intent: { move: { x: 0, z: -1 }, engaged: false, stonePos: null } })
    expect(next.pos.z).toBeLessThan(10)
    expect(next.bodyYaw).toBeCloseTo(0, 1)
  })

  it('strafe right (+x intent) moves along the right vector', () => {
    const next = computeNextPose({ ...base, intent: { move: { x: 1, z: 0 }, engaged: false, stonePos: null } })
    expect(next.pos.x).toBeGreaterThan(0)
  })

  it('engaged mode faces the stone and moves slower', () => {
    const stone = { x: 1, y: 1, z: 5 }
    const next = computeNextPose({ ...base, intent: { move: { x: 0, z: -1 }, engaged: true, stonePos: stone } })
    const toStone = Math.atan2(-(stone.x - 0), -(stone.z - 10))
    expect(next.bodyYaw).toBeCloseTo(toStone, 0)
    expect(10 - next.pos.z).toBeLessThan(TUNING.player.walkSpeed / 60 + 1e-6)
  })

  it('clamps to ground height', () => {
    const next = computeNextPose({ ...base, groundY: () => 3.5, intent: { move: { x: 0, z: -1 }, engaged: false, stonePos: null } })
    expect(next.pos.y).toBe(3.5)
  })
})
```

- [x] **Step 2: Run to verify they fail**

Run: `npx vitest run tests/input.test.ts tests/playerMath.test.ts`
Expected: FAIL — modules not found.

- [x] **Step 3: Implement**

`kimi-version/src/core/input.ts`:

```ts
export interface InputIntent {
  /** Desired walk direction, body-relative: x = strafe right, z = forward(−)/back(+). */
  move: { x: number; z: number }
  /** Head look delta this frame (pixels or stick-equivalent). */
  lookDelta: { x: number; y: number }
  leftHand: number  // 0..1
  rightHand: number // 0..1
  reset: boolean
}

export const IDLE_INTENT: InputIntent = {
  move: { x: 0, z: 0 },
  lookDelta: { x: 0, y: 0 },
  leftHand: 0,
  rightHand: 0,
  reset: false,
}

export interface MouseState { dx: number; dy: number; left: boolean; right: boolean }

export function intentFromKeyboardMouse(keys: Set<string>, mouse: MouseState): InputIntent {
  return {
    move: {
      x: (keys.has('KeyD') ? 1 : 0) - (keys.has('KeyA') ? 1 : 0),
      z: (keys.has('KeyS') ? 1 : 0) - (keys.has('KeyW') ? 1 : 0),
    },
    lookDelta: { x: mouse.dx, y: mouse.dy },
    leftHand: mouse.left ? 1 : 0,
    rightHand: mouse.right ? 1 : 0,
    reset: keys.has('KeyR'),
  }
}

const DEADZONE = 0.12
const STICK_LOOK_SPEED = 600 // "pixels per second" equivalent for shared sensitivity math
const dz = (v: number) => (Math.abs(v) < DEADZONE ? 0 : v)

export function intentFromGamepad(pad: Gamepad | null, dt = 1 / 60): InputIntent {
  if (!pad) return { ...IDLE_INTENT }
  return {
    move: { x: dz(pad.axes[0] ?? 0), z: dz(pad.axes[1] ?? 0) },
    lookDelta: {
      x: dz(pad.axes[2] ?? 0) * STICK_LOOK_SPEED * dt,
      y: dz(pad.axes[3] ?? 0) * STICK_LOOK_SPEED * dt,
    },
    leftHand: pad.buttons[6]?.value ?? 0,
    rightHand: pad.buttons[7]?.value ?? 0,
    reset: pad.buttons[9]?.pressed ?? false,
  }
}

export function mergeIntents(a: InputIntent, b: InputIntent): InputIntent {
  return {
    move: { x: clamp1(a.move.x + b.move.x), z: clamp1(a.move.z + b.move.z) },
    lookDelta: { x: a.lookDelta.x + b.lookDelta.x, y: a.lookDelta.y + b.lookDelta.y },
    leftHand: Math.max(a.leftHand, b.leftHand),
    rightHand: Math.max(a.rightHand, b.rightHand),
    reset: a.reset || b.reset,
  }
}

const clamp1 = (v: number) => Math.max(-1, Math.min(1, v))
```

`kimi-version/src/physics/playerMath.ts`:

```ts
import type { Vec3 } from './vec3'

export interface PlayerStepInput {
  pos: Vec3
  bodyYaw: number
  groundY: (x: number, z: number) => number
  dt: number
  tuning: { walkSpeed: number; engagedWalkSpeed: number; turnLerp: number }
  intent: {
    move: { x: number; z: number }
    engaged: boolean
    stonePos: Vec3 | null
  }
}

export interface PlayerPose {
  pos: Vec3
  bodyYaw: number
}

const wrapAngle = (a: number) => Math.atan2(Math.sin(a), Math.cos(a))

/**
 * One movement step. Body-relative move intent is rotated by body yaw:
 * forward = (−sin yaw, 0, −cos yaw), right = (cos yaw, 0, −sin yaw).
 * Engaged: body squares to the stone; free: body follows the move direction.
 */
export function computeNextPose(input: PlayerStepInput): PlayerPose {
  const { pos, bodyYaw, intent, tuning, dt } = input
  const speed = intent.engaged ? tuning.engagedWalkSpeed : tuning.walkSpeed
  const fwd = { x: -Math.sin(bodyYaw), z: -Math.cos(bodyYaw) }
  const right = { x: Math.cos(bodyYaw), z: -Math.sin(bodyYaw) }
  const mx = intent.move.x
  const mz = intent.move.z
  const len = Math.hypot(mx, mz)
  const nx = len > 1 ? mx / len : mx
  const nz = len > 1 ? mz / len : mz
  const dx = (right.x * nx + fwd.x * -nz) * speed * dt
  const dz = (right.z * nx + fwd.z * -nz) * speed * dt
  const x = pos.x + dx
  const z = pos.z + dz

  let targetYaw = bodyYaw
  if (intent.engaged && intent.stonePos) {
    targetYaw = Math.atan2(-(intent.stonePos.x - pos.x), -(intent.stonePos.z - pos.z))
  } else if (len > 0.01) {
    targetYaw = Math.atan2(-dx, -dz)
  }
  const k = 1 - Math.exp(-tuning.turnLerp * dt)
  const yaw = bodyYaw + wrapAngle(targetYaw - bodyYaw) * k

  return { pos: { x, y: input.groundY(x, z), z }, bodyYaw: yaw }
}
```

`kimi-version/src/physics/player.ts`:

```ts
import RAPIER from '@dimforge/rapier3d-compat'
import { TUNING } from '../core/tuning'
import { sampleHeight } from '../world/heightfield'
import { computeNextPose, type PlayerPose } from './playerMath'
import type { PhysicsWorld } from './PhysicsWorld'

export class Player {
  readonly body: RAPIER.RigidBody
  private readonly collider: RAPIER.Collider
  private readonly ctrl: RAPIER.KinematicCharacterController
  pose: PlayerPose

  constructor(pw: PhysicsWorld, x: number, z: number) {
    this.pose = { pos: { x, y: sampleHeight(x, z), z }, bodyYaw: 0 }
    this.body = pw.world.createRigidBody(
      RAPIER.RigidBodyDesc.kinematicPositionBased().setTranslation(x, this.pose.pos.y, z),
    )
    this.collider = pw.world.createCollider(
      RAPIER.ColliderDesc.capsule(0.9, TUNING.player.radius),
      this.body,
    )
    this.ctrl = pw.world.createCharacterController(0.02)
    this.ctrl.setApplyImpulsesToDynamicBodies(false) // pushing only happens through hands
  }

  /** Move with collision; stone/body contact never shoves the stone. */
  move(pw: PhysicsWorld, intent: { move: { x: number; z: number }; engaged: boolean; stonePos: { x: number; y: number; z: number } | null }, dt: number): void {
    const next = computeNextPose({
      pos: this.pose.pos,
      bodyYaw: this.pose.bodyYaw,
      groundY: sampleHeight,
      dt,
      tuning: TUNING.player,
      intent,
    })
    const delta = {
      x: next.pos.x - this.pose.pos.x,
      y: next.pos.y - this.pose.pos.y,
      z: next.pos.z - this.pose.pos.z,
    }
    this.ctrl.computeColliderMovement(this.collider, delta)
    const m = this.ctrl.computedMovement()
    this.pose = {
      pos: { x: this.pose.pos.x + m.x, y: this.pose.pos.y + m.y, z: this.pose.pos.z + m.z },
      bodyYaw: next.bodyYaw,
    }
    this.body.setNextKinematicTranslation(this.pose.pos)
  }
}
```

- [x] **Step 4: Run tests**

Run: `npx vitest run tests/input.test.ts tests/playerMath.test.ts`
Expected: all passed (3 + 3 + 1 + 4).

- [x] **Step 5: Commit**

```bash
git add kimi-version && git commit -m "feat(kimi-version): 输入意图层（键鼠+手柄）与运动学角色"
```

---

### Task 6: Two-bone arm IK solver (pure)

**Files:**
- Create: `kimi-version/src/body/armIk.ts`
- Test: `kimi-version/tests/armIk.test.ts`

- [x] **Step 1: Write the failing test**

`kimi-version/tests/armIk.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import { solveTwoBoneIK } from '../src/body/armIk'
import { length, sub } from '../src/physics/vec3'

const SHOULDER = { x: 0, y: 1.3, z: 0 }
const L1 = 0.3
const L2 = 0.28
const POLE = { x: 0, y: -1, z: -0.3 } // elbows bow down-back

describe('armIk', () => {
  it('reaches a near target with exact segment lengths', () => {
    const target = { x: 0.1, y: 1.2, z: -0.35 }
    const { elbow, wrist } = solveTwoBoneIK(SHOULDER, target, L1, L2, POLE)
    expect(wrist.x).toBeCloseTo(target.x, 3)
    expect(wrist.y).toBeCloseTo(target.y, 3)
    expect(wrist.z).toBeCloseTo(target.z, 3)
    expect(length(sub(elbow, SHOULDER))).toBeCloseTo(L1, 3)
    expect(length(sub(wrist, elbow))).toBeCloseTo(L2, 3)
  })

  it('clamps an out-of-reach target to full extension', () => {
    const target = { x: 0, y: 1.3, z: -5 }
    const { wrist } = solveTwoBoneIK(SHOULDER, target, L1, L2, POLE)
    expect(length(sub(wrist, SHOULDER))).toBeCloseTo(L1 + L2 - 1e-3, 2)
  })

  it('elbow bows toward the pole vector (not up)', () => {
    const target = { x: 0, y: 1.25, z: -0.3 }
    const { elbow } = solveTwoBoneIK(SHOULDER, target, L1, L2, POLE)
    expect(elbow.y).toBeLessThan(SHOULDER.y)
  })
})
```

- [x] **Step 2: Run to verify it fails**

Run: `npx vitest run tests/armIk.test.ts`
Expected: FAIL — module not found.

- [x] **Step 3: Implement**

`kimi-version/src/body/armIk.ts`:

```ts
import { add, cross, dot, length, normalize, scale, sub, type Vec3 } from '../physics/vec3'

export interface IkResult {
  elbow: Vec3
  wrist: Vec3
}

/**
 * Analytic two-bone IK. The elbow lies in the plane spanned by
 * (shoulder→target) and the pole direction, bowed toward the pole.
 * Out-of-reach targets clamp to just under full extension.
 */
export function solveTwoBoneIK(shoulder: Vec3, target: Vec3, l1: number, l2: number, pole: Vec3): IkResult {
  const toTarget = sub(target, shoulder)
  const maxReach = l1 + l2 - 1e-3
  const dist = Math.min(length(toTarget), maxReach)
  const dir = normalize(toTarget)

  // Law of cosines: distance from shoulder to the elbow's projection on dir.
  const cosA = (l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * Math.max(dist, 1e-6))
  const along = l1 * Math.min(Math.max(cosA, -1), 1)
  const up = Math.sqrt(Math.max(l1 * l1 - along * along, 0))

  // Bend axis: component of pole perpendicular to dir.
  const bend = normalize(sub(pole, scale(dir, dot(pole, dir))))
  const elbow = add(shoulder, add(scale(dir, along), scale(bend, up)))
  const wrist = add(shoulder, scale(dir, dist))
  return { elbow, wrist }
}
```

- [x] **Step 4: Run tests**

Run: `npx vitest run tests/armIk.test.ts`
Expected: 3 passed.

- [x] **Step 5: Commit**

```bash
git add kimi-version && git commit -m "feat(kimi-version): 双臂解析式两骨 IK 求解器"
```

---

### Task 7: Render foundation and screenshot harness

**Files:**
- Create: `kimi-version/src/world/mountainMesh.ts`
- Create: `kimi-version/src/world/sky.ts`
- Create: `kimi-version/src/world/lighting.ts`
- Create: `kimi-version/src/render/StoneMesh.ts`
- Create: `kimi-version/src/core/Game.ts`
- Create: `kimi-version/src/dev/autoDriver.ts`
- Modify: `kimi-version/src/main.ts` (replace smoke scene)
- Create: `kimi-version/scripts/capture.ts`

The game assembles here for the first time: terrain + sky + light + stone + free camera, driven by the fixed-step loop. The auto driver feeds scripted intents from URL params so Playwright can capture deterministic beats. From this task on, every visual claim is verified by reading `evidence/*.png`.

- [x] **Step 1: Implement world rendering**

`kimi-version/src/world/mountainMesh.ts`:

```ts
import * as THREE from 'three'
import { TUNING } from '../core/tuning'
import { sampleHeight } from './heightfield'

const GRASS = new THREE.Color(0x5d7a4a)
const DIRT = new THREE.Color(0x8a7355)
const ROCK = new THREE.Color(0x6f7076)

/** Terrain mesh with vertex colors: dirt path band, grassy flats, rocky banks/crest. */
export function buildMountainMesh(): THREE.Mesh {
  const M = TUNING.mountain
  const segX = 120
  const segZ = 220
  const width = M.worldHalfX * 2
  const depth = M.frontLength + M.backLength + 20
  const zMax = M.frontLength + 10
  const geo = new THREE.PlaneGeometry(width, depth, segX, segZ)
  geo.rotateX(-Math.PI / 2)
  const pos = geo.attributes.position
  const colors = new Float32Array(pos.count * 3)
  const c = new THREE.Color()
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i)
    const z = pos.getZ(i) + (M.frontLength - M.backLength) / 2
    const h = sampleHeight(x, z)
    pos.setY(i, h)
    pos.setZ(i, z)
    const ax = Math.abs(x)
    const pathT = Math.min(ax / M.pathHalfWidth, 1)
    const crestT = Math.min(h / M.ridgeHeight, 1)
    c.copy(GRASS).lerp(DIRT, 1 - pathT * pathT) // dirt inside the path band
    c.lerp(ROCK, Math.max(crestT * 0.6, Math.min((ax - M.pathHalfWidth) / 6, 0.5)))
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
```

`kimi-version/src/world/sky.ts`:

```ts
import * as THREE from 'three'

/** Gradient sky dome + matched fog. Warmth shifts both for the descent beat. */
export class Sky {
  readonly mesh: THREE.Mesh
  private readonly topDay = new THREE.Color(0x7fa8c9)
  private readonly bottomDay = new THREE.Color(0xd8e4ea)
  private readonly topWarm = new THREE.Color(0x9a86b8)
  private readonly bottomWarm = new THREE.Color(0xf2c98a)
  private readonly mat: THREE.ShaderMaterial

  constructor(readonly scene: THREE.Scene) {
    this.mat = new THREE.ShaderMaterial({
      side: THREE.BackSide,
      depthWrite: false,
      uniforms: {
        top: { value: this.topDay.clone() },
        bottom: { value: this.bottomDay.clone() },
      },
      vertexShader: `varying vec3 vP; void main(){ vP = position; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }`,
      fragmentShader: `uniform vec3 top; uniform vec3 bottom; varying vec3 vP;
        void main(){ float t = clamp(normalize(vP).y * 0.5 + 0.5, 0.0, 1.0); gl_FragColor = vec4(mix(bottom, top, t), 1.0); }`,
    })
    this.mesh = new THREE.Mesh(new THREE.SphereGeometry(600, 24, 12), this.mat)
    scene.add(this.mesh)
    scene.fog = new THREE.Fog(this.bottomDay.clone(), 60, 420)
  }

  /** t = 0 day → 1 golden-hour descent. */
  setWarmth(t: number): void {
    ;(this.mat.uniforms.top.value as THREE.Color).copy(this.topDay).lerp(this.topWarm, t)
    ;(this.mat.uniforms.bottom.value as THREE.Color).copy(this.bottomDay).lerp(this.bottomWarm, t)
    if (this.scene.fog) (this.scene.fog as THREE.Fog).color.copy(this.mat.uniforms.bottom.value as THREE.Color)
  }
}
```

`kimi-version/src/world/lighting.ts`:

```ts
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
```

`kimi-version/src/render/StoneMesh.ts`:

```ts
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
```

- [x] **Step 2: Implement Game orchestrator + fixed loop + auto driver**

`kimi-version/src/core/Game.ts`:

```ts
import * as THREE from 'three'
import { FIXED_DT, PhysicsWorld } from '../physics/PhysicsWorld'
import { Stone } from '../physics/stone'
import { Player } from '../physics/player'
import { StoneMesh } from '../render/StoneMesh'
import { buildMountainMesh } from '../world/mountainMesh'
import { Sky } from '../world/sky'
import { Lighting } from '../world/lighting'
import { TUNING } from './tuning'
import { IDLE_INTENT, type InputIntent } from './input'
import { sampleHeight } from '../world/heightfield'

export interface InputSource {
  poll(dt: number): InputIntent
}

export class Game {
  readonly renderer: THREE.WebGLRenderer
  readonly scene = new THREE.Scene()
  readonly camera: THREE.PerspectiveCamera
  readonly pw = new PhysicsWorld()
  readonly stone: Stone
  readonly player: Player
  private readonly stoneMesh = new StoneMesh()
  private readonly sky: Sky
  private readonly lighting: Lighting
  private acc = 0
  private last = 0

  constructor(parent: HTMLElement, private readonly source: InputSource) {
    this.renderer = new THREE.WebGLRenderer({ antialias: true })
    this.renderer.setSize(innerWidth, innerHeight)
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 2))
    this.renderer.shadowMap.enabled = true
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap
    parent.appendChild(this.renderer.domElement)

    this.camera = new THREE.PerspectiveCamera(TUNING.camera.fov, innerWidth / innerHeight, 0.08, 900)
    this.scene.add(buildMountainMesh())
    this.sky = new Sky(this.scene)
    this.lighting = new Lighting(this.scene)

    const sz = TUNING.mountain.frontLength - 4
    this.stone = new Stone(this.pw, 0, sampleHeight(0, sz) + TUNING.stone.radius + 0.05, sz)
    this.player = new Player(this.pw, 0, sz + 6)
    this.scene.add(this.stoneMesh)

    addEventListener('resize', () => {
      this.camera.aspect = innerWidth / innerHeight
      this.camera.updateProjectionMatrix()
      this.renderer.setSize(innerWidth, innerHeight)
    })
  }

  start(): void {
    requestAnimationFrame((t) => {
      this.last = t
      const frame = (t: number) => {
        this.acc += Math.min((t - this.last) / 1000, 0.1)
        this.last = t
        while (this.acc >= FIXED_DT) {
          this.fixedStep(FIXED_DT)
          this.acc -= FIXED_DT
        }
        this.render()
        requestAnimationFrame(frame)
      }
      requestAnimationFrame(frame)
    })
  }

  fixedStep(dt: number): void {
    const intent = this.source.poll(dt) ?? IDLE_INTENT
    this.player.move(this.pw, { ...intent, engaged: false, stonePos: null }, dt)
    this.stone.applyResistance(false)
    this.pw.step()
  }

  render(): void {
    const p = this.player.pose.pos
    this.stoneMesh.position.copy(this.stone.position() as unknown as THREE.Vector3)
    this.stoneMesh.quaternion.copy(this.stone.body.rotation() as unknown as THREE.Quaternion)
    this.camera.position.set(p.x, p.y + TUNING.player.eyeHeight, p.z)
    this.camera.rotation.set(0, this.player.pose.bodyYaw, 0, 'YXZ')
    this.lighting.follow(p.x, p.z)
    this.sky.mesh.position.copy(this.camera.position)
    this.renderer.render(this.scene, this.camera)
  }
}
```

`kimi-version/src/dev/autoDriver.ts`:

```ts
import type { InputSource } from '../core/Game'
import { IDLE_INTENT, type InputIntent } from '../core/input'

/**
 * Scripted intents for screenshot beats, selected with ?auto=<beat>&t=<seconds>.
 * The game sets window.__beatReady once `t` seconds have elapsed so the
 * capture script can screenshot a stable pose.
 */
export class AutoDriver implements InputSource {
  private time = 0

  constructor(private readonly beat: string, private readonly duration: number) {}

  poll(dt: number): InputIntent {
    this.time += dt
    if (this.time >= this.duration) {
      ;(window as unknown as { __beatReady?: boolean }).__beatReady = true
    }
    switch (this.beat) {
      case 'approach':
        return { ...IDLE_INTENT, move: { x: 0, z: -1 } }
      default:
        return IDLE_INTENT
    }
  }
}

export function autoFromUrl(): AutoDriver | null {
  const q = new URLSearchParams(location.search)
  const beat = q.get('auto')
  if (!beat) return null
  return new AutoDriver(beat, Number(q.get('t') ?? '3'))
}
```

`kimi-version/src/main.ts` (replace the smoke scene):

```ts
import { Game, type InputSource } from './core/Game'
import { autoFromUrl } from './dev/autoDriver'
import { IDLE_INTENT, type InputIntent } from './core/input'

// Human input source is wired in Task 9 (pointer lock + gamepad polling);
// until then an idle source keeps the world inspectable.
class IdleSource implements InputSource {
  poll(): InputIntent {
    return IDLE_INTENT
  }
}

const source = autoFromUrl() ?? new IdleSource()
const game = new Game(document.body, source)
game.start()
;(window as unknown as { __game?: Game }).__game = game
```

`kimi-version/scripts/capture.ts`:

```ts
import { chromium } from 'playwright'
import { mkdirSync } from 'node:fs'
import { spawn, type ChildProcess } from 'node:child_process'

const BEATS = (process.argv[2] ?? 'rest').split(',')
const PORT = 4173
const URL_BASE = `http://localhost:${PORT}`

async function main() {
  mkdirSync('evidence', { recursive: true })
  const server: ChildProcess = spawn('npm', ['run', 'preview'], { stdio: 'ignore', shell: true })
  await new Promise((r) => setTimeout(r, 2500))
  const browser = await chromium.launch()
  try {
    for (const beat of BEATS) {
      const [name, dur] = beat.split(':')
      const page = await browser.newPage({ viewport: { width: 1280, height: 720 } })
      page.on('console', (m) => console.log(`[${name}]`, m.text()))
      await page.goto(`${URL_BASE}/?auto=${name}&t=${dur ?? '3'}`)
      await page.waitForFunction(() => (window as unknown as { __beatReady?: boolean }).__beatReady, null, { timeout: 30000 })
      await page.screenshot({ path: `evidence/${name}.png` })
      console.log(`captured evidence/${name}.png`)
      await page.close()
    }
  } finally {
    await browser.close()
    server.kill()
  }
}

main().catch((e) => {
  console.error(e)
  process.exit(1)
})
```

- [x] **Step 3: Build, then capture the first beat and read it**

Run: `npm run build && npx playwright install chromium && npx tsx scripts/capture.ts rest:2`
Expected: `evidence/rest.png` exists. Open it: mountain, path band, sky, and the stone ahead must all read clearly. If the stone is missing/misplaced, fix spawn or camera before continuing — this is the visual baseline.

- [x] **Step 4: Commit**

```bash
git add kimi-version && git commit -m "feat(kimi-version): 渲染基础（山体/天空/光照/石头）+ 截图自检管线"
```

---

### Task 8: Body rig and hand state machine

**Files:**
- Create: `kimi-version/src/body/HandView.ts`
- Create: `kimi-version/src/body/BodyRig.ts`
- Modify: `kimi-version/src/core/Game.ts` (integrate rig + push forces each fixed step)
- Modify: `kimi-version/src/dev/autoDriver.ts` (add `hover`, `press`, `left` beats)
- Test: `kimi-version/tests/handState.test.ts`

- [x] **Step 1: Write the failing test for the hand state machine**

`kimi-version/tests/handState.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import { HandStateMachine, HandPhase } from '../src/body/BodyRig'

describe('hand state machine', () => {
  it('rises when in reach, presses while input held, lowers when both released', () => {
    const h = new HandStateMachine()
    expect(h.phase).toBe(HandPhase.Off)
    h.update(0.2, { inReach: true, input: 0 }) // near, not pressing
    expect(h.phase).toBe(HandPhase.Raising)
    for (let i = 0; i < 40; i++) h.update(1 / 60, { inReach: true, input: 1 })
    expect(h.phase).toBe(HandPhase.Pressing)
    for (let i = 0; i < 60; i++) h.update(1 / 60, { inReach: true, input: 0 })
    expect(h.phase).toBe(HandPhase.Raising) // hands stay up near the stone, force is zero
    h.update(0.2, { inReach: false, input: 0 })
    expect(h.phase).toBe(HandPhase.Off)
  })

  it('blend amount moves only toward the active target', () => {
    const h = new HandStateMachine()
    h.update(0.2, { inReach: true, input: 1 })
    const a = h.blend
    h.update(0.2, { inReach: true, input: 1 })
    expect(h.blend).toBeGreaterThan(a)
  })
})
```

- [x] **Step 2: Run to verify it fails**

Run: `npx vitest run tests/handState.test.ts`
Expected: FAIL — module not found.

- [x] **Step 3: Implement rig + hands**

`kimi-version/src/body/HandView.ts`:

```ts
import * as THREE from 'three'

/** Low-poly but readable hand: palm + four fingers + thumb, grouped at the wrist. */
export class HandView extends THREE.Group {
  readonly palm: THREE.Mesh
  private readonly fingers: THREE.Mesh[] = []

  constructor(mirror: boolean) {
    super()
    const skin = new THREE.MeshStandardMaterial({ color: 0xc9a184, roughness: 0.8 })
    this.palm = new THREE.Mesh(new THREE.BoxGeometry(0.11, 0.035, 0.13), skin)
    this.palm.castShadow = true
    this.add(this.palm)
    for (let i = 0; i < 4; i++) {
      const f = new THREE.Mesh(new THREE.BoxGeometry(0.02, 0.024, 0.085), skin)
      f.position.set(-0.042 + i * 0.028, 0.004, -0.1)
      f.castShadow = true
      this.add(f)
      this.fingers.push(f)
    }
    const thumb = new THREE.Mesh(new THREE.BoxGeometry(0.024, 0.026, 0.07), skin)
    thumb.position.set(mirror ? -0.066 : 0.066, 0, -0.02)
    thumb.rotation.y = mirror ? 0.5 : -0.5
    this.add(thumb)
  }

  /** Curl fingers / compress palm under load: load ∈ 0..1. */
  setLoad(load: number): void {
    for (const f of this.fingers) f.rotation.x = -0.15 - load * 0.35
    this.palm.scale.set(1, 1 - load * 0.18, 1)
  }
}
```

`kimi-version/src/body/BodyRig.ts`:

```ts
import * as THREE from 'three'
import { TUNING } from '../core/tuning'
import { computeHandContact, computeShoulder } from '../physics/pushModel'
import { solveTwoBoneIK } from './armIk'
import { HandView } from './HandView'
import type { Vec3 } from '../physics/vec3'

export enum HandPhase {
  Off = 'off',
  Raising = 'raising',
  Pressing = 'pressing',
}

const UPPER = 0.3
const FORE = 0.28

/** Per-hand engagement logic; pure enough to unit test without three.js. */
export class HandStateMachine {
  phase = HandPhase.Off
  blend = 0 // 0 lowered → 1 on-stone

  update(dt: number, s: { inReach: boolean; input: number }): void {
    if (!s.inReach) {
      this.phase = HandPhase.Off
    } else if (this.phase === HandPhase.Off) {
      this.phase = HandPhase.Raising
    } else if (s.input > 0.05) {
      this.phase = HandPhase.Pressing
    } else if (this.phase === HandPhase.Pressing) {
      this.phase = HandPhase.Raising
    }
    const target = this.phase === HandPhase.Off ? 0 : 1
    const rate = this.phase === HandPhase.Off ? 3.5 : 5
    this.blend += Math.min(Math.max(target - this.blend, -rate * dt), rate * dt)
  }
}

const skinMat = new THREE.MeshStandardMaterial({ color: 0xc9a184, roughness: 0.85 })
const sleeveMat = new THREE.MeshStandardMaterial({ color: 0x4a5568, roughness: 0.9 })

function limb(a: THREE.Vector3, b: THREE.Vector3, r: number, mat: THREE.Material): THREE.Mesh {
  const len = a.distanceTo(b)
  const m = new THREE.Mesh(new THREE.CapsuleGeometry(r, len, 3, 8), mat)
  m.position.copy(a).lerp(b, 0.5)
  m.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), b.clone().sub(a).normalize())
  m.castShadow = true
  return m
}

/** First-person body: shoulders anchor on the player pose; hands land on the stone via IK. */
export class BodyRig extends THREE.Group {
  readonly hands: Record<-1 | 1, { sm: HandStateMachine; view: HandView; arm: THREE.Group }> = {
    [-1]: { sm: new HandStateMachine(), view: new HandView(true), arm: new THREE.Group() },
    [1]: { sm: new HandStateMachine(), view: new HandView(false), arm: new THREE.Group() },
  }

  constructor() {
    super()
    for (const side of [-1, 1] as const) {
      this.hands[side].arm.add(this.hands[side].view)
      this.add(this.hands[side].arm)
    }
  }

  /**
   * Pose the rig. `playerPos`/`bodyYaw` = player pose; `stoneCenter`/`stoneRadius`
   * locate contacts; `input` = per-hand analog force this frame.
   * Returns the per-hand contacts actually pressing (for the physics step).
   */
  pose(
    dt: number,
    playerPos: Vec3,
    bodyYaw: number,
    stoneCenter: Vec3,
    stoneRadius: number,
    input: Record<-1 | 1, number>,
  ): { side: -1 | 1; point: Vec3; dir: Vec3; magnitude: number }[] {
    const pressing: { side: -1 | 1; point: Vec3; dir: Vec3; magnitude: number }[] = []
    for (const side of [-1, 1] as const) {
      const shoulder = computeShoulder(playerPos, bodyYaw, side, TUNING.push)
      const contact = computeHandContact(stoneCenter, stoneRadius, shoulder)
      const chestDist = Math.hypot(playerPos.x - stoneCenter.x, playerPos.z - stoneCenter.z) - stoneRadius
      const inReach = chestDist < TUNING.push.reachDistance * TUNING.push.reachHysteresis
      const h = this.hands[side]
      h.sm.update(dt, { inReach, input: input[side] })

      // Hand target: on-stone contact ↔ rest pose beside the hip, blended.
      const rest = new THREE.Vector3(shoulder.x + (side === -1 ? -0.05 : 0.05), playerPos.y + 0.85, playerPos.z + 0.1)
      const onStone = new THREE.Vector3(contact.point.x, contact.point.y, contact.point.z)
      const target = rest.clone().lerp(onStone, h.sm.blend)
      const { elbow } = solveTwoBoneIK(shoulder, target, UPPER, FORE, { x: 0, y: -1, z: 0.25 })

      h.arm.clear()
      const S = new THREE.Vector3(shoulder.x, shoulder.y, shoulder.z)
      const E = new THREE.Vector3(elbow.x, elbow.y, elbow.z)
      h.arm.add(limb(S, E, 0.045, sleeveMat), limb(E, target, 0.038, skinMat))
      h.view.position.copy(target)
      // Palm faces along the push direction (toward the sphere center).
      const look = new THREE.Vector3(contact.dir.x, contact.dir.y, contact.dir.z)
      h.view.quaternion.setFromRotationMatrix(new THREE.Matrix4().lookAt(new THREE.Vector3(), look, new THREE.Vector3(0, 1, 0)))
      h.view.setLoad(h.sm.phase === HandPhase.Pressing ? input[side] : 0)

      if (h.sm.phase === HandPhase.Pressing && input[side] > 0.05) {
        pressing.push({ side, point: contact.point, dir: contact.dir, magnitude: input[side] * TUNING.push.maxForcePerHand })
      }
    }
    return pressing
  }

  /** How far the hands are engaged (0..1, max of both) — drives the camera ease. */
  engageAmount(): number {
    return Math.max(this.hands[-1].sm.blend, this.hands[1].sm.blend)
  }
}
```

Integrate in `Game.fixedStep` (replace its body):

```ts
  fixedStep(dt: number): void {
    const intent = this.source.poll(dt) ?? IDLE_INTENT
    const engaged = this.rig.engageAmount() > 0.5
    this.player.move(this.pw, { ...intent, engaged, stonePos: this.stone.position() }, dt)
    const pressing = this.rig.pose(dt, this.player.pose.pos, this.player.pose.bodyYaw, this.stone.position(), TUNING.stone.radius, {
      [-1]: intent.leftHand,
      [1]: intent.rightHand,
    })
    this.stone.applyPush(pressing)
    this.stone.applyResistance(pressing.length > 0)
    this.pw.step()
  }
```

(`rig = new BodyRig()` added to `Game`, added to the scene, and in `render()` positioned at the player: `this.rig.position.set(0,0,0)` — rig works in world space already, so just add it once.)

Extend `AutoDriver` beats:

```ts
      case 'hover': // walk into reach, no buttons
        return this.time < 1.6 ? { ...IDLE_INTENT, move: { x: 0, z: -1 } } : IDLE_INTENT
      case 'press': // walk in, then both hands full
        if (this.time < 1.6) return { ...IDLE_INTENT, move: { x: 0, z: -1 } }
        return { ...IDLE_INTENT, move: { x: 0, z: -0.25 }, leftHand: 1, rightHand: 1 }
      case 'left': // left hand only — stone visibly deflects right
        if (this.time < 1.6) return { ...IDLE_INTENT, move: { x: 0, z: -1 } }
        return { ...IDLE_INTENT, move: { x: 0, z: -0.25 }, leftHand: 1, rightHand: 0 }
```

- [x] **Step 4: Run tests, build, capture beats, read them**

Run: `npx vitest run tests/handState.test.ts && npm run build && npx tsx scripts/capture.ts hover:2.5,press:4,left:4`
Expected: tests pass; `evidence/hover.png`, `evidence/press.png`, `evidence/left.png` exist. Read all three: hands must visibly rise onto the stone surface (no interpenetration, palms on the rock), arms bend at the elbow, and in `left.png` the stone must sit visibly right of its `hover` position.

- [x] **Step 5: Commit**

```bash
git add kimi-version && git commit -m "feat(kimi-version): 第一人称身体 + 手部状态机 + IK 贴合石面"
```

---

### Task 9: Camera rig (neck-limited look + engage ease)

**Files:**
- Create: `kimi-version/src/camera/headMath.ts`
- Create: `kimi-version/src/camera/CameraRig.ts`
- Create: `kimi-version/src/core/humanSource.ts` (pointer lock + gamepad)
- Modify: `kimi-version/src/main.ts` (use `HumanSource` when no `?auto=`)
- Modify: `kimi-version/src/core/Game.ts` (render through `CameraRig`)
- Test: `kimi-version/tests/headMath.test.ts`

- [x] **Step 1: Write the failing test**

`kimi-version/tests/headMath.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import { clampHead, type NeckLimits } from '../src/camera/headMath'

const L: NeckLimits = { yawDeg: 120, pitchUpDeg: 55, pitchDownDeg: 40 }
const rad = (d: number) => (d * Math.PI) / 180

describe('headMath', () => {
  it('passes through look inside neck range', () => {
    const h = clampHead(rad(30), rad(10), 0, L)
    expect(h.yaw).toBeCloseTo(rad(30))
    expect(h.pitch).toBeCloseTo(rad(10))
  })

  it('clamps yaw to the neck limit relative to body yaw', () => {
    const h = clampHead(rad(170), 0, 0, L)
    expect(h.yaw).toBeCloseTo(rad(120))
  })

  it('clamps relative to a turned body', () => {
    const body = rad(90)
    const h = clampHead(body + rad(170), 0, body, L)
    expect(h.yaw).toBeCloseTo(body + rad(120))
  })

  it('clamps pitch both ways', () => {
    expect(clampHead(0, rad(80), 0, L).pitch).toBeCloseTo(rad(55))
    expect(clampHead(0, -rad(80), 0, L).pitch).toBeCloseTo(rad(-40))
  })
})
```

- [x] **Step 2: Run to verify it fails**

Run: `npx vitest run tests/headMath.test.ts`
Expected: FAIL — module not found.

- [x] **Step 3: Implement**

`kimi-version/src/camera/headMath.ts`:

```ts
export interface NeckLimits {
  yawDeg: number
  pitchUpDeg: number
  pitchDownDeg: number
}

const wrap = (a: number) => Math.atan2(Math.sin(a), Math.cos(a))
const clamp = (v: number, lo: number, hi: number) => Math.min(Math.max(v, lo), hi)
const rad = (d: number) => (d * Math.PI) / 180

/** Clamp an absolute head yaw/pitch to neck limits measured from body yaw. */
export function clampHead(headYaw: number, pitch: number, bodyYaw: number, L: NeckLimits): { yaw: number; pitch: number } {
  const rel = wrap(headYaw - bodyYaw)
  return {
    yaw: bodyYaw + clamp(rel, -rad(L.yawDeg), rad(L.yawDeg)),
    pitch: clamp(pitch, -rad(L.pitchDownDeg), rad(L.pitchUpDeg)),
  }
}
```

`kimi-version/src/camera/CameraRig.ts`:

```ts
import * as THREE from 'three'
import { TUNING } from '../core/tuning'
import { clampHead } from './headMath'

const MOUSE_SENS = 0.0023

/** First-person head: free look inside neck limits; eases into the push stance while engaged. */
export class CameraRig {
  private headYaw = 0
  private pitch = 0
  private ease = 0

  applyLook(dx: number, dy: number): void {
    this.headYaw -= dx * MOUSE_SENS
    this.pitch -= dy * MOUSE_SENS
  }

  /** Pose the camera. engage ∈ 0..1 from BodyRig.engageAmount(). */
  update(dt: number, camera: THREE.PerspectiveCamera, playerPos: { x: number; y: number; z: number }, bodyYaw: number, engage: number): void {
    const c = TUNING.camera
    const clamped = clampHead(this.headYaw, this.pitch, bodyYaw, {
      yawDeg: c.neckYawLimitDeg,
      pitchUpDeg: c.neckPitchUpDeg,
      pitchDownDeg: c.neckPitchDownDeg,
    })
    this.headYaw = clamped.yaw
    this.pitch = clamped.pitch
    this.ease += Math.min(Math.max(engage - this.ease, -c.engageEase * dt), c.engageEase * dt)

    // Engage stance: head leans in toward the stone and lowers slightly.
    const lean = 0.22 * this.ease
    const fwd = { x: -Math.sin(bodyYaw), z: -Math.cos(bodyYaw) }
    camera.position.set(
      playerPos.x + fwd.x * lean,
      playerPos.y + TUNING.player.eyeHeight - 0.06 * this.ease,
      playerPos.z + fwd.z * lean,
    )
    camera.rotation.set(this.pitch, this.headYaw, 0, 'YXZ')
    const fov = c.fov + (c.engagedFov - c.fov) * this.ease
    if (Math.abs(fov - camera.fov) > 0.01) {
      camera.fov = fov
      camera.updateProjectionMatrix()
    }
  }
}
```

`kimi-version/src/core/humanSource.ts`:

```ts
import { intentFromGamepad, intentFromKeyboardMouse, mergeIntents, type InputIntent, type MouseState } from './input'
import type { InputSource } from './Game'
import type { CameraRig } from '../camera/CameraRig'

/** Keyboard + pointer-lock mouse + first gamepad, merged into one intent. */
export class HumanSource implements InputSource {
  private keys = new Set<string>()
  private mouse: MouseState = { dx: 0, dy: 0, left: false, right: false }

  constructor(el: HTMLElement, private readonly cam: CameraRig) {
    addEventListener('keydown', (e) => this.keys.add(e.code))
    addEventListener('keyup', (e) => this.keys.delete(e.code))
    el.addEventListener('click', () => el.requestPointerLock())
    addEventListener('mousemove', (e) => {
      if (document.pointerLockElement) {
        this.mouse.dx += e.movementX
        this.mouse.dy += e.movementY
      }
    })
    addEventListener('mousedown', (e) => {
      if (e.button === 0) this.mouse.left = true
      if (e.button === 2) this.mouse.right = true
    })
    addEventListener('mouseup', (e) => {
      if (e.button === 0) this.mouse.left = false
      if (e.button === 2) this.mouse.right = false
    })
    addEventListener('contextmenu', (e) => e.preventDefault())
  }

  poll(dt: number): InputIntent {
    const km = intentFromKeyboardMouse(this.keys, this.mouse)
    this.cam.applyLook(km.lookDelta.x, km.lookDelta.y)
    this.mouse.dx = 0
    this.mouse.dy = 0
    const pad = intentFromGamepad(navigator.getGamepads?.()[0] ?? null, dt)
    this.cam.applyLook(pad.lookDelta.x, pad.lookDelta.y)
    return mergeIntents(km, pad)
  }
}
```

`main.ts` wiring change:

```ts
import { CameraRig } from './camera/CameraRig'
import { HumanSource } from './core/humanSource'
// ...
const cam = new CameraRig()
const auto = autoFromUrl()
const game = new Game(document.body, auto ?? new HumanSource(document.body, cam), cam)
```

Update `Game` to accept a `CameraRig` (default new one), and in `render()` replace the direct camera writes with:

```ts
this.camRig.update(FIXED_DT, this.camera, p, this.player.pose.bodyYaw, this.rig.engageAmount())
```

- [x] **Step 4: Run tests + build + capture**

Run: `npx vitest run tests/headMath.test.ts && npm run build && npx tsx scripts/capture.ts press:4`
Expected: 4 passed; `evidence/press.png` now shows the closer engaged framing (compare with the Task 8 shot — visibly nearer the stone).

- [x] **Step 5: Commit**

```bash
git add kimi-version && git commit -m "feat(kimi-version): 第一人称镜头（脖子限位 + 推球贴近）与真人输入源"
```

---

### Task 10: Loop director, HUD, and result readout

**Files:**
- Create: `kimi-version/src/game/phases.ts`
- Create: `kimi-version/src/game/LoopDirector.ts`
- Create: `kimi-version/src/game/hud.ts`
- Modify: `kimi-version/src/core/Game.ts` (drive director + HUD)
- Modify: `kimi-version/src/dev/autoDriver.ts` (add `release`, `descent` beats)
- Test: `kimi-version/tests/phases.test.ts`

- [x] **Step 1: Write the failing test**

`kimi-version/tests/phases.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import { advancePhase, initialRun, type LoopSignals } from '../src/game/phases'

const base: LoopSignals = {
  stoneZ: 80,
  stoneSpeed: 0,
  playerDistToStone: 3,
  handsEngaged: false,
  secondsInPhase: 0,
}

describe('loop phases', () => {
  it('walks the full beat sequence', () => {
    let run = initialRun()
    expect(run.phase).toBe('approach')
    run = advancePhase(run, { ...base, handsEngaged: true })
    expect(run.phase).toBe('engaged')
    run = advancePhase(run, { ...base, handsEngaged: true, stoneZ: -0.5 }) // over the crest
    expect(run.phase).toBe('release')
    run = advancePhase(run, { ...base, handsEngaged: false, stoneZ: -20, stoneSpeed: 0.1, secondsInPhase: 4 })
    expect(run.phase).toBe('descent')
    run = advancePhase(run, { ...base, handsEngaged: false, stoneZ: -60, stoneSpeed: 0, playerDistToStone: 2 })
    expect(run.phase).toBe('result')
    run = advancePhase(run, { ...base, handsEngaged: true })
    expect(run.phase).toBe('approach') // next loop starts fresh
  })

  it('counts a rollback when the stone retreats more than 2 m from best progress', () => {
    let run = initialRun()
    run = advancePhase(run, { ...base, handsEngaged: true }) // engaged, stoneZ tracked
    run = advancePhase({ ...run, bestStoneZ: 40 }, { ...base, handsEngaged: true, stoneZ: 43 })
    expect(run.rollbacks).toBe(1)
  })

  it('result carries ascent seconds', () => {
    let run = { ...initialRun(), phase: 'release' as const, ascentSeconds: 95 }
    run = advancePhase(run, { ...base, stoneZ: -20, stoneSpeed: 0.1, secondsInPhase: 4 })
    expect(run.ascentSeconds).toBe(95)
  })
})
```

- [x] **Step 2: Run to verify it fails**

Run: `npx vitest run tests/phases.test.ts`
Expected: FAIL — module not found.

- [x] **Step 3: Implement**

`kimi-version/src/game/phases.ts`:

```ts
export type LoopPhase = 'approach' | 'engaged' | 'release' | 'descent' | 'result'

export interface RunState {
  phase: LoopPhase
  rollbacks: number
  ascentSeconds: number
  bestStoneZ: number // smallest |z| reached on the climbing side = best progress
  climbSide: 1 | -1 // +1: climbing the front (+z → 0); −1: the back
}

export interface LoopSignals {
  stoneZ: number
  stoneSpeed: number
  playerDistToStone: number
  handsEngaged: boolean
  secondsInPhase: number
}

export const initialRun = (): RunState => ({
  phase: 'approach',
  rollbacks: 0,
  ascentSeconds: 0,
  bestStoneZ: Infinity,
  climbSide: 1,
})

const ROLLBACK_METERS = 2

export function advancePhase(run: RunState, s: LoopSignals): RunState {
  const next = { ...run }
  // Rollback accounting is active whenever climbing on either side.
  if (run.phase === 'engaged') {
    const progress = Math.abs(s.stoneZ)
    if (progress < run.bestStoneZ) next.bestStoneZ = progress
    else if (progress > run.bestStoneZ + ROLLBACK_METERS) {
      next.rollbacks += 1
      next.bestStoneZ = progress
    }
  }
  switch (run.phase) {
    case 'approach':
      if (s.handsEngaged) next.phase = 'engaged'
      break
    case 'engaged':
      next.ascentSeconds += 1 / 60
      // Crest crossed: the stone's z sign flips away from the climb side.
      if (Math.sign(s.stoneZ) !== run.climbSide && Math.abs(s.stoneZ) > 0.3) next.phase = 'release'
      break
    case 'release':
      if (s.secondsInPhase > 3 && s.stoneSpeed < 0.25) next.phase = 'descent'
      break
    case 'descent':
      if (s.playerDistToStone < 3 && s.stoneSpeed < 0.25) next.phase = 'result'
      break
    case 'result':
      if (s.handsEngaged) {
        return { ...initialRun(), climbSide: run.climbSide === 1 ? -1 : 1 }
      }
      break
  }
  return next
}
```

`kimi-version/src/game/LoopDirector.ts`:

```ts
import { advancePhase, initialRun, type RunState } from './phases'
import type { Vec3 } from '../physics/vec3'

/** Feeds world signals into the pure phase machine and exposes run state. */
export class LoopDirector {
  run: RunState = initialRun()
  private secondsInPhase = 0
  private lastPhase = this.run.phase

  update(dt: number, stonePos: Vec3, stoneSpeed: number, playerPos: Vec3, handsEngaged: boolean): void {
    this.secondsInPhase += dt
    this.run = advancePhase(this.run, {
      stoneZ: stonePos.z,
      stoneSpeed,
      playerDistToStone: Math.hypot(playerPos.x - stonePos.x, playerPos.z - stonePos.z),
      handsEngaged,
      secondsInPhase: this.secondsInPhase,
    })
    if (this.run.phase !== this.lastPhase) {
      this.secondsInPhase = 0
      this.lastPhase = this.run.phase
    }
  }

  /** Descent warmth 0..1 for the sky/lighting. */
  warmth(): number {
    return this.run.phase === 'descent' || this.run.phase === 'result' ? 1 : 0
  }
}
```

`kimi-version/src/game/hud.ts`:

```ts
import type { RunState } from './phases'

const HINTS: Record<string, string> = {
  approach: '走近石头 · WASD 移动 / 鼠标环顾',
  engaged: '按住 左键/右键（或 LT/RT）双手用力推',
  release: '放手吧',
  descent: '走下山去',
  result: '',
}

/** Minimal DOM overlay: one contextual hint + a result panel. */
export class Hud {
  private readonly el: HTMLDivElement

  constructor() {
    this.el = document.createElement('div')
    this.el.style.cssText =
      'position:fixed;left:0;right:0;bottom:6vh;text-align:center;color:#fff;' +
      'font:15px/1.6 system-ui;text-shadow:0 1px 4px rgba(0,0,0,.6);pointer-events:none'
    document.body.appendChild(this.el)
  }

  update(run: RunState): void {
    if (run.phase === 'result') {
      this.el.innerHTML =
        `上山用时 ${run.ascentSeconds.toFixed(1)} 秒 · 回滚 ${run.rollbacks} 次<br>` +
        `<span style="opacity:.75">再次把手放上去，就是新的一程</span>`
    } else {
      this.el.textContent = HINTS[run.phase] ?? ''
    }
  }
}
```

Game integration (in `Game`, add `director` + `hud` optional — headless Node tests never construct Game):

```ts
// fixedStep, after physics:
this.director.update(dt, this.stone.position(), this.stone.speed(), this.player.pose.pos, this.rig.engageAmount() > 0.5)
// render:
this.sky.setWarmth(this.warmthSmoothed += (this.director.warmth() - this.warmthSmoothed) * dt * 0.8)
this.hud?.update(this.director.run)
```

AutoDriver beats for the far side (scripted full-loop is overkill; instead the driver teleports *itself* via direct world manipulation is forbidden — so `release`/`descent` beats are captured by scripted long pushes: `release` = press for N seconds from spawn; tune `t` until the stone crests, verified visually; `descent` = same then release inputs and walk forward):

```ts
      case 'release':
        if (this.time < 1.6) return { ...IDLE_INTENT, move: { x: 0, z: -1 } }
        return { ...IDLE_INTENT, move: { x: 0, z: -0.3 }, leftHand: 1, rightHand: 1 }
      case 'descent':
        if (this.time < 1.6) return { ...IDLE_INTENT, move: { x: 0, z: -1 } }
        if (this.time < 20) return { ...IDLE_INTENT, move: { x: 0, z: -0.3 }, leftHand: 1, rightHand: 1 }
        return { ...IDLE_INTENT, move: { x: 0, z: -1 } }
```

- [x] **Step 4: Run tests**

Run: `npx vitest run tests/phases.test.ts`
Expected: 3 passed.

- [x] **Step 5: Build + capture the release beat**

Run: `npm run build && npx tsx scripts/capture.ts release:12,descent:26`
Expected: two PNGs. Read them: `release.png` shows the stone at/over the crest with hands disengaging; `descent.png` shows warmer light and the player walking down. If the stone has not crested in `release.png`, raise `t` — do not weaken physics to make the shot work.

- [x] **Step 6: Commit**

```bash
git add kimi-version && git commit -m "feat(kimi-version): 循环节拍状态机 + HUD + 下山暖光"
```

---

### Task 11: Contact audio, rumble, polish, README, full evidence suite

**Files:**
- Create: `kimi-version/src/audio/scrape.ts`
- Create: `kimi-version/src/core/rumble.ts`
- Create: `kimi-version/src/world/crestMarker.ts`
- Create: `kimi-version/src/render/dust.ts`
- Modify: `kimi-version/src/core/Game.ts` (wire audio + rumble + dust)
- Create: `kimi-version/README.md`

- [x] **Step 1: Implement**

`kimi-version/src/audio/scrape.ts`:

```ts
/** Looping filtered-noise scrape; gain follows stone angular speed. No audio assets. */
export class ScrapeAudio {
  private ctx: AudioContext | null = null
  private gain: GainNode | null = null

  /** Call from a user gesture (first click) — browsers block audio before that. */
  start(): void {
    if (this.ctx) return
    this.ctx = new AudioContext()
    const len = this.ctx.sampleRate * 2
    const buf = this.ctx.createBuffer(1, len, this.ctx.sampleRate)
    const data = buf.getChannelData(0)
    for (let i = 0; i < len; i++) data[i] = (Math.random() * 2 - 1) * 0.5
    const src = this.ctx.createBufferSource()
    src.buffer = buf
    src.loop = true
    const filter = this.ctx.createBiquadFilter()
    filter.type = 'bandpass'
    filter.frequency.value = 320
    filter.Q.value = 0.8
    this.gain = this.ctx.createGain()
    this.gain.gain.value = 0
    src.connect(filter).connect(this.gain).connect(this.ctx.destination)
    src.start()
  }

  /** angVel = stone angular speed (rad/s); contact = stone touching ground. */
  update(angVel: number, contact: boolean): void {
    if (!this.gain || !this.ctx) return
    const target = contact ? Math.min(angVel / 6, 1) * 0.5 : 0
    this.gain.gain.setTargetAtTime(target, this.ctx.currentTime, 0.08)
  }
}
```

`kimi-version/src/core/rumble.ts`:

```ts
/** Per-hand gamepad rumble mirroring push load, where the API exists. */
export function rumble(left: number, right: number): void {
  const pad = navigator.getGamepads?.()[0]
  const act = (pad as unknown as { vibrationActuator?: { playEffect?: (t: string, o: object) => void } })?.vibrationActuator
  act?.playEffect?.('dual-rumble', {
    duration: 80,
    strongMagnitude: Math.min(Math.max(left, right), 1),
    weakMagnitude: Math.min((left + right) / 2, 1),
  })
}
```

`kimi-version/src/world/crestMarker.ts`:

```ts
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
```

`kimi-version/src/render/dust.ts`:

```ts
import * as THREE from 'three'

/** One-shot grit puff at a contact point on breakaway. Pool of one; respawn per burst. */
export class Dust extends THREE.Points {
  private life = 0

  constructor() {
    const geo = new THREE.BufferGeometry()
    geo.setAttribute('position', new THREE.BufferAttribute(new Float32Array(24 * 3), 3))
    super(geo, new THREE.PointsMaterial({ color: 0xb9a684, size: 0.09, transparent: true, opacity: 0 }))
  }

  burst(at: { x: number; y: number; z: number }): void {
    const pos = this.geometry.attributes.position as THREE.BufferAttribute
    for (let i = 0; i < pos.count; i++) {
      pos.setXYZ(i, at.x + (Math.random() - 0.5) * 0.5, at.y + Math.random() * 0.2, at.z + (Math.random() - 0.5) * 0.5)
    }
    pos.needsUpdate = true
    this.life = 0.6
  }

  update(dt: number): void {
    if (this.life <= 0) return
    this.life -= dt
    ;(this.material as THREE.PointsMaterial).opacity = Math.max(this.life, 0)
  }
}
```

Game wiring: add `buildCrestMarker()` to the scene in the constructor; keep a `Dust` instance and, when `stone.held` flips from true to false while a push is active, call `dust.burst(contact point of the stronger hand)`; call `dust.update(dt)` in `render()`.

Game wiring (audio/rumble): `ScrapeAudio.start()` on first click (alongside pointer lock in `HumanSource`), then per fixed step:

```ts
this.scrape.update(this.stone.body.angvel() ? Math.hypot(...Object.values(this.stone.body.angvel())) : 0, this.stone.speed() > 0.02)
if (pressing.length > 0) rumble(intent.leftHand, intent.rightHand)
```

(Exact one-liner form is free; keep the logic: gain ∝ angular speed, rumble ∝ hand load.)

`kimi-version/README.md`:

```markdown
# 西西弗斯下山 · Kimi Version (MVP)

Clean-room web build: first-person, physically honest push-the-stone loop.
Spec: `../docs/superpowers/specs/2026-08-18-kimi-version-mvp-design.md`

## Run

    npm install
    npm run dev        # http://localhost:5178

## Controls

- WASD 移动 · 鼠标环顾（点击画面锁定指针）
- 鼠标左键 = 左手用力 · 右键 = 右手用力
- 手柄：左摇杆移动 · 右摇杆环顾 · LT = 左手 · RT = 右手（模拟量）
- R = 复位（调试用）

## Verify

    npm run test       # vitest: 物理契约 + 纯逻辑
    npm run build
    npx tsx scripts/capture.ts hover:2.5,press:4,left:4,release:12,descent:26
    # 截图落在 evidence/，逐个目检
```

- [x] **Step 2: Full verification pass**

Run: `npm run test && npm run build && npx tsx scripts/capture.ts rest:2,hover:2.5,press:4,left:4,release:12,descent:26`
Expected: all vitest suites green; six PNGs in `evidence/`; read every one against the spec's four bars (表意 / 重量 / 接触 / 循环) and fix what fails the eye, not the test.

- [x] **Step 3: Commit**

```bash
git add kimi-version && git commit -m "feat(kimi-version): 摩擦音/震动反馈/README + 全节拍证据"
```

---

## Self-review notes (resolved during planning)

- Heightfield row/column order for Rapier is calibrated by the Task 2 drop test (single swap point in `terrainCollider.ts`).
- `timeOfImpact` vs `toi` across rapier3d-compat versions is absorbed inside `PhysicsWorld.groundProbe`.
- Left/right deflection convention: facing −z, left hand at −x, force through the sphere center pushes the stone +x — locked by `tests/pushModel.test.ts` and `tests/pushContract.test.ts`.

---

## Execution status (2026-08-18, recorder: Kimi)

All 12 tasks implemented and committed. 46 vitest assertions green. Numeric feel contract, basin containment, loop phases all verified headlessly. Beat evidence (rest/hover/press/left/release/descent) captured via Playwright and reviewed as images; two rounds of visual iteration on camera framing and hand placement. Notable deviations from the plan text:

- Rapier heightfield layout calibrated empirically: first index sweeps Z, second X (`terrainCollider.ts`), matching the plan's anticipated calibration point.
- Kinetic resistance is deceleration-based (k·g), balancing gravity at ~5°; hold slope 6° (`tuning.ts`).
- Push force fades above hand speed (`push.handSpeedMax`) — you cannot keep shoving a stone already rolling away; this is what keeps push contact stable.
- Player capsule radius 0.5 doubles as the push-stance standoff.
- Engaged camera is a high close-shoulder (back 0.42 / up 0.3) with −25°-clamped gaze bias, not a forward lean — readability won over raw closeness.
- Auto driver gained lateral tracking + rollback let-go (bot competence, not game mechanics).
- Basin deepened to −1.2 m with rock-wall level bounds after a released stone escaped the world edge; regression test added in `stonePhysics.test.ts`.
- Loop signals split into `handsRaised` / `handsPressing`; result restart requires pressing.

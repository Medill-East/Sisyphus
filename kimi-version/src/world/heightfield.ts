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
 * Beyond each foot the apron dips into a shallow collecting basin with a
 * raised rim, so a runaway stone gathers there instead of escaping.
 */
export function sampleHeight(x: number, z: number): number {
  const over = z > M.frontLength ? z - M.frontLength : z < -M.backLength ? -z - M.backLength : 0
  let h: number
  if (over > 0) {
    h = -1.2 * Math.sin(Math.PI * Math.min(over / 12, 1)) + (over > 6 ? 1.0 * (over - 6) ** 2 : 0)
  } else {
    const t = z >= 0 ? z / M.frontLength : -z / M.backLength
    h = sideProfile(t)
  }
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

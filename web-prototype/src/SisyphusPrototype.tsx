import { Canvas, useFrame, useThree } from '@react-three/fiber'
import { BallCollider, CuboidCollider, Physics, RigidBody } from '@react-three/rapier'
import type { RapierRigidBody } from '@react-three/rapier'
import { Text } from '@react-three/drei'
import { useEffect, useMemo, useRef, useState } from 'react'
import { MathUtils, Vector3 } from 'three'
import type { Camera, Group } from 'three'
import {
  calculateHumReward,
  createInitialRunMetrics,
  getCameraMode,
  getPhaseLabel,
  recordTrailPoint,
  shouldAdvancePhase,
} from './game/gameLogic'
import type {
  CameraMode,
  GamePhase,
  RunMetrics,
  TrailPoint,
  TuningConfig,
  Vector3Tuple,
} from './game/types'

const ROCK_RADIUS = 1.05
const BOTTOM_Z = 8
const SUMMIT_Z = -24
const PATH_WIDTH = 5.2
const tmpVector = new Vector3()
const tmpTarget = new Vector3()
const tmpCamera = new Vector3()

export interface GameHudState {
  phase: GamePhase
  phaseLabel: string
  cameraMode: CameraMode
  distanceToRock: number
  ascentSeconds: number
  rollbackCount: number
  rewardLevel: number
  trailPoints: number
  rockHeight: number
  prompt: string
}

interface HumState {
  clarity: number
  rewardLevel: number
}

interface PrototypeProps {
  tuning: TuningConfig
  resetSignal: number
  onHudChange: (hud: GameHudState) => void
  onHumChange: (hum: HumState) => void
  onInteract: () => void
}

interface GameWorldProps extends PrototypeProps {
  onResetRequested: () => void
}

const initialPlayerPosition = new Vector3(0, groundHeight(14, 0.28), 14)
const initialRockPosition = new Vector3(0, groundHeight(6.7, 0.28) + ROCK_RADIUS + 0.08, 6.7)

export function SisyphusPrototype(props: PrototypeProps) {
  return (
    <Canvas
      camera={{ fov: 62, near: 0.1, far: 220, position: [0, 4, 14] }}
      onPointerDown={props.onInteract}
    >
      <color attach="background" args={['#9fbbc1']} />
      <fog attach="fog" args={['#9fbbc1', 26, 98]} />
      <ambientLight intensity={0.65} />
      <directionalLight
        intensity={2.6}
        position={[7, 16, 9]}
      />
      <Physics gravity={[0, -9.81, 0]} interpolate>
        <GameWorld key={props.resetSignal} {...props} onResetRequested={() => undefined} />
      </Physics>
    </Canvas>
  )
}

function GameWorld({
  tuning,
  onHudChange,
  onHumChange,
  onInteract,
}: GameWorldProps) {
  const rockRef = useRef<RapierRigidBody | null>(null)
  const playerPosition = useRef(initialPlayerPosition.clone())
  const look = useRef({ yaw: 0, pitch: -0.1 })
  const keys = useKeyboard()
  const [phase, setPhase] = useState<GamePhase>('approach')
  const phaseRef = useRef<GamePhase>('approach')
  const [trail, setTrail] = useState<TrailPoint[]>([])
  const trailRef = useRef<TrailPoint[]>([])
  const metricsRef = useRef<RunMetrics>(createInitialRunMetrics())
  const lastRockZ = useRef(initialRockPosition.z)
  const phaseStartedAt = useRef(0)
  const ascentStartedAt = useRef(0)
  const lastHudAt = useRef(0)
  const lastHumAt = useRef(0)

  usePointerLook(look, onInteract)

  useEffect(() => {
    phaseRef.current = phase
  }, [phase])

  useEffect(() => {
    trailRef.current = trail
  }, [trail])

  useEffect(() => {
    const rock = rockRef.current
    const startPlayer = new Vector3(0, groundHeight(14, tuning.slopeGrade), 14)
    const startRock = new Vector3(
      0,
      groundHeight(6.7, tuning.slopeGrade) + ROCK_RADIUS + 0.08,
      6.7,
    )

    playerPosition.current.copy(startPlayer)
    look.current.yaw = 0
    look.current.pitch = -0.1
    phaseStartedAt.current = 0
    ascentStartedAt.current = 0
    lastRockZ.current = startRock.z

    if (rock) {
      rock.setTranslation(startRock, true)
      rock.setLinvel({ x: 0, y: 0, z: 0 }, true)
      rock.setAngvel({ x: 0, y: 0, z: 0 }, true)
    }
  }, [tuning.slopeGrade])

  useFrame(({ camera, clock }, delta) => {
    const rock = rockRef.current
    if (!rock) {
      return
    }

    const dt = Math.min(delta, 0.04)
    const elapsed = clock.getElapsedTime()
    const rockPosition = readRigidBodyPosition(rock)
    const currentPhase = phaseRef.current
    const distanceToRock = playerPosition.current.distanceTo(rockPosition)
    const releaseSeconds = elapsed - phaseStartedAt.current

    movePlayer(keys.current, playerPosition.current, look.current.yaw, dt, tuning, currentPhase)
    applyPushForce(rock, playerPosition.current, rockPosition, keys.current, dt, tuning, currentPhase)
    trackRollback(rockPosition, currentPhase, metricsRef.current, lastRockZ)
    recordAscentTrail(rockPosition, elapsed, currentPhase, trailRef, setTrail, tuning)

    const nextPhase = shouldAdvancePhase(currentPhase, {
      playerDistanceToRock: distanceToRock,
      rockHeight: rockPosition.y,
      releaseSeconds,
    })

    if (nextPhase !== currentPhase) {
      transitionPhase(nextPhase, elapsed, rock, playerPosition.current, tuning)
      phaseRef.current = nextPhase
      setPhase(nextPhase)
    }

    const cameraMode = getCameraMode(currentPhase, distanceToRock, tuning.cameraBlendDistance)
    updateCamera(
      camera,
      playerPosition.current,
      rockPosition,
      look.current,
      cameraMode,
      dt,
      tuning.slopeGrade,
    )
    updateHum(elapsed, currentPhase, metricsRef.current, onHumChange, lastHumAt, tuning)

    if (elapsed - lastHudAt.current > 0.1) {
      lastHudAt.current = elapsed
      onHudChange({
        phase: currentPhase,
        phaseLabel: getPhaseLabel(currentPhase),
        cameraMode,
        distanceToRock,
        ascentSeconds: metricsRef.current.ascentSeconds || Math.max(0, elapsed - ascentStartedAt.current),
        rollbackCount: metricsRef.current.rollbackCount,
        rewardLevel: metricsRef.current.rewardLevel,
        trailPoints: trailRef.current.length,
        rockHeight: rockPosition.y,
        prompt: getPrompt(currentPhase),
      })
    }
  })

  return (
    <>
      <Mountain tuning={tuning} />
      <Rock refObject={rockRef} tuning={tuning} />
      <PlayerMarker positionRef={playerPosition} phase={phase} />
      <TrailGrowth trail={trail} tuning={tuning} visible={phase !== 'approach' && phase !== 'ascent'} />
      <SummitMarker tuning={tuning} />
      <LowPolyScatter tuning={tuning} />
    </>
  )

  function transitionPhase(
    nextPhase: GamePhase,
    elapsed: number,
    rock: RapierRigidBody,
    player: Vector3,
    currentTuning: TuningConfig,
  ) {
    phaseStartedAt.current = elapsed

    if (nextPhase === 'ascent') {
      ascentStartedAt.current = elapsed
      metricsRef.current = createInitialRunMetrics()
      onHumChange({ clarity: 0.12, rewardLevel: 0 })
      return
    }

    if (nextPhase === 'release') {
      const ascentSeconds = Math.max(1, elapsed - ascentStartedAt.current)
      const reward = calculateHumReward({
        ...metricsRef.current,
        ascentSeconds,
      })
      metricsRef.current = {
        ...metricsRef.current,
        ascentSeconds,
        rewardLevel: reward.rewardLevel,
      }
      rock.setLinvel({ x: 0, y: -0.4, z: 8.5 }, true)
      rock.setAngvel({ x: 5, y: 0, z: 0 }, true)
      onHumChange({ clarity: reward.clarity * currentTuning.humClarity, rewardLevel: reward.rewardLevel })
      return
    }

    if (nextPhase === 'descent') {
      const bottom = new Vector3(
        0,
        groundHeight(6.7, currentTuning.slopeGrade) + ROCK_RADIUS + 0.08,
        6.7,
      )
      rock.setTranslation(bottom, true)
      rock.setLinvel({ x: 0, y: 0, z: 0 }, true)
      rock.setAngvel({ x: 0, y: 0, z: 0 }, true)
      player.set(0, groundHeight(SUMMIT_Z + 0.8, currentTuning.slopeGrade) + 0.05, SUMMIT_Z + 0.8)
      return
    }

    if (nextPhase === 'complete') {
      onHumChange({
        clarity: Math.max(0.52, currentTuning.humClarity * 0.75),
        rewardLevel: Math.max(1, metricsRef.current.rewardLevel),
      })
    }
  }
}

function Mountain({ tuning }: { tuning: TuningConfig }) {
  const angle = Math.atan(tuning.slopeGrade)
  const run = BOTTOM_Z - SUMMIT_Z
  const length = Math.sqrt(run * run + (run * tuning.slopeGrade) ** 2) + 5
  const centerZ = (BOTTOM_Z + SUMMIT_Z) / 2
  const centerY = groundHeight(centerZ, tuning.slopeGrade) - 0.2

  return (
    <>
      <RigidBody type="fixed" colliders={false}>
        <mesh
          receiveShadow
          position={[0, centerY, centerZ]}
          rotation={[angle, 0, 0]}
        >
          <boxGeometry args={[13, 0.4, length]} />
          <meshStandardMaterial color="#8a826f" roughness={0.95} />
        </mesh>
        <CuboidCollider
          args={[6.5, 0.2, length / 2]}
          friction={1.1}
          position={[0, centerY, centerZ]}
          rotation={[angle, 0, 0]}
        />
      </RigidBody>
      <RigidBody type="fixed" colliders={false}>
        <mesh receiveShadow position={[0, -0.18, 12]}>
          <boxGeometry args={[42, 0.35, 12]} />
          <meshStandardMaterial color="#6d725c" roughness={0.9} />
        </mesh>
        <CuboidCollider args={[21, 0.18, 6]} friction={1.2} position={[0, -0.18, 12]} />
      </RigidBody>
      <RigidBody type="fixed" colliders={false}>
        <CuboidCollider args={[7, 2.5, 0.35]} position={[0, 1.9, 10.5]} friction={1.1} />
      </RigidBody>
    </>
  )
}

function Rock({
  refObject,
  tuning,
}: {
  refObject: React.MutableRefObject<RapierRigidBody | null>
  tuning: TuningConfig
}) {
  const start = [
    0,
    groundHeight(6.7, tuning.slopeGrade) + ROCK_RADIUS + 0.08,
    6.7,
  ] as Vector3Tuple

  return (
    <RigidBody
      ref={refObject}
      colliders={false}
      position={start}
      mass={tuning.rockMass}
      linearDamping={tuning.windResistance}
      angularDamping={0.22 + tuning.windResistance}
      canSleep={false}
    >
      <mesh castShadow receiveShadow>
        <sphereGeometry args={[ROCK_RADIUS, 9, 7]} />
        <meshStandardMaterial color="#4f514e" roughness={0.82} metalness={0.05} />
      </mesh>
      <BallCollider args={[ROCK_RADIUS]} friction={tuning.rockFriction} restitution={0.04} />
    </RigidBody>
  )
}

function PlayerMarker({
  positionRef,
  phase,
}: {
  positionRef: React.MutableRefObject<Vector3>
  phase: GamePhase
}) {
  const groupRef = useRef<Group>(null)

  useFrame(() => {
    if (!groupRef.current) {
      return
    }
    groupRef.current.position.copy(positionRef.current)
  })

  return (
    <group ref={groupRef} visible={phase !== 'ascent'}>
      <mesh castShadow position={[0, 0.7, 0]}>
        <capsuleGeometry args={[0.16, 0.72, 4, 8]} />
        <meshStandardMaterial color="#2c3130" roughness={0.85} />
      </mesh>
      <mesh castShadow position={[0, 1.22, 0]}>
        <sphereGeometry args={[0.18, 8, 6]} />
        <meshStandardMaterial color="#39403d" roughness={0.85} />
      </mesh>
    </group>
  )
}

function TrailGrowth({
  trail,
  tuning,
  visible,
}: {
  trail: TrailPoint[]
  tuning: TuningConfig
  visible: boolean
}) {
  if (!visible || trail.length === 0) {
    return null
  }

  return (
    <group>
      {trail.slice(0, 120).map((point, index) => {
        const seed = index + 1
        const left = noise(seed) > 0.5 ? -1 : 1
        const offset = 0.28 + noise(seed + 3) * 0.82
        const flower = noise(seed + 9) > 0.58
        const x = point.position[0] + left * offset
        const z = point.position[2] + (noise(seed + 5) - 0.5) * 0.45
        const y = groundHeight(z, tuning.slopeGrade) + 0.04
        const scale = 0.55 + tuning.trailGrowthStrength * noise(seed + 7)

        return (
          <group key={`${point.time}-${index}`} position={[x, y, z]}>
            <mesh receiveShadow rotation={[-Math.PI / 2, 0, noise(seed) * Math.PI]}>
              <circleGeometry args={[0.34 * scale, 7]} />
              <meshStandardMaterial color={index % 2 === 0 ? '#8f9d63' : '#667f56'} />
            </mesh>
            <mesh castShadow position={[0, 0.14 * scale, 0]}>
              <coneGeometry args={[0.035 * scale, 0.28 * scale, 5]} />
              <meshStandardMaterial color="#526e48" />
            </mesh>
            {flower ? (
              <mesh castShadow position={[0, 0.31 * scale, 0]}>
                <sphereGeometry args={[0.055 * scale, 7, 5]} />
                <meshStandardMaterial color={index % 3 === 0 ? '#e7c368' : '#cbd7a2'} />
              </mesh>
            ) : null}
          </group>
        )
      })}
      {trail.map((point, index) => {
        if (index % 3 !== 0) {
          return null
        }
        return (
          <mesh
            key={`scar-${point.time}-${index}`}
            position={[
              point.position[0],
              groundHeight(point.position[2], tuning.slopeGrade) + 0.025,
              point.position[2],
            ]}
            rotation={[-Math.PI / 2, 0, 0]}
          >
            <circleGeometry args={[0.5, 10]} />
            <meshStandardMaterial color="#b8ad84" transparent opacity={0.38} />
          </mesh>
        )
      })}
    </group>
  )
}

function SummitMarker({ tuning }: { tuning: TuningConfig }) {
  const y = groundHeight(SUMMIT_Z, tuning.slopeGrade) + 0.3
  return (
    <group position={[0, y, SUMMIT_Z - 1.4]}>
      <Text
        color="#2e3531"
        fontSize={0.46}
        anchorX="center"
        anchorY="middle"
        rotation={[-0.15, 0, 0]}
      >
        summit
      </Text>
      <mesh position={[0, -0.35, 0]} castShadow>
        <coneGeometry args={[0.22, 0.75, 5]} />
        <meshStandardMaterial color="#d6c589" roughness={0.8} />
      </mesh>
    </group>
  )
}

function LowPolyScatter({ tuning }: { tuning: TuningConfig }) {
  const stones = useMemo(
    () =>
      Array.from({ length: 38 }, (_, index) => {
        const side = index % 2 === 0 ? -1 : 1
        const z = 9 - index * 0.9
        const x = side * (6.6 + noise(index) * 7.4)
        const y = groundHeight(z, tuning.slopeGrade) - 0.02
        const scale = 0.35 + noise(index + 8) * 1.1
        return { x, y, z, scale, rotate: noise(index + 4) * Math.PI }
      }),
    [tuning.slopeGrade],
  )

  return (
    <group>
      {stones.map((stone, index) => (
        <mesh
          key={index}
          castShadow
          receiveShadow
          position={[stone.x, stone.y + stone.scale * 0.22, stone.z]}
          rotation={[0.1, stone.rotate, 0.2]}
        >
          <dodecahedronGeometry args={[stone.scale, 0]} />
          <meshStandardMaterial
            color={index % 4 === 0 ? '#58605d' : '#77746a'}
            roughness={0.9}
          />
        </mesh>
      ))}
    </group>
  )
}

function useKeyboard() {
  const keys = useRef(new Set<string>())

  useEffect(() => {
    const down = (event: KeyboardEvent) => keys.current.add(event.code)
    const up = (event: KeyboardEvent) => keys.current.delete(event.code)
    window.addEventListener('keydown', down)
    window.addEventListener('keyup', up)
    return () => {
      window.removeEventListener('keydown', down)
      window.removeEventListener('keyup', up)
    }
  }, [])

  return keys
}

function usePointerLook(
  look: React.MutableRefObject<{ yaw: number; pitch: number }>,
  onInteract: () => void,
) {
  const { gl } = useThree()

  useEffect(() => {
    const canvas = gl.domElement
    const requestLock = () => {
      onInteract()
      if (document.pointerLockElement !== canvas) {
        void canvas.requestPointerLock()
      }
    }
    const move = (event: MouseEvent) => {
      if (document.pointerLockElement !== canvas) {
        return
      }
      look.current.yaw -= event.movementX * 0.0025
      look.current.pitch = MathUtils.clamp(
        look.current.pitch - event.movementY * 0.002,
        -0.75,
        0.45,
      )
    }

    canvas.addEventListener('click', requestLock)
    window.addEventListener('mousemove', move)
    return () => {
      canvas.removeEventListener('click', requestLock)
      window.removeEventListener('mousemove', move)
    }
  }, [gl, look, onInteract])
}

function movePlayer(
  keys: Set<string>,
  player: Vector3,
  yaw: number,
  dt: number,
  tuning: TuningConfig,
  phase: GamePhase,
) {
  if (phase === 'release' || phase === 'complete') {
    return
  }

  const vertical = Number(keys.has('KeyW')) - Number(keys.has('KeyS'))
  const horizontal = Number(keys.has('KeyD')) - Number(keys.has('KeyA'))
  const forward = tmpVector.set(Math.sin(yaw), 0, -Math.cos(yaw))
  const right = tmpTarget.set(Math.cos(yaw), 0, Math.sin(yaw))
  const move = tmpCamera
    .set(0, 0, 0)
    .addScaledVector(forward, vertical)
    .addScaledVector(right, horizontal)

  if (move.lengthSq() > 0) {
    move.normalize()
    const speed = phase === 'descent' ? 5.5 : 3.25
    player.addScaledVector(move, speed * dt)
  }

  player.x = MathUtils.clamp(player.x, -PATH_WIDTH, PATH_WIDTH)
  player.z = MathUtils.clamp(player.z, SUMMIT_Z - 1.5, 15)
  player.y = groundHeight(player.z, tuning.slopeGrade) + 0.05
}

function applyPushForce(
  rock: RapierRigidBody,
  player: Vector3,
  rockPosition: Vector3,
  keys: Set<string>,
  dt: number,
  tuning: TuningConfig,
  phase: GamePhase,
) {
  if (phase !== 'ascent' || !keys.has('KeyW')) {
    return
  }

  const distance = player.distanceTo(rockPosition)
  if (distance > 2.4) {
    return
  }

  const run = Math.sqrt(1 + tuning.slopeGrade * tuning.slopeGrade)
  const impulse = {
    x: (player.x - rockPosition.x) * -0.35 * tuning.pushForce * dt,
    y: (tuning.slopeGrade / run) * tuning.pushForce * dt,
    z: (-1 / run) * tuning.pushForce * dt,
  }

  rock.applyImpulse(impulse, true)
  player.lerp(
    tmpVector.set(
      rockPosition.x,
      groundHeight(rockPosition.z + 1.7, tuning.slopeGrade) + 0.05,
      rockPosition.z + 1.7,
    ),
    0.08,
  )
}

function trackRollback(
  rockPosition: Vector3,
  phase: GamePhase,
  metrics: RunMetrics,
  lastRockZ: React.MutableRefObject<number>,
) {
  if (phase !== 'ascent') {
    lastRockZ.current = rockPosition.z
    return
  }

  if (rockPosition.z - lastRockZ.current > 1.25) {
    metrics.rollbackCount += 1
    metrics.stabilityScore = Math.max(0, metrics.stabilityScore - 0.18)
    lastRockZ.current = rockPosition.z
    return
  }

  if (rockPosition.z < lastRockZ.current) {
    lastRockZ.current = rockPosition.z
  }
}

function recordAscentTrail(
  rockPosition: Vector3,
  elapsed: number,
  phase: GamePhase,
  trailRef: React.MutableRefObject<TrailPoint[]>,
  setTrail: React.Dispatch<React.SetStateAction<TrailPoint[]>>,
  tuning: TuningConfig,
) {
  if (phase !== 'ascent') {
    return
  }

  const point: Vector3Tuple = [
    rockPosition.x,
    groundHeight(rockPosition.z, tuning.slopeGrade),
    rockPosition.z,
  ]
  const nextTrail = recordTrailPoint(trailRef.current, point, elapsed, 0.7)

  if (nextTrail !== trailRef.current) {
    trailRef.current = nextTrail
    setTrail(nextTrail)
  }
}

function updateCamera(
  camera: Camera,
  player: Vector3,
  rock: Vector3,
  look: { yaw: number; pitch: number },
  mode: CameraMode,
  dt: number,
  slopeGrade: number,
) {
  const forward = tmpVector.set(Math.sin(look.yaw), 0, -Math.cos(look.yaw))
  const desired = tmpCamera

  if (mode === 'first-person') {
    desired.set(rock.x, groundHeight(rock.z + 2.55, slopeGrade) + 1.42, rock.z + 2.55)
    camera.position.lerp(desired, 1 - Math.exp(-dt * 7))
    camera.lookAt(rock.x, rock.y + 0.62, rock.z)
    return
  }

  if (mode === 'close-third-person') {
    desired.copy(player).addScaledVector(forward, -4.2).add(new Vector3(0, 2.1, 0))
    camera.position.lerp(desired, 1 - Math.exp(-dt * 4.5))
    camera.lookAt(rock.x, rock.y + 0.4, rock.z)
    return
  }

  if (mode === 'wide-third-person') {
    desired.set(player.x + 2.2, player.y + 6.8, player.z + 9.5)
    camera.position.lerp(desired, 1 - Math.exp(-dt * 2.4))
    camera.lookAt(player.x, player.y + 1.2, player.z - 4.5)
    return
  }

  desired.copy(player).addScaledVector(forward, -7.2).add(new Vector3(0, 3.5, 0))
  camera.position.lerp(desired, 1 - Math.exp(-dt * 3.2))
  camera.lookAt(player.x, player.y + 1.1, player.z - 2.5)
}

function updateHum(
  elapsed: number,
  phase: GamePhase,
  metrics: RunMetrics,
  onHumChange: (hum: HumState) => void,
  lastHumAt: React.MutableRefObject<number>,
  tuning: TuningConfig,
) {
  if (elapsed - lastHumAt.current < 0.24) {
    return
  }

  lastHumAt.current = elapsed

  if (phase === 'approach') {
    onHumChange({ clarity: 0.05, rewardLevel: 0 })
    return
  }

  if (phase === 'ascent') {
    const pulse = 0.5 + Math.sin(elapsed * 2.4) * 0.5
    onHumChange({
      clarity: tuning.humClarity * (0.08 + pulse * 0.12),
      rewardLevel: 1,
    })
    return
  }

  const reward = Math.max(1, metrics.rewardLevel)
  const clarity = Math.max(0.26, tuning.humClarity * (0.35 + reward * 0.17))
  onHumChange({ clarity, rewardLevel: reward })
}

function readRigidBodyPosition(body: RapierRigidBody): Vector3 {
  const position = body.translation()
  return new Vector3(position.x, position.y, position.z)
}

function groundHeight(z: number, slopeGrade: number): number {
  return Math.max(0, slopeGrade * (BOTTOM_Z - z))
}

function getPrompt(phase: GamePhase): string {
  if (phase === 'approach') {
    return 'Walk to the stone. Click the world to capture the mouse and wake the hum.'
  }
  if (phase === 'ascent') {
    return 'Hold W close to the stone. Keep it steady until the summit marker.'
  }
  if (phase === 'release') {
    return 'Let the stone fall. The path starts remembering the climb.'
  }
  if (phase === 'descent') {
    return 'Walk back downhill through the new growth and return to the stone.'
  }
  return 'The first loop is complete. The stone is waiting for the next day.'
}

function noise(seed: number): number {
  return Math.sin(seed * 12.9898) * 43758.5453 % 1
}

import { useCallback, useMemo, useState } from 'react'
import { Leva, useControls } from 'leva'
import { SisyphusPrototype } from './SisyphusPrototype'
import type { GameHudState } from './SisyphusPrototype'
import { useHumSynth } from './game/audio'
import { defaultTuning } from './game/types'
import type { TuningConfig } from './game/types'
import './App.css'

const initialHud: GameHudState = {
  phase: 'approach',
  phaseLabel: 'Approach',
  cameraMode: 'third-person',
  distanceToRock: 0,
  ascentSeconds: 0,
  rollbackCount: 0,
  rewardLevel: 0,
  trailPoints: 0,
  rockHeight: 0,
  prompt: 'Walk to the stone. Click the world to capture the mouse and wake the hum.',
}

function App() {
  const controls = useControls('Tuning', {
    rockMass: { value: defaultTuning.rockMass, min: 6, max: 48, step: 1 },
    rockFriction: { value: defaultTuning.rockFriction, min: 0.08, max: 1.4, step: 0.01 },
    pushForce: { value: defaultTuning.pushForce, min: 16, max: 110, step: 1 },
    slopeGrade: { value: defaultTuning.slopeGrade, min: 0.16, max: 0.42, step: 0.01 },
    windResistance: { value: defaultTuning.windResistance, min: 0, max: 1.5, step: 0.01 },
    cameraBlendDistance: {
      value: defaultTuning.cameraBlendDistance,
      min: 2.4,
      max: 7,
      step: 0.1,
    },
    humClarity: { value: defaultTuning.humClarity, min: 0, max: 1, step: 0.01 },
    trailGrowthStrength: {
      value: defaultTuning.trailGrowthStrength,
      min: 0.1,
      max: 1.5,
      step: 0.05,
    },
    targetAscentSeconds: {
      value: defaultTuning.targetAscentSeconds,
      min: 60,
      max: 360,
      step: 10,
    },
  })
  const tuning = useMemo(() => controls as TuningConfig, [controls])
  const [hud, setHud] = useState<GameHudState>(initialHud)
  const [resetSignal, setResetSignal] = useState(0)
  const [hum, setHum] = useState({ clarity: 0.05, rewardLevel: 0 })
  const [audioStarted, setAudioStarted] = useState(false)
  const humSynth = useHumSynth(hum.clarity, hum.rewardLevel)
  const startAudio = useCallback(() => {
    humSynth.start()
    setAudioStarted(true)
  }, [humSynth])

  return (
    <main className="prototype-shell">
      <SisyphusPrototype
        tuning={tuning}
        resetSignal={resetSignal}
        onHudChange={setHud}
        onHumChange={setHum}
        onInteract={startAudio}
      />
      <section className="hud hud-top">
        <div>
          <p className="eyebrow">Sisyphus Descent / Prototype 01</p>
          <h1>西西弗斯下山</h1>
        </div>
        <button
          type="button"
          className="hud-button"
          onClick={() => setResetSignal((value) => value + 1)}
        >
          Restart loop
        </button>
      </section>
      <section className="hud hud-bottom">
        <div className="status-grid">
          <Status label="Phase" value={hud.phaseLabel} />
          <Status label="Camera" value={hud.cameraMode} />
          <Status label="Ascent" value={`${Math.round(hud.ascentSeconds)}s`} />
          <Status label="Trail" value={`${hud.trailPoints}`} />
          <Status label="Hum" value={audioStarted ? `Lv ${hum.rewardLevel}` : 'Click'} />
        </div>
        <p className="prompt">{hud.prompt}</p>
        <p className="controls">WASD move · Mouse look after click · Hold W near the stone to push</p>
      </section>
      <Leva collapsed={false} />
    </main>
  )
}

function Status({ label, value }: { label: string; value: string }) {
  return (
    <div className="status">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  )
}

export default App

import { useCallback, useEffect, useRef } from 'react'

const odeMotif = [329.63, 329.63, 349.23, 392, 392, 349.23, 329.63, 293.66]

export function useHumSynth(clarity: number, rewardLevel: number) {
  const contextRef = useRef<AudioContext | null>(null)
  const oscillatorRef = useRef<OscillatorNode | null>(null)
  const gainRef = useRef<GainNode | null>(null)
  const filterRef = useRef<BiquadFilterNode | null>(null)
  const stepRef = useRef(0)

  const start = useCallback(() => {
    if (contextRef.current) {
      void contextRef.current.resume()
      return
    }

    const AudioContextClass = window.AudioContext || window.webkitAudioContext
    const context = new AudioContextClass()
    const oscillator = context.createOscillator()
    const gain = context.createGain()
    const filter = context.createBiquadFilter()

    oscillator.type = 'sine'
    oscillator.frequency.value = odeMotif[0]
    filter.type = 'lowpass'
    filter.frequency.value = 480
    gain.gain.value = 0

    oscillator.connect(filter)
    filter.connect(gain)
    gain.connect(context.destination)
    oscillator.start()

    contextRef.current = context
    oscillatorRef.current = oscillator
    gainRef.current = gain
    filterRef.current = filter
  }, [])

  useEffect(() => {
    const interval = window.setInterval(() => {
      const context = contextRef.current
      const oscillator = oscillatorRef.current

      if (!context || !oscillator) {
        return
      }

      const motifLength = Math.min(odeMotif.length, 3 + rewardLevel * 2)
      const frequency = odeMotif[stepRef.current % motifLength]
      oscillator.frequency.setTargetAtTime(frequency, context.currentTime, 0.08)
      stepRef.current += 1
    }, 520)

    return () => window.clearInterval(interval)
  }, [rewardLevel])

  useEffect(() => {
    const context = contextRef.current
    const gain = gainRef.current
    const filter = filterRef.current

    if (!context || !gain || !filter) {
      return
    }

    const normalized = Math.max(0, Math.min(1, clarity))
    gain.gain.setTargetAtTime(0.018 + normalized * 0.08, context.currentTime, 0.2)
    filter.frequency.setTargetAtTime(440 + normalized * 1300, context.currentTime, 0.25)
  }, [clarity])

  return { start }
}

declare global {
  interface Window {
    webkitAudioContext?: typeof AudioContext
  }
}

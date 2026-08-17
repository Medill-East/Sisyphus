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

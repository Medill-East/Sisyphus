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

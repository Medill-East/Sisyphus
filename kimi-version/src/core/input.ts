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

const clamp1 = (v: number) => Math.max(-1, Math.min(1, v))

export function mergeIntents(a: InputIntent, b: InputIntent): InputIntent {
  return {
    move: { x: clamp1(a.move.x + b.move.x), z: clamp1(a.move.z + b.move.z) },
    lookDelta: { x: a.lookDelta.x + b.lookDelta.x, y: a.lookDelta.y + b.lookDelta.y },
    leftHand: Math.max(a.leftHand, b.leftHand),
    rightHand: Math.max(a.rightHand, b.rightHand),
    reset: a.reset || b.reset,
  }
}

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
    // Stuck-key guard: losing focus or pointer lock mid-hold must not leave
    // phantom keys pressed (that reads as "the character creeps on its own").
    addEventListener('blur', () => this.keys.clear())
    document.addEventListener('pointerlockchange', () => {
      if (!document.pointerLockElement) this.keys.clear()
    })
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

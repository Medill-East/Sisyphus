import RAPIER from '@dimforge/rapier3d-compat'
import { Game, type InputSource } from './core/Game'
import { autoFromUrl } from './dev/autoDriver'
import { IDLE_INTENT, type InputIntent } from './core/input'

// Human input source arrives with the camera rig (Task 9); until then an idle
// source keeps the world inspectable, and ?auto= drives scripted beats.
class IdleSource implements InputSource {
  poll(): InputIntent {
    return IDLE_INTENT
  }
}

await RAPIER.init()
const source = autoFromUrl() ?? new IdleSource()
const game = new Game(document.body, source)
game.start()
;(window as unknown as { __game?: Game }).__game = game

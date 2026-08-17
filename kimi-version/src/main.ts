import RAPIER from '@dimforge/rapier3d-compat'
import { Game } from './core/Game'
import { autoFromUrl } from './dev/autoDriver'
import { CameraRig } from './camera/CameraRig'
import { HumanSource } from './core/humanSource'

await RAPIER.init()
const cam = new CameraRig()
const auto = autoFromUrl()
const game = new Game(document.body, auto ?? new HumanSource(document.body, cam), cam)
game.start()
;(window as unknown as { __game?: Game }).__game = game

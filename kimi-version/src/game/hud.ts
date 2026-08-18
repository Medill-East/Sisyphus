import type { RunState } from './phases'

const HINTS: Record<string, string> = {
  approach: '走近石头 · WASD 移动 / 鼠标环顾（手柄先按任意键激活）',
  engaged: 'W 顶住 + 按住 左键/右键（或 LT/RT）双手用力 · 单手修正方向',
  release: '放手吧',
  descent: '走下山去',
  result: '',
}

/** Minimal DOM overlay: one contextual hint + a result panel. */
export class Hud {
  private readonly el: HTMLDivElement

  constructor() {
    this.el = document.createElement('div')
    this.el.style.cssText =
      'position:fixed;left:0;right:0;bottom:6vh;text-align:center;color:#fff;' +
      'font:15px/1.6 system-ui;text-shadow:0 1px 4px rgba(0,0,0,.6);pointer-events:none'
    document.body.appendChild(this.el)
  }

  update(run: RunState): void {
    if (run.phase === 'result') {
      this.el.innerHTML =
        `上山用时 ${run.ascentSeconds.toFixed(1)} 秒 · 回滚 ${run.rollbacks} 次<br>` +
        `<span style="opacity:.75">再次把手放上去，就是新的一程</span>`
    } else {
      this.el.textContent = HINTS[run.phase] ?? ''
    }
  }
}

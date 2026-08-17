import { chromium } from 'playwright'
import { mkdirSync } from 'node:fs'
import { spawn, type ChildProcess } from 'node:child_process'

const BEATS = (process.argv[2] ?? 'rest').split(',')
const PORT = 4173
const URL_BASE = `http://localhost:${PORT}`

async function main() {
  mkdirSync('evidence', { recursive: true })
  const server: ChildProcess = spawn('npm', ['run', 'preview'], { stdio: 'ignore', shell: true })
  await new Promise((r) => setTimeout(r, 2500))
  const browser = await chromium.launch()
  try {
    for (const beat of BEATS) {
      const [name, dur] = beat.split(':')
      const page = await browser.newPage({ viewport: { width: 1280, height: 720 } })
      page.on('console', (m) => console.log(`[${name}]`, m.text()))
      await page.goto(`${URL_BASE}/?auto=${name}&t=${dur ?? '3'}`)
      await page.waitForFunction(() => (window as unknown as { __beatReady?: boolean }).__beatReady, null, { timeout: 30000 })
      const state = await page.evaluate(() => (window as unknown as { __game?: { debugState?: () => unknown } }).__game?.debugState?.())
      console.log(`[${name}] state:`, JSON.stringify(state))
      await page.screenshot({ path: `evidence/${name}.png` })
      console.log(`captured evidence/${name}.png`)
      await page.close()
    }
  } finally {
    await browser.close()
    server.kill()
  }
}

main().catch((e) => {
  console.error(e)
  process.exit(1)
})

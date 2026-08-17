# 西西弗斯下山 · Kimi Version (MVP)

Clean-room web build: first-person, physically honest push-the-stone loop.
Spec: `../docs/superpowers/specs/2026-08-18-kimi-version-mvp-design.md`
Plan: `../docs/superpowers/plans/2026-08-18-kimi-version-mvp.md`

## Run

    npm install
    npm run dev        # http://localhost:5178

## Controls

- WASD 移动 · 鼠标环顾（点击画面锁定指针）
- 鼠标左键 = 左手用力 · 右键 = 右手用力
- 手柄：左摇杆移动 · 右摇杆环顾 · LT = 左手 · RT = 右手（模拟量，带震动）
- R = 复位（调试用）

## Verify

    npm run test       # vitest: 物理契约 + 纯逻辑（Node 内跑 Rapier）
    npm run build
    npx tsx scripts/capture.ts rest:2,hover:2.5,press:4,left:4,release:55,descent:85
    # 截图落在 evidence/，并打印每个节拍结束时的机器可读状态

# ProjectProgress

> 现状快照，覆盖写，不堆历史。历史看 roadmap.md。

*更新于 2026-08-18 02:12 · 记录者 Kimi*

## 现在在哪

- `kimi-version/`（Web 干净重写版）MVP 已落地：TypeScript + three.js + Rapier + Vite，推→放→下完整循环可玩，46 项 vitest 数值断言全绿，六个节拍（rest/hover/press/left/release/descent）Playwright 截图证据目检通过。
- 物理按 2026-08-18 设计规格执行：接触几何诚实（左手推→石头向右偏）、镜头与发力解耦、松手回滚真实、静息起动需要突破阈值、推力随手速衰减（推得住但追不上）。
- 旧 Godot 工程、`web-prototype/`、`UE_Sisyphus/` 均未改动，维持原状作参考。
- 待真人试玩验收：手感（重量/起动/救球）只能由人判断，机器证据已齐。

## 当前阶段

Kimi Version MVP 已建成待试玩。范围：一座山（前后两坡+岭线）、一块石头、第一人称双手推球、完整迷你循环；明确不含 7 关、天气、哼唱、障碍、菜单、存档。

## 下一步

1. 無涘真人试玩（键鼠 + 手柄）：`cd kimi-version && npm run dev` → http://localhost:5178
2. 按试玩反馈迭代手感参数（`src/core/tuning.ts` 单一调参口）
3. 试玩认可后再谈：下山侧内容、美学深化、是否回填进主线 Godot 工程

## 阻塞 / 待定

- 手感终审只能由人完成（同 Godot 版的 Human Feel Gate 一个道理）
- 下山节拍的下坡"看什么"还薄（暖光已做，观察点未做）

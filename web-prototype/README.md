# Sisyphus Descent Web Prototype

Playable Web/Three.js prototype for the first vertical slice of `西西弗斯下山`.

## Run

```bash
npm install
npm run dev
```

Open the local Vite URL, usually `http://127.0.0.1:5173/`.

## Controls

- Click the 3D scene once to enable mouse look and synthetic humming audio.
- `WASD` moves Sisyphus.
- Hold `W` close to the stone to push it uphill.
- After the stone reaches the summit, walk downhill through the new growth and return to the stone.

## Prototype Scope

- Single introductory level only.
- Dynamic phase loop: approach, ascent, release, descent, complete.
- R3F scene with Rapier physics, a low-poly mountain, a heavy stone, and trail growth.
- WebAudio synthesizes a hum motif inspired by the opening of `Ode to Joy`; no external audio files are used.
- Leva tuning panel exposes mass, friction, push force, slope, resistance, camera blend, hum clarity, and trail growth.

## Checks

```bash
npm test
npm run lint
npm run build
```

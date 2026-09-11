# Daybeat — Highlight object studio

10 September 2026 · Interactive code artifact · No native app changes

A working browser prototype of sixteen collectible Highlight badges. Every object is assembled from actual 3D meshes. Materials, light, orientation, wireframe, and component separation change the live render. The prototype contains **no AI-generated images**. The default memory landscape is drawn procedurally in code; the photo picker can replace it with a local image held only in browser memory.

## Open the studio

The current New forms preview runs at **http://127.0.0.1:54528/?object=ribbon&forms=3**.

To start it again from this directory:

```sh
python3 -m http.server 54528 --bind 127.0.0.1
```

Then open http://127.0.0.1:54528 in a browser supporting WebGL2. A local HTTP server is needed for ES modules and the packaged font. All runtime dependencies are vendored; the studio makes no external network requests.

### Collection update · 11 September 2026

Collection now prepares uncached objects between browser frames, shows progress, and cancels preparation when another view is selected. Rear-logo projection uses a spatial lookup and reuses repeated surface samples. Every logo vertex, normal and UV remains identical across all twenty current variants. The first Collection opening measured 1.3 seconds in the browser regression run; cached arrangement switches reuse the existing models. See `../collection-fix/README.md` and run `node ../verify-collection.cjs` for the focused regression checks.

## What to inspect

1. **Reference trio** compares the stopwatch, hourglass, and locket under one light.
2. Select a badge below the viewer for a larger individual view. All sixteen kinds are available.
3. Drag horizontally to rotate; drag vertically for a bounded pitch. Scroll to zoom. Front, Side, and Reverse provide direct keyboard-accessible poses.
4. **Separate components** moves the actual meshes and turns to an oblique view so their construction remains visible. Returning to zero restores the preceding pose.
5. **Crafted / All metal / Clay** compares material treatment with the same geometry. Wireframe exposes the mesh structure.
6. Move the studio light and metal roughness controls to inspect how the surfaces respond.
7. **Full turn** performs a finite opening rotation, then becomes still. Touch takes over immediately. Reduce Motion resolves the opening directly.
8. **Collection** shows all sixteen objects together. Select any named button below it to inspect that badge.
9. In the locket view, choose a local photo to test the actual window. It is center-cropped for this prototype, never uploaded, and resettable.

## Package

| File | Purpose |
| --- | --- |
| `index.html` | Accessible controls and local studio entry point |
| `studio.css` | Responsive desktop/mobile presentation |
| `objects.js` | Sixteen mesh builders, material palette, inset geometry, inscriptions, and procedural memory scene |
| `studio.js` | Scene, reflection environment, light rig, interaction, animation, and local photo handling |
| `DESIGN-SPEC.md` | Design decisions, implemented scope, limitations, and native delivery stages |
| `verify.cjs` | Browser interaction and rendering checks using Playwright |
| `verification/` | Screenshots of the actual running prototype and the verification result |
| `vendor/` | Pinned Three.js, font helpers, font, and polygon-offset library |
| `THIRD-PARTY.md` | Versions, licenses, and primary technical references |

## Verification

The check script uses an isolated headless Chromium profile. With Playwright available to Node and the local server running:

```sh
node verify.cjs
```

Set `BADGE_CHROME` to an alternate Chromium executable if necessary. The default executable is the installed macOS Google Chrome. The script checks all sixteen selectors, the three reference meshes, front/side/reverse poses, component separation, material changes, moving light, full-turn completion, direct dragging and snap, Reduce Motion, idle rendering, mobile reflow, console errors, and runtime network locality. See `verification/results.json` for the completed result.

This is a desktop/browser design prototype. It does not measure native iOS performance or reproduce the native accessibility tree. No app source, achievement engine, HealthKit history, native dependency, or installation was changed.

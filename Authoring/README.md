# Optional mesh authoring tools

A self-contained WebGL2 study with sixteen code-authored 3D objects, material/light controls, component inspection, and alternate swept forms. The example collection originated in Daybeat; dates, counts, inscriptions, and the procedural landscape are synthetic fixtures. It has no dependency on the Daybeat application.

Element Studio testing takes place in the native SwiftUI/RealityKit app on an iOS simulator or connected iPhone. Follow [native validation](../Documentation/NATIVE-VALIDATION.md). This directory preserves mesh source and the historical WebGL study; it is not the product test harness.

## Historical study preview

From the repository root:

```sh
python3 -m http.server 8786 --bind 127.0.0.1 --directory Authoring
```

Open http://127.0.0.1:8786 in a WebGL2 browser. All runtime modules, fonts, and textures are vendored. The browser does not save arbitrary slider adjustments; record them or use the native saved-look library. Local photo selection stays in browser memory.

Use clay, front/side/reverse, mesh inspection, separated components, moving light, and the finite full turn to judge construction. The controls directly change meshes/materials. The scene stops rendering at rest and respects Reduce Motion. [The original design study](DESIGN-SPEC.md) records historical intent; [the learning map](../Documentation/LEARNING-MAP.md) and skills explain current refinements and their limits.

## Install developer tools

Node 20+ is required only for mesh export:

```sh
npm ci
npx playwright install chromium
```

The default is Playwright's managed Chromium. Optionally set `STUDIO_CHROME` to an existing compatible Chromium executable; no personal Chrome path or agent-bundled runtime is assumed. Linux environments may need Playwright's documented OS dependencies. Python's server is still a separate terminal process.

## Export candidate native meshes

```sh
node export-meshes.cjs http://127.0.0.1:8786/ --output build/mesh-candidate ribbon returning
python3 scripts/check_repository.py --geometry build/mesh-candidate
```

Omit IDs to export all current variants. `--live` removes fixture inscriptions and supplies a sampled surface grid for a consuming application's marks. `--help` documents options. The default output is ignored `build/mesh-export`; existing outputs require explicit `--overwrite`. Review and preserve existing editions before promoting files into `Resources/`, then build and inspect the promoted geometry in the native app.

The exporter includes named parts, PBR roles, UVs, normals, and index buffers. See [native transfer](../skills/procedural-3d-geometry/references/native-transfer.md). Current builders do not regenerate every preserved historical edition.

## Regenerate environment and surface maps

The environment generator needs only Python's standard library. The surface generator additionally needs NumPy; use a virtual environment (Python 3.10 to 3.12 is suitable for the pinned version):

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r scripts/requirements-authoring.txt
python3 scripts/make-environment.py --output build/generated/ElementStudio-environment.bin
.venv/bin/python scripts/make-surface-textures.py --output build/generated --browser-output build/generated/browser
```

Both generators refuse existing outputs unless `--overwrite` is explicit. These scripts preserve the original authored formulas and seed. The HDR environment must remain 1024 × 512 linear float RGBA unless the native loader also changes. Surface maps encode slopes and roughness rather than painted highlights. Native refinement prepares quieter normals once, then selects cached levels during edits.

## Source and licenses

`objects.js` builds the collection; `forms.js` contains continuous loop/ribbon studies; `brand-mark.js` fits the example reverse mark; `studio.js` owns scene/light/interaction; `studio.css` and `index.html` present the inspector. Retain `vendor/` and [third-party notices](THIRD-PARTY.md) when reusing the browser source. The [asset provenance record](../Documentation/ASSET-PROVENANCE.md) explains generated and historical inputs.

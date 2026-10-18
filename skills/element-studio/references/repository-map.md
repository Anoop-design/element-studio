# Reference repository and commands

The reference repository is `Anoop-design/element-studio` on GitHub. A private checkout requires permission until its owner publishes it. Skills remain readable without cloning it. Paths below are relative to a checkout root containing `ElementStudio.xcodeproj`, `Sources`, and `Authoring`; they are not relative to an installed skill directory. Ask for the checkout location or locate those markers in the current workspace. Do not assume a personal directory.

| Task | Entry point |
| --- | --- |
| Reuse neutral native Swift shapes | `Sources/StudioExampleShapes.swift`, `Sources/StudioExampleAsset.swift`, `Tests/ExampleShapeTests.swift` |
| Build a procedural object | `Authoring/objects.js`: `buildBadge`, `part`, `lathe`, `castMedal` |
| Swept forms | `Authoring/forms.js`: `shell`, `patch`, `buildFormStudy` |
| Browser light/interaction | `Authoring/studio.js`: `studioEnvironment`, `initializeLights` |
| Native mesh transfer | `export-meshes.cjs`, `Sources/ElementStudioAssets.swift` |
| Native materials | `ElementStudioMaterials.make`, `applySculptedSurface`, `softenedNormal` |
| Native shader | `Sources/ElementStudio-Glass.metal`: `elementStudioGlass` |
| Scene/light/lifecycle | `Sources/ElementStudioRenderer.swift` |
| Camera math | `Sources/StudioCameraGeometry.swift` |
| Parameters and revisions | `Sources/ElementStudioSettings.swift` |
| Undo/precise input | `Sources/StudioEditing.swift`, `Sources/StudioInspector.swift` |
| Persistence/import | `Sources/StudioLibrary.swift` |
| PNG export | `Sources/StudioShareView.swift`, renderer `snapshot` |
| Regenerate HDR/maps | `scripts/make-environment.py`, `scripts/make-surface-textures.py` |

From the checkout, build and test the native app:

```sh
python3 scripts/check_repository.py
python3 scripts/test-native.py
```

Read [native validation](native-validation.md) for explicit simulator/device destinations, signing, isolated review storage, captures, and acceptance evidence. Native testing needs Xcode and Python, with no browser or Node dependency. Keep DerivedData under `build/`; keep bundle identifiers stable when updating an existing installation. No Daybeat checkout is required.

Only when changing procedural source assets, install the locked export tools with `npm ci` and `npx playwright install chromium`, then serve `Authoring` on loopback and export candidates:

```sh
python3 -m http.server 8786 --bind 127.0.0.1 --directory Authoring
# In another terminal:
node export-meshes.cjs http://127.0.0.1:8786/ --output build/mesh-candidate ribbon
python3 scripts/check_repository.py --geometry build/mesh-candidate
```

This is asset generation, not app testing. Inspect candidate buffers and preserve previous editions before promotion into Resources. Validate promoted geometry in the native app. Run `node export-meshes.cjs --help` for the export interface.

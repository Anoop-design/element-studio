# Reference repository and commands

The reference repository is `Anoop-design/element-studio` on GitHub. A private checkout requires permission until its owner publishes it. Skills remain readable without cloning it. Paths below are relative to a checkout root containing `ElementStudio.xcodeproj`, `Sources`, and `Authoring`; they are not relative to an installed skill directory. Ask for the checkout location or locate those markers in the current workspace. Do not assume a personal directory.

| Task | Entry point |
| --- | --- |
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

From the checkout, preview the browser studio with:

```sh
python3 -m http.server 8786 --bind 127.0.0.1 --directory Authoring
```

Open `http://127.0.0.1:8786`. Runtime modules are vendored. Developer verification/export needs `npm ci` and `npx playwright install chromium` first. In another terminal:

```sh
npm run verify:browser
node export-meshes.cjs http://127.0.0.1:8786/ --output build/mesh-candidate ribbon
```

Inspect candidate files before replacing Resources. Run `node export-meshes.cjs --help` for the full interface.

For the native app, use a full Xcode installation that supports the project (iOS 26 deployment floor). Discover available destinations with `xcodebuild -project ElementStudio.xcodeproj -scheme ElementStudio -showdestinations`, then use the chosen simulator ID:

```sh
xcodebuild -project ElementStudio.xcodeproj -scheme ElementStudio   -destination 'platform=iOS Simulator,id=SIMULATOR_ID' -derivedDataPath build build
```

Replace the final action with `test -only-testing:ElementStudioTests` for unit tests. UI tests use `ElementStudioUITests` and review-mode storage. Keep DerivedData under `build/`. A simulator needs no personal development team; device signing uses the contributor's own team. Keep bundle identifiers stable when updating an existing installation. No Daybeat checkout is required.

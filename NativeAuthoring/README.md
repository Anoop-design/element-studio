# Native Swift authoring

All sixteen Daybeat recipes and four additional Comeback/ribbon study variants are editable Swift. The app also includes the three neutral runtime generators in `Sources/StudioExampleShapes.swift`. No JavaScript, browser, npm, or third-party geometry package is needed.

The dependency-free Swift package runs on macOS 13+ with a Swift 6 toolchain and full Xcode. Open the iOS app with `ElementStudio.xcodeproj`; the root `Package.swift` builds the separate authoring command and its host tests.

```sh
swift test
swift run -c release ElementStudioAuthor --output build/mesh-export
python3 scripts/check_repository.py --geometry build/mesh-export
```

Select recipes or make a template without synthetic inscriptions:

```sh
swift run -c release ElementStudioAuthor --output build/flame-study --ids energy
swift run -c release ElementStudioAuthor --output build/ribbon-study --ids ribbon,ribbon-curved,ribbon-ceramic
swift run -c release ElementStudioAuthor --output build/live-study --ids returning --live
```

The default exports twenty JSON/binary pairs with `-swift-v1` IDs and two versioned procedural PNGs. `--live` prefixes IDs with `live-`, excludes fixture lettering, calendar dots, workout symbols, and the reverse mark, and emits a 101 × 113 front/back projection grid. Surface samples are geometry support, not achievement data. `--no-textures` skips the shared photo/sand images. Unknown or duplicate IDs, missing values and existing output collisions fail. `--overwrite` replaces disposable candidates explicitly. Direct export into the repository's Resources directory is rejected.

## Change a shape

| Source | Editable construction |
| --- | --- |
| `DaybeatShapes.swift` | All sixteen objects: profiles, colors, inset widths, inscription values, marker counts and component separation |
| `FormStudies.swift` | Arrow loops and ribbon variants: centerline, width, thickness, cross-section, notch and fitted letters |
| `Geometry.swift` | Mesh buffers, world/normal transforms, conforming cap refinement, lathe, sphere, capsule, torus and transported tube frames |
| `PathGeometry.swift` | CoreGraphics path operations, contour resampling, hole-aware triangulation, bevels, lips and domed faces |
| `Inscriptions.swift` | Helvetiker outline lettering, runner symbol, surface seating and spatially indexed reverse projection |
| `NativeTextures.swift` | Seeded landscape and sand image generation with CoreGraphics/ImageIO |
| `Export.swift` | Versioned IDs, named parts/material roles, binary serialization, live templates and safe output |
| `Resources/Catalogue.json` | Descriptions for the sixteen base examples |
| `Resources/DaybeatMark.json` | Original sample vector mark, replace when adapting the branding |

Geometry coordinates are right-handed with +Z toward the viewer. Dimensions use the original study scale. Meshes expose positions, unit normals, UVs and triangle indices; adapt those to a RealityKit `MeshDescriptor` as in `Sources/ElementStudioRenderer.swift`. Geometry types do not depend on app state or a private Daybeat checkout. The geometry kernel uses Foundation, simd and CoreGraphics, available on iOS as well as macOS; the executable handles bundle resources, output and command-line options. Preserve the [font license](Resources/FONT-LICENSE.txt) when reusing outlined lettering.

## Review and promote

Keep candidate exports under `build/`. Inspect finite buffers, indices, cap holes, winding, front/side/reverse silhouettes, grazing reflections, clay, separated components, lettering and UV orientation in the native app. Use a new geometry revision when changing a published recipe. The `swift-v1` output suffix is defined in `Export.swift`; change it and add an explicit settings edition before publishing another revision. Never overwrite an existing released edition.

The Swift port uses native filled-path booleans and stroke subtraction for rounded insets. It preserves the authored formulas and dimensions, but its tessellation and offset sampling are not byte-identical to the original implementation. Ear clipping checks filled area and bridges letter counters. Offsets select the largest contour and retain the historical collapse fallback; extend this deliberately for new multi-island designs. Original fixture files are retained unchanged for saved looks.

Promote the reviewed new-version pairs and textures into `Resources`, regenerate the Xcode project with XcodeGen, then run:

```sh
python3 scripts/check_repository.py
python3 scripts/test-native.py
```

`NativeCatalogueTests` renders every Daybeat variant front/reverse, captures both the Swift and preserved geometry for visual comparison, and checks saved-look import/relaunch. `ExampleShapeTests` covers the neutral examples. XCTest captures are real RealityKit output. UI tests exercise the live collection, native controls, edits, save/reopen, mesh inspection and PNG export. See [native validation](../Documentation/NATIVE-VALIDATION.md).

Existing environment and micro-normal fixtures remain reproducible through the Python generators in `scripts/`. Those offline image tools and the maintenance/test helpers do not participate in geometry construction or app rendering:

```sh
python3 -m venv .venv
.venv/bin/pip install -r scripts/requirements-authoring.txt
.venv/bin/python scripts/make-surface-textures.py --output build/surface-candidate
python3 scripts/make-environment.py --output build/environment-candidate.bin
```

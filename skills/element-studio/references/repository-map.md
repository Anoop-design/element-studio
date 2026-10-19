# Reference repository and commands

The reference repository is `Anoop-design/element-studio` on GitHub. The repository is public under MIT, with retained font and third-party notices. Skills remain readable without cloning it. Paths below are relative to a checkout root containing `ElementStudio.xcodeproj`, `Sources`, and `NativeAuthoring`; they are not relative to an installed skill directory. Ask for the checkout location or locate those markers in the current workspace. Do not assume a personal directory.

| Task | Entry point |
| --- | --- |
| Reuse neutral native Swift shapes | `Sources/StudioExampleShapes.swift`, `Sources/StudioExampleAsset.swift`, `Tests/ExampleShapeTests.swift` |
| Build a procedural object | `NativeAuthoring/DaybeatShapes.swift`, `Geometry.swift`: `build`, `part`, `lathe`, `castMedal` |
| Swept forms | `NativeAuthoring/FormStudies.swift`: `shell`, `patch`, `formStudy` |
| Native outlines/inscriptions | `NativeAuthoring/PathGeometry.swift`, `Inscriptions.swift` |
| Native mesh transfer | `NativeAuthoring/Export.swift`, `Sources/ElementStudioAssets.swift` |
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

When changing procedural source assets, build the dependency-free Swift package and export candidates on macOS with full Xcode:

```sh
swift test
swift run -c release ElementStudioAuthor --output build/mesh-candidate --ids ribbon
python3 scripts/check_repository.py --geometry build/mesh-candidate
```

This is asset generation, not app testing. Inspect candidate buffers and preserve previous editions before promotion into Resources. Validate promoted geometry in the native app. Run `swift run -c release ElementStudioAuthor --help` for the export interface. Default IDs use `-swift-v1`; all prior editions remain readable.

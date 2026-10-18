# Element Studio

This is the self-contained Element Studio iOS app. Scheme: `ElementStudio`. Bundle ID: `com.anoop.elementstudio.dev`. iOS floor: 26.0. Its native UI, library, rendering and authored fixtures live here.

- Use a full Xcode installation supporting this project; select it with `DEVELOPER_DIR` or xcode-select. Discover available simulators rather than assuming a device name. No development team is committed; use your own team for device signing.
- This is the canonical independent checkout. Run `xcodebuild -project ElementStudio.xcodeproj -scheme ElementStudio -derivedDataPath build`. No Daywake checkout or app data is required.
- Use a dedicated Element Studio QA simulator for UI work; discover or create one rather than taking over a simulator reviewing another app.
- `project.yml` is the project-generation source; run xcodegen after adding targets or file groups.
- The home screen is only the floating collection, with a top options menu. No search or bottom tab bar. Saved looks and collection management are in the menu. The editor is an in-place camera focus in the same persistent Metal view, never a per-object modal or fresh renderer. Its official `.bottomBar` toolbar uses separate, content-sized native glass buttons for Surface, Light, Form and Reset, centered with flexible outer spacers. Fixed toolbar spacers keep their glass backgrounds separate; never wrap them in a stretched custom HStack. Each tool expands into native controls with a zoom transition from its own button. Keep the selected tool and transition source stable through dismissal. Controls use a background-interactive partial-height sheet so the live viewport stays usable.
- Appearance follows System, Light or Dark: pale gray in light mode, pure black in dark. Catalogue PNGs must be transparent.
- Latest geometry is imported from the Daywake native studio. The original standalone catalogue is preserved under -studio20260911; New forms uses -forms20260910. Library schema 2 migrates version-1 Latest saved looks to Studio original, while the working collection and newly saved looks use Latest. Retain both import compatibility and one-time migration behavior when adding another geometry version.
- Surface exposes only Finish, Texture and Color. Geometry editions remain a saved-data compatibility detail, not an editor picker.
- Camera focus uses a native non-bouncing Spring in projected position and apparent size. Preserve position and velocity when retargeting; layout changes must not restart the full duration. Closing returns to the saved collection camera independently of the selected object's separation setting. Interpolate rendered form and visibility, keeping saved edits unchanged. Keep native toolbar transition sources mounted until an expanded tool has dismissed.
- Three columns, centered final row. One-finger drag rotates all visible objects; pinch is anchored under the fingers; two-finger drag pans. Zoom cannot go below the fitted 1× view; pan bounds follow the content and viewport. Preserve the collection camera when focusing and returning.
- Mesh inspection is transient renderer state, limited to the focused object. Collection load, focus changes, Reset, Save and Share restore filled materials. Never persist the inspection toggle or inherit a legacy wireframe flag into cached catalogue materials. Change only triangle fill mode when leaving inspection so other objects retain their own finishes.
- Keep the native Undo/Redo/reset menu available in compact and expanded tools. Group one slider drag or color session into one undo; view changes do not enter editing history. Reset view preserves appearance; scoped and full edit resets preserve camera and saved looks. Hold-to-compare is transient and clears on dismissal, Save and Share.
- Surface color must reflect the actual authored palette. Present UIColorPickerViewController natively, with a working finish/dismiss path. Exact value entry validates the control range and current locale. Haptic detents fire only during a user drag crossing the original value.
- New work uses surfaceRevision 1 with quieter normal maps; nil retains the legacy material response for saved looks. Do not upgrade saved look materials silently. Cache refined normal maps during preparation, never regenerate them during a slider update.
- Share renders a 1440px PNG with actual alpha, or composites White/Black. Save confirmation follows successful persistence. Keep Save and Share accessible from the editor.
- Tool sheets measure the natural control height. At ordinary text sizes the complete mesh switch fits without scrolling or clipped native switch decoration; scroll only when the available screen cannot contain accessible text. Stack parameter labels and values at accessibility sizes. Keep the native toolbar zoom source stable through measured-height updates.
- Hidden collection roots are disabled after their fade; skip unchanged orientation and part-separation writes. Gyro updates go directly to weakly registered renderers, not through the active SwiftUI editor body. Limit live GPU submissions to two, coalesce pending redraws, and serialize snapshots with the live renderer.
- STUDIO_REVIEW=1 uses a separate cache library; never run interaction QA against the owner’s normal library. STUDIO_FORM_REPLAY=1 additionally runs the repeatable Form adjustment sequence and writes local timing data; it requires STUDIO_REVIEW.
- Keep the initial preview visible until warmup GPU frames have completed. Do not reintroduce a Preparing element surface for selection.
- Metal continuous turns require enableSetNeedsDisplay=false while unpaused; switch back to event-driven rendering when motion settles. Drag rotation must not snap on release.
- Gyro tilt is bounded and smoothed; stop Core Motion when inactive, disabled, or Reduce Motion is on.
- User libraries live in Application Support/Element Studio/library.json. Never reset or uninstall an existing app to deliver a routine update.
- Named looks preserve geometry edition/study, materials, tint, lighting, form and camera. Export/import must preserve them; imports add copies and remap collection IDs.
- Resources contains the stable geometry catalogue. Never overwrite a preserved geometry edition when adding a new version. Authoring contains editable mesh construction; export-meshes.cjs writes candidates under build/mesh-export; promote reviewed fixtures into Resources deliberately.
- Daywake production code and its stored data are independent of this app.

## Portable agent knowledge

Read `skills/README.md` to choose the relevant workflow. Skills are provider-neutral Markdown and have no dependency on a personal path or private tool. Use `element-studio` for authoring/interaction, `procedural-3d-geometry` for mesh work, and `realitykit-materials-lighting` for native materials and shaders. The current native shader is a RealityKit CustomMaterial shader, not a SwiftUI layer effect.

Keep numbers tabular with `.monospacedDigit()` or `font-variant-numeric: tabular-nums`, and reserve stable field widths. Use natural sentences rather than em dashes in new user-facing descriptions.

Run `python3 scripts/check_repository.py` after skill/package changes. Build and test the actual SwiftUI/RealityKit app with `python3 scripts/test-native.py` in a dedicated simulator, or pass `--device DEVICE_UDID --team YOUR_TEAM_ID` for a connected iPhone. Read `Documentation/NATIVE-VALIDATION.md`. Do not run browser-based tests for Element Studio. Only optional mesh export uses `npm ci` and Playwright's managed Chromium, or explicit `STUDIO_CHROME`. Asset generators live in `scripts/`; candidate exports belong under `build/`. Preserve the authored and third-party license notices.

The repository is private during release preparation. Do not change visibility, publish a release, or deploy a site without the owner's explicit request. Historical `DAYWAKE_ELEMENT_*` environment names are diagnostic compatibility aliases; they do not require the Daybeat app.

## Research model preference

Delegate external lookup, repository exploration, and API research to lightweight isolated subagents. Prefer the available Luna model in Codex subscription environments, Haiku for narrow research or Sonnet for harder synthesis in Claude Code. Discover actual model support and avoid silently inheriting an expensive parent model. Keep the main context for implementation, integration, and native validation; workers return concise evidence and conclusions, not raw search logs. Follow `skills/element-studio/references/research-delegation.md` for scope and unavailable-model handling. This is a workflow preference, not a claim about subscription entitlements or permission to use separately billed APIs.

## Native example shapes

The catalogue now has 19 objects: the retained 16 Daybeat examples plus Orbit, Twisted loop, and Stacked pebbles. `StudioExampleShapes.swift` is the independent native generator; its `-v1` IDs preserve saved geometry. `StudioExampleAsset.swift` adapts it to the existing renderer. Review `Documentation/NATIVE-SHAPES.md` before changing these examples. Keep their real native catalogue snapshots current, preserve closed seams and valid normals, and run `ExampleShapeTests` plus the native example UI flow.

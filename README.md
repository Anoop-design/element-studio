# Element Studio

A standalone, native iOS studio for developing 3D elements, materials and Metal shaders, and keeping repeatable visual configurations. Open `ElementStudio.xcodeproj` and select the `ElementStudio` scheme. The Debug app appears on the phone as **Element Studio**, with bundle ID `com.anoop.elementstudio.dev` and its own library. It does not read Daywake data.

<p>
  <img src="Documentation/collection-light.png" width="220" alt="Three-column live collection in light mode">
  <img src="Documentation/toolbar-dark.png" width="220" alt="Native bottom toolbar in dark mode">
  <img src="Documentation/surface-light.png" width="220" alt="Expanded Surface controls">
</p>

[Interaction review and validation](Documentation/REVIEW.md)

## Learn and build with an agent

The repository includes three portable [agent skills](skills/README.md): an interactive 3D authoring workflow, procedural mesh construction, and RealityKit materials/lighting/Metal shaders. They preserve the methods behind the manually tuned objects and can be used in other projects with any coding agent that can read their Markdown. Start with [the learning map](Documentation/LEARNING-MAP.md) to connect each technique to working source.

The [asset authoring guide](Authoring/README.md) covers optional mesh-generation tools and regeneration of the HDR environment and surface textures. App testing always uses the native SwiftUI/RealityKit app in a simulator or on an iPhone. Runtime previews remain offline. [MIT](LICENSE) covers original code, skills, documentation, and assets, subject to the [bundled third-party notices](THIRD-PARTY.md).

This repository is currently private. Preparing these materials does not publish it. See [release preparation](Documentation/OPEN-SOURCE.md).

## Using the app

- **Home:** all sixteen elements share a three-column live 3D canvas. The last row is centered. Drag with one finger to rotate them together, pinch to zoom under your fingers, and drag with two fingers to move around. Zoom out stops at the fitted 1× view; pan limits tighten as you zoom out, so the canvas cannot drift away. Show all resets the view. There is no search or bottom home toolbar.
- **Appearance:** follows System, with Light and Dark overrides in the top menu. Light uses a pale gray canvas; Dark uses pure black.
- **Tilt with iPhone:** bounded, smoothed gyro movement is on by default. The top menu can disable it. Motion stops in the background and with Reduce Motion.
- **Open an element:** tap it to move the camera directly toward that same live object. The scene stays alive; there is no intermediate screen, automatic spin, or per-object preparation message. A non-bouncing native spring carries the same object from its grid position into focus. Closing returns to the exact collection zoom and position, with edited depth and separated parts easing back into the grid. Reversing a transition carries its current motion forward smoothly. Closing with a tool expanded keeps its native toolbar transition intact. Reduce Motion skips the camera flight.
- **Bottom tools:** Surface, Light and Form each have their own native glass button, with Reset separate beside them. The centered controls fit their contents near the home indicator. Selecting a tool opens native controls with a zoom transition from that specific button. The downward chevron collapses them; the live viewport remains usable above the controls.
- **Undo and reset:** the counterclockwise arrow opens Undo, Redo, Reset view, and Reset all edits. Inside a tool it also offers Reset surface/light/form. A complete slider drag or color-picking session is one undoable edit. Reset view keeps your finish; Reset edits keeps your camera. Saved looks remain intact.
- **Surface:** Finish describes Gloss, Satin or Matte; Texture controls fine surface detail. Color shows the actual original color palette and opens Apple’s native picker. The original palette is available by holding the Color row. Tap any displayed control value to enter an exact number. A small mark and subtle detent identify the original slider value. Hold to compare temporarily shows the original appearance without changing your pose or edits. During a session, returning to an object restores its own controls. Existing saved looks retain their original geometry and material response.
- **Light:** direction and brightness.
- **Form:** depth, separated components and optional mesh inspection. Objects start fully shaded. Show mesh applies only to the current object and clears when you return to Collections, open another object, reset, save, share or restart the app.
- **Collections:** use the top menu to select, create, edit or delete a collection. Filtering reuses the live scene.
- **Share look:** the upper-right share control renders a clean 1440 × 1440 PNG of the current object and camera. Choose Transparent, White or Black, inspect the preview, then use Share PNG to choose the destination. Transparent output retains real alpha. Opening the preview does not send anything.
- **Save look (+):** name the current version and choose a collection. Each version keeps geometry edition, study, color, material, lighting, form, and camera angle. Its thumbnail is rendered from that saved state. A brief Saved confirmation and success haptic acknowledge the completed save.
- **Looks:** reopen, rename, favorite, duplicate, and delete saved versions. Export a JSON library through Files or import one. Imports add copies without replacing existing looks.

The catalogue contains 16 authored objects, four preserved prior editions, and six Comeback/ribbon studies. The latest Daywake update brings a continuous enamel flame, a clearer Comeback arrow with its workout symbol, a full six-month medallion, and a numbered activity medal. The alternate Comeback studies also include their workout marks. Earlier standalone geometry remains under -studio20260911, and New forms under -forms20260910. Existing saved looks keep their original geometry through the library migration; new looks use the updated shapes. This is a visual authoring library with bounded controls, not a general polygon modelling application. New mesh families are added in source. There is no account or cloud synchronization; use Export library to keep a portable backup.

## Source of truth

This repository is the canonical home for future app and shader work. The earlier copy inside Daywake is an extraction snapshot. Start with [the architecture guide](Documentation/ARCHITECTURE.md) for shader and renderer entry points.


- `Sources/`: native SwiftUI library, editor, RealityKit/Metal renderer and settings model.
- `Resources/`: authored native geometry fixtures, preserved editions and textures; the app runs fully offline.
- `Authoring/`: editable browser mesh builders and reference studio, including its vendored dependencies and licenses.
- `export-meshes.cjs`: developer conversion of authored browser geometry to native vertex/index buffers. It requires Node and Playwright's managed Chromium. Serve `Authoring` locally and pass that URL explicitly. The default export writes candidates under `build/mesh-export`; preserve previous versions under a new edition before promoting changed geometry.
- `Tests/` and `UITests/`: library round-trip, import isolation, geometry validation, and the create/save/relaunch/open flow.
- `Documentation/`: architecture and review notes. Local `Review/` logs and captures are gitignored.

User configurations are stored atomically at `Application Support/Element Studio/library.json` in the app sandbox. Rendered previews live beside it in `Previews`. Workspace changes autosave; explicitly saved looks remain separate versions. Reinstall updates over the same bundle ID. Do not uninstall the app to update it.

## Build and verify

Use full Xcode and an installed iOS 26+ simulator. From the repository root:

```sh
python3 scripts/check_repository.py
python3 scripts/test-native.py
```

The helper builds the real SwiftUI/RealityKit app and runs unit and UI tests in a dedicated Element Studio QA iPhone simulator. It keeps DerivedData warm and saves logs, test results, and native captures under `build/`. No browser or Node installation is needed for testing.

For a paired, unlocked iPhone, use `python3 scripts/test-native.py --device DEVICE_UDID --team YOUR_TEAM_ID`. No personal signing team is committed. Install updates over the existing bundle ID and use isolated review storage; never uninstall or reset a user's library for QA.

See [native validation](Documentation/NATIVE-VALIDATION.md) for destination discovery, focused tests, signing, device installation, capture commands, and visual acceptance. Use `project.yml` with XcodeGen when changing project structure. iOS 26.0 is the minimum supported version.

Materials are real-time approximations: glass uses a custom shader, and finish/detail controls are bounded artistic settings. Judge the final effect on the target phone as well as in the simulator.

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, verification, and compatibility expectations. Run `python3 scripts/check_repository.py` to validate skill packaging, documentation links, and native mesh buffers.

# Element Studio architecture

The iOS app is self-contained. It has no Swift Package Manager or CocoaPods dependencies and requires iOS 26 or later. Authored examples use synthetic inscriptions; the app does not read HealthKit or another app’s database.

## Shader and material work

- `Sources/ElementStudio-Glass.metal` contains the native custom surface shader. It compiles into the app’s default Metal library.
- `Sources/ElementStudioAssets.swift` owns texture preparation, reflection environment loading, physically based materials, and the `CustomMaterial` shader binding. Add a shader here when an authored material needs it.
- `Sources/ElementStudioSettings.swift` defines bounded, Codable editing parameters. Keep old saved libraries decodable when adding a parameter.
- `Sources/StudioInspector.swift` presents native sliders, validated exact entry, the native color picker and the accessible hold-to-compare control.
- `Sources/StudioEditing.swift` owns parameter metadata, scoped appearance resets and UndoManager gesture transactions. History belongs to the focused editing session; camera changes and mesh inspection are excluded.
- `Sources/StudioShareView.swift` captures once, previews Transparent/White/Black variants and shares a real PNG file with alpha preserved.
- `Sources/ElementStudioRenderer.swift` owns the RealityKit scene and persistent Metal view. Warm assets once, cache unchanged transforms, disable hidden roots after their fade, and stop rendering when motion settles. Two live GPU submissions are allowed; additional draw requests coalesce. Snapshots wait for submitted live frames before using the shared projection. Gyro samples are delivered directly to weakly registered renderers.
- `Sources/StudioCameraGeometry.swift` contains tested layout, camera bounds and `StudioCameraTransition`. The transition uses SwiftUI's native critically damped Spring in projected position and reciprocal depth, so apparent size follows the spring. Retargeting converts world velocity into the new projection, preserving continuity across a reversed or resized transition. The renderer interpolates each object's current opacity and form, while stored appearance remains untouched.

New work uses `surfaceRevision: 1`. Missing revisions decode as nil so previously saved material response remains unchanged. Refined unit normals are prepared and cached once; slider updates select textures. Do not change the geometry edition to revise material response.

## Geometry authoring

`Authoring/objects.js` contains mesh builders. The browser reference is a development tool; no browser runtime ships inside the iOS app. Serve `Authoring/` locally and run `export-meshes.cjs` with its explicit URL to convert geometry into `Resources/` buffers. Preserve published geometry editions because saved looks refer to them. The vendored authoring dependencies retain their licenses in `Authoring/THIRD-PARTY.md`.

## UI and persistence

`ElementStudioApp.swift` composes the collection and focused editor using the same rendering surface. The native bottom toolbar expands into controls through Apple’s zoom transition. Its partial-height sheet measures the controls, including the complete native switch, and allows interaction with the object above it. Ordinary sizes fit without scrolling; accessibility text stacks values and uses a scroll fallback when the screen cannot fit the content. The native reset menu separates view reset, scoped appearance reset, full edit reset, and Undo/Redo. Compare temporarily applies an original appearance and then restores the edit state without changing the camera. Each cached object retains its own editing controls during the session; the existing single workspace and explicitly saved looks remain the persistence contract.

`StudioLibrary.swift` stores the local library atomically and validates imports. Schema 2 accepts version-1 exports and preserves their Latest saved looks using the original standalone geometry edition. Keep this migration one-time: new Latest looks must remain current on subsequent loads. The working collection receives current geometry while saved versions retain their chosen edition. Never uninstall the app or reset its container to deliver an update. Retain `com.anoop.elementstudio.dev` so current libraries survive the repository move.

## Verification

Use `ElementStudioTests` for import, persistence, geometry and camera edge conditions. Use `ElementStudioUITests` for real pinch gestures, reset, native tool controls, collection focus, save/share and light/dark review. Judge shader changes using actual simulator captures and the connected iPhone; compile success alone is not visual validation.

`STUDIO_REVIEW=1` selects a separate cache library for interaction QA. With `STUDIO_FORM_REPLAY=1`, the editor runs 720 depth/separation updates and mesh toggles across four shapes, writing `Library/Caches/ElementStudio-form-replay.json`. This explicit diagnostic path never reads or overwrites the normal library. Replay intervals include the deliberate 16 ms delay and are not frame-rate or CPU-time measurements.

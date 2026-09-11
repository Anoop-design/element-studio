# Element Studio

This is the self-contained Element Studio iOS app. Scheme: `ElementStudio`. Bundle ID: `com.anoop.elementstudio.dev`. iOS floor: 26.0. Its native UI, library, rendering and authored fixtures live here.

- Build with the working Xcode at `/Users/anoop/Downloads/Xcode-beta.app/Contents/Developer`.
- This is the canonical independent checkout. Run `xcodebuild -project ElementStudio.xcodeproj -scheme ElementStudio -derivedDataPath build`. No Daywake checkout or app data is required.
- Use the dedicated Element Studio Interaction QA simulator for UI work; do not take over a simulator reviewing another app.
- `project.yml` is the project-generation source; run xcodegen after adding targets or file groups.
- The home screen is only the floating collection, with a top options menu. No search or bottom tab bar. Saved looks and collection management are in the menu. The editor is an in-place camera focus in the same persistent Metal view, never a per-object modal or fresh renderer. Its official `.bottomBar` toolbar expands into native controls with a zoom transition from the toolbar. Controls use a background-interactive partial-height sheet so the live viewport stays usable.
- Appearance follows System, Light or Dark: pale gray in light mode, pure black in dark. Catalogue PNGs must be transparent.
- Latest geometry is imported from the Daywake native studio. New forms points to preserved -forms20260910 assets so older looks retain their geometry.
- Surface exposes only Finish, Texture and Color. Geometry editions remain a saved-data compatibility detail, not an editor picker.
- Three columns, centered final row. One-finger drag rotates all visible objects; pinch is anchored under the fingers; two-finger drag pans. Zoom cannot go below the fitted 1× view; pan bounds follow the content and viewport. Preserve the collection camera when focusing and returning.
- Reset edits must remain available, and must not delete saved looks. Keep Save and Share accessible from the editor.
- Keep the initial preview visible until warmup GPU frames have completed. Do not reintroduce a Preparing element surface for selection.
- Metal continuous turns require enableSetNeedsDisplay=false while unpaused; switch back to event-driven rendering when motion settles. Drag rotation must not snap on release.
- Gyro tilt is bounded and smoothed; stop Core Motion when inactive, disabled, or Reduce Motion is on.
- User libraries live in Application Support/Element Studio/library.json. Never reset or uninstall an existing app to deliver a routine update.
- Named looks preserve geometry edition/study, materials, tint, lighting, form and camera. Export/import must preserve them; imports add copies and remap collection IDs.
- Resources contains the stable geometry catalogue. Never overwrite a preserved geometry edition when adding a new version. Authoring contains editable mesh construction; export-meshes.cjs writes to this app's Resources.
- Daywake production code and its stored data are independent of this app.

# Element Studio interaction review

## Open and close refinement — 12 September 2026

Opening now follows a native, critically damped spring in projected position and apparent size. The selected object grows directly from its collection position with a quicker response and a soft landing. Surrounding objects fade early enough to avoid enlarged shapes lingering behind it. The rendered rotation stays continuous, and a reversed or retargeted camera carries its current position and velocity.

Closing restores the exact collection zoom and pan. An object's separation setting no longer changes the collection fit, and its form folds back smoothly while retaining its edits. Closing from expanded controls keeps the native toolbar's transition source mounted until dismissal completes. Publishing a destination's controls now follows focus selection atomically, preserving each object's current-session finish when moving between objects. Reduce Motion disables the camera transition and stays outside edit history.

Validation: 20 unit tests passed in `StudioTransitionVerification.xcresult`, including native-spring projection, monotonic scale, reversal continuity, retargeting and exact endpoints. The updated Reduce Motion/history case passed in `StudioTransitionFinalUI.xcresult`. All six UI flows passed across the verification runs: the complete 16-object catalogue, exact collection framing, dark appearance, mesh isolation, native color selection, and precise editing/undo/compare/export. The broad run exposed a finish-restoration ordering issue; after its fix, both affected flows passed again with zero failures (98.269 seconds, `StudioTransitionFinishVerification.xcresult`). The final framing flow checks three collection positions, a zoomed collection, direct close from separated Form controls, and restoration of the edited separation on reopening.

The final native simulator recording was reviewed frame by frame through opening, focus and return. [Watch the actual open/close animation](open-close.mp4). No frame-rate measurement is claimed.

The final signed Debug build succeeded and was installed over the existing app on the connected iPhone 16 Pro Max. A monitored launch and actual device screenshot confirmed a fully shaded focused object and the native controls. Before/after library comparison confirmed that collections and saved looks were unchanged. Device captures and library backups remain local in the ignored Review directory.

## Editing polish — 12 September 2026

The compact native toolbar still contains four separate buttons. The controls now show accurate original color palettes, use the native color picker, and describe Finish as Gloss/Satin/Matte. Tapping a displayed value opens validated exact entry. Original-value marks and user-drag haptic detents help return to a reference value. The Undo/Redo menu groups a slider drag or color-picking session into one edit and separates view reset from scoped/full appearance resets.

Hold to compare temporarily restores the original appearance while retaining the camera and the current edit. It clears on release, tool dismissal, Save and Share; VoiceOver can toggle it. Switching objects restores each object's current-session controls. Fast touch selection can interrupt the return flight, while accessibility targets appear once their moving frames settle.

New material defaults use quieter dial and glaze normals, gentler brushed anisotropy, and softer enamel reflections. Refined normals are prepared once and cached. Missing surface revisions continue to use the previous material response, preserving old saved looks. The PNG export preview offers Transparent, White and Black; exports use actual 1440px PNG files. Save acknowledges successful persistence with a brief Saved title/checkmark and success haptic.

Validation: all 18 unit tests passed (10.5 seconds, `StudioPolishUnitVerification.xcresult`), including edit transaction grouping, no-op/view exclusions, scoped reset, locale/range validation, legacy material decoding, and transparent/background PNG pixels. All five UI flows passed together with zero failures (270.9 seconds, `StudioPolishFinalUI.xcresult`): all 16 objects open and rotate, bounded gestures, Save/relaunch, Light/Dark, mesh isolation, native color selection/undo, precise edit/undo/redo, compare, view reset, per-object controls, and three export backgrounds. The Light panel was then given 24pt more height after screenshot review found clipped endpoint labels; its targeted dark-mode flow passed again (`StudioLightSpacingVerification.xcresult`), and the complete labels were visually confirmed. All 16 native transparent launch previews were regenerated and checked as 600 × 600 RGBA PNGs.

Selected native captures: [Surface in light mode](surface-light.png), [Surface in dark mode](surface-dark.png), [Light controls](light-dark.png), [custom color](custom-color.png), [Undo and reset](undo-reset.png), [precise entry](precise-entry.png), [transparent export](share-transparent.png).

The final signed Debug build succeeded and was installed over the existing app on the connected iPhone 16 Pro Max. A monitored launch and actual device screenshot confirmed the full shaded collection with the updated material response. Local before/after library comparison confirmed that collections and saved looks were unchanged. Device captures and library backups remain in the ignored Review directory.

## Previous verification — 11 September 2026

Verified from this independent checkout using the ElementStudio scheme on the dedicated iPhone 17 Pro / iOS 27 simulator.

- 12 unit tests passed: library persistence/import isolation, every preserved geometry edition, three-column placement, centered final row, fitted-view pan lock, zoomed content-edge limits, camera-flight endpoints/magnification, and minimum saved zoom.
- 2 UI tests passed: real pinch gestures stop at minimum zoom and enlarge the scene; all 16 objects open and rotate; Surface/Light/Form controls work; Reset restores edited lighting; Share produces a clean image; a saved look survives relaunch; native toolbar and dark mode work; dragging the object above expanded controls changes its orientation without dismissing the controls.
- Actual screenshots were reviewed in light and dark, including the collection, compact toolbar, expanded controls, rotated shapes, and share preview. Selected captures are saved alongside this note.

## Separate toolbar controls follow-up

The two simulator UI flows were rerun after separating the toolbar controls and passed with zero failures (133.9 seconds, `SeparateToolsVerification.xcresult`). This includes Surface → Light → Reset → Form, Share, Save/relaunch, every object, and dark-mode rotation above expanded controls. The dark toolbar capture has been refreshed from this passing run. The earlier unit results above remain the baseline; camera, library and geometry code did not change in this follow-up.

## Shaded collection follow-up

A persisted mesh-inspection flag was being applied to every cached object at scene load. Turning it off while focused updated only that object, leaving a mixture of filled surfaces and see-through triangle edges in the collection. Mesh inspection now lives in the renderer, is limited to the focused object, and clears on focus changes, Reset, Save, Share and scene load. Existing materials return to filled triangles without replacing their individual finishes. Legacy settings cannot initialize the catalogue in wireframe.

The dedicated mesh regression passed (49.6 seconds, `ShadedCollectionVerification.xcresult`): enable mesh, change a material, return to the collection, open another object, reopen the inspected object, and relaunch while inspection is active. Captures confirm filled surfaces after each return and relaunch. Both the fronts and backs of the collection were reviewed; see `collection-shaded.png` and `collection-backs.png`.

## Latest Daywake shapes follow-up

The current native Daywake catalogue was compared against this standalone app. Six asset pairs changed: the continuous red enamel flame, rounded amber Comeback arrow, six-lobed 6 MONTHS medallion, upright 12 WEEKS activity medal, and both alternate Comeback studies with workout symbols. Native fixture geometry and its authoring source were imported together. `geometry-sync-20260911.json` records the imported file hashes. All sixteen transparent initial previews were regenerated by the native renderer.

The entire original standalone edition is retained under `-studio20260911`. Library schema 2 pins version-1 Latest saved looks to that edition on load and import. Their identifiers, material settings and camera remain intact; the working collection and newly saved looks use current shapes. A migration regression checks old looks, newly saved looks after relaunch, and legacy imports.

All 12 unit tests passed (9.8 seconds, `GeometrySyncVerification.xcresult`). Both interaction UI tests passed again with zero failures (131.2 seconds, `UpdatedFormsVisualVerification.xcresult`), including all 16 selections/rotations, bounded pinch, toolbar controls, Reset, Share, saved-look relaunch and dark mode. Four successive poses of each redesigned primary shape were captured and visually reviewed. The solid faces, reverse plates and edge thickness remain continuous. Fresh light and dark collection captures, plus a complete reverse collection view, are saved alongside this note. The final dark capture was taken after the complete catalogue had rendered; the early test attachment preceded some inscriptions appearing.

Selected native captures: [flame](updated-energy.png), [Comeback](updated-returning.png), [six months](updated-halfYear.png), [activity weeks](updated-activity.png), [dark collection](collection-shaded.png), [reverse collection](collection-backs.png).

The updated Debug device build succeeded and was installed over the existing iPhone app. A monitored launch remained running, and an actual iPhone screenshot confirmed the complete updated collection with filled surfaces and visible inscriptions. No app uninstall or library reset was performed. Personal device captures remain local in the ignored Review directory.

## Interaction design

The full collection is the minimum 1× view. At that scale the camera cannot pan beyond the content. Pinch follows its finger anchor; at higher magnification, pan stops at the visible content edges. Focus transitions use a native spring in projected position and apparent size, so an object opens directly from its collection position. Closing restores the exact collection camera; interruptions carry position and velocity into the new destination.

The bottom bar is an official SwiftUI bottomBar toolbar. Surface, Light, Form and Reset each have their own native glass background, separated with fixed toolbar spacers and centered with flexible outer spacers. There is no full-width custom container. Native partial-height controls zoom from the selected tool’s button and return to that same button on dismissal. Their content and detent remain stable throughout dismissal. They allow interaction with the viewport above them. Matched transition sources stay mounted during presentation; changing their accessibility visibility mid-transition left native buttons unresponsive after dismissal. The UI flow verifies the selected control title, real slider edits, and subsequent tool activation. This avoids trying to stretch a fixed-height toolbar beyond its supported bounds. Reset is available in both compact and expanded states. Saved looks remain separate from workspace resets.

Repeated writes of unchanged RealityKit transforms/components and repeated construction of accessibility elements have been removed from gesture updates. Rendering remains event-driven when motion settles. A device still needs hands-on review to judge physical gyro feel; no device frame-rate measurement is claimed.

The source includes the native Metal shader, authored fixtures, preserved geometry editions, and offline authoring tools. Build output, temporary captures, local preferences, and signing files are excluded from Git.

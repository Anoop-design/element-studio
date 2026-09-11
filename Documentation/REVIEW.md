# Standalone interaction review — 11 September 2026

Verified from this independent checkout using the ElementStudio scheme on the dedicated iPhone 17 Pro / iOS 27 simulator.

- 11 unit tests passed: library persistence/import isolation, every preserved geometry edition, three-column placement, centered final row, fitted-view pan lock, zoomed content-edge limits, camera-flight endpoints/magnification, and minimum saved zoom.
- 2 UI tests passed: real pinch gestures stop at minimum zoom and enlarge the scene; all 16 objects open and rotate; Surface/Light/Form controls work; Reset restores edited lighting; Share produces a clean image; a saved look survives relaunch; native toolbar and dark mode work; dragging the object above expanded controls changes its orientation without dismissing the controls.
- Actual screenshots were reviewed in light and dark, including the collection, compact toolbar, expanded controls, rotated shapes, and share preview. Selected captures are saved alongside this note.

## Interaction design

The full collection is the minimum 1× view. At that scale the camera cannot pan beyond the content. Pinch follows its finger anchor; at higher magnification, pan stops at the visible content edges. Focus transitions interpolate projected position and logarithmic distance, with eased endpoints, so an object opens directly from its collection position. Closing restores the collection camera.

The bottom bar is an official SwiftUI bottomBar toolbar. Native partial-height controls use a zoom transition sourced from that toolbar and allow interaction with the viewport above them. This avoids trying to stretch a fixed-height toolbar beyond its supported bounds. Reset is available in both compact and expanded states. Saved looks remain separate from workspace resets.

Repeated writes of unchanged RealityKit transforms/components and repeated construction of accessibility elements have been removed from gesture updates. Rendering remains event-driven when motion settles. A device still needs hands-on review to judge physical gyro feel; no device frame-rate measurement is claimed.

The source includes the native Metal shader, authored fixtures, preserved geometry editions, and offline authoring tools. Build output, temporary captures, local preferences, and signing files are excluded from Git.

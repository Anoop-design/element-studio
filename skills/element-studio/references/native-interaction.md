# Native interaction, persistence, and render lifetime

The reference implementation uses SwiftUI controls over a persistent MTKView driven by RealityKit's RealityRenderer. These are lessons from that architecture; a simpler RealityView is often sufficient for another app. Check the target SDK before selecting APIs.

## Keep identity through a transition

The collection and focused object share the same scene. Focus changes the camera and surrounding visibility rather than loading a fresh renderer. The app's spring interpolates projected position and reciprocal depth so apparent size changes smoothly. It carries velocity on reversal and retains the original completion deadline when layout changes. Tests in `Tests/CameraGeometryTests.swift` cover these invariants.

For an app that should reveal an object once per opening, let the owning presentation issue a stable reveal request ID. Deduplicate it in the renderer; light updates, evidence refreshes, and reconstructed views must not replay it. An explicit Replay action issues a new ID. This is a reusable lesson from the original integration, not a requirement to add automatic reveals to this standalone editor.

Keep native tool transition sources mounted through dismissal. Element Studio's toolbar opens background-interactive tool sheets; its selected tool and measured detent stay stable while closing. Do not repair a transition with a delayed visibility toggle. Check open, close, reversal, layout changes, and Reduce Motion in a recording.

## Render only when there is work

`ElementStudioRenderer.invalidate()` chooses continuous drawing during motion/warmup and event-driven drawing at rest. An unpaused MTKView requires `enableSetNeedsDisplay = false` for its continuous turn. On settling, pause it and restore event-driven invalidation. Hide the preview only after actual GPU warmup completion, not after starting an asynchronous load.

Allow at most two live GPU submissions in this implementation. Coalesce further requests; decrement the count from completion and schedule pending work. Never block a gesture waiting for a third drawable. Skip unchanged transforms/materials; disable roots after they finish fading. Gyro samples reach weakly registered renderers without invalidating the whole SwiftUI editor. Stop sensors and motion while inactive or with Reduce Motion.

For expensive native mesh preparation, cache models, yield between uncached builds, and use a revision to discard obsolete arrangements. Preserve the last visible scene if a new build fails. Spatial bins and repeated-sample caching made reverse-logo projection practical without changing the resulting vertices. Treat past timings as historical observations, not portable guarantees.

## Keep view state out of authored state

Wireframe inspection must not leak through a material cache into unrelated objects or exports. Restore only triangle fill mode when leaving it; replacing all materials can discard per-object finishes. Compare state is temporary. Save/share clear it before capturing.

The native archive's schema migration pins old Latest looks to a preserved geometry edition once. New looks continue using current geometry after relaunch. Missing `surfaceRevision` retains the legacy surface response; new work uses revision 1. Imports add copies and remap collection IDs instead of replacing the existing library. Atomic persistence must finish before success feedback.

## Share actual alpha

Serialize offscreen snapshots with live rendering because they use the same renderer and camera. Wait for submitted work before changing projection, block new live submissions during the snapshot, and restore state on success, failure, and cancellation. The current implementation yields while waiting for completion; a different renderer may use an explicit completion primitive.

Element Studio uses a clear background and a BGRA sRGB texture, then constructs a CGImage with matching byte order and premultiplied alpha. Test alpha numerically, composite over both black and white, and inspect edges for fringes. A screenshot of a checkerboard does not establish transparent PNG output. The built-in export is 1440 square pixels; choose another size when the consuming task needs it.

## Verification scope

Use a test-only library and dedicated simulator. This app selects that library with `STUDIO_REVIEW=1`. Do not reset a user's existing installation for routine testing. The form replay uses `STUDIO_FORM_REPLAY=1` together with review mode; it intentionally spaces updates and is not an FPS benchmark. Physical gyro feel and device GPU performance need device review.

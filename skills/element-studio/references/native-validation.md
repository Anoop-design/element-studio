# Validate the native SwiftUI and RealityKit app

Build and exercise the real iOS app in an iOS simulator or on a connected iPhone. Use Xcode, XCTest/XCUITest, native screenshots, and device profiling. Browser automation is not an Element Studio test path. The optional JavaScript mesh builders are an asset-generation tool; their output still needs native validation.

Commands below run from the reference repository root. When applying this skill elsewhere, discover that project's scheme, bundle ID, test targets, and supported destinations. No agent-specific tool is required. Use an available Xcode integration or the standard command-line tools below.

## Simulator: default development loop

Use a full Xcode installation supporting the project and an installed iOS 26+ runtime. Select Xcode with `DEVELOPER_DIR` when multiple versions are installed. Inspect `xcodebuild -version` and `xcrun simctl list devices available` before claiming a destination is supported.

```sh
python3 scripts/check_repository.py
python3 scripts/test-native.py
```

The helper reuses a dedicated Element Studio QA iPhone simulator or creates one from an available iPhone runtime. It builds the native app and runs both unit and UI suites, using warm `build/` DerivedData and unique `.xcresult` bundles and logs. It does not take over a simulator for another app, erase a simulator, or uninstall the app. The shared test scheme sets `STUDIO_REVIEW=1` for the test host, and every UI test explicitly passes it to the app, isolating QA libraries from ordinary saved looks. Review data may accumulate; test names must remain unique.

For an explicit destination or a focused follow-up:

```sh
python3 scripts/test-native.py --simulator SIMULATOR_UUID
python3 scripts/test-native.py --suite unit
python3 scripts/test-native.py --only-testing ElementStudioUITests/StudioFlowTests/testNativeColorPicker
```

Replace placeholders with discovered IDs. `--suite ui` selects UI tests; the default runs both suites. `--dry-run` prints the command without installing or testing. If no QA simulator exists, supply an existing UUID for a dry run. A direct equivalent, when adapting to another project, is:

```sh
xcodebuild -project ElementStudio.xcodeproj -scheme ElementStudio \
  -configuration Debug -destination 'platform=iOS Simulator,id=SIMULATOR_UUID' \
  -derivedDataPath build -resultBundlePath build/NativeReview.xcresult \
  -parallel-testing-enabled NO test
```

Choose a fresh result-bundle path per run. Open it in Xcode to inspect failed assertions, native screenshots, and test recordings. Keep logs and captures under ignored `build/` or `Review/`. Avoid parallel simulator clones for this graphics-heavy suite.

## Connected iPhone: real hardware review

Pair and trust the iPhone, enable Developer Mode, unlock it, and choose a development team available to your Xcode account. Discover the destination rather than assuming a name:

```sh
xcrun devicectl list devices
xcodebuild -project ElementStudio.xcodeproj -scheme ElementStudio -showdestinations
python3 scripts/test-native.py --device DEVICE_UDID --team YOUR_TEAM_ID
```

Only add `--allow-provisioning-updates` when Xcode needs permission to update signing profiles. The team is a command-line override, never a committed credential or project setting. The helper builds and runs the same XCTest/XCUITest suites on the selected physical device. If it is disconnected or unavailable, report that limitation and use a simulator for the supported checks.

For manual visual/gyro review, build with the same destination and signing override, replacing `test` with `build`. Install the resulting app over the existing bundle, then launch review mode:

```sh
xcodebuild -project ElementStudio.xcodeproj -scheme ElementStudio \
  -configuration Debug -destination 'platform=iOS,id=DEVICE_UDID' \
  -derivedDataPath build DEVELOPMENT_TEAM=YOUR_TEAM_ID build
xcrun devicectl device install app --device DEVICE_UDID build/Build/Products/Debug-iphoneos/ElementStudio.app
xcrun devicectl device process launch --device DEVICE_UDID \
  --environment-variables '{"STUDIO_REVIEW":"1"}' com.anoop.elementstudio.dev
```

For simulator manual review, boot the dedicated simulator if needed, wait for boot completion, install `build/Build/Products/Debug-iphonesimulator/ElementStudio.app`, and launch with `SIMCTL_CHILD_STUDIO_REVIEW=1 xcrun simctl launch SIMULATOR_UUID com.anoop.elementstudio.dev`. Capture using `xcrun simctl io SIMULATOR_UUID screenshot build/native-review.png` or `recordVideo`; stop recording after the interaction. Never reset or uninstall a normal installation to deliver an update or obtain a clean screenshot.

## Acceptance evidence

Use the checks relevant to the change. Build success establishes compilation, while captures and interaction checks establish rendered behavior.

| Change | Native evidence |
| --- | --- |
| Mesh, inscription, normals | Collection/detail scale, front/side/reverse/grazing poses, shaded and temporary wireframe views; no gaps, seams, clipping, or unintended facets |
| Lighting, PBR, Metal shader | Fixed pose/background baseline, changed light direction and brightness, material roles, gloss/texture extremes, both light/dark backgrounds, no GPU validation errors |
| Glass, image/UV, export | Actual RealityKit transparency and asymmetric image orientation; exported PNG pixel alpha and composition; do not infer correctness from a browser render |
| Controls and saved looks | Precise entry, bounded values, undo/redo, compare release, scoped reset, save/relaunch/open, archive import, preserved old revisions |
| Camera and native chrome | Focus/return, interrupted transitions, gesture continuity, sheets opening/closing, restored framing, standard and accessibility text sizes, Reduce Motion |
| Runtime behavior | Idle rendering settles, background/foreground recovery, physical-device gyro and GPU/frame/energy profiling where relevant |

The existing UI suite records native screenshots and covers collection focus, controls, mesh isolation, export preview, saved looks, and large text. It does not automatically prove every angle, Reduce Motion transition, PNG alpha pixel, gyro response, or performance target. Use targeted native review for the missing evidence. Do not compare simulator frame times to phone performance.

Report Xcode/OS/destination, exact test selection and result, captures reviewed, and limitations. If native execution is unavailable, state that it remains unverified and provide reproducible commands. Do not replace the missing native run with browser testing.

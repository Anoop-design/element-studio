# Contributing to Element Studio

Start with [README](README.md), [AGENTS.md](AGENTS.md), and the [architecture guide](Documentation/ARCHITECTURE.md). Reusable techniques and implementation pointers are in [skills](skills/README.md). The repository is public under MIT, with retained third-party notices.

## Set up

The native app requires a full Xcode installation that supports this project and an iOS 26+ simulator/device. The committed Xcode project is ready to open; XcodeGen is optional unless changing project structure. When changing `project.yml`, regenerate the project and include both changes.

No signing team is committed. Simulator builds need no personal team. For your device, choose your own team in Xcode or pass `DEVELOPMENT_TEAM=YOUR_TEAM_ID` to xcodebuild. Change bundle identifiers only for a separate installation; preserve the existing identifier to update your own library in place. Do not commit signing credentials or provisioning profiles.

Native app testing uses Xcode and Python; follow [native validation](Documentation/NATIVE-VALIDATION.md). Geometry authoring uses the dependency-free Swift package: run `swift test` and `swift run -c release ElementStudioAuthor --output build/mesh-export`. Optional surface-map generation uses Python with `scripts/requirements-authoring.txt`. See the [authoring guide](NativeAuthoring/README.md).

## Change and verify

- Keep geometry, material, lighting, camera, inspection, and stored settings separate.
- Preserve old saved looks and immutable geometry editions. Verify archive import and migration when changing schemas or defaults.
- Use the actual renderer to review visual changes. Record parameters and front/side/reverse captures; inspect standard and accessibility text sizes for control changes.
- Run `swift test`, `python3 scripts/check_repository.py` and `python3 scripts/test-native.py` for repository and native unit/UI checks. Use a focused native suite for a targeted follow-up; do not substitute browser tests for the app. Build products and local review captures belong under ignored directories.
- Use a dedicated simulator and `STUDIO_REVIEW=1` for UI review. Routine updates must not uninstall or erase a user's normal library.
- Keep reusable skill references self-contained. Run the repository check after moving or installing skills, and exercise a realistic task before asserting a new workflow works.

Describe the concrete result, why it changed, what passed, and any unverified behavior in a pull request. Screenshots establish appearance; recordings establish transition continuity. Avoid unsupported device-performance claims.

Original contributions use the repository's MIT license. Preserve third-party notices. Use synthetic examples and report a suspected credential/private-data exposure privately to the repository owner rather than putting the value in a public issue.

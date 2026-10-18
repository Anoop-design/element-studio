# Open-source preparation

The repository remains **private**. The owner selected MIT for original code, documentation, procedural assets, and the portable agent skills. No public release, visibility change, website deployment, or package publication is part of this preparation.

## Included

- Three portable skills with local references, optional display metadata, and a license in each distributable directory.
- The working iOS app, browser authoring studio, current and preserved mesh fixtures, Metal shader, and native tests.
- Recovered HDR environment and surface-texture generators, with explicit candidate output paths.
- Locked browser development dependencies, provider-independent installation instructions, a collision-safe skill installer, and repository/mesh validation.
- Contributor instructions, source/lesson map, asset provenance, MIT license, and retained third-party/font notices.
- Native simulator and connected-iPhone testing, without a committed signing team or a personal Xcode path. The portable workflow includes signing, review storage, native captures, and visual acceptance.

## Verification

Owner clarification: app acceptance uses native SwiftUI/RealityKit execution in the simulator or on a connected iPhone. The browser test runner was removed, the skills now require native testing, and CI is configured for Xcode. The optional JavaScript tools remain only for mesh authoring/export.

Executed on 18 October 2026:

| Check | Result |
| --- | --- |
| Native app/test build | Passed with Xcode 27.1 (27A9275), dedicated iPhone 17 Pro simulator, iOS 27.0, no configured development team |
| Native unit suite | 20 tests passed, zero failures; repeated successfully after setting isolated review storage in the shared test scheme |
| Native UI suite | All eight tests passed, zero failures; collection, focus/framing, light/dark controls, repeated form edits, large text, mesh isolation/relaunch, native color picker, undo/redo, and export previews |
| Native visual review | 52 native screenshot attachments exported; collection, light controls, dark surface controls, live mesh inspection, and transparent export preview inspected |
| Native command helper | Default dedicated simulator and unit-only selection executed successfully; physical-device signing command checked with dry-run. The paired iPhone was unavailable, so no physical-device test is claimed |
| Skill Creator validation | All three SKILL.md packages passed |
| Repository check | Three self-contained skills, 26 Markdown documents with local links, 92 mesh manifests / 620 batches passed |
| Skill installation | Installed into a separate path containing spaces; links valid after copying; reinstall refused without altering files |
| Asset regeneration | All 23 environment/native-surface/browser-surface files matched committed bytes exactly |
| Current mesh export | All 20 variants exported to a separate candidate directory; 113 batches validated |
| Live export compatibility | Return-arrow candidate exported without fixture inscriptions; two batches and surface-grid output retained |
| Error paths | Existing export/generator/install outputs preserved on collision; unknown object IDs and malformed buffer ranges rejected |
| History pattern review | Seven pre-existing commits checked for common token/private-key patterns; zero matches. This is a limited pattern check, not a security certification |

The complete run is saved locally as `build/NativeTests-20261018T094756Z-242199.xcresult`; the final unit-scheme check is `build/NativeTests-20261018T095817Z-d94065.xcresult`. Corresponding `.log` files sit beside them. The installed local Element Studio skill was synchronized with the portable native workflow, with its former browser bundle retained in a separate local backup.

The native compiler reported an existing weak-capture warning in ElementStudioApp.swift; no compilation or test failure resulted. This preparation does not include a new physical-device performance or gyro review. Historical visual reviews remain in [REVIEW.md](REVIEW.md) and retain their original dates.

Reproduce checks with `python3 scripts/check_repository.py` and `python3 scripts/test-native.py`. Follow [native validation](NATIVE-VALIDATION.md) for simulator/iPhone destinations, signing, captures, and targeted review. GitHub Actions now selects the macOS `xcode-27` runner and runs the same native unit/UI suites, preserving `.xcresult` bundles and logs. Browser tests and their npm command are removed. Local native outputs are ignored under `build/`.

## Before changing visibility

The owner must explicitly request publication. The current Daybeat-branded example inscriptions and reverse mark are intentionally retained, with their origin explained; a fork can replace the source mark and regenerate its own fixtures. They are examples, not required branding for a new project.

Existing history is preserved. It includes the original developer's non-secret Xcode path and Apple team identifier in older commits; current setup no longer depends on either. Do not rewrite shared history merely to hide ordinary attribution. A future review that identifies an actual credential would require revocation and a coordinated cleanup before publication.

The `package.json` private flag prevents accidental npm publication independently of GitHub visibility. This project is distributed as source and skills, not an npm runtime library. No new access is granted while GitHub remains private.

## Hosted CI status

The [first hosted run](https://github.com/Anoop-design/element-studio/actions/runs/39115789169) stopped before allocating a runner or executing any steps. GitHub reported that recent account payments failed or the spending limit needs to be increased. The replacement native macOS workflow remains unexecuted until the account issue is resolved. No billing setting was changed and no futile rerun was requested. Local native execution is recorded separately from hosted CI; configuring the workflow does not establish a hosted pass.

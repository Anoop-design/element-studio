# Open-source preparation

The repository remains **private**. The owner selected MIT for original code, documentation, procedural assets, and the portable agent skills. No public release, visibility change, website deployment, or package publication is part of this preparation.

## Included

- Three portable skills with local references, optional display metadata, and a license in each distributable directory.
- The working iOS app, browser authoring studio, current and preserved mesh fixtures, Metal shader, and native tests.
- Recovered HDR environment and surface-texture generators, with explicit candidate output paths.
- Locked browser development dependencies, provider-independent installation instructions, a collision-safe skill installer, and repository/mesh validation.
- Contributor instructions, source/lesson map, asset provenance, MIT license, and retained third-party/font notices.
- Simulator setup without a committed signing team or a personal Xcode path.

## Verification

Executed on 18 October 2026:

| Check | Result |
| --- | --- |
| Native app/test build | Passed with Xcode 27.1 (27A9275), dedicated iPhone 17 Pro simulator, iOS 27.0, no configured development team |
| Native unit suite | 20 tests passed, zero failures; persistence/import, geometry editions, camera continuity, editing, and export behavior |
| Skill Creator validation | All three SKILL.md packages passed |
| Repository check | Three self-contained skills, 24 Markdown documents with local links, 92 mesh manifests / 620 batches passed |
| Skill installation | Installed into a separate path containing spaces; links valid after copying; reinstall refused without altering files |
| Browser interaction | All eleven assertion groups passed in managed Chromium: real meshes, idle stop, poses, separation, material/light changes, turn, Reduce Motion, sixteen selectors, drag, 390px reflow, and no console errors/external runtime requests |
| Visual inspection | Actual browser trio, complete collection, and narrow trio captures reviewed |
| Asset regeneration | All 23 environment/native-surface/browser-surface files matched committed bytes exactly |
| Current mesh export | All 20 variants exported to a separate candidate directory; 113 batches validated |
| Live export compatibility | Return-arrow candidate exported without fixture inscriptions; two batches and surface-grid output retained |
| Error paths | Existing export/generator/install outputs preserved on collision; unknown object IDs and malformed buffer ranges rejected |
| History pattern review | Seven pre-existing commits checked for common token/private-key patterns; zero matches. This is a limited pattern check, not a security certification |

The first browser run used the legacy headless-shell path and timed out during a rotation. The portable runner now uses managed full Chromium and bounded condition-based waits, with failure diagnostics; the full suite then passed. Runtime animation code did not change.

The native compiler reported an existing weak-capture warning in ElementStudioApp.swift; no compilation or test failure resulted. This preparation does not include a new physical-device performance or gyro review. Historical visual reviews remain in [REVIEW.md](REVIEW.md) and retain their original dates.

Reproduce the portable checks with `python3 scripts/check_repository.py` and `npm run verify:browser` while the loopback server is running. GitHub Actions runs those checks on Linux for pushes and pull requests. Native validation is local because it requires an appropriate Xcode and simulator. Local outputs are ignored under `build/` and `Authoring/verification/`.

## Before changing visibility

The owner must explicitly request publication. The current Daybeat-branded example inscriptions and reverse mark are intentionally retained, with their origin explained; a fork can replace the source mark and regenerate its own fixtures. They are examples, not required branding for a new project.

Existing history is preserved. It includes the original developer's non-secret Xcode path and Apple team identifier in older commits; current setup no longer depends on either. Do not rewrite shared history merely to hide ordinary attribution. A future review that identifies an actual credential would require revocation and a coordinated cleanup before publication.

The `package.json` private flag prevents accidental npm publication independently of GitHub visibility. This project is distributed as source and skills, not an npm runtime library. No new access is granted while GitHub remains private.

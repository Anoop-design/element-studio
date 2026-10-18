---
name: element-studio
description: Build and refine interactive 3D objects with editable geometry, materials, lighting, and native controls. Use for Element Studio work or a similar hands-on 3D authoring workflow, including inspection, saved looks, export, and verification.
license: MIT
---

# Element Studio workflow

Deliver a real rendered object and controls that change it. Work in the user's chosen project; the Element Studio repository is a reference implementation, not a requirement to use its badge theme or UI. The knowledge here works with any coding agent that can read Markdown. Native execution and validation require macOS, Xcode, and an iOS simulator or connected iPhone. The browser mesh source is an optional asset-generation tool.

## Start with the intended object

Identify its silhouette, construction, useful viewing distance, materials, and interactions. Choose a lathe, extrusion, sweep, or assembled mesh according to the form. Use RealityKit for native lit 3D and SwiftUI for native controls. Existing JavaScript mesh builders can generate candidate assets, which must be reviewed in the native renderer. SwiftUI shader effects are appropriate for 2D view effects, not a substitute for a mesh.

Work from a small, repeatable baseline: a fixed camera, a neutral clay material, one movable light, and a saved set of parameters. Inspect front, side, reverse, and grazing angles before adding detail. If the request is for a new object, actually replace or extend the example geometry before presenting it.

Read [the tuning workflow](references/tuning-workflow.md) when designing an object or building its inspector. Read [native interaction and rendering](references/native-interaction.md) when implementing camera transitions, rendering lifetime, persistence, or export. Read [the repository map](references/repository-map.md) when using the reference app or commands.

## Make the result editable

- Separate geometry parameters from material, lighting, camera, and transient inspection state. Rebuild meshes only for geometry changes.
- Give parameters bounded ranges, visible values, reset, and repeatable presets. Group a continuous drag into one undo action. Compare mode is temporary and must restore the prior edit.
- Preserve independently editable material roles. A color change should not recolor every metal edge or destroy a glass window.
- Use tabular numerals and stable value widths, native accessible controls, and reflow at large text sizes.
- Keep the renderer alive across focus and tool changes. Stop rendering and sensors when settled or inactive; Reduce Motion resolves to a correct still state.
- Preserve saved geometry and material revisions. New defaults must not silently alter existing saved looks.

## Verify the actual artifact

Follow [native validation](references/native-validation.md): build the iOS app and run XCTest/XCUITest in a dedicated simulator or on a connected iPhone. Do not use browser-based tests for Element Studio. Inspect actual rendered captures at collection and detail sizes, light and dark backgrounds, and narrow/large-text layouts. Exercise interrupted transitions, direct manipulation, material edits, reset, and export. Check transparent output pixels, not just a checkerboard preview. Record the environment, parameters, and limitations. A compile pass is not visual validation; simulator timing is not a phone performance benchmark.

Use the available shell, Xcode/IDE, native simulator/device automation, and image tools. No particular agent provider, MCP server, subscription, private app checkout, or personal directory is required. If the execution environment cannot render, provide the code and reproducible steps and explicitly say that visual validation remains unperformed.

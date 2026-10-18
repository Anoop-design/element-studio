---
name: realitykit-materials-lighting
description: Build and tune native 3D materials, studio lighting, procedural normal maps, and RealityKit CustomMaterial Metal surface shaders. Use for real mesh rendering, glass approximations, reflection problems, and browser-to-native material translation.
license: MIT
---

# RealityKit materials and lighting

Build a material/light system that explains the object's geometry and remains editable. Start with PBR material roles and a useful reflection environment; introduce a custom shader for a defined effect that standard material controls do not supply.

Read [materials and light](references/materials-and-light.md) for the reference rig, tuning values, texture preparation, and diagnostic order. Read [Metal shader integration](references/metal-shaders.md) when writing or binding a shader. The source map in those references names files in the Element Studio checkout; the technical guidance can be used independently.

## Research delegation

Delegate research to lightweight subagents: **Luna in Codex**, **Haiku or Sonnet in Claude Code**, using models actually available in the current environment. Keep broad research out of the main agent's context; return concise findings and evidence. Read [research delegation](references/research-delegation.md) before starting research, including the unavailable-model fallback. Implementation and native validation stay with the working agent.

## Choose the shader path correctly

| Intent | API family |
| --- | --- |
| Lit 3D metal, enamel, ceramic | RealityKit PhysicallyBasedMaterial |
| Modify a 3D surface while keeping RealityKit lighting | RealityKit CustomMaterial with a `[[visible]]` Metal surface shader |
| Move rendered mesh vertices | CustomMaterial geometry modifier, with culling/normal/physics implications checked |
| Color, distortion, or sampling effect on a SwiftUI view | SwiftUI ShaderLibrary and `[[stitchable]]` Metal functions |

The Element Studio glass shader is the second case. Swift hosts parameters and scene setup; the shader itself is Metal Shading Language. Do not paste a SwiftUI `layerEffect` signature into a RealityKit surface shader. Availability differs across OSes and SDKs: confirm against the target toolchain and Apple documentation before transplanting an API.

## Tune in a stable order

Fix geometry/normals in clay, then reflection environment, light direction, roughness, clearcoat, microtexture, and tint. Keep camera and background reproducible. Separate body, polished edge, enamel, glass, photo, and lettering material roles. Cache prepared textures; slider updates change parameters or select cached levels.

Evaluate front, reverse, side, grazing angles, and both dark/light backgrounds at collection and detail scale. Rendering must settle at rest. Build and test with Xcode on an iOS simulator or connected iPhone; the reference repository provides `python3 scripts/test-native.py` for both destinations. Test transparency and export in the native renderer; a browser preview is not proof of native glass or color equivalence. Describe approximations and record the actual build, rendered evidence, and untested device behavior.

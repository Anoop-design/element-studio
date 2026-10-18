# Integrating the native glass shader

This is the actual shape of the working Element Studio API boundary. Copy `Sources/ElementStudio-Glass.metal` together with the corresponding material setup in `Sources/ElementStudioAssets.swift`, then adapt the behavior to the new object. Native verification requires the target SDK and a real renderer.

## RealityKit and SwiftUI are different contracts

RealityKit's surface function is `[[visible]] void name(realitykit::surface_parameters parameters)` and includes `<RealityKit/RealityKit.h>`. Swift creates `CustomMaterial.SurfaceShader(named:in:)` and a `CustomMaterial`. The function supplies material attributes and RealityKit handles the selected lighting model. See Apple's [custom-material guide](https://developer.apple.com/documentation/realitykit/modifying-realitykit-rendering-using-custom-materials).

SwiftUI's `colorEffect`, `distortionEffect`, and `layerEffect` use `[[stitchable]]` functions and a different signature, return type, and coordinate system. They affect view rendering. If the task needs those effects, check Apple's [Shader documentation](https://developer.apple.com/documentation/swiftui/shader) and the actual deployment target instead of using the RealityKit code unchanged. Element Studio does not include a tested SwiftUI layer-effect example.

## The implemented thin-glass model

`elementStudioGlass` computes:

```text
grazing = (1 - saturate(abs(dot(normalizedNormal, normalizedView))))^5
opacity = clamp(presence*0.18 + grazing*(0.30 + presence), 0.01, 0.82)
```

`presence` comes from `parameters.uniforms().custom_parameter().x`, supplied by Swift as `glass.custom.value = [Float(settings.glass), 0, 0, 0]`. Both normal and view are taken from the shader's geometry inputs. Keep directions in compatible spaces if changing that calculation. The absolute dot gives both sides a similar response.

The shader sets a restrained cyan base color, metallic 0, roughness 0.045, specular 0.9, clearcoat 1, and coat roughness 0.04. It leaves a head-on chamber clear while defining the wall at grazing angles. This is view-dependent transparency with reflected studio light. It is not volumetric refraction, ray tracing, simulated thickness, or physically exact Fresnel transmission.

## Swift host setup

```swift
guard let library = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary() else {
    throw CocoaError(.fileReadCorruptFile)
}
var glass = try CustomMaterial(
    surfaceShader: .init(named: "elementStudioGlass", in: library),
    lightingModel: .clearcoat
)
glass.blending = .transparent(opacity: .init(floatLiteral: 1.0))
glass.faceCulling = .none
glass.writesDepth = false
glass.custom.value = [0.14, 0, 0, 0]
```

This excerpt assumes `RealityKit`, `Metal`, and Foundation imports and a throwing context. The `.metal` file must belong to the app target so the default library contains the exact named function. `.clearcoat` is deliberate because the shader writes clearcoat outputs. The reference library prepares the material once and derives per-batch values from it.

The no-culling/no-depth-write settings suit these thin transparent surfaces. They are not a prescription for opaque models or every layered transparent scene. Inspect front/reverse and overlapping shells for ordering defects. Changing only the shader opacity while keeping opaque blending will not reproduce this material.

## Common failure checks

| Symptom | Check |
| --- | --- |
| Missing shader/library | Target membership, build logs, function spelling, default Metal library |
| Coat does not respond | Lighting model supports the outputs and the IBL is received |
| Glass hides the chamber | Base transparency, blending, duplicate faces, depth writes, view-space calculation |
| Dark/milky edge | Background, reflected sources, opacity curve, compositing and premultiplication |
| Edits affect every object | Shared material state and cache keys; derive each object's material settings |
| Unexpected old-look change | Material revision decode and migration; nil retains prior response |

A geometry modifier can move rendered vertices without moving collision/physics geometry; account for that and expanded culling bounds if using one. Element Studio's persistent form edits primarily use authored geometry/transforms rather than an unverified general-purpose geometry-modifier pipeline.

Validate the shader by compiling, then render front/side/reverse with changed light, presence, and background. Save a look, relaunch, and compare. A browser material with transmission can be a useful reference but does not prove native equivalence.

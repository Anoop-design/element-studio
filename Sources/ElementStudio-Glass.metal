#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

/// View-dependent transparency keeps the chamber clear head-on and describes the curved wall
/// at grazing angles. RealityKit still computes the reflected studio light on the real geometry.
/// This is a thin-glass approximation, not ray-traced refraction through a simulated volume.
[[visible]] void elementStudioGlass(realitykit::surface_parameters parameters) {
    float3 normal = normalize(parameters.geometry().normal());
    float3 view = normalize(parameters.geometry().view_direction());
    float grazing = pow(1.0 - saturate(abs(dot(normal, view))), 5.0);
    float presence = parameters.uniforms().custom_parameter().x;
    parameters.surface().set_base_color(half3(0.80h, 0.94h, 0.98h));
    parameters.surface().set_metallic(0.0h);
    parameters.surface().set_roughness(0.045h);
    parameters.surface().set_specular(0.9h);
    parameters.surface().set_clearcoat(1.0h);
    parameters.surface().set_clearcoat_roughness(0.04h);
    parameters.surface().set_opacity(half(clamp(presence * 0.18 + grazing * (0.30 + presence), 0.01, 0.82)));
}

# Original native Swift shape recipes

The reference app includes `Sources/StudioExampleShapes.swift`, an independently reusable Foundation/simd generator. `StudioExampleAsset.swift` adapts its output to the app's RealityKit mesh loader. Copy the generator and its MIT license into another project; use its positions, normals, UVs, and indices with the target renderer. No Daybeat or browser dependency is required for these shapes.

| Stable ID | Recipe |
| --- | --- |
| `orbit-v1` | Elliptical loop with radius (0.73, 0.93), circular section (0.17, 0.17), Z wave 0.12; separate polished ellipsoid core (0.32, 0.38, 0.30) |
| `twist-v1` | Elliptical loop (0.64, 0.90), broad section (0.28, 0.065), one full section twist, Z wave 0.10 |
| `pebbles-v1` | Four rotated, separately colored ellipsoids with decreasing radii, individually editable material roles and separation offsets |

Coordinates are right handed with +Z at the front. `loop` samples 128 longitudinal segments and 32 section segments. Duplicate seam vertices give UVs a continuous 0-to-1 range while wrapping the evaluated position and normal exactly. Finite surface derivatives account for the rotating section when computing normals. One full turn closes this orientable sweep; a half turn needs a different surface construction.

`ellipsoid` uses 64 angular segments and 30 latitude divisions, with a single vertex at each pole. This avoids degenerate pole triangles. Apply inverse scale to the sphere normal, then rotate and normalize it; applying the vertex scale directly to normals produces incorrect highlights.

For edits, keep dimensions positive, section thickness below the local loop radius, and enough sampling where silhouette curvature changes. A new topology or proportion gets a new stable ID; do not silently change v1 geometry under saved looks. Rebuild only for geometry changes. Material/light changes use existing meshes. A single continuous part has no meaningful exploded arrangement.

In the reference repository, `ExampleShapeTests` validates closed welded seams, winding, normals, finite arrays, deterministic buffers, stored looks, and actual native transparent renders. Use the iOS simulator or connected iPhone to inspect front/side/reverse, material response, light changes, depth, and export. The generated catalogue PNGs come from RealityKit on an iPhone; they are not an alternative renderer.

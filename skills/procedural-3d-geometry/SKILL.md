---
name: procedural-3d-geometry
description: Author and refine procedural 3D meshes, including lathed bodies, beveled outlines, swept ribbons, fitted insets, and curved inscriptions. Use when building code-authored objects or diagnosing silhouette, topology, normal, or mesh-export defects.
license: MIT
---

# Procedural 3D geometry

Construct an inspectable solid with useful editable parameters. This guidance comes from Element Studio's hand-tuned objects and can be applied to unrelated forms or renderers. The reference includes independent native Swift generators as well as the original Three.js builders and typed mesh buffers for RealityKit. The geometric principles do not require a particular authoring tool.

Read [construction and corrections](references/construction.md) for the actual algorithms and failure modes. Read [native transfer](references/native-transfer.md) when exporting geometry or preserving editions. Read [native Swift examples](references/native-examples.md) to reuse or extend the orbit, twisted loop, and stacked pebble generators.

## Research delegation

Delegate research to lightweight subagents: **Luna in Codex**, **Haiku or Sonnet in Claude Code**, using models actually available in the current environment. Keep broad research out of the main agent's context; return concise findings and evidence. Read [research delegation](references/research-delegation.md) before starting research, including the unavailable-model fallback. Implementation and native validation stay with the working agent.

## Choose the construction by shape

| Form | Starting approach |
| --- | --- |
| Rounded instrument/cap/chamber | Lathe a deliberate radius-height profile |
| Irregular badge or inset | Clean outline, true polygon offsets, beveled extrusion |
| Concave crowned face | Outline-aware triangulation, conforming subdivision, smooth height field |
| Folded strip or loop | Swept cross-section with shared seam and paired end caps |
| Lens or smooth convex face | Curved surface with correct reverse winding and UVs |

Use separate named components for body, lip, face, markings, and glazing. Keep their material roles independent. Work in a documented coordinate system and unit scale. Model the side and reverse, not just the front silhouette.

## Iterate by evidence

Start in clay and inspect front/side/reverse before materials. A defect that moves with the camera may be a normal or reflection issue; a hole or doubled contour in clay needs geometry work. Check shared edges, winding, degenerate triangles, thickness, and self-intersections. Use an exploded view to inspect joins and seating.

Preserve intentional hard normals while smoothing rounded shoulders. Deform normals consistently with positions. Build dense geometry only where the silhouette or curvature needs it. Do not rebuild meshes on a roughness, tint, camera, or lighting change.

The reference inset helper chooses the largest surviving offset island and has a collapsed-outline fallback. Those are study-specific compromises: do not silently use them for a shape requiring multiple islands or holes. Likewise, a radial dome is only appropriate where its center can see the boundary without crossing a concavity.

When done, retain source, parameter values, native candidate output when applicable, and actual rendered evidence. Numeric/topological checks support visual review; neither alone proves a good object.

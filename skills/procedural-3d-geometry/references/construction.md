# Construction methods and the hand-tuned corrections

Source symbols refer to `Authoring/objects.js`, `Authoring/forms.js`, and `Authoring/brand-mark.js` in the Element Studio repository. Use the methods independently of its sixteen example badges.

## Lathed profiles

`lathe(profile, material, axis, segments)` turns a radius-height profile into a body or chamber. Give the shoulder several intentional samples instead of placing a tiny bevel on a cylinder. The stopwatch uses separate case, retaining lip, recessed dial, crown neck, rounded crown, and physical flutes. Distinct parts explain construction under an oblique light; a flat colored disc cannot provide that evidence.

The hourglass uses a continuous chamber profile plus separate caps and modeled sand. Its sand transfer is an authored animation, not a volume-conserving simulation. Choose enough radial segments for the target apparent size; the source's 128-segment helper is a study setting, not a universal minimum.

## Constant-width insets

Scaling an outline toward its center changes rim thickness unevenly, especially at a heart cleft or tight concavity. `inset(points, width)` uses Clipper polygon offsets with integer coordinates (study scale 100000), round joins, winding normalization, and arc-length resampling to the original point count. It aligns the starting sample with the original outline so successive profile rings correspond.

`contourRing` connects successive offset contours at different depths. The profile defines the shoulder and lip; every ring must keep the same sample count and winding. Inspect tight corners and the reverse join. An offset may collapse or split a polygon: the existing helper chooses its largest island and falls back to a shrunken contour when empty. That fallback is not an exact offset. For new shapes, surface the failure or support all required islands/holes instead of hiding lost geometry.

## Concave caps and continuous bevels

The original radial flame cap crossed its own notch. A radial triangle fan can leave the intended outline on a concave shape. The refined `castMedal` uses outline-aware extruded triangulation, then bends a continuous enamel face, body, bevel, and details using one analytic height function.

The return arrow also benefited from `unionOutline`: combine the band, tail, and arrowhead into a single clean outline before beveling. Overlapping separately beveled solids can produce an internal ridge. Preserve openings that belong to the design; do not assume a union's largest contour can express every new shape.

Subdivide adjoining faces conformingly. Refining a cap independently from its rim creates T-junctions that can open when deformed. `conformingCaps` propagates shared-edge subdivisions. `softenedNormals` averages compatible coincident normals but leaves meaningful discontinuities. Recompute or transform normals after changing geometry, then inspect moving highlights across the join.

## Bend positions and normals together

For a height deformation `z' = z + h(x,y)`, the normal transforms by the inverse transpose of the deformation Jacobian. In the same coordinate frame:

```text
nx' = nx - (dh/dx) * nz
ny' = ny - (dh/dy) * nz
nz' = nz
normalize(n')
```

`bendAssembly` evaluates derivatives with finite differences and transforms into/out of the assembly frame. Moving only vertices leaves highlights inconsistent with the new shape. Account for nonuniform object transforms with normal matrices. Recalculate bounds for changed meshes in a different renderer.

## Swept loops and ribbons

`forms.js` builds a centerline, local across/front directions, width, depth, and a signed-power cross-section. Sweep periodic samples around each section and reuse the seam. Stitch matching front/rear samples at each end rather than filling a notched end with a center fan. Skip zero-area triangles and verify winding from both sides.

The folded bookmark's notch originally folded terminal rows back over one another, creating an extra internal V. The correction used a cubic longitudinal falloff (`u**3`) and a softened transverse notch profile so rows stayed ordered. The ceramic/metal variants change thickness and section softness as well as material; a shader alone cannot create the same silhouette.

The loop's arrowhead widens before tapering to its tip; the tail rounds into the sweep. Inspect the inside opening, tapered tip, and thickness around the bend. A fixed global "up" direction can become singular on a different centerline; choose a stable transported frame if the new path needs it.

## Seat inscriptions on the actual skin

`seatFaceDetails` finds a detail's lowest point in face space, moves its vertices onto the local height plus a small clearance, and transforms normals with the same derivatives. Relief should follow the face without burying the text or hovering above it. The reference clearance is 0.0015 in its study units; retune for another scale and depth precision.

The ribbon solves the longitudinal surface location iteratively for each letter vertex, including the notch and transverse roll. A flat text plane at one z value would intersect that skin. Reverse-logo projection samples triangle heights; spatial bins and caching repeated x/y samples avoid searching every triangle for every duplicate letter vertex. Preserve positions, normals, and UVs when optimizing that search.

## Check the whole object

Evaluate: front silhouette, narrow edge, reverse join, grazing light, clay, wireframe, separated components, thumbnail, and detail. A recognizable return arrow, continuous flame, full six-lobed medallion, and upright track-shaped medal improved through changes to construction, not added decoration. Keep the semantic identity relevant to the new user's object instead of copying these motifs indiscriminately.

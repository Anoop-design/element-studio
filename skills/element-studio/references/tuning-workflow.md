# A repeatable manual tuning session

These practices come from the authored Element Studio collection. The original objects are examples, not required motifs. Parameter values are starting points in normalized study units, not physically calibrated measurements.

## 1. Establish construction

Write down what each component does: shell, rim, inset, lettering, lens, backing. Give parts names and separate materials. Start with a silhouette roughly two units across, then evaluate its apparent size in the intended UI. A detailed model can still fail as a small collection thumbnail.

Review clay from the front, 90-degree side, reverse, and a slow full turn. Look for changes of thickness, disconnected parts, self-intersections, faceted shoulders, folded triangles, and floating inscriptions. Wireframe helps locate geometry errors but is a temporary inspection mode. Fix construction before using stronger light or gloss to hide a defect.

## 2. Establish the reflection environment

Use a broad upper-left softbox, weaker fill, narrow rear/right strip, and quiet low bounce. The broad reflection explains a curved shoulder; the strip exposes bevel continuity. Rotate the environment and key light together. First judge the same clay geometry, then satin metal. A nearly black metal often needs a useful reflection environment rather than a brighter base color.

Keep camera and exposure fixed while comparing forms. Inspect the reverse as deliberately as the front. Test both a pale and a dark background. Browser ACES tone mapping and native RealityKit rendering differ; transfer the design intent, then retune the native result.

## 3. Tune surface roles separately

Apply the body, edge, face, glass, and lettering roles independently. Adjust roughness before microtexture; then clearcoat and grain. Make a small change, compare to the baseline, save a named look, and inspect it again at thumbnail size. Fine grain should reveal a material under moving light without becoming visible noise or moire.

A useful recording table is:

| Field | Record |
| --- | --- |
| Geometry | Builder, edition, study, parameter changes |
| Surface | Role, roughness, grain, clearcoat, tint, surface revision |
| Lighting | Environment version, direction, brightness, shadow settings |
| Camera | Pose, framing, viewport size |
| Evidence | Front/side/reverse captures, motion clip, test command and result |
| Decision | What improved, what failed, remaining approximation |

The native library saves geometry selection, material values, tint, light, form, and camera. The browser reference does not persist arbitrary slider edits. For browser work, record the parameters or implement explicit preset serialization before claiming a look is saved.

## 4. Make manipulation trustworthy

Give pointer/touch control priority over automatic motion. Keep one renderer and scene identity while moving from collection to object. Save the overview camera and return to it exactly. Retarget a moving camera from its current position and velocity; resizing must not start an unrelated fresh animation.

Expose only controls that change the current object. Show the actual authored color, not a generic swatch. Validate exact numeric input using the current locale and range. A drag is one undo transaction. Reset view preserves materials; reset materials preserves view and saved looks. Keep temporary mesh inspection and compare state out of saved configurations.

## 5. Preserve the experiment

Do not overwrite a published geometry edition to try a new shape. Export to a new directory, compare it, and deliberately promote it after preserving old fixtures. Use a separate material revision for a changed shader or normal response. Check old-library load, import, save, and relaunch.

For a new object family in another app, bring the construction and inspection methods, not the original workout semantics, sixteen-object count, badge colors, or grid layout. Original fixture dates and counts are synthetic. Production claims and real user content belong to the consuming application.

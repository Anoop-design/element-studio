# Third-party code and references

All files below are pinned and vendored locally. No CDN is contacted when the studio runs.

- **Three.js 0.180.0** — MIT license. `vendor/three.module.min.js`, `three.core.min.js`, `FontLoader.js`, `TextGeometry.js`. See `vendor/THREE-LICENSE.txt`. [Official repository](https://github.com/mrdoob/three.js/tree/r180).
- **Helvetiker sample font** — MAGENTA/MgOpen font license, retained in `vendor/FONT-LICENSE.txt` and inside the typeface JSON. Used for illustrative mesh lettering; native typography is a later integration step.
- **clipper-lib 6.4.2** — JavaScript polygon clipping/offset library by Angus Johnson and Timo. Boost Software License 1.0 and included JSBN attribution; license notices are retained in `vendor/clipper.js` and `vendor/CLIPPER-LICENSE.txt`. Used to clean constant-width insets at concave and tight corners. [Project repository](https://github.com/junmer/clipper-lib).

Primary implementation references:

- [Three.js physical material documentation](https://threejs.org/docs/pages/MeshPhysicalMaterial.html): separate metal, clearcoat, roughness, and transmission behavior.
- [Lathe geometry](https://threejs.org/docs/pages/LatheGeometry.html): bodies and chambers made from explicit cross-sections.
- [Extruded geometry](https://threejs.org/docs/pages/ExtrudeGeometry.html): bevels and depth for irregular shapes.

The browser prototype's custom geometry, interaction, procedural material textures, and procedural landscape are authored in this package. It contains no image-generation output.

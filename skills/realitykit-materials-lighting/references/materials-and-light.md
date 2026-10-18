# Materials, reflection environment, and manual tuning

The formulas below describe Element Studio's current implementation, not physically calibrated constants. Source: `Sources/ElementStudioAssets.swift`, `ElementStudioRenderer.swift`, `ElementStudioSettings.swift`, `scripts/make-environment.py`, and `scripts/make-surface-textures.py` in the repository.

## Start with the authored defaults

The current new-work defaults are roughness 0.40, grain 0.16, clearcoat 0.27, glass presence 0.14, light -35 degrees, brightness 1, and depth 1. The inspector bounds roughness to 0.12...0.65, grain/clearcoat to 0...1, glass to 0.03...0.4, direction to -140...140 degrees, brightness to 0.45...1.8, and depth to 0.5...1.8. These are useful artistic limits for this collection; retune them for a different object.

## Give each role a different response

For the refined (`surfaceRevision == 1`) material path, let `r` be roughness, `g` grain, and `c` clearcoat:

| Role | Current response |
| --- | --- |
| Satin body | Metallic 1; gray alloy base; roughness texture scaled by `r + 0.025`; anisotropy `g * 0.32`; brushed normals |
| Polished edge | Roughness `max(0.095, r * 0.55)`; clearcoat 0.25; coat roughness 0.14 |
| Ceramic | Metallic 0; roughness `r * 0.75 + 0.04`; clearcoat `0.18 + c * 0.35`; coat roughness 0.19 |
| Enamel | Metallic 0; roughness `max(0.12, r * 0.72 + 0.03)`; coat `c`; coat roughness `0.12 + (1-c) * 0.14` |
| Dial | Enamel path with metallic 0.20 and radial normal pattern |
| Porcelain | Enamel path with coat fixed to 0.35 |
| Sand | Nonmetallic, roughness 0.88, granular color texture |
| Clay inspection | Gray, metallic 0, roughness 0.73 |

The source applies tint only to enamel/dial/ceramic/porcelain. Preserve a metal edge's identity when changing the face color. Earlier editions and nil surface revisions retain different legacy responses. A revised default must not silently rewrite saved looks.

## Shape reflections with an environment

The native panorama is a 1024 × 512 linear float RGBA equirectangular image. It contains broad key/fill panels, a narrow rim, and low bounce, with values above 1 retained. It is a light source, not a rendered picture of the object. `make-environment.py` regenerates it without private resources. Keep its dimensions and format consistent with `environmentImage()` when altering the generator.

Load it with `EnvironmentResource(equirectangular:)`, attach an `ImageBasedLightComponent` to the light entity, set `inheritsRotation = true`, and attach `ImageBasedLightReceiverComponent` to receiving model entities. This last association matters: a light entity alone does not express the intended receiver relationship in this setup.

The renderer rotates the environment by `light + 35` degrees around Y, and places the key at `[sin(a)*4, 4, cos(a)*4]` looking at the origin, where `a` is light direction in radians. Key/fill intensities are `4200*b` and `1300*b`; IBL exponent is `log2(b) + 0.35` for positive brightness `b`. The exponent is logarithmic: an increment of one doubles IBL intensity. See Apple's [ImageBasedLightComponent documentation](https://developer.apple.com/documentation/realitykit/imagebasedlightcomponent).

Use the renderer's applied values when copying the rig; its initial key intensity is overwritten during settings application. Environment rotation and the direct light move together so highlights describe the same scene. Shadow projection/bias are scaled to these study units. Diagnose acne versus detached shadows with side/grazing views before increasing bias.

The browser reference instead builds a PMREM environment from luminous panels and uses its own direct key/fill/rim lights. It uses ACES and sRGB output. Those numbers are not interchangeable with native intensity values. Match the visual relationships, then inspect native output.

## Bake slopes, not moving highlights

The surface generator uses a deterministic seed (240910). Brushing combines integer spatial frequencies so texture edges tile. Glaze uses band-limited random height variation and periodic finite differences, avoiding the distracting moire of a regular sinusoidal lattice. Encode normalized `(-dx, -dy, 1)` as RGB in [0,1]. The dial adds radial engine-turning slopes. Roughness is a separate scalar map.

Load normal maps with `.normal`, roughness with `.scalar`, and photos/color with `.color`. Treat data maps as data through upload and filtering. Do not bake a bright highlight into base color and then rotate it to fake a light.

The native refinement attenuates X/Y normal components and reconstructs positive Z as `sqrt(max(0, 1-x*x-y*y))`. Its brush/glaze strengths are 0.48/0.52. Dial levels use `0.06 + level*0.065`; eight prepared levels are cached. These quieter maps keep microtexture below the silhouette and major reflection cues. Prepare once, select cached levels during a drag, and check at real screen size.

## Diagnose in this order

1. In clay, confirm silhouette, winding, face normals, and no intersecting surfaces.
2. With satin, confirm the object receives the intended IBL and the environment has broad readable sources.
3. Move the key and environment. If reflections ignore the controls, check receiver links and transform inheritance.
4. Tune roughness and clearcoat before raising brightness. Inspect clipped highlights and lost edges against two backgrounds.
5. Reduce normal amplitude if the result looks dirty, glittery, or faceted. Check UV orientation, tiling, and seams.
6. Test glass separately, including overlapping surfaces and camera positions. Then test alpha export and compositing.

Use GPU/device measurements when claiming performance changes. Historical simulator timings and scripted delays establish neither physical-device frame rate nor battery impact.

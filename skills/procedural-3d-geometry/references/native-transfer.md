# Transfer authored meshes without losing their construction

The native Swift exporter constructs every Daybeat mesh and writes a JSON manifest plus a binary buffer per variant. The iOS app consumes versioned buffers directly. Geometry uses Foundation, simd and CoreGraphics; authoring and rendering need no JavaScript or browser runtime.

## Preserve the contract

- Bake world transforms into positions and transform normals consistently.
- Keep named component/explosion offsets and material roles; batch by component path and material identity, not only by color.
- Preserve geometry groups, indexed and non-indexed meshes, and remapped indices.
- Write positions/normals as float32 triples, UVs as float32 pairs, and indices as uint32. Record byte offsets and element counts, not byte counts. The current native format assumes little-endian 32-bit values.
- Check finite values, buffer bounds/alignment, matching vertex counts, triangles, and index range before accepting data. Validate file pairs as a unit.
- Serialize authored sRGB colors for native UIColor inputs; do not apply an extra linear-to-sRGB conversion to those values. Normal/roughness textures remain data, not color images.

The exporter flips V once (`1 - v`). The native photo material has a texture-coordinate correction for the uploaded image orientation. Verify an asymmetric image and a labeled UV test; do not add another blind flip when a transfer looks inverted.

## Candidate output first

On macOS with full Xcode, from the repository root:

```sh
swift test
swift run -c release ElementStudioAuthor --output build/mesh-candidate --ids ribbon,returning
python3 scripts/check_repository.py --geometry build/mesh-candidate
```

The output includes versioned Swift-generated photo and sand fixtures. Default mesh IDs end in `-swift-v1`. Unknown IDs must fail rather than silently export nothing. Promotion into Resources is a separate deliberate step after visual comparison and preservation of any edition already referenced by saved libraries. The exporter refuses overwrites unless `--overwrite` is explicit and rejects direct output into the published Resources directory. After promotion, build and run the SwiftUI/RealityKit app in a dedicated iOS simulator or on a connected iPhone. Use `python3 scripts/test-native.py` in the reference repository. Inspect actual native front/side/reverse renders, material assignments, UV orientation, and saved-look compatibility. A buffer check or browser render alone does not validate the native result.

`--live` strips fixture inscriptions and additionally exports front/back surface samples. It is a compatibility mechanism for a consuming application that supplies its own data-driven marks; it does not calculate achievements or import personal history. No Daybeat checkout is required to run it.

## Version assets, then migrate references

New work uses `-swift-v1`. Element Studio also preserves the prior unsuffixed Latest IDs, `-earlier`, `-sculpted`, `-forms20260910`, and `-studio20260911` editions. The archive migration moves version-1 Latest saved looks to Studio original while keeping new work on Swift v1. A saved material change needs its own surface revision, not an unrelated geometry edition. Test old loads/imports, a new save, and a second relaunch so a migration does not repeatedly pin new work to old geometry.

Historic binaries are compatibility fixtures. Current builders are not expected to regenerate all older shapes. Keep old files intact. CoreGraphics offsets and native triangulation differ from historical sampling. Current candidate exports can also change serialized bytes or mesh ordering across SDKs; compare dimensions, batches, attributes, topology, roles, and actual renders, not only file hashes.

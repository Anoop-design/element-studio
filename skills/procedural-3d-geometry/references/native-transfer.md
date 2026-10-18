# Transfer authored meshes without losing their construction

The reference exporter runs the browser mesh builders and writes a JSON manifest plus a binary buffer per variant. A native app consumes those files directly; it does not embed a browser runtime.

## Preserve the contract

- Bake world transforms into positions and transform normals consistently.
- Keep named component/explosion offsets and material roles; batch by component path and material identity, not only by color.
- Preserve geometry groups, indexed and non-indexed meshes, and remapped indices.
- Write positions/normals as float32 triples, UVs as float32 pairs, and indices as uint32. Record byte offsets and element counts, not byte counts. The current native format assumes little-endian 32-bit values.
- Check finite values, buffer bounds/alignment, matching vertex counts, triangles, and index range before accepting data. Validate file pairs as a unit.
- Convert Three.js linear color values to sRGB for the native UIColor inputs. Normal/roughness textures remain data, not color images.

The exporter flips V once (`1 - v`). The native photo material has a texture-coordinate correction for the uploaded image orientation. Verify an asymmetric image and a labeled UV test; do not add another blind flip when a transfer looks inverted.

## Candidate output first

With the repository's Authoring server running:

```sh
node export-meshes.cjs http://127.0.0.1:8786/ --output build/mesh-candidate ribbon returning
python3 scripts/check_repository.py --geometry build/mesh-candidate
```

The output includes shared photo and sand fixtures. Unknown IDs must fail rather than silently export nothing. Promotion into Resources is a separate deliberate step after visual comparison and preservation of any edition already referenced by saved libraries. The exporter refuses overwrites unless `--overwrite` is explicit.

`--live` strips fixture inscriptions and additionally exports front/back surface samples. It is a compatibility mechanism for a consuming application that supplies its own data-driven marks; it does not calculate achievements or import personal history. No Daybeat checkout is required to run it.

## Version assets, then migrate references

Element Studio preserves `-earlier`, `-sculpted`, `-forms20260910`, and `-studio20260911` editions. The archive migration moves version-1 Latest saved looks to Studio original while keeping new work on Latest. A saved material change needs its own surface revision, not an unrelated geometry edition. Test old loads/imports, a new save, and a second relaunch so a migration does not repeatedly pin new work to old geometry.

Historic binaries are compatibility fixtures. Current builders are not expected to regenerate all older shapes. Keep old files intact. Current candidate exports can change serialized bytes or mesh ordering with dependency/runtime changes; compare dimensions, batches, attributes, topology, roles, and actual renders, not only file hashes.

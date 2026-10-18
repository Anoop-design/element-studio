import Foundation

nonisolated extension ElementStudioAsset {
    static func example(id: String, parts: [StudioExampleShapes.Part]) -> Loaded {
        var data = Data()
        func append(_ values: [UInt32]) -> Range {
            let range = Range(offset: data.count, count: values.count)
            for value in values {
                var encoded = value.littleEndian
                withUnsafeBytes(of: &encoded) { data.append(contentsOf: $0) }
            }
            return range
        }
        let batches = parts.map { part in
            let positions = append(part.mesh.positions.flatMap { [$0.x.bitPattern, $0.y.bitPattern, $0.z.bitPattern] })
            let normals = append(part.mesh.normals.flatMap { [$0.x.bitPattern, $0.y.bitPattern, $0.z.bitPattern] })
            let uv = append(part.mesh.uv.flatMap { [$0.x.bitPattern, $0.y.bitPattern] })
            let indices = append(part.mesh.indices)
            return Batch(name: part.name, role: part.role, color: [part.color.x, part.color.y, part.color.z],
                         roughness: part.roughness, metallic: part.metallic,
                         explode: [part.separation.x, part.separation.y, part.separation.z],
                         positions: positions, normals: normals, uv: uv, indices: indices)
        }
        let title = ElementStudioSettings.choices.first { $0.id == id }?.name ?? id
        let asset = ElementStudioAsset(id: id, name: title, sub: "Native form study",
            description: "An original, reusable procedural form with editable materials and studio lighting.",
            geometry: "Native Swift parametric mesh, version 1", batches: batches, printSurface: nil)
        return Loaded(asset: asset, data: data)
    }
}

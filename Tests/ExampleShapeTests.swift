import XCTest
import simd
@testable import ElementStudio

@MainActor final class ExampleShapeTests: XCTestCase {
    func testMeshesAreClosedFiniteAndOutwardFacing() throws {
        struct Edge: Hashable { let a: Int; let b: Int }
        for id in StudioExampleShapes.ids {
            let parts = try XCTUnwrap(StudioExampleShapes.make(id: id))
            for part in parts {
                let mesh = part.mesh
                XCTAssertFalse(mesh.positions.isEmpty)
                XCTAssertLessThan(mesh.positions.count, 10_000)
                XCTAssertEqual(mesh.normals.count, mesh.positions.count)
                XCTAssertEqual(mesh.uv.count, mesh.positions.count)
                XCTAssertEqual(mesh.indices.count % 3, 0)
                var welded: [String: Int] = [:]
                var vertexIDs: [Int] = []
                for (i, p) in mesh.positions.enumerated() {
                    XCTAssertTrue(p.x.isFinite && p.y.isFinite && p.z.isFinite)
                    XCTAssertLessThan(simd_length(p), 2)
                    XCTAssertEqual(simd_length(mesh.normals[i]), 1, accuracy: 0.001)
                    XCTAssertTrue(mesh.uv[i].x.isFinite && mesh.uv[i].y.isFinite)
                    let key = [p.x, p.y, p.z].map { String(Int(($0 * 100_000).rounded())) }.joined(separator: ",")
                    if welded[key] == nil { welded[key] = welded.count }
                    vertexIDs.append(welded[key]!)
                }
                var edges: [Edge: Int] = [:]
                for offset in stride(from: 0, to: mesh.indices.count, by: 3) {
                    let face = mesh.indices[offset..<(offset + 3)].map(Int.init)
                    guard face.allSatisfy({ mesh.positions.indices.contains($0) }) else {
                        XCTFail("Out-of-range index in \(id)/\(part.name)"); continue
                    }
                    let a = mesh.positions[face[0]], b = mesh.positions[face[1]], c = mesh.positions[face[2]]
                    let normal = simd_cross(b - a, c - a)
                    XCTAssertGreaterThan(simd_length_squared(normal), 1e-12, "Degenerate triangle in \(id)")
                    XCTAssertGreaterThan(simd_dot(normal, mesh.normals[face[0]] + mesh.normals[face[1]] + mesh.normals[face[2]]), 0,
                                         "Winding disagrees with normals in \(id)")
                    for pair in [(face[0], face[1]), (face[1], face[2]), (face[2], face[0])] {
                        let first = vertexIDs[pair.0], second = vertexIDs[pair.1]
                        edges[Edge(a: min(first, second), b: max(first, second)), default: 0] += 1
                    }
                }
                XCTAssertTrue(edges.values.allSatisfy { $0 == 2 }, "Open/nonmanifold seam in \(id)/\(part.name)")
            }
        }
    }

    func testNativeBuffersAreDeterministicAndEditionIndependent() throws {
        for id in StudioExampleShapes.ids {
            let first = try ElementStudioAsset.read(id: id)
            XCTAssertEqual(first.data, try ElementStudioAsset.read(id: id).data)
            for edition in ElementStudioSettings.Edition.allCases {
                var settings = ElementStudioSettings(); settings.selected = id; settings.chosenEdition = edition
                XCTAssertEqual(settings.assetIDs, [id])
            }
        }
    }

    func testExampleLooksSurviveSaveImportAndRelaunch() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "library.json")
        let library = StudioLibrary(url: url)
        for id in StudioExampleShapes.ids {
            var settings = ElementStudioSettings(); settings.selected = id
            settings.light = 75; settings.roughness = 0.6; settings.tintRGB = [0.2, 0.5, 0.7]
            settings.explode = 0.4; settings.thickness = 1.3; settings.camera = [1.2, 0.2, 1.5]
            _ = library.saveLook(name: id, settings: settings, collection: nil)
        }
        let reopened = StudioLibrary(url: url)
        XCTAssertEqual(reopened.archive.looks, library.archive.looks)
        let imported = StudioLibrary(url: folder.appending(path: "imported.json"))
        try imported.importData(StudioDocument(archive: reopened.archive).data)
        XCTAssertEqual(imported.archive.looks.map(\.settings), library.archive.looks.map(\.settings))
    }

    func testExamplesRenderNativeTransparentThumbnails() async throws {
        let renderer = ElementStudioRenderer(reporting: false)
        for id in StudioExampleShapes.ids {
            var settings = ElementStudioSettings(); settings.selected = id; settings.reduceMotion = true
            await renderer.load(settings)
            XCTAssertNil(renderer.error)
            let image = try await renderer.snapshot(size: CGSize(width: 600, height: 600), transparent: true)
            let cg = try XCTUnwrap(image.cgImage)
            let bytes = try XCTUnwrap(cg.dataProvider?.data) as Data
            let alpha = stride(from: 3, to: bytes.count, by: 4).map { bytes[$0] }
            XCTAssertTrue(alpha.contains(0), "Transparent exterior is required")
            XCTAssertTrue(alpha.contains { $0 > 240 }, "Native geometry must actually render")
            let attachment = XCTAttachment(image: image)
            attachment.name = "Catalogue-" + id
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}

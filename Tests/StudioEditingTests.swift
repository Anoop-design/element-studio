import XCTest
@testable import ElementStudio

@MainActor final class StudioEditingTests: XCTestCase {
    func testGestureIsOneUndoAndRedoPreservesOtherEdits() {
        let history = StudioEditHistory()
        var current = ElementStudioSettings()
        history.restore = { current = $0 }
        history.start(current)
        history.begin(current, name: "Texture")
        for step in 1...8 { current.grain = Double(step) / 10; history.observe(current) }
        history.end(current)
        history.observe(current) // A late SwiftUI update must not create another entry.
        XCTAssertEqual(history.undoTitle, "Undo Texture")
        history.undo(); XCTAssertEqual(current.grain, 0.16); XCTAssertFalse(history.canUndo)
        history.redo(); XCTAssertEqual(current.grain, 0.8); XCTAssertTrue(history.canUndo)
        current.light = 42; history.observe(current)
        history.undo(); XCTAssertEqual(current.light, -35); XCTAssertEqual(current.grain, 0.8)
        history.undo(); XCTAssertEqual(current.grain, 0.16)
        history.redo(); history.redo(); XCTAssertEqual(current.light, 42)
    }
    func testNoOpAndViewChangesDoNotCreateHistory() {
        let history = StudioEditHistory(); var settings = ElementStudioSettings()
        history.start(settings); history.begin(settings, name: "Finish"); history.end(settings)
        settings.camera = [1,0.2,2]; settings.wireframe = true; history.observe(settings)
        XCTAssertFalse(history.canUndo)
        settings.grain = 0.9; history.observe(settings); XCTAssertTrue(history.canUndo)
        settings.selected = "ribbon"; history.observe(settings); XCTAssertFalse(history.canUndo)
    }
    func testResetOnlyChangesRequestedControlsAndKeepsGeometryAndPose() {
        var settings = ElementStudioSettings()
        settings.selected = "ribbon"; settings.chosenEdition = .studioOriginal; settings.chosenStudy = .ceramic
        settings.surfaceRevision = nil; settings.camera = [1.2,0.1,1.7]
        settings.roughness = 0.6; settings.light = 80; settings.thickness = 1.5; settings.tintRGB = [1,0,0]
        let surface = settings.originalAppearance(panel: "Surface")
        XCTAssertEqual(surface.roughness, 0.4); XCTAssertNil(surface.tintRGB)
        XCTAssertEqual(surface.light, 80); XCTAssertEqual(surface.thickness, 1.5)
        XCTAssertEqual(surface.camera, settings.camera); XCTAssertEqual(surface.assetIDs, settings.assetIDs)
        XCTAssertNil(surface.surfaceRevision)
        let all = settings.originalAppearance()
        XCTAssertEqual(all.light, -35); XCTAssertEqual(all.thickness, 1); XCTAssertEqual(all.camera, settings.camera)
    }
    func testPreciseValuesValidateRangeAndLocale() {
        XCTAssertEqual(StudioParameter.texture.parse("25"), 0.25)
        XCTAssertEqual(StudioParameter.light.parse("-90"), -90)
        XCTAssertEqual(StudioParameter.depth.parse("1,25", locale: Locale(identifier: "fr_FR")), 1.25)
        for invalid in ["", "NaN", "infinity", "1x", "1.2.3", "4"] {
            XCTAssertNil(StudioParameter.depth.parse(invalid), invalid)
        }
        XCTAssertNil(StudioParameter.texture.parse("101"))
        XCTAssertEqual(StudioParameter.finish.display(0.12), "Gloss")
        XCTAssertEqual(StudioParameter.finish.display(0.4), "Satin")
        XCTAssertEqual(StudioParameter.finish.display(0.65), "Matte")
    }
    func testOlderSavedSettingsRetainMaterialResponse() throws {
        let data = try JSONEncoder().encode(ElementStudioSettings())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "surfaceRevision")
        let old = try JSONDecoder().decode(ElementStudioSettings.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(old.surfaceRevision)
        XCTAssertEqual(ElementStudioSettings().surfaceRevision, 1)
    }
    func testExportPreservesTransparentPixelsAndCompositesBackground() throws {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = false
        let original = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8), format: format).image { context in
            UIColor.red.setFill(); context.fill(CGRect(x: 2, y: 2, width: 4, height: 4))
        }
        func pixel(_ image: UIImage, x: Int, y: Int) throws -> [UInt8] {
            var bytes = [UInt8](repeating: 0, count: 8 * 8 * 4)
            try bytes.withUnsafeMutableBytes { data in
                let ctx = try XCTUnwrap(CGContext(data: data.baseAddress, width: 8, height: 8, bitsPerComponent: 8,
                    bytesPerRow: 32, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                ctx.draw(try XCTUnwrap(image.cgImage), in: CGRect(x: 0, y: 0, width: 8, height: 8))
            }
            return Array(bytes[(y * 8 + x) * 4..<(y * 8 + x) * 4 + 4])
        }
        let transparent = StudioImageExport.image(original, background: .transparent)
        XCTAssertEqual(try pixel(transparent, x: 0, y: 0)[3], 0)
        XCTAssertEqual(try pixel(StudioImageExport.image(original, background: .white), x: 0, y: 0), [255,255,255,255])
        XCTAssertEqual(try pixel(StudioImageExport.image(original, background: .black), x: 0, y: 0), [0,0,0,255])
        XCTAssertEqual(try pixel(StudioImageExport.image(original, background: .black), x: 4, y: 4), [255,0,0,255])
    }
}

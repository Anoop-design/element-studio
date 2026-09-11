import XCTest
@testable import ElementStudio

@MainActor final class LibraryTests: XCTestCase {
    private func file() -> URL { FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + "/library.json") }
    func testSavedLookSurvivesRelaunchExactly() throws {
        let url = file(), library = StudioLibrary(url: url)
        var settings = ElementStudioSettings(); settings.selected = "ribbon"; settings.chosenStudy = .ceramic
        settings.tintRGB = [0.1,0.4,0.7]; settings.light = 78; settings.clearcoat = 0.22
        settings.camera = [1.3,0.25,2.4]
        let saved = library.saveLook(name: "Blue ceramic", settings: settings, collection: library.archive.collections[0].id)
        let reopened = StudioLibrary(url: url)
        XCTAssertEqual(reopened.archive.looks.first, saved)
        XCTAssertEqual(reopened.archive.looks.first?.settings, settings)
    }
    func testCatalogueRefreshPreservesOldLooksAndKeepsNewLooksCurrent() throws {
        let url = file()
        var old = StudioArchive(); old.version = 1
        var settings = ElementStudioSettings(); settings.selected = "halfYear"
        settings.tintRGB = [0.2, 0.3, 0.5]; settings.camera = [1.2, 0.1, 1.5]
        old.looks = [StudioLook(name: "Saved fan", settings: settings)]
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(old).write(to: url)
        let library = StudioLibrary(url: url)
        let preserved = try XCTUnwrap(library.archive.looks.first)
        XCTAssertEqual(preserved.id, old.looks[0].id)
        XCTAssertEqual(preserved.settings.assetIDs, ["halfYear-studio20260911"])
        XCTAssertEqual(preserved.settings.tintRGB, settings.tintRGB)
        XCTAssertEqual(preserved.settings.camera, settings.camera)
        XCTAssertEqual(library.archive.workspace.chosenEdition, .latest)
        XCTAssertEqual(library.archive.version, 2)
        let current = library.saveLook(name: "New medallion", settings: settings, collection: nil)
        let reopened = StudioLibrary(url: url)
        XCTAssertEqual(reopened.archive.looks.first, current)
        XCTAssertEqual(reopened.archive.looks.last, preserved)
        XCTAssertEqual(current.settings.assetIDs, ["halfYear"])
        let imported = StudioLibrary(url: file())
        try imported.importData(JSONEncoder().encode(old))
        XCTAssertEqual(imported.archive.looks.first?.settings.assetIDs, ["halfYear-studio20260911"])
    }

    func testDeletingCollectionKeepsLooks() {
        let library = StudioLibrary(url: file()), id = library.archive.collections[0].id
        let look = library.saveLook(name: "Keep me", settings: .init(), collection: id)
        library.removeCollection(id)
        XCTAssertEqual(library.archive.looks.first?.id, look.id)
        XCTAssertNil(library.archive.looks.first?.collectionID)
    }
    func testImportAddsCopiesAndRemapsCollectionIDs() throws {
        let library = StudioLibrary(url: file())
        let original = library.saveLook(name: "Original", settings: .init(), collection: library.archive.collections[0].id)
        let data = try StudioDocument(archive: library.archive).data
        try library.importData(data)
        XCTAssertEqual(library.archive.looks.count, 2)
        XCTAssertEqual(library.archive.looks[0], original)
        XCTAssertNotEqual(library.archive.looks[1].id, original.id)
        XCTAssertNotEqual(library.archive.looks[1].collectionID, original.collectionID)
        XCTAssertTrue(library.archive.collections.contains { $0.id == library.archive.looks[1].collectionID })
    }
    func testInvalidImportDoesNotChangeLibrary() throws {
        let library = StudioLibrary(url: file())
        let before = library.archive.collections
        var incoming = StudioArchive(); incoming.version = 500
        XCTAssertThrowsError(try library.importData(JSONEncoder().encode(incoming)))
        XCTAssertEqual(library.archive.collections, before)
        incoming.version = 1; incoming.collections[0].objects = ["missing-model"]
        XCTAssertThrowsError(try library.importData(JSONEncoder().encode(incoming)))
        XCTAssertEqual(library.archive.collections, before)
    }
    func testMalformedColorCannotReachRenderer() {
        var settings = ElementStudioSettings(); settings.tintRGB = [.nan,2,-1]; settings.clamp()
        XCTAssertNil(settings.tintRGB)
        settings.tintRGB = [-1,0.5,2]; settings.clamp(); XCTAssertEqual(settings.tintRGB, [0,0.5,1])
    }
    func testEveryEditionAndStudyHasReadableGeometry() throws {
        for edition in ElementStudioSettings.Edition.allCases {
            for object in ElementStudioSettings.choices {
                var settings = ElementStudioSettings(); settings.selected = object.id; settings.chosenEdition = edition
                for study in ElementStudioSettings.ShapeStudy.allCases {
                    settings.chosenStudy = study
                    for id in settings.assetIDs {
                        let loaded = try ElementStudioAsset.read(id: id)
                        XCTAssertFalse(loaded.asset.batches.isEmpty)
                        for batch in loaded.asset.batches {
                            let positions = try ElementStudioAsset.floats(batch.positions, in: loaded.data)
                            let indices = try ElementStudioAsset.indices(batch.indices, in: loaded.data)
                            XCTAssertTrue(positions.allSatisfy(\.isFinite))
                            XCTAssertTrue(indices.allSatisfy { $0 < positions.count / 3 })
                        }
                    }
                }
            }
        }
    }
}

import XCTest
import UIKit
@testable import ElementStudio

@MainActor final class NativeCatalogueTests: XCTestCase {
    func testNewDefaultAndPublishedLooksKeepSeparateGeometry() throws {
        XCTAssertEqual(ElementStudioSettings().assetIDs,["stopwatch-swift-v1"])
        let directory=FileManager.default.temporaryDirectory.appending(path:UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        let library=StudioLibrary(url:directory.appending(path:"library.json"))
        for edition in ElementStudioSettings.Edition.allCases {
            var settings=ElementStudioSettings();settings.selected="ribbon";settings.chosenStudy = .ceramic;settings.chosenEdition=edition
            library.saveLook(name:edition.rawValue,settings:settings,collection:nil)
        }
        let copied=StudioLibrary(url:directory.appending(path:"copy.json"))
        try copied.importData(StudioDocument(archive:library.archive).data)
        XCTAssertEqual(copied.archive.looks.map(\.settings),library.archive.looks.map(\.settings))
        XCTAssertEqual(StudioLibrary(url:directory.appending(path:"copy.json")).archive.looks.map(\.settings),library.archive.looks.map(\.settings))
        var original=ElementStudioSettings();original.chosenEdition = .latest
        XCTAssertEqual(original.assetIDs,["stopwatch"])
        original.edition=nil;XCTAssertEqual(original.assetIDs,["stopwatch-forms20260910"])
    }

    func testDaybeatCatalogueRendersInNativeSimulator() async throws {
        let renderer=ElementStudioRenderer(reporting:false)
        let folder=URL.cachesDirectory.appending(path:"NativePortReview")
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        let ids=ElementStudioSettings.choices.map(\.id).filter {!StudioExampleShapes.ids.contains($0)}
        let variants=ids.map {($0,Optional<ElementStudioSettings.ShapeStudy>.none)} + [
            ("returning",.folded),("returning",.ceramic),("ribbon",.curved),("ribbon",.ceramic)]
        for (id,study) in variants {
            for edition in [ElementStudioSettings.Edition.native,.latest] {
                var settings=ElementStudioSettings();settings.selected=id;settings.chosenEdition=edition;settings.reduceMotion=true
                if let study {settings.chosenStudy=study}
                await renderer.load(settings)
                XCTAssertNil(renderer.error,"\(id) / \(edition)")
                for pose in ["front","reverse"] {
                    settings.camera=pose=="reverse" ? [Double.pi,0.1,1]:[-0.28,0.10,1]
                    renderer.apply(settings)
                    let image=try await renderer.snapshot(size:CGSize(width:600,height:600),transparent:true)
                    let cg=try XCTUnwrap(image.cgImage),bytes=try XCTUnwrap(cg.dataProvider?.data) as Data
                    let alpha=stride(from:3,to:bytes.count,by:4).map {bytes[$0]}
                    XCTAssertTrue(alpha.contains(0),"Transparent exterior: \(id)")
                    XCTAssertGreaterThan(alpha.filter {$0>240}.count,2000,"Visible rendered geometry: \(id)")
                    let name=id+(study.map {"-"+$0.rawValue.lowercased()} ?? "")+"-"+(edition == .native ? "swift":"preserved")+"-"+pose
                    let attachment=XCTAttachment(image:image);attachment.name=name;attachment.lifetime = .keepAlways;add(attachment)
                    try image.pngData()?.write(to:folder.appending(path:name+".png"))
                }
            }
        }
    }
}

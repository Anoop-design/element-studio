import XCTest

@MainActor final class StudioFlowTests: XCTestCase {
    func testContinuousCollectionAndMorphingTools() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["STUDIO_REVIEW":"1"]
        app.launchArguments = ["-studio.appearance", "Light"]
        app.launch()
        let tile = app.buttons["element-stopwatch"]
        XCTAssertTrue(tile.waitForExistence(timeout: 60))
        XCTAssertEqual(app.searchFields.count, 0)
        XCTAssertEqual(app.tabBars.count, 0)
        capture("Live collection")
        XCTAssertEqual(tile.frame.midY, app.buttons["element-memory"].frame.midY, accuracy: 1)
        XCTAssertGreaterThan(app.buttons["element-energy"].frame.midY, tile.frame.midY)
        let fittedFrame = tile.frame
        app.pinch(withScale: 0.4, velocity: -1)
        XCTAssertEqual(tile.frame.width, fittedFrame.width, accuracy: 2)
        XCTAssertEqual(tile.frame.midX, fittedFrame.midX, accuracy: 2)
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.48))
        start.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.48)))
        capture("Collection rotated together")
        let original = tile.frame.width
        app.pinch(withScale: 1.45, velocity: 0.8)
        XCTAssertGreaterThan(tile.frame.width, original * 1.15, "Pinching must enlarge the live collection")
        capture("Collection zoomed")
        app.pinch(withScale: 0.70, velocity: -0.8)
        tile.tap()
        let save = app.buttons["save-look"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(save.isEnabled, "Selecting a warmed object must not load a new scene")
        let viewport = app.otherElements["element-studio-viewport"]
        XCTAssertTrue(viewport.waitForExistence(timeout: 5))
        XCTAssertFalse((viewport.value as? String ?? "").contains("Rotation -16 degrees"))
        capture("Direct object focus")
        viewport.swipeLeft()
        let first = viewport.value as? String
        app.buttons["panel-Surface"].tap()
        XCTAssertTrue(app.sliders["Finish"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.sliders.count, 2)
        XCTAssertFalse(app.staticTexts["Design edition"].exists)
        XCTAssertFalse(app.staticTexts["Preparing element"].exists)
        XCTAssertTrue(app.staticTexts["Surface"].exists, "Expanded controls must identify the selected tool")
        capture("Surface dock")
        app.sliders["Texture"].adjust(toNormalizedSliderPosition: 0.25)
        app.buttons["all-tools"].tap()
        app.buttons["panel-Light"].tap()
        XCTAssertEqual(first, viewport.value as? String, "Opening tools should preserve the rotation and zoom")
        let light = app.sliders["Light direction"]
        XCTAssertTrue(light.waitForExistence(timeout: 5))
        light.adjust(toNormalizedSliderPosition: 0.6)
        capture("Light dock")
        app.buttons["reset-object"].tap()
        XCTAssertEqual(light.value as? String, "-35°")
        capture("Reset object")
        app.buttons["all-tools"].tap()
        app.buttons["panel-Form"].tap()
        XCTAssertTrue(app.sliders["Depth"].waitForExistence(timeout: 5))
        capture("Form dock")
        app.buttons["share-look"].tap()
        XCTAssertTrue(app.buttons["share-image"].waitForExistence(timeout: 30))
        capture("Share preview")
        app.buttons["close-share"].tap()
        save.tap()
        let name = "Continuous study " + String(UUID().uuidString.prefix(4))
        app.textFields["look-name"].tap(); app.textFields["look-name"].typeText(name)
        app.buttons["confirm-save"].tap()
        XCTAssertTrue(app.buttons["close-studio"].waitForExistence(timeout: 15))
        app.buttons["close-studio"].tap()
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        for id in ["hourglass", "memory", "energy", "distance", "sunrise", "pennant", "returning", "week", "month", "halfYear", "year", "ribbon", "activity", "frequency", "collection"] {
            app.buttons["element-" + id].tap()
            XCTAssertTrue(save.waitForExistence(timeout: 5))
            XCTAssertTrue(save.isEnabled)
            let refreshed = ["energy", "returning", "halfYear", "activity"].contains(id)
            if refreshed { capture("Updated " + id + " initial pose") }
            viewport.swipeRight()
            if refreshed {
                capture("Updated " + id + " first turn")
                viewport.swipeRight()
                capture("Updated " + id + " second turn")
                viewport.swipeRight()
                capture("Updated " + id + " third turn")
            } else if id == "ribbon" { capture("Rotated " + id) }
            app.buttons["close-studio"].tap()
            XCTAssertTrue(tile.waitForExistence(timeout: 5))
        }
        app.terminate(); app.launch()
        app.buttons["studio-options"].tap()
        app.buttons["Saved looks"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 10))
        app.staticTexts[name].tap()
        XCTAssertTrue(save.waitForExistence(timeout: 60))
    }
    func testDarkCollectionAndSurface() {
        let app = XCUIApplication()
        app.launchEnvironment = ["STUDIO_REVIEW":"1"]
        app.launchArguments = ["-studio.appearance", "Dark"]
        app.launch()
        XCTAssertTrue(app.buttons["element-ribbon"].waitForExistence(timeout: 60))
        capture("Dark live collection")
        app.buttons["element-ribbon"].tap()
        XCTAssertTrue(app.buttons["panel-Surface"].waitForExistence(timeout: 5))
        XCTAssertGreaterThan(app.toolbars.count, 0)
        capture("Dark ribbon focus")
        app.buttons["panel-Surface"].tap()
        XCTAssertTrue(app.sliders["Texture"].waitForExistence(timeout: 5))
        let viewport = app.otherElements["element-studio-viewport"]
        let before = viewport.value as? String
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.32)).press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.32)))
        XCTAssertNotEqual(before, viewport.value as? String)
        XCTAssertTrue(app.sliders["Texture"].exists)
        capture("Dark surface dock")
    }
    func testMeshInspectionDoesNotLeakAcrossObjectsOrRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-studio.appearance", "Dark"]
        app.launch()
        XCTAssertTrue(app.buttons["element-stopwatch"].waitForExistence(timeout: 60))
        app.buttons["element-stopwatch"].tap()
        app.buttons["panel-Form"].tap()
        let mesh = app.switches["Show mesh"]
        XCTAssertTrue(mesh.waitForExistence(timeout: 5))
        XCTAssertEqual(mesh.value as? String, "0")
        mesh.tap()
        XCTAssertEqual(mesh.value as? String, "1")
        capture("Explicit mesh inspection")
        app.buttons["all-tools"].tap()
        app.buttons["panel-Surface"].tap()
        app.sliders["Finish"].adjust(toNormalizedSliderPosition: 0.7)
        capture("Mesh inspection after material edit")
        app.buttons["all-tools"].tap()
        app.buttons["close-studio"].tap()
        XCTAssertTrue(app.buttons["element-ribbon"].waitForExistence(timeout: 5))
        capture("Solid collection after mesh inspection")
        app.buttons["element-ribbon"].tap()
        app.buttons["panel-Form"].tap()
        XCTAssertTrue(mesh.waitForExistence(timeout: 5))
        XCTAssertEqual(mesh.value as? String, "0")
        capture("Next object starts shaded")
        app.buttons["all-tools"].tap()
        app.buttons["close-studio"].tap()
        XCTAssertTrue(app.buttons["element-stopwatch"].waitForExistence(timeout: 5))
        app.buttons["element-stopwatch"].tap()
        app.buttons["panel-Form"].tap()
        XCTAssertTrue(mesh.waitForExistence(timeout: 5))
        XCTAssertEqual(mesh.value as? String, "0")
        capture("Inspected object returns shaded")
        mesh.tap()
        XCTAssertEqual(mesh.value as? String, "1")
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["element-stopwatch"].waitForExistence(timeout: 60))
        capture("Solid collection after relaunch")
        app.buttons["element-stopwatch"].tap()
        app.buttons["panel-Form"].tap()
        XCTAssertTrue(mesh.waitForExistence(timeout: 5))
        XCTAssertEqual(mesh.value as? String, "0")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}

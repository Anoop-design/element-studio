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
        app.buttons["reset-all-edits"].tap()
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
        app.buttons["all-tools"].tap(); app.buttons["panel-Light"].tap()
        XCTAssertTrue(app.sliders["Brightness"].waitForExistence(timeout: 5))
        capture("Light panel complete labels")
    }
    func testMeshInspectionDoesNotLeakAcrossObjectsOrRelaunch() {
        let app = XCUIApplication()
        app.launchEnvironment = ["STUDIO_REVIEW":"1"]
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

    func testPrecisionUndoComparisonAndExport() {
        let app = XCUIApplication()
        app.launchEnvironment = ["STUDIO_REVIEW":"1"]
        app.launchArguments = ["-studio.appearance", "Light"]
        app.launch()
        XCTAssertTrue(app.buttons["element-energy"].waitForExistence(timeout: 60))
        app.buttons["element-energy"].tap()
        app.buttons["panel-Surface"].tap()
        app.buttons["reset-object"].tap(); app.buttons["reset-all-edits"].tap()
        XCTAssertTrue(app.buttons["edit-color"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["edit-color"].value as? String, "Original colors")
        capture("Polished surface controls")
        app.buttons["value-finish"].tap()
        let input = app.alerts.textFields.firstMatch
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        // Native alert fields do not retain SwiftUI accessibility identifiers.
        let existing = input.value as? String ?? ""
        input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count) + "0.62")
        capture("Precise finish entry")
        app.alerts.buttons["Apply"].tap()
        XCTAssertEqual(app.buttons["value-finish"].value as? String, "Matte")
        app.buttons["reset-object"].tap()
        capture("Undo and reset menu")
        app.buttons["undo-edit"].tap()
        XCTAssertEqual(app.buttons["value-finish"].value as? String, "Satin")
        app.buttons["reset-object"].tap(); app.buttons["redo-edit"].tap()
        XCTAssertEqual(app.buttons["value-finish"].value as? String, "Matte")
        let viewport = app.otherElements["element-studio-viewport"]
        let pose = viewport.value as? String
        app.buttons["compare-original"].press(forDuration: 1)
        XCTAssertEqual(app.buttons["compare-original"].value as? String, "Edited")
        XCTAssertEqual(app.buttons["value-finish"].value as? String, "Matte")
        XCTAssertEqual(viewport.value as? String, pose)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.30)).press(forDuration: 0.1,
            thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.30)))
        app.buttons["reset-object"].tap(); app.buttons["reset-view"].tap()
        XCTAssertEqual(app.buttons["value-finish"].value as? String, "Matte")
        capture("Reset view keeps finish")
        app.buttons["all-tools"].tap()
        app.buttons["close-studio"].tap()
        XCTAssertTrue(app.buttons["element-stopwatch"].waitForExistence(timeout: 5))
        app.buttons["element-stopwatch"].tap()
        app.buttons["panel-Surface"].tap()
        XCTAssertEqual(app.buttons["value-finish"].value as? String, "Satin", "Another object must keep its own finish")
        app.buttons["all-tools"].tap(); app.buttons["close-studio"].tap()
        XCTAssertTrue(app.buttons["element-energy"].waitForExistence(timeout: 5))
        app.buttons["element-energy"].tap(); app.buttons["panel-Surface"].tap()
        XCTAssertEqual(app.buttons["value-finish"].value as? String, "Matte", "Returning to an element must restore its controls")
        app.buttons["all-tools"].tap()
        app.buttons["share-look"].tap()
        XCTAssertTrue(app.buttons["share-image"].waitForExistence(timeout: 30))
        capture("Transparent PNG preview")
        app.segmentedControls.buttons["White"].tap()
        XCTAssertEqual(app.images["export-preview"].value as? String, "White")
        capture("White PNG preview")
        app.segmentedControls.buttons["Black"].tap()
        XCTAssertEqual(app.images["export-preview"].value as? String, "Black")
        capture("Black PNG preview")
        app.buttons["close-share"].tap()
        app.buttons["panel-Surface"].tap()
        XCTAssertEqual(app.buttons["value-finish"].value as? String, "Matte")
        app.buttons["reset-object"].tap(); app.buttons["reset-all-edits"].tap()
    }

    func testNativeColorPicker() {
        let app = XCUIApplication()
        app.launchEnvironment = ["STUDIO_REVIEW":"1"]
        app.launchArguments = ["-studio.appearance", "Light"]
        app.launch()
        XCTAssertTrue(app.buttons["element-energy"].waitForExistence(timeout: 60))
        app.buttons["element-energy"].tap(); app.buttons["panel-Surface"].tap()
        app.buttons["reset-object"].tap(); app.buttons["reset-all-edits"].tap()
        app.buttons["edit-color"].tap()
        XCTAssertTrue(app.otherElements["native-color-picker"].waitForExistence(timeout: 5))
        capture("Native color picker")
        app.collectionViews["Favorites"].cells.element(boundBy: 1).tap()
        let close = app.buttons["close"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        XCTAssertTrue(app.buttons["edit-color"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["edit-color"].value as? String, "Custom color")
        capture("Custom color applied")
        app.buttons["reset-object"].tap(); app.buttons["undo-edit"].tap()
        XCTAssertEqual(app.buttons["edit-color"].value as? String, "Original colors")
    }

    func testFormFitsAndSurvivesRepeatedAdjustments() {
        let app = XCUIApplication()
        app.launchEnvironment = ["STUDIO_REVIEW":"1"]
        app.launchArguments = ["-studio.appearance", "Light"]
        app.launch()
        XCTAssertTrue(app.buttons["element-pennant"].waitForExistence(timeout: 60))
        for id in ["pennant", "memory", "returning", "collection"] {
            app.buttons["element-" + id].tap()
            app.buttons["panel-Form"].tap()
            let mesh = app.switches["Show mesh"]
            XCTAssertTrue(mesh.waitForExistence(timeout: 5))
            let controls = app.scrollViews["tool-controls"]
            XCTAssertGreaterThanOrEqual(mesh.frame.minY, controls.frame.minY)
            XCTAssertLessThanOrEqual(mesh.frame.maxY, controls.frame.maxY - 3, "The full mesh toggle must fit without scrolling")
            XCTAssertLessThan(mesh.frame.maxY, app.buttons["compare-original"].frame.minY)
            XCTAssertTrue(mesh.isHittable)
            if id == "pennant" { capture("Form complete without scrolling") }
            for position in [CGFloat(1), 0, 0.8, 0.2] {
                app.sliders["Depth"].adjust(toNormalizedSliderPosition: position)
                app.sliders["Separate components"].adjust(toNormalizedSliderPosition: 1 - position)
                mesh.tap()
                XCTAssertEqual(app.state, .runningForeground)
                XCTAssertTrue(app.buttons["compare-original"].isHittable)
            }
            app.buttons["close-studio"].tap()
            XCTAssertTrue(app.buttons["element-" + id].waitForExistence(timeout: 5))
        }
    }

    func testFormAdaptsToLargeText() {
        let app = XCUIApplication()
        app.launchEnvironment = ["STUDIO_REVIEW":"1"]
        app.launchArguments = ["-studio.appearance", "Dark", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["element-pennant"].waitForExistence(timeout: 60))
        app.buttons["element-pennant"].tap(); app.buttons["panel-Form"].tap()
        let mesh = app.switches["Show mesh"]
        XCTAssertTrue(mesh.waitForExistence(timeout: 5))
        let controls = app.scrollViews["tool-controls"]
        if !mesh.isHittable || mesh.frame.maxY > controls.frame.maxY { controls.swipeUp() }
        XCTAssertTrue(mesh.isHittable)
        XCTAssertGreaterThanOrEqual(mesh.frame.minX, controls.frame.minX)
        XCTAssertLessThanOrEqual(mesh.frame.maxX, controls.frame.maxX)
        XCTAssertTrue(app.buttons["compare-original"].isHittable)
        capture("Form with accessibility text")
    }

    func testFocusReturnsToExactCollectionFraming() {
        let app = XCUIApplication()
        app.launchEnvironment = ["STUDIO_REVIEW":"1"]
        app.launchArguments = ["-studio.appearance", "Light"]
        app.launch()
        XCTAssertTrue(app.buttons["element-stopwatch"].waitForExistence(timeout: 60))
        for id in ["stopwatch", "memory", "collection"] {
            let tile = app.buttons["element-" + id]
            let before = tile.frame
            tile.tap()
            XCTAssertTrue(app.buttons["close-studio"].waitForExistence(timeout: 5))
            capture("Spring focus " + id)
            app.buttons["close-studio"].tap()
            XCTAssertTrue(tile.waitForExistence(timeout: 5))
            XCTAssertEqual(tile.frame.midX, before.midX, accuracy: 1)
            XCTAssertEqual(tile.frame.midY, before.midY, accuracy: 1)
            XCTAssertEqual(tile.frame.width, before.width, accuracy: 1)
        }
        app.pinch(withScale: 1.4, velocity: 1)
        let tile = app.buttons["element-returning"]
        let zoomedFrame = tile.frame
        tile.tap(); app.buttons["panel-Form"].tap()
        app.sliders["Separate components"].adjust(toNormalizedSliderPosition: 0.7)
        capture("Close from expanded form")
        app.buttons["close-studio"].tap()
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        XCTAssertEqual(tile.frame.midX, zoomedFrame.midX, accuracy: 1)
        XCTAssertEqual(tile.frame.midY, zoomedFrame.midY, accuracy: 1)
        XCTAssertEqual(tile.frame.width, zoomedFrame.width, accuracy: 1, "Exploding the object must not change the collection's saved zoom")
        capture("Restored zoomed collection")
        tile.tap(); app.buttons["panel-Form"].tap()
        XCTAssertNotEqual(app.sliders["Separate components"].value as? String, "0%", "Closing must preserve the object's edits")
        app.buttons["reset-object"].tap(); app.buttons["reset-all-edits"].tap()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}

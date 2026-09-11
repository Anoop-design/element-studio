import XCTest
@testable import ElementStudio

final class CameraGeometryTests: XCTestCase {
    func testSixteenElementsUseThreeColumnsAndCenteredLastRow() {
        let points = (0..<16).map { StudioCameraGeometry.position(index: $0, count: 16) }
        XCTAssertEqual(Set(points.prefix(3).map(\.y)).count, 1)
        XCTAssertEqual(points[3].y, points[0].y - 1)
        XCTAssertEqual(points[15].x, 0)
        XCTAssertEqual(Set(points.map(\.y)).count, 6)
    }
    func testFullyVisibleCanvasCannotBeDraggedAway() {
        let bounds = StudioCameraGeometry.bounds(count: 16)
        XCTAssertEqual(StudioCameraGeometry.clamp(pan: [100,-100], content: bounds, visible: bounds), .zero)
        XCTAssertEqual(StudioCameraGeometry.clamp(pan: [-100,100], content: bounds, visible: bounds * 1.2), .zero)
    }
    func testZoomedCanvasStopsAtContentEdges() {
        let bounds = SIMD2<Float>(3,6)
        XCTAssertEqual(StudioCameraGeometry.clamp(pan: [10,-10], content: bounds, visible: bounds / 2), [0.75,-1.5])
        XCTAssertEqual(StudioCameraGeometry.clamp(pan: [0.2,0.3], content: bounds, visible: bounds / 2), [0.2,0.3])
    }
    func testCameraFlightPreservesEndpointsAndUsesSmoothMagnification() {
        let start = SIMD3<Float>(0,0,10), end = SIMD3<Float>(1,2,2), anchor = SIMD3<Float>(1,2,0)
        for (t, expected) in [(Float(0), start), (Float(1), end)] {
            let value = StudioCameraGeometry.flight(from: start, to: end, anchor: anchor, progress: t)
            XCTAssertEqual(value.x, expected.x, accuracy: 0.0001)
            XCTAssertEqual(value.y, expected.y, accuracy: 0.0001)
            XCTAssertEqual(value.z, expected.z, accuracy: 0.0001)
        }
        let middle = StudioCameraGeometry.flight(from: start, to: end, anchor: anchor, progress: 0.5)
        XCTAssertEqual(middle.z, sqrt(20), accuracy: 0.0001)
        XCTAssertEqual((middle.x-anchor.x)/middle.z, -0.05, accuracy: 0.0001)
    }
    func testSavedZoomRespectsTheNewMinimum() {
        var settings = ElementStudioSettings(); settings.camera = [0,0,0.3]; settings.clamp()
        XCTAssertEqual(settings.camera?[2], 1)
    }
}

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
    func testSpringFollowsTheProjectedSourceAndSettlesWithoutOvershooting() {
        let start = SIMD3<Float>(0,0,10), end = SIMD3<Float>(1,2,2), anchor = SIMD3<Float>(1,2,0)
        let flight = StudioCameraTransition(from: start, to: end, anchor: anchor, initialVelocity: .zero, start: 0, duration: 0.54)
        XCTAssertEqual(flight.sample(at: 0).position, start)
        XCTAssertEqual(flight.sample(at: 0.54).position, end)
        var lastScale: Float = 0.1
        for frame in 1...64 {
            let position = flight.sample(at: Double(frame) / 120).position
            let scale = 1 / position.z
            XCTAssertGreaterThanOrEqual(scale + 0.00001, lastScale)
            XCTAssertLessThanOrEqual(scale, 0.50001)
            let progress = (scale - 0.1) / 0.4
            XCTAssertEqual((position.x-anchor.x)/position.z, -0.1 * (1-progress), accuracy: 0.00001)
            XCTAssertEqual((position.y-anchor.y)/position.z, -0.2 * (1-progress), accuracy: 0.00001)
            lastScale = scale
        }
        XCTAssertGreaterThan(1 / flight.sample(at: 0.1).position.z, 0.2, "The object should respond promptly, without the old slow lead-in")
    }
    func testReversalKeepsPositionAndVelocityAcrossDifferentAnchors() {
        let original = StudioCameraTransition(from: [0,0,10], to: [1,2,2], anchor: [1,2,0], initialVelocity: .zero, start: 0, duration: 0.54)
        let before = original.sample(at: 0.13)
        let returning = StudioCameraTransition(from: before.position, to: [0,0,10], anchor: [-1,-2,0], initialVelocity: before.velocity, start: 0.13, duration: 0.46)
        let after = returning.sample(at: 0.13)
        for axis in 0..<3 {
            XCTAssertEqual(before.position[axis], after.position[axis], accuracy: 0.00001)
            XCTAssertEqual(before.velocity[axis], after.velocity[axis], accuracy: 0.0001)
        }
        for frame in 0...60 {
            let sample = returning.sample(at: 0.13 + Double(frame)/120)
            XCTAssertTrue(sample.position.x.isFinite && sample.position.y.isFinite && sample.position.z.isFinite)
            XCTAssertGreaterThan(sample.position.z, 0)
        }
        XCTAssertEqual(returning.sample(at: 0.60).position, [0,0,10])
    }
    func testLayoutRetargetPreservesContinuityAndOriginalDeadline() {
        let flight = StudioCameraTransition(from: [0,0,10], to: [1,2,2], anchor: [1,2,0], initialVelocity: .zero, start: 0, duration: 0.54)
        let moved = flight.retarget(to: [1,1.8,2.3], at: 0.2)
        for axis in 0..<3 {
            XCTAssertEqual(flight.sample(at: 0.2).position[axis], moved.sample(at: 0.2).position[axis], accuracy: 0.00001)
            XCTAssertEqual(flight.sample(at: 0.2).velocity[axis], moved.sample(at: 0.2).velocity[axis], accuracy: 0.0001)
        }
        XCTAssertEqual(moved.start + moved.duration, 0.54, accuracy: 0.00001)
        XCTAssertEqual(moved.sample(at: 0.54).position, [1,1.8,2.3])
    }
    func testSavedZoomRespectsTheNewMinimum() {
        var settings = ElementStudioSettings(); settings.camera = [0,0,0.3]; settings.clamp()
        XCTAssertEqual(settings.camera?[2], 1)
    }
}

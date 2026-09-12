import SwiftUI

nonisolated enum StudioCameraGeometry {
    static func position(index: Int, count: Int) -> SIMD3<Float> {
        let columns = min(3, max(1, count)), rows = (max(1, count) + columns - 1) / columns
        let row = index / columns
        let rowCount = min(columns, count - row * columns)
        return [Float(index % columns) - Float(rowCount - 1) / 2, Float(rows - 1) / 2 - Float(row), 0]
    }
    static func bounds(count: Int) -> SIMD2<Float> {
        let columns = min(3, max(1, count)), rows = (max(1, count) + columns - 1) / columns
        return [Float(columns) + 0.08, Float(rows) + 0.08]
    }
    static func clamp(pan: SIMD2<Float>, content: SIMD2<Float>, visible: SIMD2<Float>) -> SIMD2<Float> {
        let limit = SIMD2(max(0, (content.x - visible.x) / 2), max(0, (content.y - visible.y) / 2))
        return [min(limit.x, max(-limit.x, pan.x)), min(limit.y, max(-limit.y, pan.y))]
    }

}

/// A native, non-bouncing spring in projected position and apparent size. Retargeting
/// carries world-space velocity across anchors, including a mid-flight return.
nonisolated struct StudioCameraTransition {
    struct Sample { var position: SIMD3<Float>; var velocity: SIMD3<Float> }
    let from: SIMD3<Float>
    let to: SIMD3<Float>
    let anchor: SIMD3<Float>
    let initialVelocity: SIMD3<Float>
    let start: TimeInterval
    let duration: TimeInterval
    var spring: Spring { Spring(settlingDuration: duration, dampingRatio: 1) }

    func sample(at time: TimeInterval) -> Sample {
        let elapsed = max(0, time - start)
        if elapsed >= duration { return Sample(position: to, velocity: .zero) }
        let a = project(from), b = project(to)
        let z = max(0.01, from.z)
        let v = SIMD3(initialVelocity.x / z - a.x * initialVelocity.z / z,
                      initialVelocity.y / z - a.y * initialVelocity.z / z,
                      -initialVelocity.z / (z * z))
        var value = a, velocity = SIMD3<Float>.zero
        for axis in 0..<3 {
            value[axis] += Float(spring.value(target: Double(b[axis] - a[axis]), initialVelocity: Double(v[axis]), time: elapsed))
            velocity[axis] = Float(spring.velocity(target: Double(b[axis] - a[axis]), initialVelocity: Double(v[axis]), time: elapsed))
        }
        let distance = 1 / max(0.001, value.z)
        let speed = -velocity.z * distance * distance
        return Sample(position: [anchor.x + value.x * distance, anchor.y + value.y * distance, distance],
                      velocity: [velocity.x * distance + value.x * speed, velocity.y * distance + value.y * speed, speed])
    }
    func retarget(to destination: SIMD3<Float>, at time: TimeInterval) -> Self {
        let current = sample(at: time)
        return Self(from: current.position, to: destination, anchor: anchor,
                    initialVelocity: current.velocity, start: time, duration: max(0.18, duration - max(0, time - start)))
    }
    private func project(_ point: SIMD3<Float>) -> SIMD3<Float> {
        let depth = max(0.01, point.z)
        return [(point.x - anchor.x) / depth, (point.y - anchor.y) / depth, 1 / depth]
    }
}

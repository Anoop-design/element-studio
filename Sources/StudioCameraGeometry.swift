import Foundation

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
    // Interpolate screen position and magnification, so an off-centre object follows a
    // direct visual path instead of sweeping sideways during a linear world-space move.
    static func flight(from: SIMD3<Float>, to: SIMD3<Float>, anchor: SIMD3<Float>, progress: Float) -> SIMD3<Float> {
        let t = min(1, max(0, progress))
        let depth = exp(log(max(0.01, from.z)) * (1 - t) + log(max(0.01, to.z)) * t)
        let start = SIMD2(from.x - anchor.x, from.y - anchor.y) / max(0.01, from.z)
        let end = SIMD2(to.x - anchor.x, to.y - anchor.y) / max(0.01, to.z)
        let point = (start + (end - start) * t) * depth
        return [anchor.x + point.x, anchor.y + point.y, depth]
    }
}

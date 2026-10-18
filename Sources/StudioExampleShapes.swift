// MIT licensed. Copy this file into a Swift target to reuse the neutral examples.
import Foundation
import simd

/// Independent geometry data. Coordinates are right handed; +Z is the front.
/// Keep v1 geometry stable for saved looks. Give revised designs new IDs.
nonisolated enum StudioExampleShapes {
    static let ids = ["orbit-v1", "twist-v1", "pebbles-v1"]

    struct Mesh: Sendable {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = []
        var indices: [UInt32] = []
    }
    struct Part: Sendable {
        let name: String
        let role: String
        let color: SIMD3<Float>
        let metallic: Float
        let roughness: Float
        let separation: SIMD3<Float>
        let mesh: Mesh
    }

    static func make(id: String) -> [Part]? {
        switch id {
        case "orbit-v1":
            return [
                Part(name: "Ceramic orbit", role: "ceramic", color: [0.18, 0.58, 0.67], metallic: 0,
                     roughness: 0.3, separation: [-0.28, 0, 0],
                     mesh: loop(radius: [0.73, 0.93], section: [0.17, 0.17], twist: 0, wave: 0.12)),
                Part(name: "Floating core", role: "polished", color: [0.88, 0.68, 0.32], metallic: 1,
                     roughness: 0.18, separation: [0.4, 0, 0.3],
                     mesh: ellipsoid(radii: [0.32, 0.38, 0.30], center: .zero, turn: 0))
            ]
        case "twist-v1":
            return [Part(name: "Continuous twisted band", role: "ceramic", color: [0.72, 0.38, 0.20],
                         metallic: 0, roughness: 0.3, separation: .zero,
                         mesh: loop(radius: [0.64, 0.90], section: [0.28, 0.065], twist: 1, wave: 0.10))]
        case "pebbles-v1":
            let forms: [(SIMD3<Float>, SIMD3<Float>, Float, SIMD3<Float>)] = [
                ([0.72, 0.25, 0.43], [-0.04, -0.61, 0], -0.08, [0.18, 0.39, 0.38]),
                ([0.61, 0.24, 0.38], [0.08, -0.15, 0.025], 0.10, [0.48, 0.66, 0.58]),
                ([0.47, 0.22, 0.33], [-0.04, 0.27, 0.015], -0.13, [0.79, 0.74, 0.57]),
                ([0.29, 0.19, 0.25], [0.05, 0.64, 0], 0.08, [0.85, 0.47, 0.32])
            ]
            return forms.enumerated().map { index, value in
                Part(name: "Pebble \(index + 1)", role: "ceramic", color: value.3, metallic: 0,
                     roughness: 0.4, separation: [index.isMultiple(of: 2) ? -0.15 : 0.15, Float(index) * 0.2 - 0.3, 0],
                     mesh: ellipsoid(radii: value.0, center: value.1, turn: value.2))
            }
        default: return nil
        }
    }

    /// A closed sweep with a full (orientable) twist and an elliptical section.
    /// Duplicate seam vertices retain UV continuity; positions/normals match.
    static func loop(radius: SIMD2<Float>, section: SIMD2<Float>, twist: Float, wave: Float) -> Mesh {
        let rows = 128, columns = 32
        let tau = Float.pi * 2
        func point(_ u: Float, _ v: Float) -> SIMD3<Float> {
            let center = SIMD3(radius.x * cos(u), radius.y * sin(u), wave * sin(2 * u))
            let tangent = simd_normalize(SIMD3(-radius.x * sin(u), radius.y * cos(u), 2 * wave * cos(2 * u)))
            let across = simd_normalize(SIMD3(tangent.y, -tangent.x, 0))
            let front = simd_normalize(simd_cross(across, tangent))
            let a = across * cos(u * twist) + front * sin(u * twist)
            let b = front * cos(u * twist) - across * sin(u * twist)
            return center + a * (section.x * cos(v)) + b * (section.y * sin(v))
        }
        var mesh = Mesh()
        for row in 0...rows {
            let u = Float(row % rows) / Float(rows) * tau
            for column in 0...columns {
                let v = Float(column % columns) / Float(columns) * tau
                let epsilon: Float = 0.0005
                let du = point(u + epsilon, v) - point(u - epsilon, v)
                let dv = point(u, v + epsilon) - point(u, v - epsilon)
                mesh.positions.append(point(u, v))
                mesh.normals.append(simd_normalize(simd_cross(du, dv)))
                mesh.uv.append([Float(row) / Float(rows), Float(column) / Float(columns)])
            }
        }
        for row in 0..<rows {
            for column in 0..<columns {
                let a = UInt32(row * (columns + 1) + column)
                let b = a + UInt32(columns + 1)
                mesh.indices += [a, b, b + 1, a, b + 1, a + 1]
            }
        }
        return mesh
    }

    /// Latitude rings plus single pole vertices avoid degenerate pole triangles.
    static func ellipsoid(radii: SIMD3<Float>, center: SIMD3<Float>, turn: Float) -> Mesh {
        let rings = 30, columns = 64
        var mesh = Mesh()
        func rotate(_ p: SIMD3<Float>) -> SIMD3<Float> {
            [p.x * cos(turn) - p.y * sin(turn), p.x * sin(turn) + p.y * cos(turn), p.z]
        }
        func append(_ direction: SIMD3<Float>, uv: SIMD2<Float>) {
            mesh.positions.append(rotate(direction * radii) + center)
            mesh.normals.append(simd_normalize(rotate(direction / radii)))
            mesh.uv.append(uv)
        }
        append([0, 1, 0], uv: [0.5, 0])
        for ring in 1..<rings {
            let latitude = Float(ring) / Float(rings) * .pi
            for column in 0...columns {
                let longitude = Float(column % columns) / Float(columns) * .pi * 2
                append([sin(latitude) * cos(longitude), cos(latitude), sin(latitude) * sin(longitude)],
                       uv: [Float(column) / Float(columns), Float(ring) / Float(rings)])
            }
        }
        let bottom = UInt32(mesh.positions.count)
        append([0, -1, 0], uv: [0.5, 1])
        for column in 0..<columns {
            let a = UInt32(1 + column)
            mesh.indices += [0, a + 1, a]
            let last = UInt32(1 + (rings - 2) * (columns + 1) + column)
            mesh.indices += [last, last + 1, bottom]
        }
        for ring in 0..<(rings - 2) {
            for column in 0..<columns {
                let a = UInt32(1 + ring * (columns + 1) + column)
                let b = a + UInt32(columns + 1)
                mesh.indices += [a, a + 1, b + 1, a, b + 1, b]
            }
        }
        return mesh
    }
}

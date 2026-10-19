import XCTest
import simd

@testable import ElementStudioAuthor

final class AuthoringTests: XCTestCase {
  func testConcaveCapAndCountersPreserveArea() {
    let outside: [V2] = [[0, 0], [4, 0], [4, 4], [2, 2], [0, 4]]
    let hole: [V2] = [[0.5, 0.5], [0.5, 1], [1, 1], [1, 0.5]]
    let result = triangulate([outside, hole])
    let actual = stride(from: 0, to: result.indices.count, by: 3).reduce(0.0) { sum, i in
      let a = result.points[result.indices[i]]
      let b = result.points[result.indices[i + 1]]
      let c = result.points[result.indices[i + 2]]
      return sum + abs(cross2(b - a, c - a)) / 2
    }
    XCTAssertEqual(actual, 11.75, accuracy: 1e-9)
    for i in stride(from: 0, to: result.indices.count, by: 3) {
      let p =
        (result.points[result.indices[i]] + result.points[result.indices[i + 1]]
          + result.points[result.indices[i + 2]]) / 3
      XCTAssertFalse(inside(p, hole))
    }
  }
  func testBendPreservesClosedSharedEdges() {
    let node = extruded(smoothPolygon(regular(6), 0.1), 0.15, 0.02, .satin)
    bend(node, { x, y in 0.05 * (1 - x * x - y * y) })
    let mesh = node.mesh!
    func key(_ p: V3) -> String {
      [p.x, p.y, p.z].map { String(Int(($0 * 1e6).rounded())) }.joined(separator: ",")
    }
    var edges: [String: Int] = [:]
    for i in stride(from: 0, to: mesh.indices.count, by: 3) {
      for j in 0..<3 {
        let a = key(mesh.vertices[mesh.indices[i + j]].p)
        let b = key(mesh.vertices[mesh.indices[i + (j + 1) % 3]].p)
        edges[a < b ? a + "|" + b : b + "|" + a, default: 0] += 1
      }
    }
    XCTAssertTrue(edges.values.allSatisfy { $0 == 2 }, "Cap subdivision must not open bevel seams")
    XCTAssertTrue(mesh.vertices.allSatisfy { abs(simd_length($0.n) - 1) < 1e-8 })
  }
  func testSphereAndShellNormalsFaceOutward() {
    let sphere = sphere(1, .satin).mesh!
    for i in stride(from: 0, to: sphere.indices.count, by: 3) {
      let a = sphere.vertices[sphere.indices[i]].p
      let b = sphere.vertices[sphere.indices[i + 1]].p
      let c = sphere.vertices[sphere.indices[i + 2]].p
      XCTAssertGreaterThan(simd_dot(simd_cross(b - a, c - a), (a + b + c) / 3), 0)
    }
    let mesh = lathe([[0, -0.5], [1, -0.5], [1, 0.5], [0, 0.5]], .satin, axis: "y").mesh!
    for vertex in mesh.vertices where abs(vertex.p.y) < 0.51 && hypot(vertex.p.x, vertex.p.z) > 0.9
    {
      XCTAssertGreaterThan(simd_dot(vertex.p, vertex.n), 0)
    }
  }
  func testArgumentValidation() throws {
    XCTAssertThrowsError(try AuthorOptions(["--ids"]))
    XCTAssertThrowsError(try AuthorOptions(["--output", "--live"]))
    XCTAssertThrowsError(try AuthorOptions(["--browser"]))
    XCTAssertEqual(
      try AuthorOptions(["--ids", "energy,ribbon-ceramic"]).ids, ["energy", "ribbon-ceramic"])
  }
}

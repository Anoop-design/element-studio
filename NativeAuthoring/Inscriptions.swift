import CoreGraphics
import Foundation
import simd

final class Outline {
  let path = CGMutablePath()
  @discardableResult func move(_ x: Double, _ y: Double) -> Self {
    path.move(to: CGPoint(x: x, y: y))
    return self
  }
  @discardableResult func line(_ x: Double, _ y: Double) -> Self {
    path.addLine(to: CGPoint(x: x, y: y))
    return self
  }
  @discardableResult func quad(_ x: Double, _ y: Double, _ endX: Double, _ endY: Double) -> Self {
    path.addQuadCurve(to: CGPoint(x: endX, y: endY), control: CGPoint(x: x, y: y))
    return self
  }
  @discardableResult func cubic(
    _ x: Double, _ y: Double, _ x2: Double, _ y2: Double, _ endX: Double, _ endY: Double
  ) -> Self {
    path.addCurve(
      to: CGPoint(x: endX, y: endY), control1: CGPoint(x: x, y: y), control2: CGPoint(x: x2, y: y2))
    return self
  }
  @discardableResult func arc(_ x: Double, _ y: Double, _ r: Double, _ start: Double, _ end: Double)
    -> Self
  {
    path.addArc(
      center: CGPoint(x: x, y: y), radius: r, startAngle: start, endAngle: end,
      clockwise: end < start)
    return self
  }
  @discardableResult func close() -> Self {
    path.closeSubpath()
    return self
  }
  func points(_ count: Int = 160) -> [V2] { shapePoints(path, count) }
}
func orientedLoops(_ loops: [[V2]]) -> [[V2]] {
  loops.enumerated().map { i, p in
    let depth = loops.enumerated().filter {
      $0.offset != i && abs(area($0.element)) > abs(area(p)) && inside(p[0], $0.element)
    }.count
    return depth % 2 == 0 ? ccw(p) : Array(ccw(p).reversed())
  }
}
struct OutlineFont {
  struct Glyph: Decodable {
    let ha: Double
    let o: String?
  }
  struct Font: Decodable {
    let resolution: Double
    let glyphs: [String: Glyph]
  }
  let font: Font
  init(url: URL) throws { font = try JSONDecoder().decode(Font.self, from: Data(contentsOf: url)) }
  func text(
    _ value: String, _ size: Double, _ depth: Double, _ material: Material, _ x: Double = 0,
    _ y: Double = 0, _ z: Double = 0
  ) -> Node {
    let scale = size / font.resolution
    var pen = 0.0
    var mesh = Mesh(bendableCap: true)
    for character in value {
      guard let glyph = font.glyphs[String(character)] else {
        preconditionFailure("Missing font glyph: \(character)")
      }
      defer { pen += glyph.ha * scale }
      guard let outline = glyph.o, !outline.isEmpty else { continue }
      let tokens = outline.split(separator: " ").map(String.init)
      let path = CGMutablePath()
      var index = 0
      func point() -> CGPoint {
        let a = Double(tokens[index])!
        let b = Double(tokens[index + 1])!
        index += 2
        return CGPoint(x: a * scale + pen, y: b * scale)
      }
      while index < tokens.count {
        let command = tokens[index]
        index += 1
        switch command {
        case "m": path.move(to: point())
        case "l": path.addLine(to: point())
        // Typeface outline grammar stores the endpoint before its controls (unlike SVG).
        case "q":
          let end = point()
          let control = point()
          path.addQuadCurve(to: end, control: control)
        case "b":
          let end = point()
          let a = point()
          let b = point()
          path.addCurve(to: end, control1: a, control2: b)
        default: preconditionFailure("Unsupported outline command \(command)")
        }
      }
      let loops = orientedLoops(contours(path, steps: 5))
      mesh.append(
        extrusion(
          loops, depth: depth, bevel: depth > 0.004 ? min(0.002, depth * 0.25) : 0, bevelSegments: 2
        ))
    }
    if !mesh.vertices.isEmpty {
      let xs = mesh.vertices.map { $0.p.x }
      let ys = mesh.vertices.map { $0.p.y }
      let cx = (xs.min()! + xs.max()!) / 2
      let cy = (ys.min()! + ys.max()!) / 2
      for i in mesh.vertices.indices {
        mesh.vertices[i].p.x -= cx
        mesh.vertices[i].p.y -= cy
      }
    }
    let node = Node(mesh, material)
    node.position = [x, y, z]
    node.fixture = true
    return node
  }
}
func runner(_ material: Material, _ scale: Double = 1) -> Node {
  let group = Node()
  group.fixture = true
  group.scale = V3(repeating: scale)
  let paths: [[V3]] = [
    [[0.03, 0.19, 0], [-0.04, 0.04, 0], [0.06, -0.08, 0], [-0.05, -0.29, 0]],
    [[-0.04, 0.04, 0], [-0.23, -0.09, 0], [-0.39, -0.07, 0]],
    [[-0.04, 0.15, 0], [0.14, 0.07, 0], [0.25, 0.17, 0]],
    [[-0.03, 0.17, 0], [-0.2, 0.21, 0], [-0.27, 0.11, 0]],
  ]
  for path in paths { group.add(tube(path, 0.031, material, segments: 24)) }
  let head = sphere(0.058, material)
  head.position = [0.08, 0.32, 0]
  group.add(head)
  return group
}
func seatFaceDetails(_ root: Node) {
  root.visit { owner, _ in
    guard let face = owner.face, let height = owner.faceHeight else { return }
    for child in face.children.dropFirst() {
      var base = Double.infinity
      child.visit { node, matrix in
        guard var mesh = node.mesh else { return }
        mesh.transform(matrix)
        base = min(base, mesh.vertices.map { $0.p.z }.min() ?? .infinity)
      }
      if base.isFinite { bend(child, { x, y in height(x, y) + 0.0015 - base }) }
    }
  }
}
// Barycentric reverse projection uses only the actual authored surfaces.
// A coarse spatial index keeps the small mark independent of catalogue triangle counts.
struct SurfaceSampler {
  struct Triangle {
    let a: V3
    let b: V3
    let c: V3
  }
  let triangles: [Triangle]
  let x0: Double, y0: Double, dx: Double, dy: Double
  let bins: [[Int]]
  init(_ root: Node) {
    var triangles: [Triangle] = []
    root.visit { node, world in
      guard var mesh = node.mesh, node.material.role != "glass" else { return }
      mesh.transform(world)
      for i in stride(from: 0, to: mesh.indices.count, by: 3) {
        let a = mesh.vertices[mesh.indices[i]].p
        let b = mesh.vertices[mesh.indices[i + 1]].p
        let c = mesh.vertices[mesh.indices[i + 2]].p
        if abs(cross2(V2(b.x - a.x, b.y - a.y), V2(c.x - a.x, c.y - a.y))) > 1e-12 {
          triangles.append(Triangle(a: a, b: b, c: c))
        }
      }
    }
    self.triangles = triangles
    let all = triangles.flatMap { [$0.a, $0.b, $0.c] }
    x0 = all.map(\.x).min()!
    y0 = all.map(\.y).min()!
    dx = max(1e-6, (all.map(\.x).max()! - x0) / 32)
    dy = max(1e-6, (all.map(\.y).max()! - y0) / 32)
    var bins = Array(repeating: [Int](), count: 1024)
    for (i, t) in triangles.enumerated() {
      let xMin = max(0, min(31, Int(floor((min(t.a.x, t.b.x, t.c.x) - x0) / dx))))
      let xMax = max(0, min(31, Int(floor((max(t.a.x, t.b.x, t.c.x) - x0) / dx))))
      let yMin = max(0, min(31, Int(floor((min(t.a.y, t.b.y, t.c.y) - y0) / dy))))
      let yMax = max(0, min(31, Int(floor((max(t.a.y, t.b.y, t.c.y) - y0) / dy))))
      for y in yMin...yMax { for x in xMin...xMax { bins[y * 32 + x].append(i) } }
    }
    self.bins = bins
  }
  func range(_ x: Double, _ y: Double) -> (front: Double, back: Double)? {
    let xx = Int(floor((x - x0) / dx))
    let yy = Int(floor((y - y0) / dy))
    guard xx >= 0, xx < 32, yy >= 0, yy < 32 else { return nil }
    var front = -Double.infinity
    var back = Double.infinity
    for index in bins[yy * 32 + xx] {
      let t = triangles[index]
      let a = t.a
      let b = t.b
      let c = t.c
      let den = (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
      let u = ((b.y - c.y) * (x - c.x) + (c.x - b.x) * (y - c.y)) / den
      let v = ((c.y - a.y) * (x - c.x) + (a.x - c.x) * (y - c.y)) / den
      if u < -0.0001 || v < -0.0001 || u + v > 1.0001 { continue }
      let z = u * a.z + v * b.z + (1 - u - v) * c.z
      front = max(front, z)
      back = min(back, z)
    }
    return back.isFinite ? (front, back) : nil
  }
}
struct BrandMark {
  struct Layer: Decodable {
    let path: String
    let cage: Bool
  }
  let layers: [Layer]
  init(url: URL) throws {
    layers = try JSONDecoder().decode([Layer].self, from: Data(contentsOf: url))
  }
  func add(to root: Node, id: String) {
    let placement: [String: V3] = [
      "returning": [0, -0.74, 0.14], "hourglass": [0, -0.918, 0.10], "halfYear": [0, 0, 0.34],
      "sunrise": [0, -0.02, 0.26], "activity": [0, 0, 0.30], "ribbon": [0, 0.10, 0.34],
      "collection": [0.13, 0.17, 0.34], "memory": [0, -0.02, 0.34],
    ]
    let place = placement[id] ?? [0, 0, 0.38]
    let side = place.z
    var path: CGPath = CGMutablePath()
    for layer in layers {
      let regex = try! NSRegularExpression(
        pattern: "[MLCZmlcz]|[-+]?(?:[0-9]*\\.)?[0-9]+(?:[eE][-+]?[0-9]+)?")
      let matches = regex.matches(
        in: layer.path, range: NSRange(layer.path.startIndex..., in: layer.path))
      let tokens = matches.map { String(layer.path[Range($0.range, in: layer.path)!]) }
      var i = 0
      let p = CGMutablePath()
      func point() -> CGPoint {
        let x = Double(tokens[i])!
        let y = Double(tokens[i + 1])!
        i += 2
        return CGPoint(
          x: (x / 600 - 0.5) * side, y: (0.5 - y / 600) * side + (layer.cage ? side * 0.055 : 0))
      }
      while i < tokens.count {
        let command = tokens[i]
        i += 1
        switch command {
        case "M": p.move(to: point())
        case "L": p.addLine(to: point())
        case "C":
          let a = point()
          let b = point()
          let c = point()
          p.addCurve(to: c, control1: a, control2: b)
        case "Z": p.closeSubpath()
        default: preconditionFailure("Unsupported brand path command \(command)")
        }
      }
      path = path.union(p)
    }
    var mesh = extrusion(orientedLoops(contours(path, steps: 12)), depth: 0.0015, bevel: 0)
    mesh.subdivideCaps(maxEdge: side / 28)
    let transform = Node()
    transform.rotation.y = .pi
    transform.position = [-place.x, place.y, 0]
    mesh.transform(transform.matrix)
    let sampler = SurfaceSampler(root)
    for i in mesh.vertices.indices {
      let p = mesh.vertices[i].p
      let n = mesh.vertices[i].n
      let e = 0.0005
      guard let back = sampler.range(p.x, p.y)?.back else {
        preconditionFailure("\(id): reverse mark has no supporting surface at \(p)")
      }
      let dx =
        ((sampler.range(p.x + e, p.y)?.back ?? back) - (sampler.range(p.x - e, p.y)?.back ?? back))
        / (2 * e)
      let dy =
        ((sampler.range(p.x, p.y + e)?.back ?? back) - (sampler.range(p.x, p.y - e)?.back ?? back))
        / (2 * e)
      mesh.vertices[i].p.z += back - 0.0015
      mesh.vertices[i].n = unit([n.x - dx * n.z, n.y - dy * n.z, n.z])
    }
    let mark = Node(mesh, .ink)
    mark.fixture = true
    root.add(mark)
  }
}

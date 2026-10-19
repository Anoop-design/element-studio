// MIT. Native authoring primitives. Coordinates are right handed, +Z faces the viewer.
import Foundation
import simd

typealias V2 = SIMD2<Double>
typealias V3 = SIMD3<Double>
let tau = Double.pi * 2
func clamp(_ x: Double, _ a: Double = 0, _ b: Double = 1) -> Double { min(b, max(a, x)) }
func smooth(_ x: Double) -> Double {
  let t = clamp(x)
  return t * t * (3 - 2 * t)
}
func signedPower(_ x: Double, _ p: Double) -> Double { (x < 0 ? -1 : 1) * pow(abs(x), p) }
func unit(_ v: V3) -> V3 {
  let n = simd_length(v)
  return n > 1e-14 ? v / n : V3(0, 0, 1)
}
func mix(_ a: V3, _ b: V3, _ t: Double) -> V3 { a + (b - a) * t }
func mix(_ a: V2, _ b: V2, _ t: Double) -> V2 { a + (b - a) * t }
func cross2(_ a: V2, _ b: V2) -> Double { a.x * b.y - a.y * b.x }

struct Vertex {
  var p: V3
  var n: V3 = .zero
  var uv: V2 = .zero
  static func midpoint(_ a: Self, _ b: Self) -> Self {
    Self(p: (a.p + b.p) / 2, n: unit(a.n + b.n), uv: (a.uv + b.uv) / 2)
  }
}
struct Mesh {
  var vertices: [Vertex] = []
  var indices: [Int] = []
  var bendableCap = false
  mutating func triangle(_ a: Int, _ b: Int, _ c: Int) {
    if simd_length_squared(simd_cross(vertices[b].p - vertices[a].p, vertices[c].p - vertices[a].p))
      > 1e-20
    {
      indices += [a, b, c]
    }
  }
  mutating func normals() {
    for i in vertices.indices { vertices[i].n = .zero }
    for i in stride(from: 0, to: indices.count, by: 3) {
      let a = indices[i]
      let b = indices[i + 1]
      let c = indices[i + 2]
      let n = simd_cross(vertices[b].p - vertices[a].p, vertices[c].p - vertices[a].p)
      vertices[a].n += n
      vertices[b].n += n
      vertices[c].n += n
    }
    for i in vertices.indices { vertices[i].n = unit(vertices[i].n) }
  }
  mutating func reverse() {
    for i in stride(from: 0, to: indices.count, by: 3) { indices.swapAt(i + 1, i + 2) }
    for i in vertices.indices { vertices[i].n = -vertices[i].n }
  }
  mutating func transform(_ matrix: simd_double4x4) {
    let linear = simd_double3x3(
      V3(matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z),
      V3(matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z),
      V3(matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z))
    let normal = linear.inverse.transpose
    for i in vertices.indices {
      let p = matrix * SIMD4(vertices[i].p, 1)
      vertices[i].p = V3(p.x, p.y, p.z)
      vertices[i].n = unit(normal * vertices[i].n)
    }
  }
  mutating func append(_ other: Mesh) {
    let offset = vertices.count
    vertices += other.vertices
    indices += other.indices.map { $0 + offset }
  }
  // Shared geometric edge splits propagate across both caps and bevels before bending.
  mutating func subdivideCaps(maxEdge: Double = 0.045) {
    struct Face {
      var v: [Vertex]
      let cap: Bool
    }
    func key(_ p: V3) -> String {
      [p.x, p.y, p.z].map { String(Int64(($0 * 1e6).rounded())) }.joined(separator: ",")
    }
    func edge(_ a: Vertex, _ b: Vertex) -> String {
      let x = key(a.p)
      let y = key(b.p)
      return x < y ? x + "|" + y : y + "|" + x
    }
    var faces = stride(from: 0, to: indices.count, by: 3).map { i -> Face in
      let v = indices[i..<(i + 3)].map { vertices[$0] }
      return Face(v: v, cap: abs(v[0].p.z - v[1].p.z) < 1e-7 && abs(v[0].p.z - v[2].p.z) < 1e-7)
    }
    for _ in 0..<12 {
      var splits = Set<String>()
      for f in faces where f.cap {
        for j in 0..<3 where simd_length_squared(f.v[j].p - f.v[(j + 1) % 3].p) > maxEdge * maxEdge
        { splits.insert(edge(f.v[j], f.v[(j + 1) % 3])) }
      }
      if splits.isEmpty { break }
      var next: [Face] = []
      for f in faces {
        let a = f.v[0]
        let b = f.v[1]
        let c = f.v[2]
        let ab = splits.contains(edge(a, b))
        let bc = splits.contains(edge(b, c))
        let ca = splits.contains(edge(c, a))
        let d = Vertex.midpoint(a, b)
        let e = Vertex.midpoint(b, c)
        let g = Vertex.midpoint(c, a)
        func add(_ v: Vertex...) { next.append(Face(v: v, cap: f.cap)) }
        switch (ab ? 1 : 0) + (bc ? 2 : 0) + (ca ? 4 : 0) {
        case 0: add(a, b, c)
        case 1:
          add(a, d, c)
          add(d, b, c)
        case 2:
          add(b, e, a)
          add(e, c, a)
        case 4:
          add(c, g, b)
          add(g, a, b)
        case 3:
          add(d, b, e)
          add(a, d, c)
          add(d, e, c)
        case 5:
          add(a, d, g)
          add(d, b, c)
          add(d, c, g)
        case 6:
          add(c, g, e)
          add(a, b, g)
          add(b, e, g)
        default:
          add(a, d, g)
          add(d, b, e)
          add(g, e, c)
          add(d, e, g)
        }
      }
      faces = next
    }
    vertices = []
    indices = []
    for f in faces {
      let start = vertices.count
      vertices += f.v
      triangle(start, start + 1, start + 2)
    }
    bendableCap = false
  }
}

struct Material: Hashable {
  var role: String
  var hex: UInt32
  var roughness: Double = 0.25
  var metallic: Double = 0
  var color: [Double] {
    [Double((hex >> 16) & 255) / 255, Double((hex >> 8) & 255) / 255, Double(hex & 255) / 255]
  }
  static let satin = Self(role: "satin", hex: 0xa6adb3, roughness: 0.32, metallic: 1)
  static let polished = Self(role: "polished", hex: 0xe0e5e9, roughness: 0.14, metallic: 1)
  static let lettering = Self(role: "lettering", hex: 0xd8e4ec, roughness: 0.29, metallic: 0.42)
  static let ink = Self(role: "ink", hex: 0x12232d, roughness: 0.42, metallic: 0.35)
  static let glass = Self(role: "glass", hex: 0xf5ffff, roughness: 0.065)
  static let sand = Self(role: "sand", hex: 0xd8b477, roughness: 0.76)
  static let photo = Self(role: "photo", hex: 0xffffff, roughness: 0.8)
  static func enamel(_ hex: UInt32) -> Self { Self(role: "enamel", hex: hex) }
  static func ceramic(_ hex: UInt32) -> Self { Self(role: "ceramic", hex: hex, roughness: 0.34) }
}

final class Node {
  var mesh: Mesh?
  var material: Material = .satin
  var children: [Node] = []
  var name = ""
  var position: V3 = .zero
  var scale = V3(repeating: 1)
  var rotation: V3 = .zero
  var explode: V3?
  var fixture = false
  var face: Node?
  var faceHeight: ((Double, Double) -> Double)?
  var warp: ((Double, Double) -> Double)?
  init(_ mesh: Mesh? = nil, _ material: Material = .satin) {
    self.mesh = mesh
    self.material = material
  }
  @discardableResult func add(_ node: Node) -> Node {
    children.append(node)
    return node
  }
  var matrix: simd_double4x4 {
    let qx = simd_quatd(angle: rotation.x, axis: [1, 0, 0])
    let qy = simd_quatd(angle: rotation.y, axis: [0, 1, 0])
    let qz = simd_quatd(angle: rotation.z, axis: [0, 0, 1])
    var m = simd_double4x4(qx * qy * qz)
    m.columns.0 *= scale.x
    m.columns.1 *= scale.y
    m.columns.2 *= scale.z
    m.columns.3 = SIMD4(position, 1)
    return m
  }
  func visit(
    _ action: (Node, simd_double4x4) -> Void, parent: simd_double4x4 = matrix_identity_double4x4
  ) {
    let world = parent * matrix
    action(self, world)
    for child in children { child.visit(action, parent: world) }
  }
}
@discardableResult func part(_ parent: Node, _ node: Node, _ name: String, _ explode: V3 = .zero)
  -> Node
{
  node.name = name
  node.explode = explode
  return parent.add(node)
}
func bend(_ root: Node, _ height: (Double, Double) -> Double) {
  root.visit { node, world in
    guard var mesh = node.mesh else { return }
    if mesh.bendableCap { mesh.subdivideCaps() }
    mesh.transform(world)
    for i in mesh.vertices.indices {
      let p = mesh.vertices[i].p
      let n = mesh.vertices[i].n
      let e = 0.0001
      let dx = (height(p.x + e, p.y) - height(p.x - e, p.y)) / (2 * e)
      let dy = (height(p.x, p.y + e) - height(p.x, p.y - e)) / (2 * e)
      mesh.vertices[i].n = unit(V3(n.x - dx * n.z, n.y - dy * n.z, n.z))
      mesh.vertices[i].p.z += height(p.x, p.y)
    }
    mesh.transform(world.inverse)
    node.mesh = mesh
  }
}

func lathe(_ profile: [V2], _ material: Material, axis: String = "z", segments: Int = 128) -> Node {
  var m = Mesh()
  let count = profile.count
  for i in 0...segments {
    let a = Double(i % segments) / Double(segments) * tau
    for (j, p) in profile.enumerated() {
      // Three's lathe starts at +Z and follows +X around its Y axis.
      let v = V3(p.x * sin(a), p.y, p.x * cos(a))
      m.vertices.append(
        Vertex(
          p: axis == "z" ? V3(v.x, -v.z, v.y) : v,
          uv: V2(Double(i) / Double(segments), Double(j) / Double(count - 1))))
    }
  }
  for i in 0..<segments {
    for j in 0..<(count - 1) {
      let a = i * count + j
      let b = a + count
      m.triangle(a, b, a + 1)
      m.triangle(b, b + 1, a + 1)
    }
  }
  m.normals()
  for j in 0..<count {
    let n = unit(m.vertices[j].n + m.vertices[segments * count + j].n)
    m.vertices[j].n = n
    m.vertices[segments * count + j].n = n
  }
  return Node(m, material)
}
func sphere(_ radius: Double, _ material: Material, columns: Int = 20, rows: Int = 16) -> Node {
  var m = Mesh()
  for j in 0...rows {
    for i in 0...columns {
      let u = Double(i) / Double(columns)
      let v = Double(j) / Double(rows)
      let a = u * tau
      let b = v * .pi
      let n = V3(-cos(a) * sin(b), cos(b), sin(a) * sin(b))
      m.vertices.append(Vertex(p: n * radius, n: n, uv: [u, 1 - v]))
    }
  }
  for j in 0..<rows {
    for i in 0..<columns {
      let a = j * (columns + 1) + i
      let b = a + columns + 1
      m.triangle(a, b, a + 1)
      m.triangle(a + 1, b, b + 1)
    }
  }
  return Node(m, material)
}
func capsule(
  _ radius: Double, _ length: Double, _ material: Material, capSegments: Int = 5, radial: Int = 12
) -> Node {
  var profile: [V2] = []
  for i in 0...capSegments {
    let a = Double(i) / Double(capSegments) * .pi / 2
    profile.append([radius * sin(a), -length / 2 - radius * cos(a)])
  }
  for i in 0...capSegments {
    let a = Double(i) / Double(capSegments) * .pi / 2
    profile.append([radius * cos(a), length / 2 + radius * sin(a)])
  }
  return lathe(profile, material, axis: "y", segments: radial)
}
func cylinder(_ radius: Double, _ height: Double, _ material: Material, segments: Int = 16) -> Node
{
  lathe(
    [[0, -height / 2], [radius, -height / 2], [radius, height / 2], [0, height / 2]], material,
    axis: "y", segments: segments)
}
func ring(_ radius: Double, _ section: Double, _ z: Double, _ material: Material) -> Node {
  var m = Mesh()
  let rows = 128
  let cols = 10
  for j in 0...cols {
    for i in 0...rows {
      let a = Double(i % rows) / Double(rows) * tau
      let b = Double(j % cols) / Double(cols) * tau
      let n = V3(cos(b) * cos(a), cos(b) * sin(a), sin(b))
      let p = V3(radius * cos(a), radius * sin(a), z) + n * section
      m.vertices.append(
        Vertex(p: p, n: n, uv: [Double(i) / Double(rows), Double(j) / Double(cols)]))
    }
  }
  for j in 0..<cols {
    for i in 0..<rows {
      let a = j * (rows + 1) + i
      let b = a + rows + 1
      m.triangle(a, a + 1, b)
      m.triangle(a + 1, b + 1, b)
    }
  }
  return Node(m, material)
}
// Centripetal Catmull-Rom interpolation with parallel-transport tube frames.
func tube(_ points: [V3], _ radius: Double, _ material: Material, segments: Int = 80) -> Node {
  func at(_ t: Double) -> V3 {
    let u = clamp(t) * Double(points.count - 1)
    let i = min(points.count - 2, Int(u))
    let w = u - Double(i)
    let p1 = points[i]
    let p2 = points[i + 1]
    let p0 = i > 0 ? points[i - 1] : p1 * 2 - p2
    let p3 = i + 2 < points.count ? points[i + 2] : p2 * 2 - p1
    let d0 = max(1e-4, pow(simd_length_squared(p1 - p0), 0.25))
    let d1 = max(1e-4, pow(simd_length_squared(p2 - p1), 0.25))
    let d2 = max(1e-4, pow(simd_length_squared(p3 - p2), 0.25))
    let t1 = ((p1 - p0) / d0 - (p2 - p0) / (d0 + d1) + (p2 - p1) / d1) * d1
    let t2 = ((p2 - p1) / d1 - (p3 - p1) / (d1 + d2) + (p3 - p2) / d2) * d1
    return p1 + t1 * w + (-3 * p1 + 3 * p2 - 2 * t1 - t2) * w * w + (2 * p1 - 2 * p2 + t1 + t2) * w
      * w * w
  }
  let tangents = (0...segments).map { i in
    unit(at(Double(i) / Double(segments) + 0.0001) - at(Double(i) / Double(segments) - 0.0001))
  }
  let t = tangents[0]
  let axis: V3 =
    abs(t.x) <= abs(t.y) && abs(t.x) <= abs(t.z)
    ? [1, 0, 0] : abs(t.y) <= abs(t.z) ? [0, 1, 0] : [0, 0, 1]
  var normal = unit(simd_cross(t, unit(simd_cross(t, axis))))
  var m = Mesh()
  for i in 0...segments {
    if i > 0 {
      let a = simd_cross(tangents[i - 1], tangents[i])
      if simd_length(a) > 1e-8 {
        normal = simd_quatd(
          angle: acos(clamp(simd_dot(tangents[i - 1], tangents[i]), -1, 1)), axis: unit(a)
        ).act(normal)
      }
    }
    let binormal = unit(simd_cross(tangents[i], normal))
    let p = at(Double(i) / Double(segments))
    for j in 0...8 {
      let a = Double(j % 8) / 8 * tau
      let n = normal * -cos(a) + binormal * sin(a)
      m.vertices.append(
        Vertex(p: p + n * radius, n: n, uv: [Double(i) / Double(segments), Double(j) / 8]))
    }
  }
  for i in 0..<segments {
    for j in 0..<8 {
      let a = i * 9 + j
      let b = a + 9
      m.triangle(a, b, a + 1)
      m.triangle(b, b + 1, a + 1)
    }
  }
  return Node(m, material)
}

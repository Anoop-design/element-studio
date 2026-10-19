import CoreGraphics
import Foundation
import simd

func area(_ p: [V2]) -> Double {
  guard p.count > 2 else { return 0 }
  return p.indices.reduce(0) { $0 + cross2(p[$1], p[($1 + 1) % p.count]) } / 2
}
func ccw(_ p: [V2]) -> [V2] { area(p) < 0 ? p.reversed() : p }
func pathOf(_ points: [V2]) -> CGPath {
  let p = CGMutablePath()
  guard let first = points.first else { return p }
  p.move(to: CGPoint(x: first.x, y: first.y))
  for v in points.dropFirst() { p.addLine(to: CGPoint(x: v.x, y: v.y)) }
  p.closeSubpath()
  return p
}
func contours(_ path: CGPath, steps: Int = 24) -> [[V2]] {
  var result: [[V2]] = []
  var current: [V2] = []
  var last = V2.zero
  func flush() {
    if current.count > 1 && simd_distance(current[0], current.last!) < 1e-9 { current.removeLast() }
    if current.count >= 3 { result.append(current) }
    current = []
  }
  path.applyWithBlock { pointer in
    let e = pointer.pointee
    func v(_ i: Int) -> V2 { [e.points[i].x, e.points[i].y] }
    switch e.type {
    case .moveToPoint:
      flush()
      last = v(0)
      current = [last]
    case .addLineToPoint:
      last = v(0)
      if current.last != last { current.append(last) }
    case .addQuadCurveToPoint:
      let a = last
      let b = v(0)
      let c = v(1)
      for i in 1...steps {
        let t = Double(i) / Double(steps)
        let u = 1 - t
        current.append(a * (u * u) + b * (2 * u * t) + c * (t * t))
      }
      last = c
    case .addCurveToPoint:
      let a = last
      let b = v(0)
      let c = v(1)
      let d = v(2)
      for i in 1...steps {
        let t = Double(i) / Double(steps)
        let u = 1 - t
        current.append(
          a * (u * u * u) + b * (3 * u * u * t) + c * (3 * u * t * t) + d * (t * t * t))
      }
      last = d
    case .closeSubpath: flush()
    @unknown default: preconditionFailure("Unsupported path element")
    }
  }
  flush()
  return result
}
func resample(_ polygon: [V2], _ count: Int, near: V2? = nil) -> [V2] {
  var p = ccw(polygon)
  guard p.count > 2 else { preconditionFailure("Collapsed outline") }
  if let near,
    let start = p.indices.min(by: {
      simd_length_squared(p[$0] - near) < simd_length_squared(p[$1] - near)
    })
  {
    p = Array(p[start...]) + Array(p[..<start])
  }
  let lengths = p.indices.map { simd_distance(p[$0], p[($0 + 1) % p.count]) }
  let total = lengths.reduce(0, +)
  var edge = 0
  var walked = 0.0
  var result: [V2] = []
  for i in 0..<count {
    let target = Double(i) / Double(count) * total
    while edge < lengths.count - 1 && walked + lengths[edge] < target {
      walked += lengths[edge]
      edge += 1
    }
    result.append(
      mix(p[edge], p[(edge + 1) % p.count], (target - walked) / max(1e-12, lengths[edge])))
  }
  return result
}
func shapePoints(_ path: CGPath, _ count: Int = 160) -> [V2] {
  resample(contours(path, steps: 80).max(by: { abs(area($0)) < abs(area($1)) })!, count)
}
// CoreGraphics performs native filled-path operations. Sampling is explicitly versioned:
// it is not byte-identical to the historical polygon-offset implementation.
func inset(_ points: [V2], _ width: Double) -> [V2] {
  if abs(width) < 1e-7 { return points }
  let p = pathOf(points)
  let stroke = p.copy(
    strokingWithWidth: abs(width) * 2, lineCap: .round, lineJoin: .round, miterLimit: 2)
  let adjusted = width > 0 ? p.subtracting(stroke) : p.union(stroke)
  let candidates = contours(adjusted)
  guard let largest = candidates.max(by: { abs(area($0)) < abs(area($1)) }),
    abs(area(largest)) > 1e-8
  else {
    let center = points.reduce(.zero, +) / Double(points.count)
    return points.map { mix($0, center, 0.65) }
  }
  return resample(largest, points.count, near: points[0])
}
func unionOutline(_ polygons: [[V2]], _ count: Int = 320) -> [V2] {
  let p = polygons.dropFirst().reduce(pathOf(polygons[0])) { $0.union(pathOf($1)) }
  return shapePoints(p, count)
}
func inside(_ q: V2, _ p: [V2]) -> Bool {
  var hit = false
  for i in p.indices {
    let a = p[i]
    let b = p[(i + 1) % p.count]
    if (a.y > q.y) != (b.y > q.y) && q.x < (b.x - a.x) * (q.y - a.y) / (b.y - a.y) + a.x {
      hit.toggle()
    }
  }
  return hit
}
func segmentsCross(_ a: V2, _ b: V2, _ c: V2, _ d: V2) -> Bool {
  let x = cross2(b - a, c - a)
  let y = cross2(b - a, d - a)
  let z = cross2(d - c, a - c)
  let w = cross2(d - c, b - c)
  return x * y < -1e-16 && z * w < -1e-16
}
struct PlanarTriangles {
  var points: [V2]
  var indices: [Int]
}
// Ear clipping with visibility bridges preserves glyph counters and concave silhouettes.
// The area check fails closed if a new outline cannot be triangulated correctly.
func triangulate(_ loops: [[V2]]) -> PlanarTriangles {
  var output = PlanarTriangles(points: [], indices: [])
  let sorted = loops.filter { abs(area($0)) > 1e-12 }.sorted { abs(area($0)) > abs(area($1)) }
  var levels: [Int] = []
  for i in sorted.indices {
    levels.append((0..<i).filter { inside(sorted[i][0], sorted[$0]) }.count)
  }
  for index in sorted.indices where levels[index] % 2 == 0 {
    let outer = ccw(sorted[index])
    let holes = sorted.indices.filter {
      levels[$0] == levels[index] + 1 && inside(sorted[$0][0], outer)
    }.map { Array(ccw(sorted[$0]).reversed()) }.sorted { $0.map(\.x).max()! > $1.map(\.x).max()! }
    var p = outer
    for hole in holes {
      let h = hole.indices.max { hole[$0].x < hole[$1].x }!
      let hp = hole[h]
      let candidates = p.indices.sorted {
        simd_length_squared(p[$0] - hp) < simd_length_squared(p[$1] - hp)
      }
      let bridge = candidates.first { candidate in
        let q = p[candidate]
        let mid = (q + hp) / 2
        guard inside(mid, outer), !holes.contains(where: { inside(mid, $0) }) else { return false }
        return !([p] + holes).contains { loop in
          loop.indices.contains { j in segmentsCross(hp, q, loop[j], loop[(j + 1) % loop.count]) }
        }
      }
      guard let b = bridge else { preconditionFailure("No visible bridge for polygon hole") }
      let ring = Array(hole[h...]) + Array(hole[..<h]) + [hp, p[b]]
      p = Array(p[...b]) + ring + Array(p[(b + 1)...])
    }
    var remaining = Array(p.indices)
    var triangles: [Int] = []
    var stalled = 0
    while remaining.count > 3 {
      var found = false
      for j in remaining.indices {
        let a = remaining[(j + remaining.count - 1) % remaining.count]
        let b = remaining[j]
        let c = remaining[(j + 1) % remaining.count]
        let pa = p[a]
        let pb = p[b]
        let pc = p[c]
        let turn = cross2(pb - pa, pc - pb)
        if turn <= 1e-13 { continue }
        let contains = remaining.contains { k in
          let q = p[k]
          if k == a || k == b || k == c || simd_distance(q, pa) < 1e-9
            || simd_distance(q, pb) < 1e-9 || simd_distance(q, pc) < 1e-9
          {
            return false
          }
          return cross2(pb - pa, q - pa) >= (-1e-12) && cross2(pc - pb, q - pb) >= (-1e-12)
            && cross2(pa - pc, q - pc) >= (-1e-12)
        }
        if !contains {
          triangles += [a, b, c]
          remaining.remove(at: j)
          found = true
          break
        }
      }
      if !found {
        // Collinear flattened curve vertices may be removed without changing the fill.
        if let j = remaining.indices.first(where: { j in
          let a = p[remaining[(j + remaining.count - 1) % remaining.count]]
          let b = p[remaining[j]]
          let c = p[remaining[(j + 1) % remaining.count]]
          return abs(cross2(b - a, c - b)) < 1e-11
        }) {
          remaining.remove(at: j)
        } else {
          stalled += 1
        }
        precondition(stalled == 0, "Unable to triangulate outline (\(remaining.count) remaining)")
      }
    }
    if remaining.count == 3 { triangles += remaining }
    let expected = abs(area(outer)) - holes.reduce(0) { $0 + abs(area($1)) }
    let actual = stride(from: 0, to: triangles.count, by: 3).reduce(0.0) { sum, i in
      sum + abs(
        cross2(p[triangles[i + 1]] - p[triangles[i]], p[triangles[i + 2]] - p[triangles[i]])) / 2
    }
    precondition(
      abs(expected - actual) < max(1e-8, expected * 1e-5),
      "Triangulation changed filled area: \(expected) / \(actual)")
    let base = output.points.count
    output.points += p
    output.indices += triangles.map { $0 + base }
  }
  return output
}
func extrusion(_ loops: [[V2]], depth: Double, bevel: Double, z: Double = 0, bevelSegments: Int = 5)
  -> Mesh
{
  let caps = triangulate(loops)
  var m = Mesh(bendableCap: true)
  for face in 0...1 {
    let base = m.vertices.count
    let zz = z + (face == 0 ? -bevel : depth + bevel)
    let normal = V3(0, 0, face == 0 ? -1 : 1)
    m.vertices += caps.points.map { Vertex(p: V3($0.x, $0.y, zz), n: normal, uv: $0) }
    for i in stride(from: 0, to: caps.indices.count, by: 3) {
      let a = base + caps.indices[i]
      let b = base + caps.indices[i + 1]
      let c = base + caps.indices[i + 2]
      if face == 0 { m.triangle(a, c, b) } else { m.triangle(a, b, c) }
    }
  }
  // Miter vectors preserve vertex correspondence along the shallow rounded bevel.
  for loop in loops {
    let p = loop
    let n = p.count
    guard n > 2 else { continue }
    let offsets = p.indices.map { i -> V2 in
      let a = simd_normalize(p[i] - p[(i + n - 1) % n])
      let b = simd_normalize(p[(i + 1) % n] - p[i])
      let na = V2(a.y, -a.x)
      let nb = V2(b.y, -b.x)
      let bis = na + nb
      let denom = simd_dot(bis, nb)
      return abs(denom) > 1e-6 ? bis / denom : nb
    }
    var profile: [V2] = []
    if bevel > 0 {
      for j in 0...bevelSegments {
        let a = Double(j) / Double(bevelSegments) * .pi / 2
        profile.append([sin(a) * bevel, -cos(a) * bevel])
      }
      for j in 0...bevelSegments {
        let a = Double(j) / Double(bevelSegments) * .pi / 2
        profile.append([cos(a) * bevel, depth + sin(a) * bevel])
      }
    } else {
      profile = [[0, 0], [0, depth]]
    }
    var side = Mesh()
    for (j, pr) in profile.enumerated() {
      for i in p.indices {
        let xy = p[i] + offsets[i] * pr.x
        side.vertices.append(
          Vertex(
            p: [xy.x, xy.y, z + pr.y],
            uv: [Double(i) / Double(n), Double(j) / Double(profile.count - 1)]))
      }
    }
    for j in 0..<(profile.count - 1) {
      for i in p.indices {
        let a = j * n + i
        let b = j * n + (i + 1) % n
        side.triangle(a, b, a + n)
        side.triangle(b, b + n, a + n)
      }
    }
    side.normals()
    m.append(side)
  }
  return m
}
func extruded(
  _ points: [V2], _ depth: Double, _ bevel: Double, _ material: Material, _ z: Double = 0
) -> Node {
  Node(extrusion([ccw(points)], depth: depth, bevel: bevel, z: z), material)
}
func contourRing(_ points: [V2], _ profile: [V2], _ material: Material) -> Node {
  let rows = profile + [profile[0]]
  let n = points.count
  var m = Mesh()
  for (j, row) in rows.enumerated() {
    let p = inset(points, row.x)
    for i in 0..<n {
      m.vertices.append(
        Vertex(
          p: [p[i].x, p[i].y, row.y], uv: [Double(i) / Double(n), Double(j) / Double(rows.count)]))
    }
  }
  for j in 0..<(rows.count - 1) {
    for i in 0..<n {
      let a = j * n + i
      let b = j * n + (i + 1) % n
      m.triangle(a, b, a + n)
      m.triangle(b, b + n, a + n)
    }
  }
  m.normals()
  return Node(m, material)
}
func dome(_ points: [V2], _ z: Double, _ rise: Double, _ material: Material, reverse: Bool = false)
  -> Node
{
  let n = points.count
  let rows = 24
  let x0 = points.map(\.x).min()!
  let x1 = points.map(\.x).max()!
  let y0 = points.map(\.y).min()!
  let y1 = points.map(\.y).max()!
  var m = Mesh(vertices: [Vertex(p: [0, 0, z + rise], uv: [0.5, 0.5])])
  for j in 1...rows {
    let r = Double(j) / Double(rows)
    for p in points {
      let x = p.x * r
      let y = p.y * r
      m.vertices.append(
        Vertex(
          p: [x, y, z + rise * (1 - r * r)], uv: [(x - x0) / (x1 - x0), (y - y0) / (y1 - y0)]))
    }
  }
  for i in 0..<n { m.triangle(0, 1 + i, 1 + (i + 1) % n) }
  for j in 1..<rows {
    for i in 0..<n {
      let a = 1 + (j - 1) * n + i
      let b = 1 + (j - 1) * n + (i + 1) % n
      m.triangle(a, a + n, b)
      m.triangle(b, a + n, b + n)
    }
  }
  m.normals()
  if reverse { m.reverse() }
  return Node(m, material)
}
func radialHeight(_ p: [V2], _ z: Double, _ rise: Double) -> (Double, Double) -> Double {
  { x, y in
    if hypot(x, y) < 1e-8 { return z + rise }
    let v = V2(x, y)
    var edge = Double.infinity
    for i in p.indices {
      let a = p[i]
      let d = p[(i + 1) % p.count] - a
      let det = cross2(v, d)
      if abs(det) < 1e-10 { continue }
      let t = cross2(a, d) / det
      let u = cross2(a, v) / det
      if t > 0 && u >= 0 && u <= 1 { edge = min(edge, t) }
    }
    return z + rise * max(0, 1 - 1 / (edge * edge))
  }
}
func circlePoints(_ radius: Double = 1, _ n: Int = 192, _ lobes: Int = 0, _ depth: Double = 0)
  -> [V2]
{
  (0..<n).map { i in
    let a = Double(i) / Double(n) * tau
    let r = radius + cos(a * Double(lobes)) * depth
    return [cos(a) * r, sin(a) * r]
  }
}
func regular(_ n: Int, _ radius: Double = 1, _ rotation: Double = 0) -> [V2] {
  (0..<n).map { i in
    let a = Double(i) / Double(n) * tau + rotation
    return [cos(a) * radius, sin(a) * radius]
  }
}
func smoothPolygon(_ points: [V2], _ cut: Double = 0.15) -> [V2] {
  let path = CGMutablePath()
  let n = points.count
  for i in 0..<n {
    let a = points[(i + n - 1) % n]
    let b = points[i]
    let c = points[(i + 1) % n]
    let start = mix(b, a, cut)
    let end = mix(b, c, cut)
    if i == 0 {
      path.move(to: CGPoint(x: start.x, y: start.y))
    } else {
      path.addLine(to: CGPoint(x: start.x, y: start.y))
    }
    path.addQuadCurve(to: CGPoint(x: end.x, y: end.y), control: CGPoint(x: b.x, y: b.y))
  }
  path.closeSubpath()
  return shapePoints(path)
}

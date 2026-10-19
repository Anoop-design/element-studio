import Foundation
import simd

func shell(
  _ sample: (Double, Double) -> V3, _ material: Material, sections: Int = 280, sides: Int = 48,
  flip: Bool = false
) -> Node {
  var m = Mesh()
  for i in 0...sections {
    for j in 0..<sides {
      let u = Double(i) / Double(sections)
      let v = Double(j) / Double(sides)
      m.vertices.append(Vertex(p: sample(u, v * tau), uv: [u, v]))
    }
  }
  for i in 0..<sections {
    for j in 0..<sides {
      let a = i * sides + j
      let b = a + sides
      let d = i * sides + (j + 1) % sides
      let c = d + sides
      m.triangle(a, b, d)
      m.triangle(b, c, d)
    }
  }
  for end in [0, sections] {
    for j in 0..<(sides / 2) {
      let a = end * sides + j
      let b = a + 1
      let c = end * sides + (sides - j - 1) % sides
      let d = end * sides + (sides - j) % sides
      if end == 0 {
        m.triangle(a, d, b)
        m.triangle(b, d, c)
      } else {
        m.triangle(a, b, d)
        m.triangle(b, c, d)
      }
    }
  }
  m.normals()
  if flip { m.reverse() }
  return Node(m, material)
}
func patch(
  _ sample: (Double, Double) -> V3, _ material: Material, sections: Int = 260, across: Int = 36,
  flip: Bool = false
) -> Node {
  var m = Mesh()
  for i in 0...sections {
    for j in 0...across {
      let u = Double(i) / Double(sections)
      let v = Double(j) / Double(across)
      m.vertices.append(Vertex(p: sample(u, v), uv: [u, v]))
    }
  }
  for i in 0..<sections {
    for j in 0..<across {
      let a = i * (across + 1) + j
      let b = a + across + 1
      m.triangle(a, b, a + 1)
      m.triangle(b, b + 1, a + 1)
    }
  }
  m.normals()
  if flip { m.reverse() }
  return Node(m, material)
}
func formStudy(_ id: String, _ study: String, _ font: OutlineFont) -> Node {
  let group = Node()
  let folded = study == "folded"
  let porcelain = study == "ceramic"
  if id == "returning" {
    func center(_ t: Double) -> V3 {
      let a = 0.55 + t * 5.93
      let r = 0.755 + 0.027 * sin(t * tau)
      let z = folded ? 0.16 * sin(t * tau - 0.5) : -0.12 + 0.26 * smooth(t)
      return [r * cos(a), r * sin(a), z]
    }
    func sweep(_ t: Double, _ phi: Double) -> V3 {
      let a = 0.55 + t * 5.93
      let c = center(t)
      let tangent = unit(center(clamp(t + 0.0001)) - center(clamp(t - 0.0001)))
      let radial = V3(cos(a), sin(a), 0)
      let forward = unit(simd_cross(radial, tangent))
      let twist = (folded ? 0.36 : 0.06) * sin(t * tau)
      let across = radial * cos(twist) + forward * sin(twist)
      let front = forward * cos(twist) - radial * sin(twist)
      var width = 0.30 + 0.045 * sin(t * .pi)
      if t > 0.69 && t < 0.81 { width += (0.66 - width) * smooth((t - 0.69) / 0.12) }
      if t >= 0.81 { width = 0.66 * cos(clamp((t - 0.81) / 0.19) * .pi / 2) }
      if t < 0.035 { width *= sqrt(max(0.0001, 1 - pow(1 - t / 0.035, 2))) }
      width = max(0.007, width)
      var depth = porcelain ? 0.24 : folded ? 0.066 : 0.16
      depth *= sqrt(max(0.0001, 1 - pow(1 - clamp(t / 0.025), 2)))
      depth *= sqrt(max(0.0001, 1 - pow(clamp((t - 0.94) / 0.06), 2)))
      depth = max(0.009, depth)
      let exponent = porcelain ? 1.0 : folded ? 0.32 : 0.62
      return c + across * (signedPower(cos(phi), exponent) * width / 2) + front
        * (signedPower(sin(phi), porcelain ? 1 : 0.62) * depth / 2)
    }
    part(
      group, shell(sweep, porcelain ? .ceramic(0xd8aa67) : .satin, sections: 420, sides: 64),
      "Continuous rounded loop")
    if !porcelain {
      let face = patch(
        { u, v in
          var p = sweep(0.0005 + u * 0.999, 0.19 * .pi + v * 0.62 * .pi)
          p.z += 0.0035
          return p
        }, .enamel(folded ? 0xbb8235 : 0xb87825))
      part(group, face, "Glazed amber along the sweep", [0, 0, 0.32])
    }
  } else {
    let start = folded ? -0.58 : 0
    let halfDepth = folded ? 0.029 : porcelain ? 0.115 : 0.095
    func width(_ s: Double) -> Double {
      s < 0 ? 0.56 : 0.56 - 0.12 * sin(s * .pi) + 0.08 * pow(s, 5)
    }
    func spine(_ s: Double) -> V3 {
      if folded && s < -0.34 {
        return [0, 0.93 + (s + 0.34) * 0.95, -0.18 + 0.02 * sin((s + 0.34) * 4)]
      }
      if folded && s < 0 {
        let a = -s / 0.34 * .pi
        return [0, 0.93 + 0.14 * sin(a), -0.04 + 0.14 * cos(a)]
      }
      return [0, 0.93 - 2.02 * s, (folded ? 0.10 : 0.065) * cos(s * tau) + 0.055 * s]
    }
    func ribbonPoint(_ s: Double, _ v: Double, _ depth: Double) -> V3 {
      var p = spine(s)
      let u = clamp(s)
      p.x = v * width(s)
      let notch = (sqrt(v * v + 0.06 * 0.06) - 0.06) / (sqrt(1 + 0.06 * 0.06) - 0.06)
      p.y += 0.46 * pow(max(0, 1 - notch), 1.65) * pow(u, 3)
      if !folded { p.y -= 0.055 * (1 - sqrt(max(0, 1 - v * v))) * pow(1 - u, 6) }
      p.z += (folded ? 0.09 : 0.045) * v * v + (folded ? 0.15 : 0.075) * v * pow(u, 3)
      let tangent = unit(spine(s + 0.0001) - spine(s - 0.0001))
      let normal = unit(simd_cross(tangent, V3(1, 0, 0)))
      return p + normal * depth
    }
    func sample(_ t: Double, _ phi: Double) -> V3 {
      ribbonPoint(
        start + t * (1 - start), cos(phi),
        signedPower(sin(phi), porcelain ? 0.75 : 0.24) * halfDepth)
    }
    part(
      group,
      shell(
        sample, porcelain ? .ceramic(0xb8bd81) : folded ? .enamel(0x7e923f) : .satin, sections: 280,
        sides: 128, flip: true), "Continuous folded strip")
    if !folded && !porcelain {
      part(
        group,
        patch(
          { u, v in
            var p = sample(0.008 + u * 0.984, 0.13 * .pi + v * 0.74 * .pi)
            p.z += 0.004
            return p
          }, .enamel(0x8f9c43), flip: true), "Glazed front", [0, 0, 0.30])
    }
    if folded {
      for side in [-1.0, 1.0] {
        let path = (0..<180).map { ribbonPoint(start + (1 - start) * Double($0) / 179, side, 0) }
        part(
          group, tube(path, 0.0075, .satin, segments: 280), "Fine edge binding",
          [side * 0.20, 0, 0.12])
      }
    }
    let face = Node()
    let ink: Material = porcelain ? .enamel(0x65713c) : .ceramic(0xe9ecd8)
    face.add(font.text("12", 0.47, 0.006, ink, 0, 0.03))
    face.add(font.text("ACTIVE", 0.072, 0.0015, ink, 0, -0.31))
    face.add(font.text("WEEKS", 0.072, 0.0015, ink, 0, -0.425))
    bend(
      face,
      { x, y in
        var s = clamp((0.93 - y) / 2.02)
        for _ in 0..<6 {
          let v = clamp(x / width(s), -1, 1)
          let p = ribbonPoint(s, v, 0)
          s = clamp(s + (p.y - y) / 2.02)
        }
        let v = clamp(x / width(s), -0.98, 0.98)
        let p = ribbonPoint(s, v, 0)
        let depth = halfDepth * pow(max(0, 1 - v * v), (porcelain ? 0.75 : 0.24) / 2)
        return p.z + depth + 0.009
      })
    part(group, face, "Low relief count", [0, 0, 0.30])
    group.face = face
  }
  return group
}

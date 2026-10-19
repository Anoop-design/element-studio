import Foundation
import simd

struct DaybeatShapes {
  let font: OutlineFont
  let mark: BrandMark
  func medal(
    _ points: [V2], _ color: UInt32, label: String = "", sub: String = "", rise: Double = 0.045
  ) -> Node {
    let group = Node()
    let face = Node()
    let facePoints = inset(points, 0.077)
    part(group, extruded(inset(points, 0.032), 0.16, 0.032, .satin, -0.11), "Satin body")
    part(
      group,
      contourRing(
        points,
        [[0.025, 0.075], [0.002, 0.095], [0.010, 0.118], [0.035, 0.13], [0.074, 0.099]], .polished),
      "Polished retaining lip", [0, 0, 0.72])
    face.add(dome(facePoints, 0.080, rise, .enamel(color)))
    if !label.isEmpty { face.add(font.text(label, 0.39, 0.007, .lettering, 0, 0.05, 0.15)) }
    if !sub.isEmpty { face.add(font.text(sub, 0.069, 0.003, .lettering, 0, -0.29, 0.14)) }
    part(group, face, "Enamel inset", [0, 0, 0.32])
    group.face = face
    group.faceHeight = radialHeight(facePoints, 0.080, rise)
    return group
  }
  func castMedal(
    _ points: [V2], _ color: UInt32, label: String = "", sub: String = "", crown: Double = 0.045
  ) -> Node {
    let group = Node()
    let face = Node()
    part(group, extruded(inset(points, 0.018), 0.15, 0.034, .satin, -0.09), "Rounded satin casting")
    part(
      face, extruded(inset(points, 0.063), 0.023, 0.025, .enamel(color), 0.063),
      "Continuous enamel crown")
    if !label.isEmpty { face.add(font.text(label, 0.44, 0.004, .lettering, 0, 0.08, 0.115)) }
    if !sub.isEmpty { face.add(font.text(sub, 0.095, 0.002, .lettering, 0, -0.28, 0.115)) }
    part(group, face, "Fitted enamel face", [0, 0, 0.35])
    group.face = face
    group.faceHeight = { _, _ in 0.111 }
    group.warp = { x, y in crown * (1 - 0.62 * x * x - 0.30 * y * y) }
    return group
  }
  func build(_ id: String, study: String? = nil, live: Bool = false) -> Node {
    var group = Node()
    switch id {
    case "returning" where study == nil || study == "curved":
      let r = 0.74
      let half = 0.135
      let start = 50 * Double.pi / 180
      let end = 330 * Double.pi / 180
      var band: [V2] = []
      for i in 0...160 {
        let a = start + (end - start) * Double(i) / 160
        band.append([cos(a) * (r + half), sin(a) * (r + half)])
      }
      for i in (0...160).reversed() {
        let a = start + (end - start) * Double(i) / 160
        band.append([cos(a) * (r - half), sin(a) * (r - half)])
      }
      let c = V2(cos(end) * r, sin(end) * r)
      let tangent = V2(-sin(end), cos(end))
      let radial = V2(cos(end), sin(end))
      let head = [
        c + tangent * 0.41, c - tangent * 0.085 + radial * 0.30,
        c - tangent * 0.085 - radial * 0.30,
      ]
      let tail = circlePoints(half, 64).map { $0 + V2(cos(start) * r, sin(start) * r) }
      let united = unionOutline([ccw(band), ccw(head), tail], 260)
      let outline = inset(inset(united, 0.045), -0.045)
      group = castMedal(outline, 0xb77c29, crown: 0.024)
    case "returning", "ribbon":
      group = formStudy(id, study ?? (id == "ribbon" ? "folded" : "curved"), font)
    case "stopwatch":
      part(
        group,
        lathe(
          [
            [0.001, -0.13], [0.88, -0.13], [0.95, -0.12], [0.989, -0.078], [1, -0.025], [1, 0.045],
            [0.99, 0.08], [0.966, 0.105], [0.93, 0.111], [0.912, 0.09], [0.912, -0.08],
            [0.001, -0.08],
          ], .satin), "Lathed titanium case")
      part(
        group,
        lathe(
          [
            [0.905, 0.082], [0.985, 0.082], [0.992, 0.096], [0.969, 0.123], [0.932, 0.134],
            [0.909, 0.115], [0.905, 0.082],
          ], .satin), "Polished bezel", [0, 0, 0.76])
      let face = Node()
      let dial = lathe(
        [[0.001, 0.057], [0.90, 0.057], [0.906, 0.065], [0.9, 0.083], [0.001, 0.083]],
        Material(role: "dial", hex: 0x123766, metallic: 0.20))
      if var mesh = dial.mesh {
        for i in mesh.vertices.indices {
          let p = mesh.vertices[i].p
          mesh.vertices[i].uv = [p.x / 1.82 + 0.5, p.y / 1.82 + 0.5]
        }
        dial.mesh = mesh
      }
      face.add(dial)
      face.add(ring(0.965, 0.0035, 0.126, .polished))
      face.add(ring(0.887, 0.006, 0.093, .polished))
      face.add(ring(0.726, 0.0025, 0.086, .ink))
      for i in 0..<60 {
        let major = i % 5 == 0
        let a = Double(i) / 60 * tau
        let tick = capsule(
          major ? 0.0065 : 0.0035, major ? 0.067 : 0.033, major ? .lettering : .satin,
          capSegments: 4, radial: 8)
        tick.scale.z = 0.42
        tick.position = [sin(a) * (major ? 0.801 : 0.821), cos(a) * (major ? 0.801 : 0.821), 0.089]
        tick.rotation.z = -a
        face.add(tick)
      }
      face.add(font.text("5K", 0.50, 0.012, .lettering, 0, 0.07, 0.087))
      let run = runner(.lettering, 0.38)
      run.position = [0.02, -0.39, 0.10]
      face.add(run)
      part(group, face, "Blue enamel dial and chapter ring", [0, 0, 0.33])
      let crown = Node()
      crown.add(
        lathe(
          [[0.04, 0], [0.062, 0.015], [0.062, 0.13], [0.04, 0.14]], .satin, axis: "y", segments: 64)
      )
      crown.add(
        lathe(
          [
            [0.09, 0.11], [0.115, 0.13], [0.117, 0.25], [0.102, 0.273], [0.071, 0.285],
            [0.001, 0.288],
          ], .satin, axis: "y", segments: 96))
      for i in 0..<32 {
        let a = Double(i) / 32 * tau
        let flute = cylinder(0.006, 0.112, .polished, segments: 6)
        flute.position = [cos(a) * 0.116, 0.19, sin(a) * 0.116]
        crown.add(flute)
      }
      crown.position.y = 0.972
      part(group, crown, "32-flute crown", [0, 0.60, 0])
      part(
        group,
        lathe([[0.001, -0.145], [0.82, -0.145], [0.89, -0.137], [0.927, -0.12]], .satin),
        "Fitted reverse cap", [0, 0, -0.40])
    case "hourglass":
      let profile = (0...80).map { i -> V2 in
        let y = -0.87 + Double(i) / 80 * 1.74
        let t = abs(y) / 0.87
        return [0.048 + 0.667 * pow(sin(t * .pi * 0.65), 1.18), y]
      }
      let glass = lathe(profile, .glass, axis: "y")
      glass.scale.z = 0.29
      part(group, glass, "Continuous glass chambers", [0, 0, 0.65])
      for side in [-1.0, 1.0] {
        let cap = lathe(
          [
            [0.001, -0.07], [0.69, -0.07], [0.755, -0.055], [0.787, -0.02], [0.787, 0.04],
            [0.755, 0.067], [0.001, 0.067],
          ], .satin, axis: "y")
        cap.position.y = side * 0.91
        cap.scale.z = 0.35
        part(group, cap, side > 0 ? "Upper cap" : "Lower cap", [0, side * 0.55, 0])
        let lip = lathe(
          [[0.723, -0.017], [0.78, -0.011], [0.789, 0], [0.78, 0.015]], .polished, axis: "y")
        lip.position.y = side * 0.853
        lip.scale.z = 0.35
        part(group, lip, "Polished glass seat", [0, side * 0.43, 0])
        let path = profile.enumerated().filter { $0.offset % 4 == 0 }.map {
          V3(side * ($0.element.x + 0.045), $0.element.y, -0.005)
        }
        let rail = tube(path, 0.042, .satin, segments: 100)
        rail.scale.z = 0.72
        part(group, rail, "Curved frame shoulder", [side * 0.48, 0, 0])
      }
      let lower = lathe(
        [
          [0.001, 0], [0.60, 0], [0.655, 0.042], [0.59, 0.07], [0.45, 0.115], [0.30, 0.195],
          [0.15, 0.29], [0.001, 0.39],
        ], .sand, axis: "y", segments: 96)
      lower.scale.z = 0.27
      lower.position.y = -0.822
      group.add(lower)
      let upper = lathe(
        [
          [0.025, 0], [0.07, 0.09], [0.18, 0.24], [0.36, 0.43], [0.52, 0.58], [0.53, 0.60],
          [0.001, 0.60],
        ], .sand, axis: "y", segments: 96)
      upper.scale.z = 0.27
      upper.position.y = 0.035
      group.add(upper)
      let inscription = Node()
      inscription.position = [0, -0.918, 0.266]
      inscription.add(font.text("1:00:00", 0.072, 0.002, .ink))
      part(group, inscription, "Cap inscription", [0, -0.55, 0])
    case "memory":
      let pts = Outline().move(-0.07, 0.60).cubic(-0.49, 1.02, -1.10, 0.56, -0.86, -0.03).cubic(
        -0.66, -0.38, -0.20, -0.75, -0.06, -0.89
      ).quad(0, -0.96, 0.06, -0.89).cubic(0.20, -0.75, 0.66, -0.38, 0.86, -0.03).cubic(
        1.10, 0.56, 0.49, 1.02, 0.07, 0.60
      ).quad(0, 0.51, -0.07, 0.60).points(192)
      part(group, extruded(inset(pts, 0.050), 0.16, 0.032, .satin, -0.12), "Satin heart shell")
      part(
        group, dome(inset(pts, 0.005), -0.139, -0.055, .satin, reverse: true), "Domed reverse",
        [0, 0, -0.45])
      part(
        group,
        contourRing(
          pts, [[0.019, 0.067], [0.001, 0.100], [0.017, 0.12], [0.047, 0.13], [0.083, 0.105]],
          .polished), "Polished window lip", [0, 0, 0.77])
      part(
        group,
        contourRing(
          inset(pts, 0.09), [[0, 0.095], [0.006, 0.105], [0.026, 0.101], [0.036, 0.093]],
          .enamel(0x174973)), "Blue enamel gasket", [0, 0, 0.5])
      part(
        group, dome(inset(pts, 0.128), 0.103, 0.012, .photo), "Recessed photograph", [0, 0, 0.21])
      part(
        group, dome(inset(pts, 0.115), 0.122, 0.045, .glass), "Curved protective lens",
        [0, 0, 1.05])
    case "energy":
      let outline = Outline().move(0, -1).cubic(-1.14, -0.61, -0.90, 0.10, -0.48, 0.42).cubic(
        -0.16, 0.70, 0.05, 0.91, 0.11, 1.13
      ).cubic(0.43, 0.84, 0.38, 0.45, 0.31, 0.26).cubic(0.52, 0.37, 0.66, 0.52, 0.63, 0.68).cubic(
        1.04, 0.09, 1.03, -0.64, 0, -1
      ).points(260)
      group = castMedal(outline, 0xbc3024, crown: 0.072)
      let run = runner(.lettering, 0.4)
      run.position = [-0.19, -0.3, 0.21]
      group.face!.add(run)
    case "distance":
      group = medal(
        smoothPolygon(regular(6, 1.06, .pi / 6), 0.07), 0x137d9e, label: "12.4", sub: "KM",
        rise: 0.055)
      let run = runner(.lettering, 0.32)
      run.position = [0.02, 0.5, 0.13]
      group.face!.add(run)
    case "sunrise":
      let pts = Outline().move(-0.76, -0.35).arc(0, -0.35, 0.76, .pi, 0).line(-0.76, -0.35).points()
      group = medal(pts, 0xd69732, rise: 0.055)
      let radius = 0.683
      let height: (Double, Double) -> Double = { x, y in
        0.080 + 0.045 * (1 - (x * x + pow(y + 0.35, 2)) / (radius * radius))
      }
      let face = group.face!.children[0]
      var mesh = face.mesh!
      for i in mesh.vertices.indices {
        let p = mesh.vertices[i].p
        mesh.vertices[i].p.z = height(p.x, p.y)
        mesh.vertices[i].n = unit([
          0.090 * p.x / (radius * radius), 0.090 * (p.y + 0.35) / (radius * radius), 1,
        ])
      }
      face.mesh = mesh
      group.faceHeight = height
      for i in 0..<5 {
        let a = Double(i + 1) / 6 * .pi
        let ray = capsule(0.071, 0.28, .polished)
        ray.position = [cos(a) * 0.99, sin(a) * 0.99 - 0.35, 0.018]
        ray.rotation.z = a - .pi / 2
        part(group, ray, "Dawn ray", [cos(a) * 0.22, sin(a) * 0.22, 0.2])
      }
      part(
        group,
        extruded(
          smoothPolygon([[-0.94, -0.32], [0.94, -0.32], [0.84, -0.49], [-0.84, -0.49]], 0.16), 0.16,
          0.03, .satin, -0.065), "Raised horizon", [0, -0.30, 0.20])
      let run = runner(.lettering, 0.43)
      run.position = [0, -0.03, 0.14]
      group.face!.add(run)
    case "pennant":
      group = medal(
        smoothPolygon(
          [[-0.66, 0.96], [0.66, 0.96], [0.62, -0.42], [0, -0.94], [-0.62, -0.42]], 0.065),
        0x218d72, label: "5K", sub: "FIRST", rise: 0.035)
      group.warp = { _, y in 0.05 * tanh((y + 0.38) * 12) }
      group.face!.add(
        tube(
          [[-0.46, 0.78, 0.16], [0, 0.80, 0.18], [0.46, 0.78, 0.16]], 0.009, .polished, segments: 50
        ))
    case "year":
      group = medal(
        circlePoints(0.90, 240, 12, 0.047), 0x819947, label: "2026", sub: "ONE YEAR", rise: 0.035)
      for i in 0..<12 {
        let a = Double(i) / 12 * tau + .pi / 2
        let marker = sphere(0.020, .polished, columns: 16, rows: 12)
        marker.scale.z = 0.32
        marker.position = [cos(a) * 0.715, sin(a) * 0.715, 0.105]
        marker.rotation.z = a - .pi / 2
        group.face!.add(marker)
      }
    case "month", "week":
      let week = id == "week"
      group = medal(
        smoothPolygon([[-0.78, 0.90], [0.78, 0.90], [0.72, -0.73], [-0.77, -0.88]], 0.12),
        week ? 0x18784e : 0x255f83)
      group.face!.add(
        font.text(
          week ? "7" : "JUL 2026", week ? 0.40 : 0.145, 0.005, .lettering, 0, week ? 0.18 : 0.57,
          0.13))
      if week {
        group.face!.add(font.text("ACTIVE DAYS", 0.085, 0.005, .lettering, 0, -0.15, 0.13))
      }
      for day in 1...(week ? 7 : 31) {
        let cell = week ? day - 1 : day + 1
        let col = cell % 7
        let row = cell / 7
        let dot = cylinder(0.029, 0.013, .polished)
        dot.fixture = true
        dot.rotation.x = .pi / 2
        dot.position = [Double(col - 3) * 0.17, (week ? -0.43 : 0.29) - Double(row) * 0.17, 0.131]
        group.face!.add(dot)
      }
      group.face!.add(
        tube(
          [[-0.60, 0.77, 0.13], [0, 0.79, 0.17], [0.60, 0.77, 0.13]], 0.025, .satin, segments: 50))
    case "halfYear":
      group = castMedal(
        circlePoints(0.88, 264, 6, 0.063), 0x884b87, label: "6", sub: "MONTHS", crown: 0.05)
      for i in 0..<6 {
        let a = .pi / 2 + Double(i) * .pi / 3
        let marker = sphere(0.026, .polished, columns: 20, rows: 12)
        marker.scale.z = 0.32
        marker.position = [cos(a) * 0.68, sin(a) * 0.68, 0.115]
        group.face!.add(marker)
      }
    case "activity":
      let pts = Outline().move(-0.66, -0.29).line(-0.66, 0.29).arc(0, 0.29, 0.66, .pi, 0).line(
        0.66, -0.29
      ).arc(0, -0.29, 0.66, 0, -Double.pi).close().points(240)
      group = castMedal(pts, 0x248894, label: "12", sub: "WEEKS")
      let run = runner(.lettering, 0.43)
      run.position = [0, 0.58, 0.115]
      group.face!.add(run)
    case "frequency":
      group = medal(
        smoothPolygon(
          [
            [-0.61, 0.84], [0.61, 0.84], [0.84, 0.08], [0.49, -0.83], [-0.49, -0.83],
            [-0.84, 0.08],
          ], 0.18), 0x247f87, label: "3+", sub: "DAYS / WEEK")
      for i in 0..<3 {
        let x = -0.22 + Double(i) * 0.22
        group.face!.add(
          tube([[x, -0.54, 0.135], [x, -0.47, 0.138]], 0.015, .polished, segments: 6))
      }
    case "collection":
      let pts = smoothPolygon(
        [
          [-0.67, 0.7], [0.67, 0.7], [0.73, -0.1], [0.43, -0.67], [0, -0.85], [-0.43, -0.67],
          [-0.73, -0.1],
        ], 0.18)
      for i in 0..<2 {
        let crest = medal(
          pts, i == 0 ? 0x717341 : 0xa69a50, label: i == 1 ? "2" : "",
          sub: i == 1 ? "MILESTONES" : "", rise: 0.035)
        crest.position = [i == 0 ? -0.13 : 0.10, i == 0 ? 0.17 : -0.07, Double(i) * 0.21]
        part(
          group, crest, "Collected crest \(i+1)",
          [(Double(i) - 0.5) * 0.37, (0.5 - Double(i)) * 0.24, Double(i) * 0.30])
      }
    default: preconditionFailure("Unknown Daybeat object: \(id)")
    }
    seatFaceDetails(group)
    group.visit { node, _ in if let warp = node.warp { bend(node, warp) } }
    if id == "returning" {
      let activity = runner(.satin, 0.80)
      activity.position = [0.056, -0.035, 0.14]
      part(group, activity, "Workout symbol")
    }
    if !live { mark.add(to: group, id: id) }
    group.name = id
    return group
  }
}

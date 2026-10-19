import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct SeededRandom {
  var state: UInt32
  mutating func next() -> Double {
    state = 1_664_525 &* state &+ 1_013_904_223
    return Double(state) / 4_294_967_296
  }
}
enum NativeTextures {
  static func color(_ hex: UInt32, _ alpha: Double = 1) -> CGColor {
    CGColor(
      colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
      components: [
        Double((hex >> 16) & 255) / 255, Double((hex >> 8) & 255) / 255, Double(hex & 255) / 255,
        alpha,
      ])!
  }
  static func save(_ image: CGImage, to url: URL) throws {
    guard
      let destination = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { throw AuthorError.argument("Cannot create PNG: \(url.path)") }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
      throw AuthorError.argument("Cannot finalize PNG: \(url.path)")
    }
  }
  static func memory() -> CGImage {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(
      data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 4096, space: space,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // Use top-left drawing coordinates to retain the original landscape composition.
    ctx.translateBy(x: 0, y: 1024)
    ctx.scaleBy(x: 1, y: -1)
    func gradient(
      _ colors: [UInt32], _ stops: [CGFloat], _ y0: Double, _ y1: Double, _ rect: CGRect
    ) {
      ctx.saveGState()
      ctx.clip(to: rect)
      let g = CGGradient(
        colorsSpace: space, colors: colors.map { color($0) } as CFArray, locations: stops)!
      ctx.drawLinearGradient(
        g, start: CGPoint(x: 0, y: y0), end: CGPoint(x: 0, y: y1),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
      ctx.restoreGState()
    }
    gradient(
      [0x344c78, 0xb0bcd0, 0xecc297, 0xd8a888], [0, 0.45, 0.72, 1], 0, 700,
      CGRect(x: 0, y: 0, width: 1024, height: 1024))
    let glow = CGGradient(
      colorsSpace: space, colors: [color(0xf6daba, 0.85), color(0xf6daba, 0)] as CFArray,
      locations: [0, 1])!
    ctx.drawRadialGradient(
      glow, startCenter: CGPoint(x: 405, y: 368), startRadius: 20,
      endCenter: CGPoint(x: 405, y: 368), endRadius: 80, options: [])
    ctx.setFillColor(color(0xffedcc))
    ctx.fillEllipse(in: CGRect(x: 383, y: 346, width: 44, height: 44))
    let layers: [(UInt32, [[Double]])] = [
      (
        0x8194ad,
        [
          [0, 520], [90, 352], [164, 419], [256, 255], [355, 413], [485, 500], [603, 311],
          [724, 371], [844, 250], [973, 445], [1024, 421],
        ]
      ),
      (
        0x556e8b,
        [
          [0, 544], [97, 475], [187, 510], [303, 368], [416, 505], [542, 428], [649, 480],
          [765, 345], [937, 510], [1024, 435],
        ]
      ),
      (
        0x304b65,
        [
          [0, 590], [119, 548], [189, 568], [291, 489], [352, 510], [446, 568], [611, 529],
          [739, 464], [871, 503], [1024, 573],
        ]
      ),
    ]
    for (hex, points) in layers {
      ctx.setFillColor(color(hex))
      ctx.beginPath()
      ctx.move(to: CGPoint(x: 0, y: 675))
      for p in points { ctx.addLine(to: CGPoint(x: p[0], y: p[1])) }
      ctx.addLine(to: CGPoint(x: 1024, y: 675))
      ctx.closePath()
      ctx.fillPath()
    }
    gradient(
      [0x9ba4aa, 0x586e80, 0x193a53], [0, 0.35, 1], 590, 1024,
      CGRect(x: 0, y: 600, width: 1024, height: 424))
    var random = SeededRandom(state: 938)
    for _ in 0..<220 {
      let y = 604 + random.next() * 420
      let half = 20 + (y - 600) * 0.31
      ctx.setStrokeColor(color(0xedcd9e, 0.06 + random.next() * 0.22))
      ctx.setLineWidth(0.5 + random.next() * 2)
      ctx.beginPath()
      ctx.move(to: CGPoint(x: 405 + (random.next() - 0.5) * half * 2, y: y))
      ctx.addLine(to: CGPoint(x: 405 + (random.next() - 0.5) * half * 2, y: y))
      ctx.strokePath()
    }
    for side in [-1, 1] {
      for i in 0..<14 {
        let x = Double(side < 0 ? i * 15 : 1024 - i * 15)
        let h = 110 + random.next() * 150
        let base = 790 + random.next() * 220
        ctx.setFillColor(color(i % 2 == 1 ? 0x1b3543 : 0x203b48))
        ctx.beginPath()
        ctx.move(to: CGPoint(x: x, y: base - h))
        ctx.addLine(to: CGPoint(x: x - 30, y: base))
        ctx.addLine(to: CGPoint(x: x + 30, y: base))
        ctx.closePath()
        ctx.fillPath()
      }
    }
    return ctx.makeImage()!
  }
  static func sand() -> CGImage {
    var random = SeededRandom(state: 127)
    // Retain the original seed progression after the brushed-metal noise pass.
    for _ in 0..<(512 * 513) { _ = random.next() }
    var pixels = [UInt8]()
    pixels.reserveCapacity(256 * 256 * 4)
    for _ in 0..<(256 * 256) {
      let v = 130 + random.next() * 120
      pixels += [UInt8(v.rounded()), UInt8((v * 0.84).rounded()), UInt8((v * 0.49).rounded()), 255]
    }
    let provider = CGDataProvider(data: Data(pixels) as CFData)!
    return CGImage(
      width: 256, height: 256, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 1024,
      space: CGColorSpace(name: CGColorSpace.sRGB)!,
      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider,
      decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
  }
  static func write(to folder: URL) throws {
    try save(memory(), to: folder.appendingPathComponent("ElementStudio-photo-swift-v1.png"))
    try save(sand(), to: folder.appendingPathComponent("ElementStudio-sand-swift-v1.png"))
  }
}

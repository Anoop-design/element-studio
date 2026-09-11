import Foundation
import RealityKit
import UIKit
import Metal

/// Authored geometry only. Live templates omit fixture inscriptions; canonical
/// Highlight content supplies their markings separately at presentation time.
nonisolated struct ElementStudioAsset: Decodable, Sendable {
    struct Range: Decodable, Sendable { let offset: Int; let count: Int }
    struct Batch: Decodable, Sendable {
        let name: String
        let role: String
        let color: [Float]
        let roughness: Float
        let metallic: Float
        let explode: [Float]
        let positions: Range
        let normals: Range
        let uv: Range
        let indices: Range
    }
    let id: String
    let name: String
    let sub: String
    let description: String
    let geometry: String
    let batches: [Batch]
    let printSurface: PrintSurface?

    struct PrintSurface: Decodable, Sendable {
        let width: Int
        let height: Int
        let xMin: Float
        let yMin: Float
        let xStep: Float
        let yStep: Float
        let front: [Float?]
        let back: [Float?]
    }

    struct Loaded: Sendable { let asset: ElementStudioAsset; let data: Data }
    static func read(id: String, bundle: Bundle = .main) throws -> Loaded {
        guard let manifest = bundle.url(forResource: "ElementStudio-\(id)", withExtension: "json"),
              let binary = bundle.url(forResource: "ElementStudio-\(id)", withExtension: "bin") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let asset = try JSONDecoder().decode(Self.self, from: Data(contentsOf: manifest))
        return Loaded(asset: asset, data: try Data(contentsOf: binary, options: .mappedIfSafe))
    }

    static func floats(_ range: Range, in data: Data) throws -> [Float] {
        try validate(range, in: data)
        return data.withUnsafeBytes { bytes in
            (0..<range.count).map { bytes.loadUnaligned(fromByteOffset: range.offset + $0 * 4, as: Float.self) }
        }
    }
    static func indices(_ range: Range, in data: Data) throws -> [UInt32] {
        try validate(range, in: data)
        return data.withUnsafeBytes { bytes in
            (0..<range.count).map { bytes.loadUnaligned(fromByteOffset: range.offset + $0 * 4, as: UInt32.self) }
        }
    }
    private static func validate(_ range: Range, in data: Data) throws {
        guard range.offset >= 0, range.count >= 0, range.offset <= data.count,
              range.count <= (data.count - range.offset) / 4 else { throw CocoaError(.fileReadCorruptFile) }
    }
}

@MainActor
final class ElementStudioMaterials {
    private var grain: TextureResource?
    private var sand: TextureResource?
    private var photo: TextureResource?
    private var glassMaterial: CustomMaterial?
    private var surfaces: [String: TextureResource] = [:]
    private var prepared = false

    func prepare() async throws {
        if prepared { return }
        grain = try await TextureResource(image: Self.grainImage(), options: .init(semantic: .normal))
        let surfaceNames = (1...8).flatMap { ["brush-\($0)", "glaze-\($0)"] } + ["dial", "roughness"]
        for name in surfaceNames where surfaces[name] == nil {
            try Task.checkCancellation()
            guard let url = Bundle.main.url(forResource: "ElementStudio-surface-\(name)", withExtension: "png"),
                  let image = UIImage(contentsOfFile: url.path)?.cgImage else { throw CocoaError(.fileReadCorruptFile) }
            surfaces[name] = try await TextureResource(image: image,
                options: .init(semantic: name == "roughness" ? .scalar : .normal))
        }
        guard let library = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary() else { throw CocoaError(.fileReadCorruptFile) }
        var glass = try CustomMaterial(surfaceShader: .init(named: "elementStudioGlass", in: library), lightingModel: .clearcoat)
        glass.blending = .transparent(opacity: .init(floatLiteral: 1.0))
        glass.faceCulling = .none
        glass.writesDepth = false
        glassMaterial = glass
        for name in ["sand", "photo"] {
            guard let url = Bundle.main.url(forResource: "ElementStudio-\(name)", withExtension: "png"),
                  let image = UIImage(contentsOfFile: url.path)?.cgImage else { throw CocoaError(.fileReadCorruptFile) }
            let texture = try await TextureResource(image: image, options: .init(semantic: .color))
            if name == "sand" { sand = texture } else { photo = texture }
        }
        prepared = true
    }

    func setPhoto(_ image: CGImage) async throws {
        photo = try await TextureResource(image: image, options: .init(semantic: .color))
    }

    func clearPhoto() { photo = nil }

    func make(_ batch: ElementStudioAsset.Batch, settings: ElementStudioSettings) -> any Material {
        var material = PhysicallyBasedMaterial()
        let role = settings.finish == .clay ? "clay" : settings.finish == .metal ? "satin" : batch.role
        material.baseColor = .init(tint: UIColor(red: CGFloat(batch.color[0]), green: CGFloat(batch.color[1]), blue: CGFloat(batch.color[2]), alpha: 1))
        material.metallic = .init(floatLiteral: batch.metallic)
        material.roughness = .init(floatLiteral: batch.roughness)
        material.triangleFillMode = settings.wireframe ? .lines : .fill
        if settings.chosenEdition != .earlier,
           applySculptedSurface(role, to: &material, settings: settings) { return material }
        switch role {
        case "satin":
            material.baseColor = .init(tint: UIColor(red: 0.71, green: 0.76, blue: 0.80, alpha: 1))
            material.metallic = 1.0
            material.roughness = .init(floatLiteral: Float(settings.roughness))
            material.anisotropyLevel = .init(floatLiteral: Float(settings.grain) * 0.30)
            if settings.grain > 0.01, let grain {
                material.normal = .init(texture: .init(grain))
                material.textureCoordinateTransform = .init(scale: [3, 3])
            }
        case "polished":
            material.roughness = .init(floatLiteral: max(0.065, Float(settings.roughness) * 0.38))
            material.clearcoat = 0.45
            material.clearcoatRoughness = 0.08
        case "enamel":
            material.clearcoat = .init(floatLiteral: Float(settings.clearcoat))
            material.clearcoatRoughness = 0.12
            material.roughness = 0.23
        case "glass":
            if var glass = glassMaterial {
                glass.custom.value = [Float(settings.glass), 0, 0, 0]
                glass.triangleFillMode = settings.wireframe ? .lines : .fill
                return glass
            }
            material.baseColor = .init(tint: UIColor(red: 0.80, green: 0.94, blue: 0.98, alpha: 1))
            material.metallic = 0.0
            material.roughness = 0.065
            material.specular = 1.0
            material.clearcoat = 1.0
            material.clearcoatRoughness = 0.04
            material.blending = .transparent(opacity: .init(floatLiteral: Float(settings.glass)))
            material.faceCulling = .none
            material.writesDepth = false
        case "photo":
            if let photo { material.baseColor = .init(tint: .white, texture: .init(photo)) }
            else { material.baseColor = .init(tint: UIColor(red: 0.12, green: 0.19, blue: 0.23, alpha: 1)) }
            material.roughness = 0.7
            material.textureCoordinateTransform = .init(offset: [0, 1], scale: [1, -1])
        case "sand":
            if let sand { material.baseColor = .init(tint: .white, texture: .init(sand)) }
            material.roughness = 0.88
            material.textureCoordinateTransform = .init(scale: [3, 3])
        case "clay":
            material.baseColor = .init(tint: UIColor(white: 0.61, alpha: 1))
            material.metallic = 0.0
            material.roughness = 0.73
        default: break
        }
        return material
    }

    /// Each surface has its own response to a moving softbox. Microgeometry is encoded
    /// in normals and filtered by RealityKit; no highlight is baked into the color.
    private func applySculptedSurface(_ role: String, to material: inout PhysicallyBasedMaterial,
                                     settings: ElementStudioSettings) -> Bool {
        let detail = min(8, max(1, Int((settings.grain * 8).rounded())))
        let coat = Float(settings.clearcoat)
        switch role {
        case "satin":
            material.baseColor = .init(tint: UIColor(red: 0.65, green: 0.68, blue: 0.70, alpha: 1))
            material.metallic = 1.0
            let roughness = Float(settings.roughness) + 0.025
            material.roughness = .init(scale: roughness, texture: surfaces["roughness"].map { .init($0) })
            material.anisotropyLevel = .init(floatLiteral: Float(settings.grain) * 0.55)
            if settings.grain > 0.01, let texture = surfaces["brush-\(detail)"] {
                material.normal = .init(texture: .init(texture))
            }
            material.textureCoordinateTransform = .init(scale: [2, 2])
        case "polished":
            material.roughness = .init(floatLiteral: max(0.095, Float(settings.roughness) * 0.55))
            material.clearcoat = 0.25
            material.clearcoatRoughness = 0.09
        case "ceramic":
            material.metallic = 0.0
            material.roughness = 0.34
            material.clearcoat = .init(floatLiteral: 0.18 + coat * 0.35)
            material.clearcoatRoughness = 0.19
            if settings.grain > 0.01, let texture = surfaces["glaze-\(detail)"] {
                material.normal = .init(texture: .init(texture))
            }
        case "enamel", "dial", "porcelain":
            material.metallic = .init(floatLiteral: role == "dial" ? 0.20 : 0.0)
            material.clearcoat = .init(floatLiteral: role == "porcelain" ? 0.35 : coat)
            material.clearcoatRoughness = .init(floatLiteral: 0.05 + (1 - coat) * 0.14)
            material.roughness = .init(floatLiteral: role == "porcelain" ? 0.28 : 0.20 + (1 - coat) * 0.11)
            if role == "dial", let texture = surfaces["dial"] {
                material.normal = .init(texture: .init(texture))
            } else if settings.grain > 0.01, let texture = surfaces["glaze-\(detail)"] {
                material.normal = .init(texture: .init(texture))
                material.textureCoordinateTransform = .init(scale: [2, 2])
            }
        default: return false
        }
        return true
    }

    /// Deterministic microscopic normal variation; the surface never gets a moving noise overlay.
    private static func grainImage() -> CGImage {
        let size = 512
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        var seed: UInt32 = 127
        for y in 0..<size {
            for x in 0..<size {
                seed = 1664525 &* seed &+ 1013904223
                let offset = (y * size + x) * 4
                pixels[offset] = UInt8(clamping: 128 + Int(seed >> 28) - 7)
                pixels[offset + 1] = UInt8(clamping: 128 + Int(sin(Double(y) * 2.39) * 8))
                pixels[offset + 2] = 254
            }
        }
        return CGImage(width: size, height: size, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: CGDataProvider(data: Data(pixels) as CFData)!, decode: nil,
            shouldInterpolate: true, intent: .defaultIntent)!
    }

    /// A linear HDR studio panorama: a broad softbox, cool fill, narrow rim and quiet lower bounce.
    /// The source is computed once. Rotating its receiving entity moves the reflections coherently.
    nonisolated static func environmentImage() throws -> CGImage {
        let width = 1024, height = 512
        guard let url = Bundle.main.url(forResource: "ElementStudio-environment", withExtension: "bin") else { throw CocoaError(.fileNoSuchFile) }
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        guard data.count == width * height * 16,
              let provider = CGDataProvider(data: data as CFData),
              let image = CGImage(width: width, height: height, bitsPerComponent: 32, bitsPerPixel: 128,
                bytesPerRow: width * 16, space: CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!,
                bitmapInfo: [.floatComponents, .byteOrder32Little, CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)],
                provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return image
    }
}

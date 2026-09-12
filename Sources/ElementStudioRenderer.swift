import SwiftUI
import RealityKit
import MetalKit
@preconcurrency import QuartzCore
import Observation
import CoreMotion

/// Native RealityKit rendering into a Metal view. The view stops drawing when a gesture or
/// finite animation settles; no AR session, web runtime, or perpetual display link is involved.
@MainActor @Observable
final class ElementStudioRenderer {
    private(set) var focusedID: String?
    private(set) var showsMesh = false
    private(set) var comparingOriginal = false
    @ObservationIgnored var editingUndoManager: UndoManager?
    @ObservationIgnored private var comparisonSettings: ElementStudioSettings?
    var originalColors: [UIColor] {
        guard let assembly = active.first(where: { $0.objectID == focusedID }) ?? active.first else { return [.white] }
        let colored = assembly.asset.batches.filter { ["enamel", "dial", "ceramic", "porcelain"].contains($0.role) }
        var colors: [[Float]] = []
        for batch in colored where !colors.contains(batch.color) { colors.append(batch.color) }
        return colors.prefix(4).map { UIColor(red: CGFloat($0[0]), green: CGFloat($0[1]), blue: CGFloat($0[2]), alpha: 1) }
    }

    func compareOriginal(_ enabled: Bool) {
        guard enabled != comparingOriginal else { return }
        if enabled {
            guard focusedID != nil else { return }
            setMeshInspection(false)
            comparisonSettings = settings
            comparingOriginal = true
            apply(settings.originalAppearance(), forceMaterials: true, preservePose: true)
        } else {
            comparingOriginal = false
            if let saved = comparisonSettings {
                comparisonSettings = nil
                apply(saved, forceMaterials: true, preservePose: true)
            }
        }
    }
    @ObservationIgnored var onSelect: ((String) -> Void)?
    @ObservationIgnored private var flight: Flight?
    @ObservationIgnored private var focusBlend: Float = 0
    @ObservationIgnored private var cameraPan = SIMD2<Float>.zero
    @ObservationIgnored private var savedOverview: (Float, SIMD2<Float>) = (1, .zero)
    @ObservationIgnored private var pinchCamera = SIMD3<Float>.zero
    @ObservationIgnored private var panCamera = SIMD2<Float>.zero
    @ObservationIgnored private var pinchPoint = CGPoint.zero
    @ObservationIgnored private var controlInset: CGFloat = 64
    @ObservationIgnored private var visibleIDs: Set<String>?
    private struct ObjectPresentation {
        var opacity: Float = 1
        var thickness: Float = 1
        var separation: Float = 0
    }
    private struct Flight {
        var path: StudioCameraTransition
        let start: Double
        let duration: TimeInterval
        let fromBlend: Float
        let toBlend: Float
        let object: String?
        let appearances: [String: ObjectPresentation]
    }
    @ObservationIgnored private var presentations: [String: ObjectPresentation] = [:]
    var isOverview: Bool { active.count > 1 && focusedID == nil }
    private var darkAppearance = false
    private var tilt = SIMD2<Float>.zero
    private let reporting: Bool
    init(reporting: Bool = true) { self.reporting = reporting }
    private(set) var loading = true
    private(set) var error: String?
    private(set) var description = "A fitted titanium case, recessed enamel, and a precisely fluted crown."
    private(set) var frameCount = 0
    private(set) var hasPresentedFrame = false
    @ObservationIgnored private var warmupFrames = 8
    @ObservationIgnored weak var view: ElementStudioMetalView?
    @ObservationIgnored private var renderer: RealityRenderer?
    @ObservationIgnored private let camera = PerspectiveCamera()
    @ObservationIgnored private let light = Entity()
    @ObservationIgnored private let key = DirectionalLight()
    @ObservationIgnored private let fill = DirectionalLight()
    @ObservationIgnored private let materials = ElementStudioMaterials()
    @ObservationIgnored private var cache: [String: Assembly] = [:]
    @ObservationIgnored private var active: [Assembly] = []
    @ObservationIgnored private var objectAppearances: [String: ElementStudioSettings] = [:]
    @ObservationIgnored private var settings = ElementStudioSettings()
    @ObservationIgnored private var outputSize: CGSize?
    @ObservationIgnored private var loadIdentity = UUID()
    @ObservationIgnored private var lastFrame: CFTimeInterval = 0
    @ObservationIgnored private var animation: Turn?
    @ObservationIgnored private var yaw: Float = -0.16
    @ObservationIgnored private var pitch: Float = 0.055
    @ObservationIgnored private var zoom: Float = 1
    @ObservationIgnored private var origin = SIMD2<Float>.zero
    @ObservationIgnored private var pinchOrigin: Float = 1
    @ObservationIgnored private var isActive = true
    @ObservationIgnored private var reportedFrame = false
    @ObservationIgnored private(set) var loadStage = "starting"

    struct Assembly {
        let root: Entity
        let asset: ElementStudioAsset
        let models: [(ModelEntity, ElementStudioAsset.Batch)]
        var objectID: String { ElementStudioSettings.choices.first { asset.id == $0.id || asset.id.hasPrefix($0.id + "-") }?.id ?? asset.id }
    }
    private struct Turn {
        let start: CFTimeInterval
        let from: SIMD2<Float>
        let to: SIMD2<Float>
        let duration: Double
        let full: Bool
    }

    func load(_ newSettings: ElementStudioSettings) async {
        compareOriginal(false)
        setMeshInspection(false)
        let token = UUID()
        loadIdentity = token
        loading = true; error = nil; settings = newSettings; reportedFrame = false
        hasPresentedFrame = false; warmupFrames = 8
        focusedID = nil; flight = nil; focusBlend = 0; cameraPan = .zero; presentations = [:]
        let assetIDs = newSettings.assetIDs
        report("loading", stage: "starting")
        do {
            try Task.checkCancellation()
            if renderer == nil {
                report("loading", stage: "renderer")
                let nativeRenderer = try RealityRenderer()
                nativeRenderer.cameraSettings.isToneMappingEnabled = true
                nativeRenderer.cameraSettings.antialiasing = .multisample4X
                camera.camera.fieldOfViewInDegrees = 34
                camera.camera.near = 0.01; camera.camera.far = 50
                nativeRenderer.entities.append(camera)
                nativeRenderer.activeCamera = camera
                report("loading", stage: "environment-image")
                let panorama = try await Task.detached(priority: .userInitiated) { try ElementStudioMaterials.environmentImage() }.value
                try Task.checkCancellation()
                report("loading", stage: "environment-resource")
                let environment = try await EnvironmentResource(equirectangular: panorama)
                try Task.checkCancellation()
                guard token == loadIdentity else { return }
                var component = ImageBasedLightComponent(source: .single(environment))
                component.inheritsRotation = true
                light.components.set(component)
                nativeRenderer.entities.append(light)
                key.light.color = UIColor(red: 1, green: 0.965, blue: 0.9, alpha: 1)
                key.light.intensity = 1100
                let reviewBias = ProcessInfo.processInfo.environment["DAYWAKE_ELEMENT_SHADOW_BIAS"].flatMap(Float.init)
                key.shadow = .init(shadowProjection: .fixed(zNear: 0.1, zFar: 14, orthographicScale: 5),
                                   depthBias: min(4, max(0, reviewBias ?? 1)))
                nativeRenderer.entities.append(key)
                fill.light.color = UIColor(red: 0.78, green: 0.88, blue: 1, alpha: 1)
                fill.look(at: .zero, from: [3, 1, 5], relativeTo: nil)
                nativeRenderer.entities.append(fill)
                renderer = nativeRenderer
            }
            report("loading", stage: "materials")
            try await materials.prepare()
            try Task.checkCancellation()
            for id in assetIDs where cache[id] == nil {
                report("loading", stage: "asset-\(id)")
                let loaded = try await Task.detached(priority: .userInitiated) { try ElementStudioAsset.read(id: id) }.value
                try Task.checkCancellation()
                let assembly = try await makeAssembly(loaded)
                guard token == loadIdentity else { return }
                cache[id] = assembly
            }
            guard token == loadIdentity else { return }
            for assembly in active { renderer?.entities.remove(assembly.root) }
            active = assetIDs.compactMap { cache[$0] }
            for assembly in active { renderer?.entities.append(assembly.root) }
            description = active.count == 1 ? active[0].asset.description : "One shared light reveals the construction across the collection."
            loading = false
            animation = nil; yaw = settings.chosenEdition == .earlier ? -0.16 : -0.28
            pitch = settings.chosenEdition == .earlier ? 0.055 : 0.10; zoom = 1
            if let pose = settings.camera { yaw = Float(pose[0]); pitch = Float(pose[1]); zoom = Float(pose[2]) }
            let previewPose = ProcessInfo.processInfo.environment["DAYWAKE_ELEMENT_POSE"]
            if previewPose == "back" { yaw = .pi }
            if previewPose == "side" { yaw = .pi / 2 }
            if newSettings.explode > 0 { yaw = -0.62; pitch = 0.12 }
            report("prepared", stage: "ready")
            apply(settings, forceMaterials: true)
            if previewPose == "turn" { pose(0, full: true) }
        } catch is CancellationError {
            // A superseded task must not overwrite its replacement. If this task still
            // owns loading, make interruption recoverable instead of keeping the spinner.
            guard token == loadIdentity else { return }
            loading = false
            error = "Preparation was interrupted. Please try again."
            report("cancelled")
        } catch {
            guard token == loadIdentity else { return }
            loading = false
            self.error = "The object could not load. \(error.localizedDescription)"
            report("error")
        }
    }

    private func makeAssembly(_ loaded: ElementStudioAsset.Loaded) async throws -> Assembly {
        let root = Entity()
        root.name = loaded.asset.id
        var models: [(ModelEntity, ElementStudioAsset.Batch)] = []
        for batch in loaded.asset.batches {
            report("loading", stage: "mesh-\(loaded.asset.id)-\(batch.name)")
            try Task.checkCancellation()
            let positions = try ElementStudioAsset.floats(batch.positions, in: loaded.data)
            let normals = try ElementStudioAsset.floats(batch.normals, in: loaded.data)
            let uv = try ElementStudioAsset.floats(batch.uv, in: loaded.data)
            let indices = try ElementStudioAsset.indices(batch.indices, in: loaded.data)
            guard positions.count % 3 == 0, normals.count == positions.count,
                  uv.count / 2 == positions.count / 3, indices.allSatisfy({ $0 < positions.count / 3 }),
                  positions.allSatisfy(\.isFinite), normals.allSatisfy(\.isFinite) else { throw CocoaError(.fileReadCorruptFile) }
            var descriptor = MeshDescriptor(name: batch.name)
            descriptor.positions = .init(stride(from: 0, to: positions.count, by: 3).map { SIMD3(positions[$0], positions[$0 + 1], positions[$0 + 2]) })
            descriptor.normals = .init(stride(from: 0, to: normals.count, by: 3).map { SIMD3(normals[$0], normals[$0 + 1], normals[$0 + 2]) })
            descriptor.textureCoordinates = .init(stride(from: 0, to: uv.count, by: 2).map { SIMD2(uv[$0], uv[$0 + 1]) })
            descriptor.primitives = .triangles(indices)
            let mesh = try await MeshResource(from: [descriptor])
            let model = ModelEntity(mesh: mesh, materials: [makeMaterial(batch)])
            model.name = batch.name
            model.components.set(ImageBasedLightReceiverComponent(imageBasedLight: light))
            model.components.set(DynamicLightShadowComponent(castsShadow: batch.role != "glass" && batch.role != "photo"))
            root.addChild(model)
            models.append((model, batch))
        }
        return Assembly(root: root, asset: loaded.asset, models: models)
    }

    func apply(_ newSettings: ElementStudioSettings, forceMaterials: Bool = false, preservePose: Bool = false) {
        let previous = settings
        settings = newSettings
        if !preservePose, previous.camera != settings.camera {
            let pose = settings.camera ?? [-0.28,0.10,1]
            animation = nil; yaw = Float(pose[0]); pitch = Float(pose[1]); zoom = Float(pose[2])
        }
        let changedMaterial = forceMaterials || previous.surfaceRevision != settings.surfaceRevision || previous.chosenEdition != settings.chosenEdition || previous.finish != settings.finish || previous.roughness != settings.roughness ||
            previous.grain != settings.grain || previous.clearcoat != settings.clearcoat || previous.glass != settings.glass || previous.tintRGB != settings.tintRGB
        if changedMaterial {
            for assembly in active where focusedID == nil || assembly.objectID == focusedID {
                for (model, batch) in assembly.models {
                    model.model?.materials = [makeMaterial(batch, inspectingMesh: showsMesh && assembly.objectID == focusedID)]
                    model.components.set(DynamicLightShadowComponent(castsShadow:
                        settings.finish != .crafted || (batch.role != "glass" && batch.role != "photo")))
                }
            }
        }
        if !comparingOriginal {
            for assembly in active where assembly.objectID == focusedID || (focusedID == nil && changedMaterial) {
                var appearance = settings
                appearance.selected = assembly.objectID; appearance.arrangement = .object; appearance.camera = nil; appearance.wireframe = false
                objectAppearances[assembly.objectID] = appearance
            }
        }
        if !preservePose, previous.selected == settings.selected, previous.explode == 0, settings.explode > 0 { animation = nil; yaw = -0.62; pitch = 0.12 }
        if settings.reduceMotion { flight = nil; focusBlend = focusedID == nil ? 0 : 1 }
        if settings.reduceMotion, let turn = animation {
            yaw = turn.to.x; pitch = turn.to.y; animation = nil
        }
        var ibl = light.components[ImageBasedLightComponent.self]
        ibl?.intensityExponent = Float(log2(settings.brightness)) + 0.35
        if let ibl { light.components.set(ibl) }
        light.orientation = simd_quatf(angle: Float(settings.light + 35) * .pi / 180, axis: [0, 1, 0])
        let angle = Float(settings.light) * .pi / 180
        key.look(at: .zero, from: [sin(angle) * 4, 4, cos(angle) * 4], relativeTo: nil)
        key.light.intensity = 4200 * Float(settings.brightness)
        fill.light.intensity = 1300 * Float(settings.brightness)
        let background = darkAppearance ? UIColor.black : UIColor(white: 0.97, alpha: 1)
        renderer?.cameraSettings.colorBackground = .color(background.cgColor)
        updateTransforms()
        invalidate()
    }

    func appearance(for object: String) -> ElementStudioSettings {
        var value = objectAppearances[object] ?? settings
        value.selected = object; value.arrangement = .object; value.camera = nil; value.wireframe = false
        return value
    }

    private func makeMaterial(_ batch: ElementStudioAsset.Batch, inspectingMesh: Bool = false) -> any RealityKit.Material {
        // Inspection is a transient view mode, never inherited from a saved workspace.
        var materialSettings = settings
        materialSettings.wireframe = inspectingMesh
        var result = materials.make(batch, settings: materialSettings)
        if settings.finish == .crafted, let rgb = settings.tintRGB, ["enamel", "dial", "ceramic", "porcelain"].contains(batch.role), var pbr = result as? PhysicallyBasedMaterial {
            pbr.baseColor = .init(tint: UIColor(red: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1))
            result = pbr
        }
        return result
    }

    /// A single shared thumbnail renderer uses this offscreen path serially. The
    /// resulting image is cached in memory; neither history nor photos are written out.
    func snapshot(size: CGSize = CGSize(width: 360, height: 300), transparent: Bool = false) async throws -> UIImage {
        guard !loading, let renderer, let device = MTLCreateSystemDefaultDevice() else { throw CocoaError(.coderInvalidValue) }
        outputSize = size; updateTransforms()
        if transparent { renderer.cameraSettings.colorBackground = .color(UIColor.clear.cgColor) }
        defer { outputSize = nil; apply(settings) }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb,
            width: Int(size.width), height: Int(size.height), mipmapped: false)
        descriptor.storageMode = .shared
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        guard let texture = device.makeTexture(descriptor: descriptor) else { throw CocoaError(.coderInvalidValue) }
        let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: texture))
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try renderer.updateAndRender(deltaTime: 1.0 / 60, cameraOutput: output, onComplete: { _ in continuation.resume() })
            } catch { continuation.resume(throwing: error) }
        }
        let width = texture.width, height = texture.height, rowBytes = texture.width * 4
        var bytes = [UInt8](repeating: 0, count: rowBytes * height)
        texture.getBytes(&bytes, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: rowBytes, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: [.byteOrder32Little, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)],
                provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { throw CocoaError(.coderInvalidValue) }
        return UIImage(cgImage: image)
    }

    static let background = UIColor { $0.userInterfaceStyle == .dark ? .black : UIColor(white: 0.97, alpha: 1) }

    func setAppearance(dark: Bool) { darkAppearance = dark; apply(settings); view?.backgroundColor = dark ? .black : UIColor(white: 0.97, alpha: 1) }
    func setTilt(x: Double, y: Double) {
        tilt = settings.reduceMotion ? .zero : SIMD2(Float(x), Float(y))
        updateTransforms(); invalidate()
    }

    private func updateTransforms() {
        let visible = active.filter { visibleIDs == nil || visibleIDs!.contains($0.objectID) }
        for assembly in active {
            let index = visible.firstIndex { $0.objectID == assembly.objectID } ?? 0
            let position = active.count == 1 ? SIMD3<Float>.zero : StudioCameraGeometry.position(index: index, count: visible.count)
            if assembly.root.position != position { assembly.root.position = position }
        }
        let size = outputSize ?? view?.bounds.size ?? CGSize(width: 400, height: 320)
        guard size.width > 0, size.height > 0 else { return }
        let target = cameraTarget(size: size, visibleCount: visible.count, clampPan: outputSize == nil)
        let now = CACurrentMediaTime()
        var progress: Float = 1
        var transition = flight
        if var moving = transition, outputSize == nil {
            if simd_distance(moving.path.to, target) > 0.00001 {
                moving.path = moving.path.retarget(to: target, at: now)
                flight = moving; transition = moving
            }
            camera.position = moving.path.sample(at: now).position
            progress = min(1, max(0, Float(Spring(settlingDuration: moving.duration, dampingRatio: 1).value(target: 1.0, time: now - moving.start))))
            focusBlend = moving.fromBlend + (moving.toBlend - moving.fromBlend) * progress
            if now - moving.path.start >= moving.path.duration {
                camera.position = target; focusBlend = moving.toBlend
                flight = nil; transition = nil; progress = 1
            }
        } else { camera.position = target }

        for assembly in active {
            let id = assembly.objectID
            let included = visibleIDs == nil || visibleIDs!.contains(id) || id == focusedID
            let focused = id == focusedID || active.count == 1
            let final = ObjectPresentation(opacity: included ? (focusedID == nil || focused ? 1 : 0) : 0,
                                           thickness: focused ? Float(settings.thickness) : 1,
                                           separation: focused ? Float(settings.explode) : 0)
            var presentation = final
            if outputSize == nil, let initial = transition?.appearances[id] {
                // Clear the surrounding collection early, before its magnified shapes
                // can distract from the selected object's continuous path.
                let fadingOut = final.opacity < initial.opacity
                let fade = fadingOut ? min(1, progress * 1.6) : progress
                let opacityProgress = fadingOut ? fade * fade * (3 - 2 * fade) : fade
                presentation.opacity = initial.opacity + (final.opacity - initial.opacity) * opacityProgress
                presentation.thickness = initial.thickness + (final.thickness - initial.thickness) * progress
                presentation.separation = initial.separation + (final.separation - initial.separation) * progress
            }
            if outputSize == nil { presentations[id] = presentation }
            if assembly.root.components[OpacityComponent.self]?.opacity != presentation.opacity {
                assembly.root.components.set(OpacityComponent(opacity: presentation.opacity))
            }
            let scale: Float = active.count == 1 ? 1 : 0.40
            let dimensions = SIMD3<Float>(scale, scale, scale * presentation.thickness)
            if assembly.root.scale != dimensions { assembly.root.scale = dimensions }
            assembly.root.orientation = simd_quatf(angle: yaw + tilt.x, axis: [0, 1, 0]) * simd_quatf(angle: pitch + tilt.y, axis: [1, 0, 0])
            for (model, batch) in assembly.models {
                let offset = SIMD3(batch.explode[0], batch.explode[1], batch.explode[2]) * presentation.separation
                if model.position != offset { model.position = offset }
            }
        }
        view?.updateObjectAccessibility()
    }

    private func cameraTarget(size: CGSize, visibleCount: Int, clampPan: Bool) -> SIMD3<Float> {
        let focus = active.first { $0.objectID == focusedID }
        let inset = focus != nil && outputSize == nil ? min(controlInset, size.height * 0.55) : 0
        let visibleHeight = max(1, size.height - inset)
        let aspect = Float(size.width / visibleHeight)
        let bounds = focus != nil ? SIMD2<Float>(1.10, 1.22) : active.count == 1 ? SIMD2<Float>(2.75, 2.95) : StudioCameraGeometry.bounds(count: visibleCount)
        let separation = focus != nil || active.count == 1 ? Float(settings.explode) : 0
        let fit = max(bounds.y, bounds.x / max(0.3, aspect)) * Float(size.height / visibleHeight) * (1 + separation * 0.15)
        let center = focus?.root.position ?? .zero
        let distance = fit / (2 * tan(17 * .pi / 180)) / zoom
        let lift = Float(inset / size.height) * distance * tan(17 * .pi / 180)
        if clampPan {
            let visibleSpan = SIMD2<Float>(distance * 2 * tan(17 * .pi / 180) * Float(size.width / size.height), distance * 2 * tan(17 * .pi / 180) * Float(visibleHeight / size.height))
            cameraPan = StudioCameraGeometry.clamp(pan: cameraPan, content: bounds, visible: visibleSpan)
        }
        return [center.x + cameraPan.x, center.y + cameraPan.y - lift, distance]
    }

    private func beginFlight(object: String?, toBlend: Float, duration: TimeInterval) {
        guard !settings.reduceMotion else { flight = nil; focusBlend = toBlend; return }
        let now = CACurrentMediaTime()
        let current = flight?.path.sample(at: now) ?? .init(position: camera.position, velocity: .zero)
        let size = view?.bounds.size ?? CGSize(width: 400, height: 320)
        guard size.width > 0, size.height > 0 else { return }
        let count = active.filter { visibleIDs == nil || visibleIDs!.contains($0.objectID) }.count
        let target = cameraTarget(size: size, visibleCount: count, clampPan: true)
        let anchor = active.first { $0.objectID == object }?.root.position ?? .zero
        let path = StudioCameraTransition(from: current.position, to: target, anchor: anchor,
                                          initialVelocity: current.velocity, start: now, duration: duration)
        flight = Flight(path: path, start: now, duration: duration, fromBlend: focusBlend, toBlend: toBlend, object: object, appearances: presentations)
    }

    func setControlInset(_ height: CGFloat) {
        guard abs(controlInset - height) > 1 else { return }
        controlInset = height
        if focusedID != nil { beginFlight(object: focusedID, toBlend: 1, duration: 0.36) }
        updateTransforms(); invalidate()
    }

    func setMeshInspection(_ enabled: Bool) {
        let enabled = enabled && focusedID != nil
        guard showsMesh != enabled else { return }
        showsMesh = enabled
        // Change only rasterization on the existing materials. Rebuilding from the
        // current object's settings would overwrite other cached objects' finishes.
        for assembly in active {
            let mode: MaterialParameterTypes.TriangleFillMode = enabled && assembly.objectID == focusedID ? .lines : .fill
            for (model, _) in assembly.models {
                guard var component = model.model else { continue }
                var changed = false
                component.materials = component.materials.map { original in
                    if var material = original as? PhysicallyBasedMaterial, material.triangleFillMode != mode {
                        material.triangleFillMode = mode; changed = true; return material
                    }
                    if var material = original as? CustomMaterial, material.triangleFillMode != mode {
                        material.triangleFillMode = mode; changed = true; return material
                    }
                    return original
                }
                if changed { model.model = component }
            }
        }
        invalidate()
    }

    func focus(on id: String?, preservePose: Bool = false) {
        compareOriginal(false)
        if id != nil { view?.becomeFirstResponder() }
        guard !loading else { return }
        setMeshInspection(false)
        let previous = focusedID
        if previous == nil, flight == nil { savedOverview = (zoom, cameraPan) }
        focusedID = id
        if id == nil { zoom = savedOverview.0; cameraPan = savedOverview.1 }
        else { if !preservePose { zoom = 1 }; cameraPan = .zero }
        animation = nil
        beginFlight(object: id ?? previous, toBlend: id == nil ? 0 : 1, duration: id == nil ? 0.46 : 0.54)
        updateTransforms(); invalidate()
    }

    func resetOverview() { zoom = 1; cameraPan = .zero; pose(-0.28) }
    func resetObject() {
        setMeshInspection(false)
        zoom = 1; cameraPan = .zero
        beginFlight(object: focusedID, toBlend: 1, duration: 0.40)
        pose(-0.28)
        updateTransforms(); invalidate()
    }
    func showObjects(_ ids: [String]?) { visibleIDs = ids.map(Set.init); updateTransforms(); invalidate() }
    func objectTargets(duringTransition: Bool = false) -> [(String, CGRect)] {
        guard isOverview, duringTransition || flight == nil, !loading, hasPresentedFrame, let view else { return [] }
        let focal = Float(view.bounds.height) / (2 * tan(17 * .pi / 180))
        return active.filter { visibleIDs == nil || visibleIDs!.contains($0.objectID) }.map { assembly in
            let point = assembly.root.position, distance = max(0.1, camera.position.z - point.z)
            let x = Float(view.bounds.midX) + (point.x-camera.position.x) * focal/distance
            let y = Float(view.bounds.midY) - (point.y-camera.position.y) * focal/distance
            let radius = max(22, 0.48 * focal/distance)
            return (assembly.objectID, CGRect(x: CGFloat(x-radius), y: CGFloat(y-radius), width: CGFloat(radius*2), height: CGFloat(radius*2)))
        }
    }
    func select(at point: CGPoint) {
        guard let target = objectTargets(duringTransition: true).filter({ $0.1.contains(point) }).min(by: {
            hypot($0.1.midX-point.x,$0.1.midY-point.y) < hypot($1.1.midX-point.x,$1.1.midY-point.y)
        }) else { return }
        onSelect?(target.0)
    }
    func moveCamera(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began { panCamera = cameraPan }
        let translation = gesture.translation(in: view)
        let factor = camera.position.z * 2 * tan(Float(17) * .pi/180) / Float(max(1, view?.bounds.height ?? 1))
        cameraPan = panCamera + SIMD2(-Float(translation.x)*factor, Float(translation.y)*factor)
                updateTransforms(); invalidate()
    }

    func pose(_ angle: Float, full: Bool = false) {
        if settings.reduceMotion { yaw = angle; pitch = 0.055; animation = nil; updateTransforms(); invalidate(); return }
        let destination = full ? yaw + 2 * .pi : angle
        animation = Turn(start: CACurrentMediaTime(), from: [yaw, pitch], to: [destination, 0.055], duration: full ? 2.4 : 0.62, full: full)
        invalidate()
    }
    var cameraState: [Double] { [Double(atan2(sin(yaw),cos(yaw))), Double(pitch), Double(zoom)] }
    func rotate(by angle: Float) { pose(yaw + angle) }
    func magnify(by factor: Float) { zoom = min(isOverview ? 4 : 2.5, max(1, zoom * factor)); updateTransforms(); invalidate() }

    func pan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            animation = nil; origin = [yaw, pitch]
        case .changed:
            let offset = gesture.translation(in: view)
            let width = Float(max(1, view?.bounds.width ?? 1))
            yaw = origin.x + Float(offset.x) / width * .pi * 1.5
            pitch = min(0.65, max(-0.65, origin.y + Float(offset.y) / width * 1.5))
            updateTransforms(); invalidate()
        case .ended, .cancelled: updateTransforms(); invalidate()
        default: break
        }
    }

    func pinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.state == .began || gesture.state == .changed else { invalidate(); return }
        if gesture.state == .began {
            pinchOrigin = zoom; pinchCamera = camera.position; pinchPoint = gesture.location(in: view)
        }
        zoom = min(isOverview ? 4 : 2.5, max(1, pinchOrigin * Float(gesture.scale)))
        let distance = pinchCamera.z * pinchOrigin / zoom
        let focal = Float(max(1, view?.bounds.height ?? 1)) / (2 * tan(Float(17) * .pi / 180))
        let center = active.first { $0.objectID == focusedID }?.root.position ?? .zero
        let current = gesture.location(in: view)
        let midpoint = CGPoint(x: view?.bounds.midX ?? 0, y: view?.bounds.midY ?? 0)
        let lift = focusedID == nil ? 0 : Float(min(controlInset, (view?.bounds.height ?? 1) * 0.55) / 2) * distance / focal
        cameraPan.x = pinchCamera.x + Float(pinchPoint.x - midpoint.x) * pinchCamera.z / focal - Float(current.x - midpoint.x) * distance / focal - center.x
        cameraPan.y = pinchCamera.y - Float(pinchPoint.y - midpoint.y) * pinchCamera.z / focal + Float(current.y - midpoint.y) * distance / focal - center.y + lift
        updateTransforms(); invalidate()
    }

    func setActive(_ active: Bool) {
        if !active { compareOriginal(false) }
        isActive = active
        if !active { animation = nil; view?.isPaused = true }
        else { invalidate() }
    }

    func resize() { updateTransforms(); invalidate() }
    func invalidate() {
        guard isActive, !loading else { return }
        let settled = animation == nil && flight == nil && warmupFrames == 0
        view?.enableSetNeedsDisplay = settled
        view?.isPaused = settled
        if settled { view?.setNeedsDisplay() }
    }

    func draw(in view: MTKView) {
        guard isActive, !loading, let renderer, let drawable = view.currentDrawable else { return }
        view.accessibilityValue = "Rotation \(Int(cameraState[0] * 180 / .pi)) degrees, zoom \(String(format: "%.2f", zoom))" + (comparingOriginal ? ", Original" : ", Edited")
        let now = CACurrentMediaTime()
        var finishedTurn = false
        if flight != nil {
            updateTransforms()
            finishedTurn = flight == nil
        }
        if let turn = animation {
            let t = min(1, max(0, (now - turn.start) / turn.duration))
            let p = Float(t * t * (3 - 2 * t))
            let angle = turn.from + (turn.to - turn.from) * p
            yaw = angle.x; pitch = angle.y + (turn.full ? sin(Float(t) * .pi) * 0.09 : 0)
            if t >= 1 { animation = nil; yaw = turn.to.x; pitch = turn.to.y; finishedTurn = true }
            updateTransforms()
        }
        do {
            let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: drawable.texture))
            warmupFrames = max(0, warmupFrames - 1)
            let shouldReport = (!reportedFrame && warmupFrames == 0) || finishedTurn
            let identity = loadIdentity
            if shouldReport { reportedFrame = true }
            try renderer.updateAndRender(deltaTime: min(1.0 / 20.0, max(1.0 / 120, now - lastFrame)), cameraOutput: output,
                whenScheduled: { _ in drawable.present() },
                onComplete: { [weak self] _ in
                    if shouldReport { Task { @MainActor in
                        guard let self, self.loadIdentity == identity else { return }
                        self.hasPresentedFrame = true
                        self.view?.updateObjectAccessibility()
                        self.report("rendered")
                    } }
                })
            lastFrame = now; frameCount += 1
            if animation == nil && flight == nil && warmupFrames == 0 { view.isPaused = true; view.enableSetNeedsDisplay = true }
        } catch {
            self.error = "The native render was interrupted. \(error.localizedDescription)"
            report("error")
            view.isPaused = true
        }
    }

    /// Small debug-only readiness record lets simulator captures wait for the actual GPU frame.
    /// It contains synthetic fixture IDs and renderer state, never HealthKit values or photos.
    private func report(_ phase: String, stage: String? = nil) {
        if let stage { loadStage = stage }
        guard reporting else { return }
        guard ProcessInfo.processInfo.environment["STUDIO_REVIEW"] == "1" else { return }
        guard let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let status: [String: Any] = ["phase": phase, "pid": ProcessInfo.processInfo.processIdentifier,
                                   "objects": settings.objectIDs, "frames": frameCount, "error": error ?? "",
                                   "stage": loadStage, "active": isActive, "viewAttached": view != nil,
                                   "assets": settings.assetIDs, "yaw": yaw, "pitch": pitch, "turning": animation != nil,
                                   "focused": focusedID ?? "", "flying": flight != nil, "zoom": zoom,
                                   "updatedAt": Date().timeIntervalSince1970]
        if let data = try? JSONSerialization.data(withJSONObject: status, options: .sortedKeys) {
            try? data.write(to: directory.appendingPathComponent("ElementStudio-status.json"), options: .atomic)
        }
    }

    func attach(_ newView: ElementStudioMetalView) {
        view = newView
        resize()
    }

    func detach(_ oldView: ElementStudioMetalView) {
        guard view === oldView else { return }
        oldView.isPaused = true
        // Replacing a drawing surface must not invalidate the screen's in-flight load.
        animation = nil
        view = nil
    }
}

struct ElementStudioViewport: UIViewRepresentable {
    let renderer: ElementStudioRenderer
    var embedded = false
    func makeUIView(context: Context) -> ElementStudioMetalView {
        let view = ElementStudioMetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.delegate = view
        view.isPaused = true; view.enableSetNeedsDisplay = true
        view.framebufferOnly = false
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.preferredFramesPerSecond = 60
        view.backgroundColor = embedded ? .clear : ElementStudioRenderer.background
        view.isOpaque = !embedded
        if !embedded {
        let rotate = UIPanGestureRecognizer(target: view, action: #selector(view.panned(_:)))
        rotate.maximumNumberOfTouches = 1
        view.addGestureRecognizer(rotate)
        let move = UIPanGestureRecognizer(target: view, action: #selector(view.moved(_:)))
        move.minimumNumberOfTouches = 2; move.maximumNumberOfTouches = 2; move.delegate = view
        view.addGestureRecognizer(move)
        let tap = UITapGestureRecognizer(target: view, action: #selector(view.tapped(_:)))
        tap.require(toFail: rotate); view.addGestureRecognizer(tap)
        let pinch = UIPinchGestureRecognizer(target: view, action: #selector(view.pinched(_:))); pinch.delegate = view; view.addGestureRecognizer(pinch)
        }
        view.isUserInteractionEnabled = !embedded
        view.isAccessibilityElement = !embedded
        view.accessibilityLabel = "Three dimensional element"
        view.accessibilityHint = "Drag to rotate. Pinch to zoom. Use two fingers to move around the collection."
        view.accessibilityIdentifier = "element-studio-viewport"
        view.bind(to: renderer)
        return view
    }
    func updateUIView(_ view: ElementStudioMetalView, context: Context) {
        // A presentation may reuse its UIKit view while SwiftUI installs the persistent
        // @State model. Always reconnect the drawing surface to the current owner.
        view.bind(to: renderer)
    }
    static func dismantleUIView(_ view: ElementStudioMetalView, coordinator: ()) {
        view.studio?.detach(view)
    }
}

final class ElementStudioMetalView: MTKView, MTKViewDelegate, UIGestureRecognizerDelegate {
    weak var studio: ElementStudioRenderer?
    override var canBecomeFirstResponder: Bool { true }
    override var undoManager: UndoManager? { studio?.editingUndoManager ?? super.undoManager }
    private var pinchHandled = false
    private var objectElements: [String: StudioObjectAccessibility] = [:]
    private lazy var cameraActions = [
        UIAccessibilityCustomAction(name: "Rotate left") { [weak self] _ in self?.studio?.rotate(by: -.pi / 4); return true },
        UIAccessibilityCustomAction(name: "Rotate right") { [weak self] _ in self?.studio?.rotate(by: .pi / 4); return true },
        UIAccessibilityCustomAction(name: "Zoom in") { [weak self] _ in self?.studio?.magnify(by: 1.25); return true },
        UIAccessibilityCustomAction(name: "Zoom out") { [weak self] _ in self?.studio?.magnify(by: 0.8); return true }
    ]
    func bind(to renderer: ElementStudioRenderer) {
        if studio !== renderer {
            studio?.detach(self)
            studio = renderer
        }
        if renderer.view !== self { renderer.attach(self) }
    }
    func draw(in view: MTKView) { studio?.draw(in: view) }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { studio?.resize() }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    @objc func tapped(_ gesture: UITapGestureRecognizer) { studio?.select(at: gesture.location(in: self)) }
    @objc func moved(_ gesture: UIPanGestureRecognizer) {
        let pinching = (gestureRecognizers ?? []).contains { $0 is UIPinchGestureRecognizer && ($0.state == .began || $0.state == .changed) }
        if gesture.state == .began && !pinching { pinchHandled = false }
        guard !pinching && !pinchHandled else { return }
        studio?.moveCamera(gesture)
    }
    func updateObjectAccessibility() {
        guard let studio else { return }
        isAccessibilityElement = !studio.isOverview
        accessibilityCustomActions = cameraActions
        if studio.isOverview {
            accessibilityElements = studio.objectTargets().map { id, frame in
                let element = objectElements[id] ?? StudioObjectAccessibility(accessibilityContainer: self)
                objectElements[id] = element
                element.accessibilityLabel = ElementStudioSettings.choices.first { $0.id == id }?.name ?? id
                element.accessibilityIdentifier = "element-" + id
                element.accessibilityTraits = .button
                element.accessibilityCustomActions = cameraActions
                element.accessibilityFrameInContainerSpace = frame
                element.activate = { [weak studio] in studio?.onSelect?(id) }
                return element
            }
        } else { accessibilityElements = nil }
    }
    @objc func panned(_ gesture: UIPanGestureRecognizer) { studio?.pan(gesture) }
    @objc func pinched(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed { pinchHandled = true }
        studio?.pinch(gesture)
    }
}


@MainActor @Observable
final class StudioMotion {
    static let shared = StudioMotion()
    var x = 0.0
    var y = 0.0
    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var reference: (Double, Double)?
    func setEnabled(_ enabled: Bool) {
        guard enabled else {
            manager.stopDeviceMotionUpdates(); reference = nil; x = 0; y = 0; return
        }
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            let roll = motion.attitude.roll, pitch = motion.attitude.pitch
            Task { @MainActor [weak self] in
                guard let self, self.manager.isDeviceMotionActive else { return }
                if self.reference == nil { self.reference = (roll, pitch) }
                let reference = self.reference!
                let targetX = min(0.22, max(-0.22, atan2(sin(roll-reference.0), cos(roll-reference.0)) * 0.5))
                let targetY = min(0.18, max(-0.18, (pitch-reference.1) * 0.5))
                let nextX = self.x + (targetX-self.x)*0.16, nextY = self.y + (targetY-self.y)*0.16
                if abs(nextX-self.x) + abs(nextY-self.y) > 0.0006 { self.x = nextX; self.y = nextY }
            }
        }
    }
}

@MainActor final class StudioObjectAccessibility: UIAccessibilityElement {
    var activate: (() -> Void)?
    override func accessibilityActivate() -> Bool { activate?(); return true }
}

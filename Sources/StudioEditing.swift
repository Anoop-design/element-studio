import SwiftUI

nonisolated enum StudioParameter: String, CaseIterable, Identifiable {
    case finish, texture, light, brightness, depth, separation
    var id: String { rawValue }
    var title: String {
        switch self {
        case .finish: "Finish"
        case .texture: "Texture"
        case .light: "Light direction"
        case .brightness: "Brightness"
        case .depth: "Depth"
        case .separation: "Separate components"
        }
    }
    var keyPath: WritableKeyPath<ElementStudioSettings, Double> {
        switch self {
        case .finish: \.roughness
        case .texture: \.grain
        case .light: \.light
        case .brightness: \.brightness
        case .depth: \.thickness
        case .separation: \.explode
        }
    }
    var range: ClosedRange<Double> {
        switch self {
        case .finish: 0.12...0.65
        case .texture, .separation: 0...1
        case .light: -140...140
        case .brightness: 0.45...1.8
        case .depth: 0.5...1.8
        }
    }
    var original: Double { ElementStudioSettings()[keyPath: keyPath] }
    var ends: (String, String) {
        switch self {
        case .finish: ("Gloss", "Matte")
        case .texture: ("Smooth", "Textured")
        case .light: ("Left", "Right")
        case .brightness: ("Quiet", "Bright")
        case .depth: ("Slim", "Substantial")
        case .separation: ("Assembled", "Exploded")
        }
    }
    func display(_ value: Double) -> String {
        switch self {
        case .finish: value < 0.25 ? "Gloss" : value < 0.50 ? "Satin" : "Matte"
        case .texture, .separation: "\(Int((value * 100).rounded()))%"
        case .light: "\(Int(value.rounded()))°"
        case .brightness: value.formatted(.number.precision(.fractionLength(2)))
        case .depth: value.formatted(.number.precision(.fractionLength(2))) + "×"
        }
    }
    var entryUnit: String {
        switch self {
        case .texture, .separation: "percent"
        case .light: "degrees"
        case .depth: "times original depth"
        default: ""
        }
    }
    private var entryScale: Double { self == .texture || self == .separation ? 100 : 1 }
    func entryText(_ value: Double) -> String { (value * entryScale).formatted(.number.grouping(.never).precision(.fractionLength(0...2))) }
    func parse(_ text: String, locale: Locale = .current) -> Double? {
        let scanner = Scanner(string: text.trimmingCharacters(in: .whitespacesAndNewlines)); scanner.locale = locale
        guard let number = scanner.scanDouble(), scanner.isAtEnd, number.isFinite else { return nil }
        let value = number / entryScale
        guard range.contains(value) else { return nil }
        return value
    }
}

extension ElementStudioSettings {
    /// A reference appearance keeps the selected geometry and the current view.
    func originalAppearance(panel: String? = nil) -> Self {
        var result = self
        let original = Self()
        if panel == nil || panel == "Surface" {
            result.finish = original.finish; result.roughness = original.roughness
            result.grain = original.grain; result.clearcoat = original.clearcoat
            result.glass = original.glass; result.tintRGB = nil
        }
        if panel == nil || panel == "Light" { result.light = original.light; result.brightness = original.brightness }
        if panel == nil || panel == "Form" { result.thickness = original.thickness; result.explode = original.explode }
        result.wireframe = false
        return result
    }
    var editingState: Self {
        var value = self; value.camera = nil; value.wireframe = false; value.arrangement = .object
        return value
    }
}

@MainActor @Observable final class StudioEditHistory {
    @ObservationIgnored let manager = UndoManager()
    @ObservationIgnored var restore: ((ElementStudioSettings) -> Void)?
    private var revision = 0
    private var last: ElementStudioSettings?
    private var pending: (ElementStudioSettings, String)?
    init() { manager.groupsByEvent = false }
    var canUndo: Bool { _ = revision; return manager.canUndo }
    var canRedo: Bool { _ = revision; return manager.canRedo }
    var undoTitle: String { _ = revision; return manager.undoActionName.isEmpty ? "Undo" : "Undo " + manager.undoActionName }
    var redoTitle: String { _ = revision; return manager.redoActionName.isEmpty ? "Redo" : "Redo " + manager.redoActionName }
    func start(_ settings: ElementStudioSettings) {
        manager.removeAllActions(); pending = nil; last = settings.editingState; revision += 1
    }
    func begin(_ settings: ElementStudioSettings, name: String) {
        guard pending == nil else { return }
        pending = (settings.editingState, name)
    }
    func end(_ settings: ElementStudioSettings) {
        guard let (before, name) = pending else { return }
        pending = nil; let after = settings.editingState
        if before != after { register(before: before, after: after, name: name) }
        last = after
    }
    func observe(_ settings: ElementStudioSettings) {
        let next = settings.editingState
        guard let before = last else { last = next; return }
        guard next.selected == before.selected, next.assetIDs == before.assetIDs else { start(settings); return }
        if pending == nil, next != before {
            let name = StudioParameter.allCases.first { before[keyPath: $0.keyPath] != next[keyPath: $0.keyPath] }?.title ?? "Color"
            register(before: before, after: next, name: name)
        }
        last = next
    }
    private func register(before: ElementStudioSettings, after: ElementStudioSettings, name: String) {
        manager.beginUndoGrouping()
        manager.registerUndo(withTarget: self) { history in
            history.register(before: after, after: before, name: name)
            history.last = before
            history.restore?(before)
        }
        manager.setActionName(name); manager.endUndoGrouping(); revision += 1
    }
    func undo() { manager.undo(); revision += 1 }
    func redo() { manager.redo(); revision += 1 }
}

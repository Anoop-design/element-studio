import Foundation

nonisolated struct ElementStudioSettings: Codable, Equatable, Sendable {
    enum Edition: String, Codable, CaseIterable, Identifiable {
        case latest = "Latest", studioOriginal = "Studio original", newForms = "New forms", sculpted = "Sculpted", earlier = "Earlier"
        var id: String { rawValue }
    }
    enum Finish: String, Codable, CaseIterable, Identifiable {
        case crafted = "Crafted", metal = "Metal", clay = "Clay"
        var id: String { rawValue }
    }
    enum ShapeStudy: String, Codable, CaseIterable, Identifiable {
        case curved = "Curved", folded = "Folded", ceramic = "Ceramic"
        var id: String { rawValue }
    }
    enum Arrangement: String, Codable, CaseIterable, Identifiable {
        case object = "Object", trio = "Reference trio", collection = "Collection"
        var id: String { rawValue }
    }
    var selected = "stopwatch"
    var arrangement = Arrangement.object
    var finish = Finish.crafted
    var roughness = 0.40
    var grain = 0.16
    var clearcoat = 0.27
    var glass = 0.14
    var light = -35.0
    var brightness = 1.0
    var thickness = 1.0
    var explode = 0.0
    var wireframe = false
    var colorBackdrop = false
    var reduceMotion = false
    // Optional so looks saved before editions were introduced continue decoding intact.
    var edition: Edition? = .latest
    // Missing in older saved looks: retain their original material response.
    var surfaceRevision: Int? = 1
    var tintRGB: [Double]?
    var camera: [Double]?
    var studies: [String: ShapeStudy]?
    var chosenEdition: Edition {
        get { edition ?? .newForms }
        set { edition = newValue }
    }
    var hasShapeStudies: Bool { selected == "returning" || selected == "ribbon" }
    func study(for id: String) -> ShapeStudy { studies?[id] ?? (id == "ribbon" ? .folded : .curved) }
    var chosenStudy: ShapeStudy {
        get { study(for: selected) }
        set { var saved = studies ?? [:]; saved[selected] = newValue; studies = saved }
    }

    static let choices: [(id: String, name: String, symbol: String)] = [
        ("stopwatch", "Stopwatch", "stopwatch"), ("hourglass", "Hourglass", "hourglass"),
        ("memory", "Memory locket", "heart"), ("energy", "Energy", "flame"),
        ("distance", "Distance", "hexagon"), ("sunrise", "First light", "sunrise"),
        ("pennant", "First distance", "flag"), ("returning", "Comeback", "arrow.uturn.backward"),
        ("week", "Perfect week", "calendar"), ("month", "Active month", "calendar"),
        ("halfYear", "6 months", "calendar"), ("year", "Full year", "rosette"),
        ("ribbon", "12 active weeks", "bookmark"), ("activity", "Activity", "figure.run"),
        ("frequency", "Frequency", "triangle"), ("collection", "Collection crest", "square.stack"),
        ("orbit-v1", "Orbit", "circle"), ("twist-v1", "Twisted loop", "infinity"),
        ("pebbles-v1", "Stacked pebbles", "square.stack.3d.up")
    ]
    var selectionName: String { Self.choices.first { $0.id == selected }?.name ?? "Stopwatch" }
    var objectIDs: [String] {
        switch arrangement {
        case .object: [selected]
        case .trio: ["stopwatch", "hourglass", "memory"]
        case .collection: Self.choices.map(\.id)
        }
    }
    var assetIDs: [String] {
        objectIDs.map { id in
            if StudioExampleShapes.ids.contains(id) { return id }
            if chosenEdition == .earlier { return id + "-earlier" }
            if chosenEdition == .sculpted { return id + "-sculpted" }
            let suffix = chosenEdition == .studioOriginal ? "-studio20260911" : chosenEdition == .newForms ? "-forms20260910" : ""
            if id == "returning" || id == "ribbon" {
                let selectedStudy = study(for: id)
                let defaultStudy: ShapeStudy = id == "ribbon" ? .folded : .curved
                if selectedStudy != defaultStudy { return id + "-" + selectedStudy.rawValue.lowercased() + suffix }
            }
            return id + suffix
        }
    }
    var sceneKey: String { assetIDs.joined(separator: ",") }
    static let storageKey = "elementstudio.workspace.v1"

    func saved() { if let data = try? JSONEncoder().encode(self) { UserDefaults.standard.set(data, forKey: Self.storageKey) } }
    static func load() -> Self {
        let environment = ProcessInfo.processInfo.environment
        var settings = UserDefaults.standard.data(forKey: storageKey)
            .flatMap { try? JSONDecoder().decode(Self.self, from: $0) } ?? Self()
        if environment["DAYWAKE_ELEMENT_RESET"] == "1" { settings = Self() }
        if let selection = environment["DAYWAKE_ELEMENT_OBJECT"], choices.contains(where: { $0.id == selection }) {
            settings.selected = selection; settings.arrangement = .object
        }
        if let arrangement = environment["DAYWAKE_ELEMENT_ARRANGEMENT"], let value = Arrangement(rawValue: arrangement) { settings.arrangement = value }
        if let finish = environment["DAYWAKE_ELEMENT_FINISH"], let value = Finish(rawValue: finish) { settings.finish = value }
        if let edition = environment["DAYWAKE_ELEMENT_EDITION"], let value = Edition(rawValue: edition) { settings.edition = value }
        if let study = environment["DAYWAKE_ELEMENT_STUDY"], let value = ShapeStudy(rawValue: study) { settings.chosenStudy = value }
        if let light = environment["DAYWAKE_ELEMENT_LIGHT"].flatMap(Double.init) { settings.light = light }
        if let explode = environment["DAYWAKE_ELEMENT_EXPLODE"].flatMap(Double.init) { settings.explode = explode }
        settings.clamp()
        return settings
    }
    mutating func clamp() {
        if let values = camera {
            camera = values.count == 3 && values.allSatisfy(\.isFinite)
                ? [min(1_000_000,max(-1_000_000,values[0])), min(0.65,max(-0.65,values[1])), min(2.5,max(1,values[2]))] : nil
        }
        if let rgb = tintRGB { tintRGB = rgb.count == 3 && rgb.allSatisfy(\.isFinite) ? rgb.map { min(1,max(0,$0)) } : nil }
        if !Self.choices.contains(where: { $0.id == selected }) { selected = "stopwatch" }
        func safe(_ value: Double, _ range: ClosedRange<Double>, _ fallback: Double) -> Double {
            value.isFinite ? min(range.upperBound, max(range.lowerBound, value)) : fallback
        }
        roughness = safe(roughness, 0.12...0.65, 0.32)
        grain = safe(grain, 0...1, 0.45); clearcoat = safe(clearcoat, 0...1, 0.72)
        glass = safe(glass, 0.03...0.4, 0.14); light = safe(light, -140...140, -35)
        brightness = safe(brightness, 0.45...1.8, 1); thickness = safe(thickness, 0.5...1.8, 1)
        explode = safe(explode, 0...1, 0)
    }
}

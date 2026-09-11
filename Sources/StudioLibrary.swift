import SwiftUI
import UniformTypeIdentifiers

struct StudioLook: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var settings: ElementStudioSettings
    var collectionID: UUID?
    var created = Date()
    var modified = Date()
    var favorite = false
}

struct StudioCollection: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var objects: [String]
}

struct StudioArchive: Codable {
    var version = 1
    var looks: [StudioLook] = []
    var collections: [StudioCollection] = [
        .init(name: "Highlights", objects: ElementStudioSettings.choices.map(\.id)),
        .init(name: "Form studies", objects: ["returning", "ribbon"]),
        .init(name: "Material studies", objects: ["stopwatch", "hourglass", "memory"])
    ]
    var workspace = ElementStudioSettings()

    mutating func validate() throws {
        guard version == 1, looks.count <= 2000, collections.count <= 200,
              Set(looks.map(\.id)).count == looks.count,
              Set(collections.map(\.id)).count == collections.count else { throw StudioError.invalidLibrary }
        let allowed = Set(ElementStudioSettings.choices.map(\.id))
        for collection in collections {
            guard !collection.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  collection.name.count <= 100,
                  Set(collection.objects).isSubset(of: allowed) else { throw StudioError.invalidLibrary }
        }
        let ids = Set(collections.map(\.id))
        for index in looks.indices {
            guard !looks[index].name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  looks[index].name.count <= 100,
                  allowed.contains(looks[index].settings.selected) else { throw StudioError.invalidLibrary }
            looks[index].settings.clamp()
            if let id = looks[index].collectionID, !ids.contains(id) { looks[index].collectionID = nil }
        }
        workspace.clamp()
    }
}

enum StudioError: LocalizedError {
    case invalidLibrary, tooLarge
    var errorDescription: String? {
        switch self {
        case .invalidLibrary: "This file is not a supported Element Studio library."
        case .tooLarge: "This library is too large to import. The limit is 8 MB."
        }
    }
}

struct StudioDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(archive: StudioArchive) throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        data = try encoder.encode(archive)
    }
    init(configuration: ReadConfiguration) throws {
        guard let bytes = configuration.file.regularFileContents else { throw StudioError.invalidLibrary }
        data = bytes
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

@MainActor @Observable
final class StudioLibrary {
    var archive: StudioArchive
    var message: String?
    private let url: URL
    private var canSave = true
    @ObservationIgnored private var pendingSave: Task<Void, Never>?

    init(url: URL? = nil) {
        self.url = url ?? URL.applicationSupportDirectory.appending(path: "Element Studio/library.json")
        archive = StudioArchive()
        if FileManager.default.fileExists(atPath: self.url.path) {
            do {
                archive = try JSONDecoder().decode(StudioArchive.self, from: Data(contentsOf: self.url))
                try archive.validate()
            } catch {
                canSave = false
                message = "The saved library could not be read. Its file has been preserved. Import an exported library to recover your work."
            }
        }
    }
    func persist() {
        guard canSave else { message = "The preserved library is read-only until recovery. Import an exported library before saving new work."; return }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(archive).write(to: url, options: .atomic)
        } catch { message = "Your changes could not be saved: \(error.localizedDescription)" }
    }
    func updateWorkspace(_ settings: ElementStudioSettings) {
        archive.workspace = settings
        pendingSave?.cancel()
        pendingSave = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(350)); self?.persist() }
            catch { }
        }
    }
    @discardableResult func saveLook(name: String, settings: ElementStudioSettings, collection: UUID?) -> StudioLook {
        var settings = settings; settings.clamp()
        let clean = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
        let look = StudioLook(name: clean.isEmpty ? settings.selectionName : clean, settings: settings, collectionID: collection)
        archive.looks.insert(look, at: 0); persist(); return look
    }
    func update(_ look: StudioLook) {
        guard let index = archive.looks.firstIndex(where: { $0.id == look.id }) else { return }
        var value = look; value.modified = Date(); archive.looks[index] = value; persist()
    }
    func removeLook(_ id: UUID) { archive.looks.removeAll { $0.id == id }; persist() }
    func removeCollection(_ id: UUID) {
        archive.collections.removeAll { $0.id == id }
        for i in archive.looks.indices where archive.looks[i].collectionID == id { archive.looks[i].collectionID = nil }
        persist()
    }
    func importData(_ data: Data) throws {
        guard data.count < 8_000_000 else { throw StudioError.tooLarge }
        var incoming = try JSONDecoder().decode(StudioArchive.self, from: data)
        try incoming.validate()
        guard incoming.looks.count + archive.looks.count <= 2000,
              incoming.collections.count + archive.collections.count <= 200 else { throw StudioError.tooLarge }
        var mapping: [UUID: UUID] = [:]
        for var collection in incoming.collections {
            let old = collection.id; collection.id = UUID(); mapping[old] = collection.id
            archive.collections.append(collection)
        }
        for var look in incoming.looks {
            look.id = UUID(); look.collectionID = look.collectionID.flatMap { mapping[$0] }
            archive.looks.append(look)
        }
        if !canSave {
            let preserved = url.deletingPathExtension().appendingPathExtension("unreadable-\(UUID().uuidString).json")
            try FileManager.default.copyItem(at: url, to: preserved)
            canSave = true
        }
        persist()
    }
}

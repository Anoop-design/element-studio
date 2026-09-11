import SwiftUI
import UniformTypeIdentifiers

enum StudioThumbnail {
    static func url(_ id: UUID) -> URL { URL.applicationSupportDirectory.appending(path: "Element Studio/Previews/\(id.uuidString).png") }
    static func save(_ image: UIImage, id: UUID) {
        let file = url(id)
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try image.pngData()?.write(to: file, options: .atomic)
        } catch { /* The saved settings remain authoritative; previews are reproducible. */ }
    }
}

@MainActor @Observable
final class LookPreviewStore {
    static let shared = LookPreviewStore()
    var images: [UUID: UIImage] = [:]
    private var queue: [StudioLook] = []
    private var running = false
    private let renderer = ElementStudioRenderer(reporting: false)
    func request(_ look: StudioLook) {
        if images[look.id] != nil { return }
        if let image = UIImage(contentsOfFile: StudioThumbnail.url(look.id).path) { images[look.id] = image; return }
        guard !queue.contains(where: { $0.id == look.id }) else { return }
        queue.append(look)
        guard !running else { return }; running = true
        Task {
            while !queue.isEmpty {
                let look = queue.removeFirst()
                await renderer.load(look.settings)
                if let image = try? await renderer.snapshot(size: CGSize(width: 500, height: 420)) {
                    images[look.id] = image; StudioThumbnail.save(image, id: look.id)
                }
            }
            running = false
        }
    }
}

struct LookThumbnail: View {
    let look: StudioLook
    private var store: LookPreviewStore { .shared }
    var body: some View {
        Group {
            if let image = store.images[look.id] { Image(uiImage: image).resizable().scaledToFit() }
            else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
        }.aspectRatio(1.2, contentMode: .fit)
            .background(Color(uiColor: ElementStudioRenderer.background))
            .task(id: look.id) { store.request(look) }
            .accessibilityHidden(true)
    }
}

struct ObjectTile: View {
    let id: String
    var name: String { ElementStudioSettings.choices.first { $0.id == id }?.name ?? id }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("Object-" + id).resizable().scaledToFit()
                .padding(.vertical, 18).aspectRatio(0.95, contentMode: .fit).frame(maxWidth: .infinity)
                .background(Color(uiColor: ElementStudioRenderer.background)).accessibilityHidden(true)
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(name).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Text(id == "returning" || id == "ribbon" ? "3 shape studies" : "3 design editions")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
            }.padding(16)
        }
        .background(.background.secondary, in: .rect(cornerRadius: 24))
        .clipShape(.rect(cornerRadius: 24)).contentShape(.rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }
}

struct CollectionLibraryView: View {
    @Bindable var library: StudioLibrary
    let open: (String) -> Void
    let openLook: (StudioLook) -> Void
    @State private var query = ""
    @State private var showLooks = false
    @State private var pendingLook: StudioLook?
    @State private var resetCanvas = UUID()
    @AppStorage("studio.appearance") private var appearance = "System"
    @AppStorage("studio.tilt") private var tiltEnabled = true
    @State private var adding = false
    @State private var editing = false
    @State private var deletingCollection = false
    @State private var selectedCollection: UUID?
    @State private var selection: StudioSelection?
    @Namespace private var zoom
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var collection: StudioCollection? { library.archive.collections.first { $0.id == selectedCollection } }
    var objects: [String] {
        (collection?.objects ?? ElementStudioSettings.choices.map(\.id)).filter { id in
            query.isEmpty || (ElementStudioSettings.choices.first { $0.id == id }?.name ?? id).localizedCaseInsensitiveContains(query)
        }
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if objects.isEmpty {
                    ContentUnavailableView("No elements here", systemImage: "cube.transparent", description: Text(query.isEmpty ? "Edit this collection to add elements." : "Try another search."))
                } else {
                    FloatingCollectionCanvas(objects: objects, namespace: zoom, reset: resetCanvas) { object in
                        var value = library.archive.workspace
                        value.selected = object; value.arrangement = .object; value.camera = nil
                        value.chosenEdition = .latest
                        selection = StudioSelection(settings: value)
                    }
                }
            }
            .background(Color(uiColor: ElementStudioRenderer.background))
            .navigationTitle("Collections").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Show all") { resetCanvas = UUID() }
                        Button("Saved looks", systemImage: "square.stack.3d.up") { showLooks = true }
                        Button("New collection", systemImage: "plus") { adding = true }
                        Menu("Collection") {
                            Button("All elements") { selectedCollection = nil }
                            ForEach(library.archive.collections) { item in Button(item.name) { selectedCollection = item.id } }
                        }
                        if collection != nil {
                            Button("Edit collection", systemImage: "pencil") { editing = true }
                            Button("Delete collection", systemImage: "trash", role: .destructive) { deletingCollection = true }
                        }
                        Picker("Appearance", selection: $appearance) { ForEach(["System", "Light", "Dark"], id: \.self) { Text($0).tag($0) } }
                        Toggle("Tilt with iPhone", isOn: $tiltEnabled)
                    } label: { Label("Studio options", systemImage: "ellipsis") }.accessibilityIdentifier("studio-options")
                }
            }
            .sheet(isPresented: $showLooks, onDismiss: {
                if let pendingLook { selection = StudioSelection(settings: pendingLook.settings); self.pendingLook = nil }
            }) {
                LooksLibraryView(library: library) { look in pendingLook = look; showLooks = false }
            }
            .confirmationDialog("Delete this collection? Saved looks will remain in Looks.", isPresented: $deletingCollection, titleVisibility: .visible) {
                Button("Delete collection", role: .destructive) {
                    if let selectedCollection { library.removeCollection(selectedCollection) }; selectedCollection = nil
                }
            }
            .sheet(isPresented: $adding) { CollectionEditor(library: library, collection: nil) }
            .sheet(isPresented: $editing) { CollectionEditor(library: library, collection: collection) }
            .fullScreenCover(item: $selection) { value in
                StudioEditor(library: library, initial: value.settings)
                    .studioZoom(source: value.settings.selected, namespace: zoom, reduced: reduceMotion)
            }
        }
    }
    private func collectionChip(_ title: String, id: UUID?) -> some View {
        Button { selectedCollection = id } label: {
            Text(title).font(.subheadline.weight(.medium)).padding(.horizontal, 4).frame(minHeight: 32)
        }.buttonStyle(.glass).tint(selectedCollection == id ? Color.accentColor : Color.primary)
            .accessibilityAddTraits(selectedCollection == id ? .isSelected : [])
            .contextMenu {
                if let id {
                    Button("Edit collection", systemImage: "pencil") { selectedCollection = id; editing = true }
                    Button("Delete collection", systemImage: "trash", role: .destructive) {
                        library.removeCollection(id); if selectedCollection == id { selectedCollection = nil }
                    }
                }
            }
    }
}

private extension View {
    @ViewBuilder func studioZoom(source: String, namespace: Namespace.ID, reduced: Bool) -> some View {
        if reduced { self } else { self.navigationTransition(.zoom(sourceID: source, in: namespace)) }
    }
}

struct CollectionDetailView: View {
    @Bindable var library: StudioLibrary
    let id: UUID
    let open: (String) -> Void
    let openLook: (StudioLook) -> Void
    @State private var editing = false
    @State private var deleting = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    var collection: StudioCollection? { library.archive.collections.first { $0.id == id } }
    var body: some View {
        ScrollView {
            if let collection {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 270 : 150))], spacing: 16) {
                    ForEach(collection.objects, id: \.self) { object in
                        Button { open(object) } label: { ObjectTile(id: object) }.buttonStyle(.plain)
                    }
                }.padding(20)
                let looks = library.archive.looks.filter { $0.collectionID == id }
                if !looks.isEmpty {
                    Text("Saved looks").font(.title2.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
                    LazyVStack(spacing: 12) { ForEach(looks) { look in
                        Button { openLook(look) } label: { LookRow(look: look) }.buttonStyle(.plain)
                    } }.padding(20)
                }
                if collection.objects.isEmpty && looks.isEmpty {
                    ContentUnavailableView("Make room for an idea", systemImage: "square.grid.2x2", description: Text("Use Edit collection to choose objects, or save a look here from the studio."))
                }
            }
        }
        .navigationTitle(collection?.name ?? "Collection")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit collection", systemImage: "pencil") { editing = true }
                    Button("Delete collection", systemImage: "trash", role: .destructive) { deleting = true }
                } label: { Label("Collection actions", systemImage: "ellipsis") }
            }
        }
        .sheet(isPresented: $editing) { CollectionEditor(library: library, collection: collection) }
        .confirmationDialog("Delete this collection? Your saved looks will remain in Looks.", isPresented: $deleting, titleVisibility: .visible) {
            Button("Delete collection", role: .destructive) { library.removeCollection(id); dismiss() }
        }
    }
}

struct CollectionEditor: View {
    @Bindable var library: StudioLibrary
    let collection: StudioCollection?
    @State private var name = ""
    @State private var objects: Set<String> = []
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Collection name") { TextField("Untitled collection", text: $name).accessibilityIdentifier("collection-name") }
                Section("Objects") {
                    ForEach(ElementStudioSettings.choices, id: \.id) { choice in
                        Toggle(choice.name, isOn: Binding(get: { objects.contains(choice.id) }, set: { value in
                            if value { objects.insert(choice.id) } else { objects.remove(choice.id) }
                        }))
                    }
                }
            }
            .navigationTitle(collection == nil ? "New collection" : "Edit collection").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark") {
                        let value = StudioCollection(id: collection?.id ?? UUID(), name: String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100)), objects: ElementStudioSettings.choices.map(\.id).filter { objects.contains($0) })
                        if let index = library.archive.collections.firstIndex(where: { $0.id == value.id }) { library.archive.collections[index] = value }
                        else { library.archive.collections.append(value) }
                        library.persist(); dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("confirm-collection")
                }
            }
        }.onAppear { name = collection?.name ?? ""; objects = Set(collection?.objects ?? []) }
    }
}

struct LookRow: View {
    let look: StudioLook
    var body: some View {
        HStack(spacing: 16) {
            LookThumbnail(look: look).frame(width: 88).clipShape(.rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(look.name).font(.headline).foregroundStyle(.primary)
                Text(look.settings.selectionName).font(.caption).foregroundStyle(.secondary)
                Text(look.modified, style: .date).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            if look.favorite { Image(systemName: "star.fill").foregroundStyle(.tint).accessibilityLabel("Favorite") }
        }.padding(.vertical, 4).accessibilityElement(children: .combine)
    }
}

struct LooksLibraryView: View {
    @Bindable var library: StudioLibrary
    let open: (StudioLook) -> Void
    @State private var query = ""
    @State private var favorites = false
    @State private var exporting = false
    @State private var importing = false
    @State private var document: StudioDocument?
    @State private var editing: StudioLook?
    @State private var name = ""
    var looks: [StudioLook] { library.archive.looks.filter { (!favorites || $0.favorite) && (query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.settings.selectionName.localizedCaseInsensitiveContains(query)) }.sorted { $0.modified > $1.modified } }
    var body: some View {
        NavigationStack {
            List {
                if looks.isEmpty {
                    ContentUnavailableView(query.isEmpty ? "Keep a look you love" : "No matching looks", systemImage: "square.stack.3d.up", description: Text("Use + in the studio to save an exact version of an element. Your library stays on this iPhone and can be exported to Files."))
                        .listRowBackground(Color.clear)
                }
                ForEach(looks) { look in
                    Button { open(look) } label: { LookRow(look: look) }.buttonStyle(.plain)
                        .swipeActions {
                            Button("Delete", role: .destructive) { library.removeLook(look.id) }
                        }
                        .contextMenu {
                            Button(look.favorite ? "Unfavorite" : "Favorite", systemImage: "star") { var value = look; value.favorite.toggle(); library.update(value) }
                            Button("Rename", systemImage: "pencil") { name = look.name; editing = look }
                            Button("Duplicate", systemImage: "doc.on.doc") { library.saveLook(name: look.name + " copy", settings: look.settings, collection: look.collectionID) }
                        }
                }
            }
            .navigationTitle("Looks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Favorites", systemImage: favorites ? "star.fill" : "star") { favorites.toggle() }.accessibilityAddTraits(favorites ? .isSelected : []) }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Export library", systemImage: "square.and.arrow.up") {
                            do { document = try StudioDocument(archive: library.archive); exporting = true }
                            catch { library.message = error.localizedDescription }
                        }
                        Button("Import library", systemImage: "square.and.arrow.down") { importing = true }
                    } label: { Label("Library actions", systemImage: "ellipsis") }
                }
            }
            .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "Element Studio Library") { result in
                if case .failure(let error) = result { library.message = error.localizedDescription }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get(), accessed = url.startAccessingSecurityScopedResource()
                    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                    if (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) >= 8_000_000 { throw StudioError.tooLarge }
                    try library.importData(Data(contentsOf: url))
                } catch { library.message = error.localizedDescription }
            }
            .alert("Rename look", isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } })) {
                TextField("Name", text: $name)
                Button("Cancel", role: .cancel) { editing = nil }
                Button("Save") { if var look = editing { look.name = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100)); if !look.name.isEmpty { library.update(look) } }; editing = nil }
            }
        }
    }
}

/// One continuous object field. No per-object drawing loop: the authored preview
/// remains still until selected, when the native 3D editor takes over.
struct FloatingCollectionCanvas: View {
    let objects: [String]
    let namespace: Namespace.ID
    let reset: UUID
    let open: (String) -> Void
    @State private var zoom = 1.0
    @State private var offset = CGSize.zero
    @GestureState private var drag = CGSize.zero
    @GestureState private var magnification = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let field = CGSize(width: 960, height: 1120)
    private let positions: [CGPoint] = [
        CGPoint(x: 135, y: 140), CGPoint(x: 385, y: 180), CGPoint(x: 645, y: 125), CGPoint(x: 835, y: 240),
        CGPoint(x: 175, y: 405), CGPoint(x: 440, y: 420), CGPoint(x: 705, y: 400), CGPoint(x: 865, y: 545),
        CGPoint(x: 110, y: 650), CGPoint(x: 365, y: 685), CGPoint(x: 625, y: 660), CGPoint(x: 825, y: 815),
        CGPoint(x: 160, y: 935), CGPoint(x: 415, y: 950), CGPoint(x: 660, y: 965), CGPoint(x: 850, y: 1050)
    ]
    private let angles: [Double] = [-12, 9, -9, 14, 8, -13, 11, -8, -10, 13, -7, 11, -8, 10, -12, 9]
    var body: some View {
        GeometryReader { geometry in
            let size = CGSize(width: geometry.size.width, height: max(100, geometry.size.height))
            let fit = min(size.width / (field.width + 80), size.height / (field.height + 80))
            let scale = min(3.5, max(1, zoom * magnification))
            let translation = bounded(CGSize(width: offset.width + drag.width, height: offset.height + drag.height), viewport: size, scale: fit * scale)
            ZStack {
                Color(uiColor: ElementStudioRenderer.background)
                ZStack {
                    ForEach(Array(objects.enumerated()), id: \.element) { index, object in
                        let slot = objects.count == 1 ? CGPoint(x: field.width / 2, y: field.height / 2) : positions[index % positions.count]
                        Button { open(object) } label: {
                            Image("Object-" + object).resizable().scaledToFit()
                                .frame(width: 220, height: 210)
                                .rotationEffect(.degrees(angles[index % angles.count]))
                                .rotation3DEffect(.radians(StudioMotion.shared.x), axis: (x: 0, y: 1, z: 0))
                                .rotation3DEffect(.radians(StudioMotion.shared.y), axis: (x: 1, y: 0, z: 0))
                                .offset(x: StudioMotion.shared.x * 55, y: StudioMotion.shared.y * 55)
                        }
                        .buttonStyle(.plain)
                        .contentShape(.ellipse)
                        .matchedTransitionSource(id: object, in: namespace)
                        .accessibilityLabel(ElementStudioSettings.choices.first { $0.id == object }?.name ?? object)
                        .accessibilityHint("Opens the three dimensional studio")
                        .accessibilityIdentifier("element-" + object)
                        .position(slot)
                    }
                }
                .frame(width: field.width, height: field.height)
                .scaleEffect(fit * scale)
                .offset(translation)
                .frame(width: size.width, height: size.height)
                .contentShape(.rect)
                .gesture(
                    DragGesture(minimumDistance: 8)
                        .updating($drag) { value, state, _ in state = value.translation }
                        .onEnded { value in
                            let destination = bounded(CGSize(width: offset.width + value.predictedEndTranslation.width, height: offset.height + value.predictedEndTranslation.height), viewport: size, scale: fit * zoom)
                            if reduceMotion { offset = destination }
                            else { withAnimation(.interpolatingSpring(stiffness: 180, damping: 28)) { offset = destination } }
                        }
                )
                .simultaneousGesture(
                    MagnifyGesture().updating($magnification) { value, state, _ in state = value.magnification }
                        .onEnded { value in
                            zoom = min(3.5, max(1, zoom * value.magnification))
                            offset = bounded(offset, viewport: size, scale: fit * zoom)
                        }
                )
            }
            .frame(height: size.height).clipped()
            .onChange(of: reset) { _, _ in zoom = 1; offset = .zero }
            .accessibilityAction(named: "Show all") { zoom = 1; offset = .zero }
            .onChange(of: objects) { _, _ in zoom = 1; offset = .zero }
        }
    }
    private func bounded(_ value: CGSize, viewport: CGSize, scale: Double) -> CGSize {
        let x = max(0, (field.width * scale - viewport.width) / 2 + 44)
        let y = max(0, (field.height * scale - viewport.height) / 2 + 44)
        return CGSize(width: min(x, max(-x, value.width)), height: min(y, max(-y, value.height)))
    }
}

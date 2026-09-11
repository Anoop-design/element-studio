import SwiftUI

@main
struct ElementStudioApp: App {
    @State private var library = StudioLibrary()
    @AppStorage("studio.appearance") private var appearance = "System"
    var body: some Scene {
        WindowGroup { StudioRoot(library: library).preferredColorScheme(appearance == "Light" ? .light : appearance == "Dark" ? .dark : nil).tint(Color("AccentColor")) }
    }
}

struct StudioSelection: Identifiable {
    let id = UUID()
    var settings: ElementStudioSettings
}

struct StudioRoot: View {
    @Bindable var library: StudioLibrary
    @State private var selection: StudioSelection?
    @AppStorage("studio.tilt") private var tiltEnabled = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        StudioEditor(library: library, initial: library.archive.workspace, startsInCollection: true)
        .fullScreenCover(item: $selection) { value in StudioEditor(library: library, initial: value.settings) }
        .alert("Library", isPresented: Binding(get: { library.message != nil }, set: { if !$0 { library.message = nil } })) {
            Button("OK") { library.message = nil }
        } message: { Text(library.message ?? "") }
        .onChange(of: scenePhase, initial: true) { _, value in StudioMotion.shared.setEnabled(value == .active && tiltEnabled && !reduceMotion) }
        .onChange(of: tiltEnabled) { _, value in StudioMotion.shared.setEnabled(value && scenePhase == .active && !reduceMotion) }
        .onChange(of: reduceMotion) { _, value in StudioMotion.shared.setEnabled(!value && tiltEnabled && scenePhase == .active) }
        .task {
            if ProcessInfo.processInfo.environment["STUDIO_EXPORT_CATALOG"] == "1" {
                let renderer = ElementStudioRenderer(reporting: false)
                let directory = URL.cachesDirectory.appending(path: "Catalogue")
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                for choice in ElementStudioSettings.choices {
                    var value = ElementStudioSettings(); value.selected = choice.id; value.reduceMotion = true
                    await renderer.load(value)
                    if let image = try? await renderer.snapshot(size: CGSize(width: 600, height: 600), transparent: true) {
                        try? image.pngData()?.write(to: directory.appending(path: choice.id + ".png"))
                    }
                }
                try? Data("complete".utf8).write(to: directory.appending(path: "complete"))
                return
            }
            if let id = ProcessInfo.processInfo.environment["STUDIO_OBJECT"] {
                var settings = library.archive.workspace; settings.selected = id; settings.camera = nil; settings.chosenEdition = .latest
                selection = StudioSelection(settings: settings)
            }
        }
    }
    private func openLook(_ look: StudioLook) { selection = StudioSelection(settings: look.settings) }
}

struct StudioEditor: View {
    @Bindable var library: StudioLibrary
    let initial: ElementStudioSettings
    var startsInCollection = false
    @State private var settings = ElementStudioSettings()
    @State private var renderer = ElementStudioRenderer()
    @State private var panel: String?
    @State private var saveSheet = false
    @State private var sharing = false
    @State private var shareImage: UIImage?
    @State private var showLooks = false
    @State private var newCollection = false
    @State private var selectedCollection: UUID?
    @State private var editCollection = false
    @State private var deleteCollection = false
    @State private var pendingLook: StudioLook?
    @State private var pendingAction: String?
    @State private var ready = false
    @State private var viewportSize = CGSize(width: 402, height: 760)
    @Namespace private var glass
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("studio.tilt") private var tiltEnabled = true
    @AppStorage("studio.appearance") private var appearance = "System"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var editing: Bool { renderer.focusedID != nil }
    private var collection: StudioCollection? { library.archive.collections.first { $0.id == selectedCollection } }
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    ElementStudioViewport(renderer: renderer)
                    if !renderer.hasPresentedFrame {
                        InitialCollectionPreview().allowsHitTesting(false).accessibilityHidden(true)
                    }
                    if let error = renderer.error {
                        ContentUnavailableView { Label("Unable to render", systemImage: "cube.transparent") }
                        description: { Text(error) }
                        actions: { Button("Try again") { Task { await loadCollection(settings) } } }
                    }
                }
                .background(Color(uiColor: ElementStudioRenderer.background))
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { viewportSize = $0 }
            .toolbar(editing ? .visible : .hidden, for: .bottomBar)
            .navigationTitle(editing ? settings.selectionName : "Collections").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if editing {
                    ToolbarItem(placement: .bottomBar) {
                        toolDock(maxHeight: viewportSize.height * 0.43)
                            .frame(width: min(540, max(280, viewportSize.width - 32)))
                            .matchedTransitionSource(id: "studio-tools", in: glass)
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close studio", systemImage: "arrow.left") {
                            panel = nil
                            if startsInCollection { renderer.focus(on: nil) } else { dismiss() }
                        }.accessibilityIdentifier("close-studio")
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("Share look", systemImage: "square.and.arrow.up") {
                            performAfterTools("share")
                        }.disabled(renderer.loading).accessibilityIdentifier("share-look")
                        Button("Save look", systemImage: "plus") { performAfterTools("save") }.disabled(renderer.loading).accessibilityIdentifier("save-look")
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Show all") { selectedCollection = nil; renderer.resetOverview() }
                            Button("Saved looks", systemImage: "square.stack.3d.up") { showLooks = true }
                            Button("New collection", systemImage: "plus") { newCollection = true }
                            Menu("Collection") {
                                Button("All elements") { selectedCollection = nil }
                                ForEach(library.archive.collections) { item in Button(item.name) { selectedCollection = item.id } }
                            }
                            if collection != nil {
                                Button("Edit collection", systemImage: "pencil") { editCollection = true }
                                Button("Delete collection", systemImage: "trash", role: .destructive) { deleteCollection = true }
                            }
                            Picker("Appearance", selection: $appearance) { ForEach(["System", "Light", "Dark"], id: \.self) { Text($0).tag($0) } }
                            Toggle("Tilt with iPhone", isOn: $tiltEnabled)
                        } label: { Label("Studio options", systemImage: "ellipsis") }.accessibilityIdentifier("studio-options")
                    }
                }
            }
        }
        .task {
            guard !ready else { return }
            settings = initial; settings.reduceMotion = settings.reduceMotion || reduceMotion
            settings.chosenEdition = .latest; settings.camera = nil; settings.clamp()
            renderer.onSelect = { id in openObject(id) }
            renderer.setAppearance(dark: colorScheme == .dark)
            await loadCollection(settings)
            ready = true
            if !startsInCollection { openObject(initial.selected) }
        }
        .onChange(of: colorScheme, initial: true) { _, value in renderer.setAppearance(dark: value == .dark) }
        .onChange(of: StudioMotion.shared.x) { _, value in renderer.setTilt(x: value, y: StudioMotion.shared.y) }
        .onChange(of: StudioMotion.shared.y) { _, value in renderer.setTilt(x: StudioMotion.shared.x, y: value) }
        .onChange(of: settings) { _, value in
            if ready { renderer.apply(value); library.updateWorkspace(value) }
        }
        .onChange(of: collection) { _, value in renderer.showObjects(value?.objects) }
        .onChange(of: scenePhase, initial: true) { _, value in renderer.setActive(value == .active) }
        .onDisappear { renderer.setActive(false); library.persist() }
        .sheet(isPresented: toolPresentation, onDismiss: {
            if let action = pendingAction { pendingAction = nil; performAfterTools(action) }
        }) { toolControls }
        .sheet(isPresented: $newCollection) { CollectionEditor(library: library, collection: nil) }
        .sheet(isPresented: $editCollection) { CollectionEditor(library: library, collection: collection) }
        .confirmationDialog("Delete this collection? Saved looks will remain.", isPresented: $deleteCollection, titleVisibility: .visible) {
            Button("Delete collection", role: .destructive) {
                if let selectedCollection { library.removeCollection(selectedCollection) }; selectedCollection = nil
            }
        }
        .sheet(isPresented: $showLooks, onDismiss: {
            if let pendingLook {
                self.pendingLook = nil
                Task { settings = pendingLook.settings; await loadCollection(settings); renderer.focus(on: settings.selected, preservePose: true) }
            }
        }) { LooksLibraryView(library: library) { pendingLook = $0; showLooks = false } }
        .sheet(isPresented: $saveSheet) { SaveLookView(library: library, settings: settings, renderer: renderer) }
        .sheet(isPresented: $sharing, onDismiss: { shareImage = nil }) {
            NavigationStack {
                VStack(spacing: 20) {
                    if let shareImage {
                        Image(uiImage: shareImage).resizable().scaledToFit().clipShape(.rect(cornerRadius: 24))
                        Text(settings.selectionName).font(.title2.weight(.semibold))
                        ShareLink(item: Image(uiImage: shareImage), preview: SharePreview(settings.selectionName, image: Image(uiImage: shareImage))) {
                            Label("Share image", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                        }.buttonStyle(.glass).controlSize(.large).accessibilityIdentifier("share-image")
                    } else { ProgressView("Rendering your look…") }
                }.padding(24).navigationTitle("Share look").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { sharing = false }.accessibilityIdentifier("close-share") } }
            }
        }
    }
    private func openObject(_ id: String) {
        settings.selected = id; settings.arrangement = .object
        renderer.setControlInset(64)
        renderer.focus(on: id)
    }
    private func loadCollection(_ value: ElementStudioSettings) async {
        var collection = value; collection.arrangement = .collection
        await renderer.load(collection)
    }
    private func toolDock(maxHeight: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach([("Surface", "paintpalette"), ("Light", "light.max"), ("Form", "cube")], id: \.0) { title, symbol in
                Button { changeTool(title) } label: {
                    Label(title, systemImage: symbol).frame(maxWidth: .infinity, minHeight: 44)
                }.accessibilityIdentifier("panel-" + title)
            }
            resetButton
        }.padding(4).accessibilityHidden(panel != nil)
    }
    private func performAfterTools(_ action: String) {
        if panel != nil { pendingAction = action; changeTool(nil); return }
        if action == "save" { saveSheet = true; return }
        sharing = true
        Task {
            do { shareImage = try await renderer.snapshot(size: CGSize(width: 1440, height: 1440)) }
            catch { library.message = error.localizedDescription; sharing = false }
        }
    }
    private var toolPresentation: Binding<Bool> {
        Binding(get: { panel != nil }, set: { if !$0 { changeTool(nil) } })
    }
    private var toolControls: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Tools", systemImage: "chevron.down") { changeTool(nil) }
                    .labelStyle(.iconOnly).frame(width: 44, height: 44).accessibilityIdentifier("all-tools")
                Spacer()
                Text(panel ?? "Surface").font(.headline)
                Spacer()
                resetButton
            }
            ScrollView { StudioInspector(settings: $settings, renderer: renderer, panel: panel ?? "Surface").padding(.bottom, 8) }
        }.padding(.horizontal, 20).padding(.top, 12)
        .presentationDetents([.height(panel == "Light" ? 240 : 300)])
        .presentationDragIndicator(.hidden)
        .presentationBackgroundInteraction(.enabled)
        .navigationTransition(.zoom(sourceID: "studio-tools", in: glass))
    }
    private var resetButton: some View {
        Button("Reset edits", systemImage: "arrow.counterclockwise") {
            var original = ElementStudioSettings()
            original.selected = settings.selected
            original.edition = settings.edition; original.studies = settings.studies
            original.reduceMotion = settings.reduceMotion
            settings = original
            renderer.apply(original, forceMaterials: true)
            renderer.resetObject()
        }.labelStyle(.iconOnly).frame(width: 44, height: 44).accessibilityIdentifier("reset-object")
    }
    private func changeTool(_ value: String?) {
        renderer.setControlInset(value == nil ? 64 : value == "Light" ? 272 : 332)
        panel = value
    }
}

private struct InitialCollectionPreview: View {
    var body: some View {
        GeometryReader { geometry in
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(ElementStudioSettings.choices, id: \.id) { choice in
                    Image("Object-" + choice.id).resizable().scaledToFit().frame(height: max(1, min(geometry.size.width / 3, (geometry.size.height - 72) / 6)))
                }
            }.padding(16).frame(maxHeight: .infinity)
        }.background(Color(uiColor: ElementStudioRenderer.background))
    }
}

struct SaveLookView: View {
    @Bindable var library: StudioLibrary
    let settings: ElementStudioSettings
    let renderer: ElementStudioRenderer
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var collection: UUID?
    @State private var saving = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Name this look") { TextField(settings.selectionName, text: $name).accessibilityIdentifier("look-name") }
                Section {
                    Picker("Collection", selection: $collection) {
                        Text("Unfiled").tag(Optional<UUID>.none)
                        ForEach(library.archive.collections) { Text($0.name).tag(Optional($0.id)) }
                    }
                    LabeledContent("Element", value: settings.selectionName)
                } footer: { Text("Saves the object, shape, color, material, lighting and form settings as a new version.") }
            }
            .navigationTitle("Save look").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(saving) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark") {
                        saving = true
                        Task {
                            var captured = settings; captured.camera = renderer.cameraState
                            let look = library.saveLook(name: name, settings: captured, collection: collection)
                            if let image = try? await renderer.snapshot(size: CGSize(width: 600, height: 500)) { StudioThumbnail.save(image, id: look.id) }
                            dismiss()
                        }
                    }.disabled(saving).accessibilityIdentifier("confirm-save")
                }
            }
        }.presentationDetents([.medium, .large])
    }
}

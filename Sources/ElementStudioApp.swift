import SwiftUI

@main
struct ElementStudioApp: App {
    @State private var library = StudioLibrary(url: ProcessInfo.processInfo.environment["STUDIO_REVIEW"] == "1"
        ? URL.cachesDirectory.appending(path: "ElementStudio-review-library.json") : nil)
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

private enum StudioTool: String, Identifiable {
    case surface = "Surface", light = "Light", form = "Form"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .surface: "paintpalette"
        case .light: "light.max"
        case .form: "cube"
        }
    }
    var height: CGFloat { self == .light ? 338 : 372 }
}

struct StudioEditor: View {
    @Bindable var library: StudioLibrary
    let initial: ElementStudioSettings
    var startsInCollection = false
    @State private var settings = ElementStudioSettings()
    @State private var renderer = ElementStudioRenderer()
    @State private var panel: StudioTool?
    @State private var toolHeights: [StudioTool: CGFloat] = [:]
    @State private var closingTools = false
    @State private var saveSheet = false
    @State private var sharing = false
    @State private var history = StudioEditHistory()
    @State private var savedFeedback = false
    @State private var saveFeedbackID = 0
    @State private var showLooks = false
    @State private var newCollection = false
    @State private var selectedCollection: UUID?
    @State private var editCollection = false
    @State private var deleteCollection = false
    @State private var pendingLook: StudioLook?
    @State private var pendingAction: String?
    @State private var ready = false
    @Namespace private var glass
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("studio.tilt") private var tiltEnabled = true
    @AppStorage("studio.appearance") private var appearance = "System"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var editing: Bool { renderer.focusedID != nil || closingTools }
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
            .toolbar(editing ? .visible : .hidden, for: .bottomBar)
            .navigationTitle(editing ? (savedFeedback ? "Saved" : settings.selectionName) : "Collections").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if editing {
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                    ToolbarItem(placement: .bottomBar) {
                        toolButton(.surface)
                    }
                    ToolbarSpacer(.fixed, placement: .bottomBar)
                    ToolbarItem(placement: .bottomBar) {
                        toolButton(.light)
                    }
                    ToolbarSpacer(.fixed, placement: .bottomBar)
                    ToolbarItem(placement: .bottomBar) {
                        toolButton(.form)
                    }
                    ToolbarSpacer(.fixed, placement: .bottomBar)
                    ToolbarItem(placement: .bottomBar) {
                        resetButton.accessibilityHidden(panel != nil)
                    }
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close studio", systemImage: "arrow.left", action: closeObject)
                            .disabled(closingTools).accessibilityIdentifier("close-studio")
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("Share look", systemImage: "square.and.arrow.up") {
                            performAfterTools("share")
                        }.disabled(renderer.loading).accessibilityIdentifier("share-look")
                        Button(savedFeedback ? "Saved" : "Save look", systemImage: savedFeedback ? "checkmark" : "plus") { performAfterTools("save") }
                            .contentTransition(.symbolEffect(.replace))
                            .disabled(renderer.loading).accessibilityIdentifier("save-look")
                            .accessibilityValue(savedFeedback ? "Saved" : "")
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
            settings = initial; settings.wireframe = false; settings.reduceMotion = settings.reduceMotion || reduceMotion
            settings.chosenEdition = .latest; settings.surfaceRevision = 1; settings.camera = nil; settings.clamp()
            history.start(settings)
            let editingSettings = $settings
            history.restore = { [weak renderer] restored in
                renderer?.compareOriginal(false)
                var value = restored; value.camera = editingSettings.wrappedValue.camera
                value.reduceMotion = editingSettings.wrappedValue.reduceMotion
                editingSettings.wrappedValue = value
                renderer?.apply(value, preservePose: true)
            }
            renderer.editingUndoManager = history.manager
            renderer.onSelect = { id in openObject(id) }
            renderer.setAppearance(dark: colorScheme == .dark)
            await loadCollection(settings)
            ready = true
            if !startsInCollection { openObject(initial.selected) }
        }
        .task(id: ready) { if ready { await replayFormAdjustments() } }
        .onChange(of: reduceMotion) { _, value in settings.reduceMotion = value }
        .onChange(of: colorScheme, initial: true) { _, value in renderer.setAppearance(dark: value == .dark) }
        .onChange(of: settings) { _, value in
            if ready { history.observe(value); renderer.apply(value); library.updateWorkspace(value) }
        }
        .onChange(of: collection) { _, value in renderer.showObjects(value?.objects) }
        .onChange(of: scenePhase, initial: true) { _, value in renderer.setActive(value == .active) }
        .onDisappear { renderer.compareOriginal(false); renderer.setActive(false); library.persist() }
        .sensoryFeedback(.success, trigger: saveFeedbackID)
        .task(id: saveFeedbackID) {
            guard savedFeedback else { return }
            do { try await Task.sleep(for: .seconds(2.5)); savedFeedback = false } catch { }
        }
        .sheet(item: $panel, onDismiss: {
            renderer.compareOriginal(false)
            renderer.setControlInset(64)
            if closingTools {
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.20)) { closingTools = false }
            }
            if let action = pendingAction { pendingAction = nil; performAfterTools(action) }
        }) { tool in toolControls(for: tool) }
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
                Task { settings = pendingLook.settings; settings.wireframe = false; history.start(settings); await loadCollection(settings); renderer.focus(on: settings.selected, preservePose: true) }
            }
        }) { LooksLibraryView(library: library) { pendingLook = $0; showLooks = false } }
        .sheet(isPresented: $saveSheet) {
            SaveLookView(library: library, settings: settings, renderer: renderer) {
                savedFeedback = true; saveFeedbackID += 1
            }
        }
        .sheet(isPresented: $sharing) {
            StudioShareView(renderer: renderer, name: settings.selectionName)
        }
    }

    // Explicit local QA replay uses the isolated review library, never the user's looks.
    private func replayFormAdjustments() async {
        guard ProcessInfo.processInfo.environment["STUDIO_REVIEW"] == "1",
              ProcessInfo.processInfo.environment["STUDIO_FORM_REPLAY"] == "1" else { return }
        do {
            try await Task.sleep(for: .seconds(8))
            var gaps: [Double] = []
            let start = ProcessInfo.processInfo.systemUptime
            let firstFrame = renderer.frameCount
            for id in ["pennant", "memory", "returning", "collection"] {
                openObject(id); changeTool(.form)
                try await Task.sleep(for: .seconds(1))
                var previous = ProcessInfo.processInfo.systemUptime
                for step in 0..<180 {
                    try Task.checkCancellation()
                    let amount = (sin(Double(step) * .pi / 45) + 1) / 2
                    settings.thickness = 0.5 + amount * 1.3
                    settings.explode = amount
                    if step % 60 == 0 { renderer.setMeshInspection(!renderer.showsMesh) }
                    try await Task.sleep(for: .milliseconds(16))
                    let now = ProcessInfo.processInfo.systemUptime
                    gaps.append((now - previous) * 1000); previous = now
                }
                closeObject()
                try await Task.sleep(for: .seconds(1))
            }
            gaps.sort()
            let result: [String: Any] = ["updates": gaps.count, "elapsed": ProcessInfo.processInfo.systemUptime - start,
                "frames": renderer.frameCount - firstFrame, "p50UpdateMS": gaps[gaps.count / 2],
                "p95UpdateMS": gaps[Int(Double(gaps.count - 1) * 0.95)], "maxUpdateMS": gaps.last ?? 0]
            let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: URL.cachesDirectory.appending(path: "ElementStudio-form-replay.json"), options: .atomic)
        } catch { }
    }

    private func closeObject() {
        renderer.compareOriginal(false)
        // Keep the toolbar's native zoom source mounted until its sheet has returned.
        closingTools = panel != nil && startsInCollection
        panel = nil
        if startsInCollection {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.32)) { renderer.focus(on: nil) }
        } else { dismiss() }
    }
    private func openObject(_ id: String) {
        let appearance = renderer.appearance(for: id)
        history.start(appearance); savedFeedback = false
        renderer.setControlInset(64)
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.36)) {
            // Establish the destination before publishing its controls. A native
            // animation can flush SwiftUI updates immediately; applying while still
            // in overview would overwrite every object's individual appearance.
            renderer.focus(on: id)
            renderer.apply(appearance, preservePose: true)
            settings = appearance
        }
    }
    private func loadCollection(_ value: ElementStudioSettings) async {
        var collection = value; collection.arrangement = .collection
        await renderer.load(collection)
    }
    private func toolButton(_ tool: StudioTool) -> some View {
        Button(tool.rawValue, systemImage: tool.symbol) { changeTool(tool) }
            .labelStyle(.iconOnly)
            .frame(width: 44, height: 44)
            .matchedTransitionSource(id: tool, in: glass)
            .accessibilityIdentifier("panel-" + tool.rawValue)
    }
    private func performAfterTools(_ action: String) {
        renderer.compareOriginal(false)
        renderer.setMeshInspection(false)
        if panel != nil { pendingAction = action; changeTool(nil); return }
        if action == "save" { saveSheet = true; return }
        sharing = true
    }
    private func toolControls(for tool: StudioTool) -> some View {
        VStack(spacing: 12) {
            HStack {
                Button("Tools", systemImage: "chevron.down") { changeTool(nil) }
                    .labelStyle(.iconOnly).frame(width: 44, height: 44).accessibilityIdentifier("all-tools")
                Spacer()
                Text(tool.rawValue).font(.headline)
                Spacer()
                resetButton
            }.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            GeometryReader { viewport in
                ScrollView {
                    StudioInspector(settings: $settings, renderer: renderer, panel: tool.rawValue,
                                    beginEdit: { history.begin(settings, name: $0) }, endEdit: { history.end(settings) })
                        .padding(.horizontal, 8)
                        .frame(width: viewport.size.width)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 4)
                        .onGeometryChange(for: CGFloat.self, of: { ceil($0.size.height) }) { height in
                            // Fit the actual controls, including Dynamic Type and native switch metrics.
                            let fitted = height + 140
                            guard toolHeights[tool] != fitted else { return }
                            toolHeights[tool] = fitted
                            if panel == tool { renderer.setControlInset(fitted + 32) }
                        }
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                .scrollDisabled((toolHeights[tool] ?? tool.height) - 140 <= viewport.size.height + 1)
                .accessibilityIdentifier("tool-controls")
            }
            StudioCompareButton(comparing: renderer.comparingOriginal, changed: renderer.compareOriginal)
                .frame(height: 44)
        }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 16)
        .presentationDetents([.height(toolHeights[tool] ?? tool.height)])
        .presentationDragIndicator(.hidden)
        .presentationBackgroundInteraction(.enabled)
        .navigationTransition(.zoom(sourceID: tool, in: glass))
    }
    private var resetButton: some View {
        Menu {
            Button(history.undoTitle, systemImage: "arrow.uturn.backward") { renderer.compareOriginal(false); history.undo() }
                .disabled(!history.canUndo).accessibilityIdentifier("undo-edit")
            Button(history.redoTitle, systemImage: "arrow.uturn.forward") { renderer.compareOriginal(false); history.redo() }
                .disabled(!history.canRedo).accessibilityIdentifier("redo-edit")
            Divider()
            Button("Reset view", systemImage: "viewfinder") { renderer.compareOriginal(false); renderer.resetObject() }
                .accessibilityIdentifier("reset-view")
            if let panel {
                Button("Reset " + panel.rawValue.lowercased()) { resetEdits(panel: panel.rawValue) }
            }
            Button("Reset all edits", systemImage: "arrow.counterclockwise") { resetEdits() }
                .accessibilityIdentifier("reset-all-edits")
        } label: {
            Label("Undo and reset", systemImage: "arrow.counterclockwise")
                .labelStyle(.iconOnly).frame(width: 44, height: 44)
        }.accessibilityIdentifier("reset-object")
    }
    private func resetEdits(panel: String? = nil) {
        renderer.compareOriginal(false)
        renderer.setMeshInspection(false)
        history.begin(settings, name: panel.map { "Reset " + $0 } ?? "Reset edits")
        settings = settings.originalAppearance(panel: panel)
        renderer.apply(settings, forceMaterials: true, preservePose: true)
        history.end(settings)
    }
    private func changeTool(_ value: StudioTool?) {
        renderer.compareOriginal(false)
        renderer.setControlInset(value.map { (toolHeights[$0] ?? $0.height) + 32 } ?? 64)
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
    var onSaved: () -> Void = {}
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
                            guard library.lastSaveSucceeded else { saving = false; return }
                            if let image = try? await renderer.snapshot(size: CGSize(width: 600, height: 500)) { StudioThumbnail.save(image, id: look.id) }
                            onSaved(); dismiss()
                        }
                    }.disabled(saving).accessibilityIdentifier("confirm-save")
                }
            }
        }.presentationDetents([.medium, .large])
    }
}

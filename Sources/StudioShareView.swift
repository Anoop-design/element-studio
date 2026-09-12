import SwiftUI

nonisolated enum StudioExportBackground: String, CaseIterable, Identifiable {
    case transparent = "Transparent", white = "White", black = "Black"
    var id: String { rawValue }
}

@MainActor enum StudioImageExport {
    static func image(_ source: UIImage, background: StudioExportBackground) -> UIImage {
        guard background != .transparent else { return source }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        return UIGraphicsImageRenderer(size: source.size, format: format).image { context in
            (background == .white ? UIColor.white : UIColor.black).setFill()
            context.fill(CGRect(origin: .zero, size: source.size))
            source.draw(in: CGRect(origin: .zero, size: source.size))
        }
    }
}

struct StudioShareView: View {
    let renderer: ElementStudioRenderer
    let name: String
    @Environment(\.dismiss) private var dismiss
    @State private var source: UIImage?
    @State private var image: UIImage?
    @State private var background: StudioExportBackground = .transparent
    @State private var url: URL?
    @State private var error: String?
    @State private var exportID = UUID()
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                            .background { if background == .transparent { TransparencyGrid() } }
                            .clipShape(.rect(cornerRadius: 24))
                            .accessibilityLabel("Preview of " + name).accessibilityValue(background.rawValue)
                            .accessibilityIdentifier("export-preview")
                        Picker("Background", selection: $background) {
                            ForEach(StudioExportBackground.allCases) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented).accessibilityIdentifier("export-background")
                        if let url {
                            ShareLink(item: url, preview: SharePreview(name, image: Image(uiImage: image))) {
                                Label("Share PNG", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                            }.buttonStyle(.glassProminent).controlSize(.large).accessibilityIdentifier("share-image")
                        }
                    } else if let error {
                        ContentUnavailableView("Unable to export", systemImage: "exclamationmark.triangle", description: Text(error))
                    } else { ProgressView("Rendering your look…").frame(minHeight: 280) }
                }.padding(24)
            }
            .navigationTitle("Share look").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("close-share") } }
        }
        .task {
            do {
                let captured = try await renderer.snapshot(size: CGSize(width: 1440, height: 1440), transparent: true)
                try Task.checkCancellation()
                source = captured; updateExport()
            } catch is CancellationError { }
            catch { self.error = error.localizedDescription }
        }
        .onChange(of: background) { _, _ in updateExport() }
        .alert("Unable to export", isPresented: Binding(get: { source != nil && error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") { }
        } message: { Text(error ?? "") }
    }
    private func updateExport() {
        guard let source else { return }
        let rendered = StudioImageExport.image(source, background: background)
        let filename = "Element-\(exportID.uuidString)-\(background.rawValue).png"
        let destination = URL.cachesDirectory.appending(path: filename)
        do {
            guard let data = rendered.pngData() else { throw CocoaError(.coderInvalidValue) }
            try data.write(to: destination, options: .atomic)
            image = rendered; url = destination
        } catch { self.error = error.localizedDescription; url = nil }
    }
}

private struct TransparencyGrid: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 16
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.96)))
            for row in 0...Int(size.height / step) {
                for column in 0...Int(size.width / step) where (row + column).isMultiple(of: 2) {
                    context.fill(Path(CGRect(x: CGFloat(column) * step, y: CGFloat(row) * step, width: step, height: step)),
                                 with: .color(colorScheme == .dark ? Color(white: 0.19) : Color(white: 0.91)))
                }
            }
        }.accessibilityHidden(true)
    }
}

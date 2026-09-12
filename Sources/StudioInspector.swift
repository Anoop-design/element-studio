import SwiftUI

struct StudioInspector: View {
    @Binding var settings: ElementStudioSettings
    @Bindable var renderer: ElementStudioRenderer
    let panel: String
    let beginEdit: (String) -> Void
    let endEdit: () -> Void
    @State private var pickingColor = false
    var body: some View {
        VStack(spacing: 12) {
            ForEach(parameters) { parameter in
                StudioParameterSlider(parameter: parameter, value: $settings[dynamicMember: parameter.keyPath],
                                      beginEdit: beginEdit, endEdit: endEdit)
            }
            if panel == "Surface" {
                if renderer.originalColors.isEmpty || settings.finish != .crafted {
                    LabeledContent("Color", value: "Original materials").font(.subheadline).frame(minHeight: 44)
                } else { colorControl }
            }
            if panel == "Form" {
                Toggle("Show mesh", isOn: Binding(get: { renderer.showsMesh }, set: { renderer.setMeshInspection($0) }))
                    .font(.subheadline).frame(minHeight: 44)
            }
        }
        .disabled(renderer.comparingOriginal)
        .background {
            StudioColorPicker(isPresented: $pickingColor, color: tint).frame(width: 0, height: 0)
        }
        .onChange(of: pickingColor) { _, shown in if !shown { endEdit() } }
    }
    private var parameters: [StudioParameter] {
        switch panel {
        case "Surface": [.finish, .texture]
        case "Light": [.light, .brightness]
        default: [.depth, .separation]
        }
    }
    private var colors: [Color] {
        if let rgb = settings.tintRGB { return [Color(red: rgb[0], green: rgb[1], blue: rgb[2])] }
        return renderer.originalColors.map { Color(uiColor: $0) }
    }
    private var tint: Binding<UIColor> {
        Binding(get: {
            if let rgb = settings.tintRGB { return UIColor(red: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1) }
            return renderer.originalColors.first ?? .white
        }, set: { color in
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return }
            settings.tintRGB = [Double(r), Double(g), Double(b)]
        })
    }
    private var colorControl: some View {
        Button { beginEdit("Color"); pickingColor = true } label: {
            HStack {
                Text("Color").font(.subheadline.weight(.medium)).foregroundStyle(.primary)
                Spacer()
                Text(settings.tintRGB == nil ? "Original colors" : "Custom").font(.caption).foregroundStyle(.secondary)
                Circle().fill(AngularGradient(colors: colors.count > 1 ? colors : colors + colors, center: .center))
                    .frame(width: 26, height: 26)
                    .overlay { Circle().strokeBorder(.primary.opacity(0.12), lineWidth: 0.5) }
            }.frame(minHeight: 44).contentShape(.rect)
        }.buttonStyle(.plain).accessibilityIdentifier("edit-color")
        .accessibilityValue(settings.tintRGB == nil ? "Original colors" : "Custom color")
        .contextMenu {
            Button("Use original colors") { beginEdit("Color"); settings.tintRGB = nil; endEdit() }
        }
    }
}

private struct StudioParameterSlider: View {
    let parameter: StudioParameter
    @Binding var value: Double
    let beginEdit: (String) -> Void
    let endEdit: () -> Void
    @State private var editing = false
    @State private var atOriginal = false
    @State private var detent = 0
    @State private var enteringValue = false
    @State private var text = ""
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        VStack(spacing: 0) {
            let valueLayout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0)) : AnyLayout(HStackLayout(alignment: .center))
            valueLayout {
                Text(parameter.title).font(.subheadline.weight(.medium))
                if !typeSize.isAccessibilitySize { Spacer(minLength: 8) }
                Button { text = parameter.entryText(value); enteringValue = true } label: {
                    Text(parameter.display(value)).font(.subheadline.monospacedDigit())
                        .contentTransition(.numericText()).frame(minWidth: 58, minHeight: 44, alignment: .trailing)
                }.buttonStyle(.plain).foregroundStyle(.tint)
                    .accessibilityLabel("Set " + parameter.title.lowercased())
                    .accessibilityValue(parameter.display(value))
                    .accessibilityIdentifier("value-" + parameter.rawValue)
            }
            Slider(value: $value, in: parameter.range, onEditingChanged: { active in
                editing = active
                if active { atOriginal = isOriginal(value); beginEdit(parameter.title) }
                else { endEdit() }
            }) { Text(parameter.title) }
                .accessibilityValue(parameter.display(value))
                .overlay(alignment: .bottom) {
                    GeometryReader { proxy in
                        let fraction = (parameter.original - parameter.range.lowerBound) / (parameter.range.upperBound - parameter.range.lowerBound)
                        Capsule().fill(.secondary.opacity(0.6)).frame(width: 2, height: 4)
                            .position(x: 14 + (proxy.size.width - 28) * fraction, y: proxy.size.height + 1)
                    }.allowsHitTesting(false).accessibilityHidden(true)
                }
                .onChange(of: value) { old, new in
                    guard editing else { return }
                    let reached = isOriginal(new)
                    let crossed = (old - parameter.original) * (new - parameter.original) < 0
                    if !atOriginal && (reached || crossed) { detent += 1 }
                    atOriginal = reached
                }
                .sensoryFeedback(.selection, trigger: detent)
            let endpointLayout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 3)) : AnyLayout(HStackLayout())
            endpointLayout {
                Text(parameter.ends.0)
                if !typeSize.isAccessibilitySize { Spacer() }
                Text(parameter.ends.1)
            }
                .font(.caption2).foregroundStyle(.secondary).padding(.top, 3).accessibilityHidden(true)
        }
        .alert("Set " + parameter.title.lowercased(), isPresented: $enteringValue) {
            TextField("Value", text: $text).keyboardType(.numbersAndPunctuation).accessibilityIdentifier("precise-value")
            Button("Cancel", role: .cancel) { }
            Button("Apply") {
                if let parsed = parameter.parse(text) { beginEdit(parameter.title); value = parsed; endEdit() }
            }.disabled(parameter.parse(text) == nil)
        } message: {
            Text("\(parameter.entryText(parameter.range.lowerBound))–\(parameter.entryText(parameter.range.upperBound)) \(parameter.entryUnit)")
        }
    }
    private func isOriginal(_ value: Double) -> Bool { abs(value - parameter.original) < (parameter.range.upperBound - parameter.range.lowerBound) * 0.008 }
}

private struct StudioColorPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var color: UIColor
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
    func updateUIViewController(_ presenter: UIViewController, context: Context) {
        context.coordinator.parent = self
        if isPresented, context.coordinator.picker == nil {
            let picker = UIColorPickerViewController()
            picker.selectedColor = color; picker.supportsAlpha = false
            picker.delegate = context.coordinator
            picker.view.accessibilityIdentifier = "native-color-picker"
            context.coordinator.picker = picker
            presenter.present(picker, animated: true)
            picker.presentationController?.delegate = context.coordinator
        } else if !isPresented, let picker = context.coordinator.picker {
            // The presenter can inherit an ancestor's presented controller. Only
            // dismiss the picker we own; alerts and the tool sheet belong to SwiftUI.
            if !picker.isBeingDismissed { picker.dismiss(animated: true) }
            context.coordinator.picker = nil
        }
    }
    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
        var parent: StudioColorPicker
        weak var picker: UIColorPickerViewController?
        init(_ parent: StudioColorPicker) { self.parent = parent }
        func colorPickerViewControllerDidSelectColor(_ picker: UIColorPickerViewController) { parent.color = picker.selectedColor }
        func colorPickerViewControllerDidFinish(_ picker: UIColorPickerViewController) { parent.isPresented = false }
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { picker = nil; parent.isPresented = false }
    }
}

struct StudioCompareButton: UIViewRepresentable {
    let comparing: Bool
    let changed: (Bool) -> Void
    func makeUIView(context: Context) -> CompareControl {
        let button = CompareControl(type: .system)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "circle.lefthalf.filled"); config.imagePadding = 7
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var result = incoming
            // This compact toolbar action follows the same text ceiling as native chrome.
            result.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15), maximumPointSize: 23)
            return result
        }
        button.configuration = config
        button.addTarget(button, action: #selector(CompareControl.down), for: .touchDown)
        button.addTarget(button, action: #selector(CompareControl.up), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        button.addTarget(button, action: #selector(CompareControl.activateFromKeyboard(_:event:)), for: .primaryActionTriggered)
        button.accessibilityIdentifier = "compare-original"
        button.accessibilityHint = "Hold to view the original. With VoiceOver, double tap to switch between original and edited."
        return button
    }
    func updateUIView(_ button: CompareControl, context: Context) {
        button.changed = changed; button.comparing = comparing
        button.configuration?.title = comparing ? "Original" : "Hold to compare"
        button.accessibilityLabel = "Compare with original"
        button.accessibilityValue = comparing ? "Original" : "Edited"
    }
    final class CompareControl: UIButton {
        var comparing = false
        var changed: ((Bool) -> Void)?
        @objc func activateFromKeyboard(_ sender: UIButton, event: UIEvent?) {
            if event?.type != .touches { changed?(!comparing) }
        }
        @objc func down() { changed?(true) }
        @objc func up() { changed?(false) }
        override func accessibilityActivate() -> Bool { changed?(!comparing); return true }
    }
}

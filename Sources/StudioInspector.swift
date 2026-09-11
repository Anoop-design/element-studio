import SwiftUI

struct StudioInspector: View {
    @Binding var settings: ElementStudioSettings
    let renderer: ElementStudioRenderer
    let panel: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if panel == "Surface" {
                surfaceControls
                ColorPicker("Color", selection: tint, supportsOpacity: false)
                if settings.tintRGB != nil { Button("Use original colors") { settings.tintRGB = nil } }
            } else if panel == "Light" { lightControls }
            else { formControls }
        }

    }
    private var tint: Binding<Color> {
        Binding(get: {
            let rgb = settings.tintRGB ?? [0.65,0.72,0.40]
            return Color(red: rgb[0], green: rgb[1], blue: rgb[2])
        }, set: { color in
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
            settings.tintRGB = [Double(r), Double(g), Double(b)]
        })
    }
    private var surfaceControls: some View {
        Group {
            slider("Finish", value: $settings.roughness, range: 0.12...0.65,
                   display: settings.roughness < 0.25 ? "Gloss" : "Satin", low: "Gloss", high: "Matte")
            slider("Texture", value: $settings.grain, range: 0...1,
                   display: percent(settings.grain), low: "Smooth", high: "Textured")
        }
    }

    private var lightControls: some View {
        Group {
            slider("Light direction", value: $settings.light, range: -140...140,
                   display: "\(Int(settings.light))°", low: "Left", high: "Right")
            slider("Brightness", value: $settings.brightness, range: 0.45...1.8,
                   display: settings.brightness.formatted(.number.precision(.fractionLength(2))), low: "Quiet", high: "Bright")
        }
    }

    private var formControls: some View {
        Group {
            slider("Depth", value: $settings.thickness, range: 0.5...1.8,
                   display: settings.thickness.formatted(.number.precision(.fractionLength(2))) + "×", low: "Slim", high: "Substantial")
            slider("Separate components", value: $settings.explode, range: 0...1,
                   display: percent(settings.explode), low: "Assembled", high: "Exploded")
            Toggle("Show mesh", isOn: $settings.wireframe)

        }
    }

    private func lightPreset(_ name: String, angle: Double, brightness: Double) -> some View {
        Button(name) { settings.light = angle; settings.brightness = brightness }
            .font(.subheadline).frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.glass)
    }

    private func percent(_ number: Double) -> String { "\(Int(number * 100))%" }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, display: String, low: String, high: String) -> some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.subheadline.weight(.medium))
                Spacer(minLength: 8)
                Text(display).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            Slider(value: value, in: range) { Text(title) }
                .accessibilityValue(display)
                .tint(.accentColor)
            HStack { Text(low); Spacer(); Text(high) }
                .font(.caption2).foregroundStyle(.tertiary).accessibilityHidden(true)
        }
    }
}

private extension View {
    @ViewBuilder func studioSelectionStyle(accessible: Bool) -> some View {
        if accessible { self.pickerStyle(.menu) }
        else { self.pickerStyle(.segmented) }
    }
}

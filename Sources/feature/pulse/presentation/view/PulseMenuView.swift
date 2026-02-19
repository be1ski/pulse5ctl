import AppKit
import FeaturePulseDomain
import SwiftUI

public struct PulseMenuView: View {
    @ObservedObject private var feature: PulseFeature
    private let onSettingsTapped: () -> Void

    public init(feature: PulseFeature, onSettingsTapped: @escaping () -> Void = {}) {
        self.feature = feature
        self.onSettingsTapped = onSettingsTapped
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if state.canShowControls {
                    connectedContent
                } else {
                    disconnectedContent
                }
            }
            .padding(16)
        }
        .frame(width: 340)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            feature.send(.lifecycle(.started))
        }
    }

    private var state: PulseState {
        feature.state
    }

    // MARK: - Disconnected

    @ViewBuilder
    private var disconnectedContent: some View {
        if state.connectionState == .scanning || !state.discoveredDevices.isEmpty {
            scanningContent
        } else {
            heroSection
        }

        if let errorMessage = state.errorMessage {
            errorSection(message: errorMessage)
        }

        quitButton
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "hifispeaker")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Text("JBL Pulse 5")
                .font(.headline)

            Text("Connect to control\nLED themes, brightness and animations")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                feature.send(.connection(.connectTapped))
            } label: {
                Label("Scan for Speaker", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 4)
        }
    }

    private var scanningContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(state.connectionState.displayText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Cancel") {
                    feature.send(.connection(.disconnectTapped))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if state.discoveredDevices.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Searching for Pulse 5...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(state.discoveredDevices) { device in
                    Button {
                        feature.send(.connection(.selectDevice(device.id)))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    if device.hasJBLService {
                                        Image(systemName: "hifispeaker.fill")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                    }

                                    Text(device.name)
                                        .font(.subheadline)
                                        .fontWeight(device.hasJBLService ? .semibold : .regular)
                                }

                                Text("RSSI: \(device.rssi) dBm")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                            Text("Connect")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(device.hasJBLService ? Color.accentColor.opacity(0.08) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Connected

    private var connectedContent: some View {
        Group {
            connectedHeader

            if let errorMessage = state.errorMessage {
                errorSection(message: errorMessage)
            }

            themesSection

            if let theme = state.selectedTheme, !theme.patterns.isEmpty {
                patternsSection(theme: theme)
            }

            colorSection
            brightnessSection
            speedSection
        }
    }

    private var connectedHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "hifispeaker.fill")
                .font(.title2)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Connected")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let name = state.connectedDeviceName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                onSettingsTapped()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Menu {
                Button("Disconnect") {
                    feature.send(.connection(.disconnectTapped))
                }
                Divider()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Controls

    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Themes")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(LEDTheme.allCases) { theme in
                    let isSelected = state.selectedTheme == theme

                    Button {
                        feature.send(.controls(.selectTheme(theme)))
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                if isSelected {
                                    Circle()
                                        .fill(themeColor(theme).opacity(0.3))
                                        .frame(width: 32, height: 32)
                                        .blur(radius: 6)
                                }

                                Image(systemName: theme.sfSymbol)
                                    .font(.title3)
                                    .foregroundStyle(themeColor(theme))
                            }

                            Text(theme.displayName)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? themeColor(theme).opacity(0.15) : Color(.controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? themeColor(theme) : Color.clear, lineWidth: 1.5)
                        )
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func patternsSection(theme: LEDTheme) -> some View {
        let activeSet = state.activePatternsForTheme(theme)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Patterns")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(theme.patterns) { pattern in
                    let isActive = activeSet.contains(pattern)

                    HStack(spacing: 4) {
                        Image(systemName: pattern.sfSymbol)
                            .font(.caption2)
                        Text(pattern.displayName)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isActive ? themeColor(theme).opacity(0.15) : Color(.controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isActive ? themeColor(theme) : Color(.separatorColor), lineWidth: 1)
                    )
                    .onTapGesture(count: 2) {
                        feature.send(.controls(.soloPattern(pattern, theme)))
                    }
                    .onTapGesture(count: 1) {
                        feature.send(.controls(.togglePattern(pattern, theme)))
                    }
                    .animation(.easeInOut(duration: 0.15), value: isActive)
                }
            }
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .font(.headline)

            let swatches: [(String, LEDColor)] = [
                ("Red", LEDColor(red: 0xFF, green: 0x00, blue: 0x00)),
                ("Orange", LEDColor(red: 0xFF, green: 0x8C, blue: 0x00)),
                ("Yellow", LEDColor(red: 0xFF, green: 0xFF, blue: 0x00)),
                ("Green", LEDColor(red: 0x00, green: 0xFF, blue: 0x00)),
                ("Cyan", LEDColor(red: 0x00, green: 0xFF, blue: 0xFF)),
                ("Blue", LEDColor(red: 0x00, green: 0x00, blue: 0xFF)),
                ("Purple", LEDColor(red: 0x80, green: 0x00, blue: 0xFF)),
                ("Pink", LEDColor(red: 0xFF, green: 0x00, blue: 0x80)),
                ("White", LEDColor(red: 0xFF, green: 0xFF, blue: 0xFF)),
            ]

            HStack(spacing: 6) {
                ForEach(swatches, id: \.0) { name, color in
                    let isSelected = state.customColor == color && state.colorEffect == .staticColor
                    Button {
                        if state.colorEffect == .colorLoop {
                            feature.send(.controls(.setColorEffect(.staticColor)))
                        }
                        feature.send(.controls(.setCustomColor(color)))
                    } label: {
                        Circle()
                            .fill(Color(
                                red: Double(color.red) / 255.0,
                                green: Double(color.green) / 255.0,
                                blue: Double(color.blue) / 255.0
                            ))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                            )
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? Color.black.opacity(0.3) : Color(.separatorColor), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(name)
                }

                Spacer()
            }
            .opacity(state.colorEffect == .colorLoop ? 0.4 : 1.0)

            HStack(spacing: 12) {
                ColorPicker(
                    "Custom",
                    selection: Binding(
                        get: {
                            Color(
                                red: Double(state.customColor.red) / 255.0,
                                green: Double(state.customColor.green) / 255.0,
                                blue: Double(state.customColor.blue) / 255.0
                            )
                        },
                        set: { newColor in
                            if state.colorEffect == .colorLoop {
                                feature.send(.controls(.setColorEffect(.staticColor)))
                            }
                            if let components = newColor.cgColor?.components, components.count >= 3 {
                                let r = UInt8(min(max(components[0] * 255, 0), 255))
                                let g = UInt8(min(max(components[1] * 255, 0), 255))
                                let b = UInt8(min(max(components[2] * 255, 0), 255))
                                feature.send(.controls(.setCustomColor(LEDColor(red: r, green: g, blue: b))))
                            }
                        }
                    ),
                    supportsOpacity: false
                )
                .font(.caption)
                .opacity(state.colorEffect == .colorLoop ? 0.4 : 1.0)

                Spacer()

                Toggle(
                    "Color Loop",
                    isOn: Binding(
                        get: { state.colorEffect == .colorLoop },
                        set: { isOn in
                            feature.send(.controls(.setColorEffect(isOn ? .colorLoop : .staticColor)))
                        }
                    )
                )
                .toggleStyle(.switch)
                .controlSize(.small)
                .font(.caption)
            }
        }
    }

    private var brightnessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Brightness")
                .font(.headline)

            HStack(spacing: 10) {
                Image(systemName: "sun.min")
                Slider(
                    value: Binding(
                        get: { Double(state.brightness) },
                        set: { feature.send(.controls(.setBrightness($0))) }
                    ),
                    in: 20 ... 80,
                    step: 1
                )
                .tint(.orange)
                Image(systemName: "sun.max")
                Text("\(Int(round(Double(state.brightness - 20) / 60.0 * 100)))%")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 38)
            }

            HStack(spacing: 12) {
                Toggle(
                    "Body",
                    isOn: Binding(
                        get: { state.bodyLightOn },
                        set: { _ in feature.send(.controls(.toggleBodyLight)) }
                    )
                )
                .toggleStyle(.switch)
                .controlSize(.small)

                Toggle(
                    "Projection",
                    isOn: Binding(
                        get: { state.projectionOn },
                        set: { _ in feature.send(.controls(.toggleProjection)) }
                    )
                )
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .font(.caption)
            .frame(maxWidth: .infinity)
        }
    }

    private var speedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Animation Speed")
                .font(.headline)

            Picker("Speed", selection: Binding(
                get: { state.speed },
                set: { feature.send(.controls(.setSpeed($0))) }
            )) {
                Text("Low").tag(UInt8(1))
                Text("Mid").tag(UInt8(2))
                Text("High").tag(UInt8(3))
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    // MARK: - Shared

    private func errorSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)

            Button("Dismiss") {
                feature.send(.system(.dismissError))
            }
            .buttonStyle(.plain)
            .font(.caption2)
        }
    }

    private var quitButton: some View {
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
    }

    private func themeColor(_ theme: LEDTheme) -> Color {
        switch theme {
        case .nature:
            return Color(red: 0xAD / 255.0, green: 0x52 / 255.0, blue: 0xFF / 255.0)
        case .party:
            return Color(red: 0xFA / 255.0, green: 0xBC / 255.0, blue: 0x03 / 255.0)
        case .spiritual:
            return Color(red: 0xFF / 255.0, green: 0x6C / 255.0, blue: 0x00 / 255.0)
        case .cocktail:
            return Color(red: 0x00 / 255.0, green: 0xCB / 255.0, blue: 0xFF / 255.0)
        case .weather:
            return Color(red: 0x00 / 255.0, green: 0x52 / 255.0, blue: 0xFF / 255.0)
        case .canvas:
            return Color(red: 0x00 / 255.0, green: 0xFF / 255.0, blue: 0xCC / 255.0)
        }
    }
}

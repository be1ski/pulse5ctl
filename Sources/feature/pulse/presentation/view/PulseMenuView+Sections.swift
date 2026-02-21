import AppKit
import CoreLocalization
import FeaturePulseDomain
import SwiftUI

// MARK: - Disconnected

extension PulseMenuView {

    var visibleDevices: [DiscoveredDevice] {
        let devices = state.discoveredDevices
        let pulse = devices.filter(\.hasPulseService)
        let other = devices.filter { !$0.hasPulseService }
        return Array((pulse + other).prefix(8))
    }

    @ViewBuilder
    var disconnectedContent: some View {
        if state.connectionState.isActive || !state.discoveredDevices.isEmpty {
            scanningContent
        } else {
            heroSection
        }

        if let errorMessage = state.errorMessage {
            errorSection(message: errorMessage)
        }

        quitButton
    }

    var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "hifispeaker")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Text(L10n.heroTitle)
                .font(.headline)

            Text(L10n.heroSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                feature.send(.connection(.connectTapped))
            } label: {
                Label(L10n.heroScanButton, systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 4)
        }
    }

    var scanningContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(state.connectionState.displayText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(L10n.generalCancel) {
                    feature.send(.connection(.disconnectTapped))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if state.discoveredDevices.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(L10n.heroSearching)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(visibleDevices) { device in
                    Button {
                        feature.send(.connection(.selectDevice(device.id)))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    if device.hasPulseService {
                                        Image(systemName: "hifispeaker.fill")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                    }

                                    Text(device.name)
                                        .font(.subheadline)
                                        .fontWeight(
                                            device.hasPulseService ? .semibold : .regular
                                        )
                                }

                                Text(L10n.formatRSSI(device.rssi))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                            Text(L10n.generalConnect)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            device.hasPulseService
                                ? Color.accentColor.opacity(0.08) : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Controls

extension PulseMenuView {

    var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.controlsColor)
                .font(.headline)

            let swatches: [(String, LEDColor)] = [
                (L10n.colorRed, LEDColor(red: 0xFF, green: 0x00, blue: 0x00)),
                (L10n.colorOrange, LEDColor(red: 0xFF, green: 0x8C, blue: 0x00)),
                (L10n.colorYellow, LEDColor(red: 0xFF, green: 0xFF, blue: 0x00)),
                (L10n.colorGreen, LEDColor(red: 0x00, green: 0xFF, blue: 0x00)),
                (L10n.colorCyan, LEDColor(red: 0x00, green: 0xFF, blue: 0xFF)),
                (L10n.colorBlue, LEDColor(red: 0x00, green: 0x00, blue: 0xFF)),
                (L10n.colorPurple, LEDColor(red: 0x80, green: 0x00, blue: 0xFF)),
                (L10n.colorPink, LEDColor(red: 0xFF, green: 0x00, blue: 0x80)),
                (L10n.colorWhite, LEDColor(red: 0xFF, green: 0xFF, blue: 0xFF))
            ]

            HStack(spacing: 6) {
                ForEach(swatches, id: \.0) { name, color in
                    let isSelected = state.customColor == color
                        && state.colorEffect == .staticColor
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
                                    .stroke(
                                        isSelected ? Color.white : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        isSelected
                                            ? Color.black.opacity(0.3)
                                            : Color(.separatorColor),
                                        lineWidth: 1
                                    )
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
                    L10n.controlsCustom,
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
                            if let components = newColor.cgColor?.components,
                               components.count >= 3 {
                                let red = UInt8(min(max(components[0] * 255, 0), 255))
                                let green = UInt8(min(max(components[1] * 255, 0), 255))
                                let blue = UInt8(min(max(components[2] * 255, 0), 255))
                                feature.send(
                                    .controls(.setCustomColor(
                                        LEDColor(red: red, green: green, blue: blue)
                                    ))
                                )
                            }
                        }
                    ),
                    supportsOpacity: false
                )
                .font(.caption)
                .opacity(state.colorEffect == .colorLoop ? 0.4 : 1.0)

                Spacer()

                Toggle(
                    L10n.controlsColorLoop,
                    isOn: Binding(
                        get: { state.colorEffect == .colorLoop },
                        set: { isOn in
                            feature.send(
                                .controls(.setColorEffect(isOn ? .colorLoop : .staticColor))
                            )
                        }
                    )
                )
                .toggleStyle(.switch)
                .controlSize(.small)
                .font(.caption)
            }
        }
    }

    var brightnessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.controlsBrightness)
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
                    L10n.controlsBody,
                    isOn: Binding(
                        get: { state.bodyLightOn },
                        set: { _ in feature.send(.controls(.toggleBodyLight)) }
                    )
                )
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(state.lightScheduleActive)

                Toggle(
                    L10n.controlsProjection,
                    isOn: Binding(
                        get: { state.projectionOn },
                        set: { _ in feature.send(.controls(.toggleProjection)) }
                    )
                )
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(state.lightScheduleActive)
            }
            .font(.caption)
            .frame(maxWidth: .infinity)

            if state.lightScheduleActive {
                Text(L10n.controlsScheduleActive)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var speedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.controlsAnimationSpeed)
                .font(.headline)

            Picker(L10n.controlsSpeed, selection: Binding(
                get: { state.speed },
                set: { feature.send(.controls(.setSpeed($0))) }
            )) {
                Text(L10n.controlsSpeedLow).tag(UInt8(1))
                Text(L10n.controlsSpeedMid).tag(UInt8(2))
                Text(L10n.controlsSpeedHigh).tag(UInt8(3))
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }
}

// MARK: - Shared

extension PulseMenuView {

    func errorSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)

            Button(L10n.generalDismiss) {
                feature.send(.system(.dismissError))
            }
            .buttonStyle(.plain)
            .font(.caption2)
        }
    }

    var quitButton: some View {
        Button(L10n.generalQuit) {
            NSApplication.shared.terminate(nil)
        }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
    }

    func themeColor(_ theme: LEDTheme) -> Color {
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

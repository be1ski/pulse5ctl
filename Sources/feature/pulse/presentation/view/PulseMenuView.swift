import AppKit
import CoreLocalization
import FeaturePulseDomain
import SwiftUI

public struct PulseMenuView: View {
    @ObservedObject var feature: PulseFeature
    let onSettingsTapped: () -> Void

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

    var state: PulseState {
        feature.state
    }

    // MARK: - Connected

    var connectedContent: some View {
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

    var connectedHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "hifispeaker.fill")
                .font(.title2)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.generalConnected)
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
                Button(L10n.generalDisconnect) {
                    feature.send(.connection(.disconnectTapped))
                }
                Divider()
                Button(L10n.generalQuit) {
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

    var themesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.controlsThemes)
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

    func patternsSection(theme: LEDTheme) -> some View {
        let activeSet = state.activePatternsForTheme(theme)

        return VStack(alignment: .leading, spacing: 8) {
            Text(L10n.controlsPatterns)
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

}

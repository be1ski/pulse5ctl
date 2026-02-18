import FeaturePulseDomain
import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var feature: PulseFeature
    private let onBack: () -> Void

    public init(feature: PulseFeature, onBack: @escaping () -> Void) {
        self.feature = feature
        self.onBack = onBack
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.plain)

                Text("Settings")
                    .font(.headline)

                Spacer()
            }

            HStack {
                Text("Auto Theme")
                Spacer()
                Toggle(
                    "",
                    isOn: Binding(
                        get: { feature.state.autoThemeSettings.enabled },
                        set: { _ in feature.send(.autoTheme(.toggleEnabled)) }
                    )
                )
                .toggleStyle(.switch)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("When music plays:")
                    .font(.subheadline)
                    .foregroundStyle(isEnabled ? .primary : .secondary)

                Picker("Playing theme", selection: Binding(
                    get: { feature.state.autoThemeSettings.playingTheme },
                    set: { feature.send(.autoTheme(.setPlayingTheme($0))) }
                )) {
                    ForEach(LEDTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .labelsHidden()
                .disabled(!isEnabled)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("When idle:")
                    .font(.subheadline)
                    .foregroundStyle(isEnabled ? .primary : .secondary)

                Picker("Idle theme", selection: Binding(
                    get: { feature.state.autoThemeSettings.idleTheme },
                    set: { feature.send(.autoTheme(.setIdleTheme($0))) }
                )) {
                    ForEach(LEDTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .labelsHidden()
                .disabled(!isEnabled)
            }
        }
        .padding(16)
        .frame(width: 340)
    }

    private var isEnabled: Bool {
        feature.state.autoThemeSettings.enabled
    }
}

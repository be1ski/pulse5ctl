import CoreLocalization
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

                Text(L10n.settingsTitle)
                    .font(.headline)

                Spacer()
            }

            HStack {
                Text(L10n.settingsAutoTheme)
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
                Text(L10n.settingsWhenMusicPlays)
                    .font(.subheadline)
                    .foregroundStyle(isEnabled ? .primary : .secondary)

                Picker(L10n.settingsPlayingTheme, selection: Binding(
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
                Text(L10n.settingsWhenIdle)
                    .font(.subheadline)
                    .foregroundStyle(isEnabled ? .primary : .secondary)

                Picker(L10n.settingsIdleTheme, selection: Binding(
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

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.settingsLanguage)
                    .font(.subheadline)

                Picker(L10n.settingsLanguage, selection: Binding(
                    get: { feature.state.selectedLanguage ?? "" },
                    set: { feature.send(.settings(.setLanguage($0.isEmpty ? nil : $0))) }
                )) {
                    Text(L10n.settingsLanguageSystem).tag("")
                    Divider()
                    ForEach(L10n.supportedLocales, id: \.self) { code in
                        Text(Self.autonym(for: code)).tag(code)
                    }
                }
                .labelsHidden()
            }
        }
        .padding(16)
        .frame(width: 340)
    }

    private var isEnabled: Bool {
        feature.state.autoThemeSettings.enabled
    }

    private static func autonym(for code: String) -> String {
        let locale = Locale(identifier: code)
        return locale.localizedString(forIdentifier: code)?.localizedCapitalized ?? code
    }
}

import FeaturePulsePresentation
import SwiftUI

public struct AppRoot: View {
    private let dependencies: AppDependencies
    @State private var showSettings = false

    public init(_ dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    public var body: some View {
        if showSettings {
            SettingsView(feature: dependencies.pulseFeature, onBack: { showSettings = false })
        } else {
            PulseMenuView(feature: dependencies.pulseFeature, onSettingsTapped: { showSettings = true })
        }
    }
}

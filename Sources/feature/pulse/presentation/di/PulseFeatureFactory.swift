import CoreLocalization
import FeaturePulseDomain
import Foundation

public enum PulseFeatureFactory {
    @MainActor
    public static func create(dependencies: PulseDependencies) -> PulseFeature {
        let autoThemeSettings = dependencies.loadAutoThemeSettings()
        let ledCustomization = dependencies.loadLedCustomization()
        let lightScheduleSettings = dependencies.loadLightScheduleSettings()
        let savedLanguage = dependencies.loadLanguage()
        L10n.overrideLocale = savedLanguage

        let effectHandler = PulseEffectHandler(
            observePulseEvents: dependencies.observePulseEvents,
            startPulseScan: dependencies.startPulseScan,
            connectPulseSpeaker: dependencies.connectPulseSpeaker,
            disconnectPulseSpeaker: dependencies.disconnectPulseSpeaker,
            setPulseTheme: dependencies.setPulseTheme,
            setPulseLightStatus: dependencies.setPulseLightStatus,
            setPulseBrightness: dependencies.setPulseBrightness,
            setPulseSpeed: dependencies.setPulseSpeed,
            setPulseLedPackage: dependencies.setPulseLedPackage,
            requestPulseState: dependencies.requestPulseState,
            observeNowPlaying: dependencies.observeNowPlaying,
            observeLightSchedule: dependencies.observeLightSchedule,
            saveAutoThemeSettings: dependencies.saveAutoThemeSettings,
            saveLedCustomization: dependencies.saveLedCustomization,
            saveLightScheduleSettings: dependencies.saveLightScheduleSettings,
            saveLanguage: dependencies.saveLanguage
        )

        let hasCachedPeripheral = UserDefaults.standard.string(forKey: "lastPeripheralUUID") != nil
        let initialConnectionState: ConnectionState = hasCachedPeripheral ? .connecting : .disconnected

        let feature = PulseFeature(
            initialState: PulseState(
                connectionState: initialConnectionState,
                autoThemeSettings: autoThemeSettings,
                activePatterns: ledCustomization.activePatternsMap(),
                colorEffect: ledCustomization.colorEffect,
                customColor: ledCustomization.customColor,
                selectedLanguage: savedLanguage,
                lightScheduleSettings: lightScheduleSettings
            ),
            reducer: pulseReducer,
            effectHandler: effectHandler.handle
        )

        feature.launch()
        return feature
    }
}

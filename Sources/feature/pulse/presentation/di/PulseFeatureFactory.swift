import FeaturePulseDomain

public enum PulseFeatureFactory {
    @MainActor
    public static func create(dependencies: PulseDependencies) -> PulseFeature {
        let snapshot = dependencies.loadPulseSnapshot()
        let autoThemeSettings = dependencies.loadAutoThemeSettings()
        let ledCustomization = dependencies.loadLedCustomization()

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
            saveAutoThemeSettings: dependencies.saveAutoThemeSettings,
            saveLedCustomization: dependencies.saveLedCustomization
        )

        let feature = PulseFeature(
            initialState: PulseState(
                connectionState: snapshot.connectionState,
                discoveredDevices: [],
                brightness: snapshot.brightness,
                bodyLightOn: snapshot.bodyLightOn,
                projectionOn: snapshot.projectionOn,
                lightOn: snapshot.lightOn,
                speed: snapshot.speed,
                selectedTheme: snapshot.selectedTheme,
                errorMessage: nil,
                isObservingRepository: false,
                autoThemeSettings: autoThemeSettings,
                activePatterns: ledCustomization.activePatternsMap(),
                colorEffect: ledCustomization.colorEffect,
                customColor: ledCustomization.customColor
            ),
            reducer: pulseReducer,
            effectHandler: effectHandler.handle
        )

        feature.launch()
        return feature
    }
}

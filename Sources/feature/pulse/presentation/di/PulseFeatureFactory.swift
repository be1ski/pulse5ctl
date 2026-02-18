public enum PulseFeatureFactory {
    @MainActor
    public static func create(dependencies: PulseDependencies) -> PulseFeature {
        let snapshot = dependencies.loadPulseSnapshot()
        let autoThemeSettings = dependencies.loadAutoThemeSettings()

        let effectHandler = PulseEffectHandler(
            observePulseEvents: dependencies.observePulseEvents,
            startPulseScan: dependencies.startPulseScan,
            connectPulseSpeaker: dependencies.connectPulseSpeaker,
            disconnectPulseSpeaker: dependencies.disconnectPulseSpeaker,
            setPulseTheme: dependencies.setPulseTheme,
            setPulseLightStatus: dependencies.setPulseLightStatus,
            setPulseBrightness: dependencies.setPulseBrightness,
            setPulseSpeed: dependencies.setPulseSpeed,
            requestPulseState: dependencies.requestPulseState,
            observeNowPlaying: dependencies.observeNowPlaying,
            saveAutoThemeSettings: dependencies.saveAutoThemeSettings
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
                autoThemeSettings: autoThemeSettings
            ),
            reducer: pulseReducer,
            effectHandler: effectHandler.handle
        )

        feature.launch()
        return feature
    }
}

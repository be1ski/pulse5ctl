public struct PulseSpeakerSnapshot: Equatable {
    public var connectionState: ConnectionState
    public var brightness: UInt8
    public var bodyLightOn: Bool
    public var projectionOn: Bool
    public var lightOn: Bool
    public var speed: UInt8
    public var selectedTheme: LEDTheme?

    public init(
        connectionState: ConnectionState = .disconnected,
        brightness: UInt8 = 50,
        bodyLightOn: Bool = true,
        projectionOn: Bool = true,
        lightOn: Bool = true,
        speed: UInt8 = 2,
        selectedTheme: LEDTheme? = nil
    ) {
        self.connectionState = connectionState
        self.brightness = brightness
        self.bodyLightOn = bodyLightOn
        self.projectionOn = projectionOn
        self.lightOn = lightOn
        self.speed = speed
        self.selectedTheme = selectedTheme
    }
}

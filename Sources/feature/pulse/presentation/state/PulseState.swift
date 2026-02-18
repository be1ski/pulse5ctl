import FeaturePulseDomain

public struct PulseState: Equatable {
    public var connectionState: ConnectionState = .disconnected
    public var discoveredDevices: [DiscoveredDevice] = []
    public var brightness: UInt8 = 50
    public var bodyLightOn = true
    public var projectionOn = true
    public var lightOn = true
    public var speed: UInt8 = 2
    public var selectedTheme: LEDTheme?
    public var errorMessage: String?
    public var isObservingRepository = false
    public var connectedDeviceName: String?
    public var autoThemeSettings: AutoThemeSettings = .init()
    public var isMusicPlaying: Bool = false

    public init(
        connectionState: ConnectionState = .disconnected,
        discoveredDevices: [DiscoveredDevice] = [],
        brightness: UInt8 = 50,
        bodyLightOn: Bool = true,
        projectionOn: Bool = true,
        lightOn: Bool = true,
        speed: UInt8 = 2,
        selectedTheme: LEDTheme? = nil,
        errorMessage: String? = nil,
        isObservingRepository: Bool = false,
        connectedDeviceName: String? = nil,
        autoThemeSettings: AutoThemeSettings = .init(),
        isMusicPlaying: Bool = false
    ) {
        self.connectionState = connectionState
        self.discoveredDevices = discoveredDevices
        self.brightness = brightness
        self.bodyLightOn = bodyLightOn
        self.projectionOn = projectionOn
        self.lightOn = lightOn
        self.speed = speed
        self.selectedTheme = selectedTheme
        self.errorMessage = errorMessage
        self.isObservingRepository = isObservingRepository
        self.connectedDeviceName = connectedDeviceName
        self.autoThemeSettings = autoThemeSettings
        self.isMusicPlaying = isMusicPlaying
    }

    public var canShowControls: Bool {
        connectionState.isConnected
    }
}

public struct AutoThemeSettings: Equatable, Codable, Sendable {
    public var enabled: Bool
    public var playingTheme: LEDTheme
    public var idleTheme: LEDTheme

    public init(
        enabled: Bool = false,
        playingTheme: LEDTheme = .party,
        idleTheme: LEDTheme = .nature
    ) {
        self.enabled = enabled
        self.playingTheme = playingTheme
        self.idleTheme = idleTheme
    }
}

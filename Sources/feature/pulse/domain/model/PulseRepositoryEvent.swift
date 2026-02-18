public enum PulseRepositoryEvent: Equatable {
    case connectionChanged(ConnectionState)
    case discoveredDevices([DiscoveredDevice])
    case lightStatus(Bool)
    case brightness(level: UInt8, bodyLight: Bool, projection: Bool)
    case speed(UInt8)
    case theme(LEDTheme?)
    case error(String)
}

public struct LEDColor: Equatable, Codable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public enum ColorEffect: UInt8, Equatable, Codable {
    case staticColor = 0
    case colorLoop = 1
}

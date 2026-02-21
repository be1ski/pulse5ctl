public struct LightScheduleSettings: Equatable, Codable {
    public var enabled: Bool
    public var offHour: Int
    public var offMinute: Int
    public var onHour: Int
    public var onMinute: Int

    public init(
        enabled: Bool = false,
        offHour: Int = 2,
        offMinute: Int = 0,
        onHour: Int = 10,
        onMinute: Int = 0
    ) {
        self.enabled = enabled
        self.offHour = offHour
        self.offMinute = offMinute
        self.onHour = onHour
        self.onMinute = onMinute
    }
}

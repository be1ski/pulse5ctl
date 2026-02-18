import Foundation

public struct DiscoveredDevice: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let rssi: Int
    public let hasPulseService: Bool

    public init(id: UUID, name: String, rssi: Int, hasPulseService: Bool) {
        self.id = id
        self.name = name
        self.rssi = rssi
        self.hasPulseService = hasPulseService
    }
}

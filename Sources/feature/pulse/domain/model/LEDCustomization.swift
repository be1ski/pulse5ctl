public struct LEDCustomization: Codable, Equatable {
    public var activePatterns: [UInt8: [UInt8]]
    public var colorEffect: ColorEffect
    public var customColor: LEDColor

    public init(
        activePatterns: [UInt8: [UInt8]] = [:],
        colorEffect: ColorEffect = .colorLoop,
        customColor: LEDColor = LEDColor(red: 0xFF, green: 0xFF, blue: 0xFF)
    ) {
        self.activePatterns = activePatterns
        self.colorEffect = colorEffect
        self.customColor = customColor
    }

    public func activePatternsMap() -> [LEDTheme: Set<LEDPattern>] {
        var result: [LEDTheme: Set<LEDPattern>] = [:]
        for (themeRaw, patternRaws) in activePatterns {
            guard let theme = LEDTheme(rawValue: themeRaw) else { continue }
            let patterns = Set(patternRaws.compactMap { LEDPattern(rawValue: $0) })
            if !patterns.isEmpty {
                result[theme] = patterns
            }
        }
        return result
    }

    public static func from(
        activePatterns: [LEDTheme: Set<LEDPattern>],
        colorEffect: ColorEffect,
        customColor: LEDColor
    ) -> LEDCustomization {
        var raw: [UInt8: [UInt8]] = [:]
        for (theme, patterns) in activePatterns {
            raw[theme.rawValue] = patterns.map(\.rawValue).sorted()
        }
        return LEDCustomization(activePatterns: raw, colorEffect: colorEffect, customColor: customColor)
    }
}

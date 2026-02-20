import Foundation

public enum L10n {
    // MARK: - Locale Override

    public static let supportedLocales: [String] = [
        "ar", "az", "be", "de", "en", "es", "fr", "hi", "ja",
        "ka", "kk", "ky", "pt-BR", "ro", "ru", "tg", "tk", "uk", "uz", "zh-Hans"
    ]

    public static var overrideLocale: String? {
        didSet {
            guard let code = overrideLocale else {
                _overrideBundle = nil
                return
            }
            // SwiftPM lowercases lproj folder names, so match case-insensitively
            let matched = Bundle.module.localizations.first {
                $0.caseInsensitiveCompare(code) == .orderedSame
            }
            if let matched,
               let path = Bundle.module.path(forResource: matched, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                _overrideBundle = bundle
            } else {
                _overrideBundle = nil
            }
        }
    }

    private static var _overrideBundle: Bundle?

    // MARK: - General

    public static var generalCancel: String { str("general.cancel") }
    public static var generalConnect: String { str("general.connect") }
    public static var generalConnected: String { str("general.connected") }
    public static var generalDisconnect: String { str("general.disconnect") }
    public static var generalQuit: String { str("general.quit") }
    public static var generalDismiss: String { str("general.dismiss") }

    // MARK: - Hero

    public static var heroTitle: String { str("hero.title") }
    public static var heroSubtitle: String { str("hero.subtitle") }
    public static var heroScanButton: String { str("hero.scan_button") }
    public static var heroSearching: String { str("hero.searching") }

    // MARK: - Controls

    public static var controlsThemes: String { str("controls.themes") }
    public static var controlsPatterns: String { str("controls.patterns") }
    public static var controlsColor: String { str("controls.color") }
    public static var controlsCustom: String { str("controls.custom") }
    public static var controlsColorLoop: String { str("controls.color_loop") }
    public static var controlsBrightness: String { str("controls.brightness") }
    public static var controlsBody: String { str("controls.body") }
    public static var controlsProjection: String { str("controls.projection") }
    public static var controlsAnimationSpeed: String { str("controls.animation_speed") }
    public static var controlsSpeed: String { str("controls.speed") }
    public static var controlsSpeedLow: String { str("controls.speed_low") }
    public static var controlsSpeedMid: String { str("controls.speed_mid") }
    public static var controlsSpeedHigh: String { str("controls.speed_high") }
    public static var controlsScheduleActive: String { str("controls.schedule_active") }

    // MARK: - Settings

    public static var settingsTitle: String { str("settings.title") }
    public static var settingsAutoTheme: String { str("settings.auto_theme") }
    public static var settingsWhenMusicPlays: String { str("settings.when_music_plays") }
    public static var settingsPlayingTheme: String { str("settings.playing_theme") }
    public static var settingsWhenIdle: String { str("settings.when_idle") }
    public static var settingsIdleTheme: String { str("settings.idle_theme") }
    public static var settingsLightSchedule: String { str("settings.light_schedule") }
    public static var settingsLightsOffAt: String { str("settings.lights_off_at") }
    public static var settingsLightsOnAt: String { str("settings.lights_on_at") }
    public static var settingsLanguage: String { str("settings.language") }
    public static var settingsLanguageSystem: String { str("settings.language_system") }

    // MARK: - Color

    public static var colorRed: String { str("color.red") }
    public static var colorOrange: String { str("color.orange") }
    public static var colorYellow: String { str("color.yellow") }
    public static var colorGreen: String { str("color.green") }
    public static var colorCyan: String { str("color.cyan") }
    public static var colorBlue: String { str("color.blue") }
    public static var colorPurple: String { str("color.purple") }
    public static var colorPink: String { str("color.pink") }
    public static var colorWhite: String { str("color.white") }

    // MARK: - Theme

    public static var themeNature: String { str("theme.nature") }
    public static var themeParty: String { str("theme.party") }
    public static var themeSpiritual: String { str("theme.spiritual") }
    public static var themeCocktail: String { str("theme.cocktail") }
    public static var themeWeather: String { str("theme.weather") }
    public static var themeCanvas: String { str("theme.canvas") }

    // MARK: - Pattern

    public static var patternCampfire: String { str("pattern.campfire") }
    public static var patternNorthernLights: String { str("pattern.northern_lights") }
    public static var patternSeaWave: String { str("pattern.sea_wave") }
    public static var patternUniverse: String { str("pattern.universe") }
    public static var patternStrobe: String { str("pattern.strobe") }
    public static var patternEqualizer: String { str("pattern.equalizer") }
    public static var patternGeometry: String { str("pattern.geometry") }
    public static var patternSpin: String { str("pattern.spin") }
    public static var patternRainbow: String { str("pattern.rainbow") }
    public static var patternDynamicWave: String { str("pattern.dynamic_wave") }
    public static var patternLava: String { str("pattern.lava") }
    public static var patternFocus: String { str("pattern.focus") }
    public static var patternSkySunny: String { str("pattern.sky_sunny") }
    public static var patternRain: String { str("pattern.rain") }
    public static var patternSnow: String { str("pattern.snow") }
    public static var patternThunder: String { str("pattern.thunder") }
    public static var patternCloud: String { str("pattern.cloud") }
    public static var patternFruitGin: String { str("pattern.fruit_gin") }
    public static var patternMojito: String { str("pattern.mojito") }
    public static var patternTequila: String { str("pattern.tequila") }
    public static var patternCherry: String { str("pattern.cherry") }

    // MARK: - State

    public static var stateDisconnected: String { str("state.disconnected") }
    public static var stateScanning: String { str("state.scanning") }
    public static var stateConnecting: String { str("state.connecting") }
    public static var stateDiscoveringServices: String { str("state.discovering_services") }
    public static var stateConnected: String { str("state.connected") }

    public static func stateReconnecting(_ attempt: Int) -> String {
        String(format: str("state.reconnecting"), attempt)
    }

    // MARK: - Error

    public static var errorPoweredOff: String { str("error.powered_off") }
    public static var errorUnauthorized: String { str("error.unauthorized") }
    public static var errorUnsupported: String { str("error.unsupported") }
    public static var errorServiceNotFound: String { str("error.service_not_found") }
    public static var errorCharacteristicNotFound: String { str("error.characteristic_not_found") }

    public static func errorConnectionFailed(_ reason: String) -> String {
        String(format: str("error.connection_failed"), reason)
    }

    public static func errorWriteFailed(_ reason: String) -> String {
        String(format: str("error.write_failed"), reason)
    }

    public static var errorDisconnected: String { str("error.disconnected") }
    public static var errorUnknownDevice: String { str("error.unknown_device") }

    // MARK: - Format

    public static func formatRSSI(_ value: Int) -> String {
        String(format: str("format.rssi"), value)
    }

    // MARK: - Private

    private static func str(_ key: String) -> String {
        (_overrideBundle ?? Bundle.module).localizedString(forKey: key, value: nil, table: nil)
    }
}

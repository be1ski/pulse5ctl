import CoreElm
import FeaturePulseDomain

func pulseControlsReducer(
    _ action: PulseAction.Controls,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch action {
    case .toggleLight:
        let toggled = !state.lightOn
        context.state { current in
            var updated = current
            updated.lightOn = toggled
            return updated
        }
        context.command(.setLight(toggled))

    case let .selectTheme(theme):
        context.state { current in
            var updated = current
            updated.selectedTheme = theme
            return updated
        }
        context.command(.setTheme(theme))

    case let .setBrightness(value):
        let clamped = clampBrightness(value)
        context.state { current in
            var updated = current
            updated.brightness = clamped
            return updated
        }
        context.command(.setBrightness(level: clamped, bodyLight: state.bodyLightOn, projection: state.projectionOn))

    case .toggleBodyLight:
        guard !state.lightScheduleActive else { return }
        let toggled = !state.bodyLightOn
        context.state { current in
            var updated = current
            updated.bodyLightOn = toggled
            return updated
        }
        context.command(.setBrightness(level: state.brightness, bodyLight: toggled, projection: state.projectionOn))

    case .toggleProjection:
        guard !state.lightScheduleActive else { return }
        let toggled = !state.projectionOn
        context.state { current in
            var updated = current
            updated.projectionOn = toggled
            return updated
        }
        context.command(.setBrightness(level: state.brightness, bodyLight: state.bodyLightOn, projection: toggled))

    case let .setSpeed(speed):
        context.state { current in
            var updated = current
            updated.speed = speed
            return updated
        }
        context.command(.setSpeed(speed))

    case let .togglePattern(pattern, theme):
        let current = state.activePatternsForTheme(theme)
        if current.contains(pattern) && current.count <= 1 { return }

        let updated: Set<LEDPattern>
        if current.contains(pattern) {
            updated = current.subtracting([pattern])
        } else {
            updated = current.union([pattern])
        }

        context.state { current in
            var s = current
            s.activePatterns[theme] = updated
            return s
        }
        emitLedPackage(for: theme, activeOverride: updated, state: state, context: context)
        emitSaveCustomization(activeOverride: (theme, updated), state: state, context: context)

    case let .soloPattern(pattern, theme):
        let updated: Set<LEDPattern> = [pattern]
        context.state { current in
            var s = current
            s.activePatterns[theme] = updated
            return s
        }
        emitLedPackage(for: theme, activeOverride: updated, state: state, context: context)
        emitSaveCustomization(activeOverride: (theme, updated), state: state, context: context)

    case let .setCustomColor(color):
        context.state { current in
            var updated = current
            updated.customColor = color
            return updated
        }
        if let theme = state.selectedTheme {
            emitLedPackage(for: theme, colorOverride: color, state: state, context: context)
        }
        emitSaveCustomization(colorOverride: color, state: state, context: context)

    case let .setColorEffect(effect):
        context.state { current in
            var updated = current
            updated.colorEffect = effect
            return updated
        }
        if let theme = state.selectedTheme {
            emitLedPackage(for: theme, colorEffectOverride: effect, state: state, context: context)
        }
        emitSaveCustomization(colorEffectOverride: effect, state: state, context: context)
    }
}

private func emitLedPackage(
    for theme: LEDTheme,
    activeOverride: Set<LEDPattern>? = nil,
    colorOverride: LEDColor? = nil,
    colorEffectOverride: ColorEffect? = nil,
    state: PulseState,
    context: ReducerContext<PulseState, PulseEffect, Never>
) {
    let allThemePatterns = theme.patterns
    let activeSet = activeOverride ?? state.activePatternsForTheme(theme)
    let colorEffect = colorEffectOverride ?? state.colorEffect
    let color = colorOverride ?? state.customColor

    let active = allThemePatterns.filter { activeSet.contains($0) }
    let inactive = allThemePatterns.filter { !activeSet.contains($0) }
    let allOrdered = active + inactive

    context.command(.setLedPackage(
        theme: theme,
        activePatterns: active,
        allPatterns: allOrdered,
        colorEffect: colorEffect,
        color: color
    ))
}

private func emitSaveCustomization(
    activeOverride: (LEDTheme, Set<LEDPattern>)? = nil,
    colorOverride: LEDColor? = nil,
    colorEffectOverride: ColorEffect? = nil,
    state: PulseState,
    context: ReducerContext<PulseState, PulseEffect, Never>
) {
    var patterns = state.activePatterns
    if let (theme, active) = activeOverride {
        patterns[theme] = active
    }
    let colorEffect = colorEffectOverride ?? state.colorEffect
    let color = colorOverride ?? state.customColor

    context.command(.saveLedCustomization(
        LEDCustomization.from(activePatterns: patterns, colorEffect: colorEffect, customColor: color)
    ))
}

private func clampBrightness(_ value: Double) -> UInt8 {
    let clamped = min(max(value, 20), 80)
    return UInt8(clamped.rounded())
}

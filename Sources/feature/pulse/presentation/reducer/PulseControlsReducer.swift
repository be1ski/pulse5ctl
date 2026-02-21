import CoreElm
import FeaturePulseDomain

func pulseControlsReducer(
    _ action: PulseAction.Controls,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch action {
    case .toggleLight:
        handleToggleLight(state, context)
    case let .selectTheme(theme):
        handleSelectTheme(theme, state, context)
    case let .setBrightness(value):
        handleSetBrightness(value, state, context)
    case .toggleBodyLight:
        handleToggleBodyLight(state, context)
    case .toggleProjection:
        handleToggleProjection(state, context)
    case let .setSpeed(speed):
        handleSetSpeed(speed, context)
    case let .togglePattern(pattern, theme):
        handleTogglePattern(pattern, theme, state, context)
    case let .soloPattern(pattern, theme):
        handleSoloPattern(pattern, theme, state, context)
    case let .setCustomColor(color):
        handleSetCustomColor(color, state, context)
    case let .setColorEffect(effect):
        handleSetColorEffect(effect, state, context)
    }
}

private func handleToggleLight(
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    let toggled = !state.lightOn
    context.state {
        $0.lightOn = toggled
    }
    context.command(.setLight(toggled))
}

private func handleSelectTheme(
    _ theme: LEDTheme,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    context.state {
        $0.selectedTheme = theme
    }
    context.command(.setTheme(theme))
}

private func handleSetBrightness(
    _ value: Double,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    let clamped = clampBrightness(value)
    context.state {
        $0.brightness = clamped
    }
    context.command(.setBrightness(level: clamped, bodyLight: state.bodyLightOn, projection: state.projectionOn))
}

private func handleToggleBodyLight(
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    guard !state.lightScheduleActive else { return }
    let toggled = !state.bodyLightOn
    context.state {
        $0.bodyLightOn = toggled
    }
    context.command(.setBrightness(level: state.brightness, bodyLight: toggled, projection: state.projectionOn))
}

private func handleToggleProjection(
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    guard !state.lightScheduleActive else { return }
    let toggled = !state.projectionOn
    context.state {
        $0.projectionOn = toggled
    }
    context.command(.setBrightness(level: state.brightness, bodyLight: state.bodyLightOn, projection: toggled))
}

private func handleSetSpeed(
    _ speed: UInt8,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    context.state {
        $0.speed = speed
    }
    context.command(.setSpeed(speed))
}

private func handleTogglePattern(
    _ pattern: LEDPattern,
    _ theme: LEDTheme,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    let activeSet = state.activePatternsForTheme(theme)
    if activeSet.contains(pattern) && activeSet.count <= 1 { return }

    let updated: Set<LEDPattern>
    if activeSet.contains(pattern) {
        updated = activeSet.subtracting([pattern])
    } else {
        updated = activeSet.union([pattern])
    }

    context.state {
        $0.activePatterns[theme] = updated
    }
    emitLedPackage(for: theme, activeOverride: updated, state: state, context: context)
    emitSaveCustomization(activeOverride: (theme, updated), state: state, context: context)
}

private func handleSoloPattern(
    _ pattern: LEDPattern,
    _ theme: LEDTheme,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    let updated: Set<LEDPattern> = [pattern]
    context.state {
        $0.activePatterns[theme] = updated
    }
    emitLedPackage(for: theme, activeOverride: updated, state: state, context: context)
    emitSaveCustomization(activeOverride: (theme, updated), state: state, context: context)
}

private func handleSetCustomColor(
    _ color: LEDColor,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    context.state {
        $0.customColor = color
    }
    if let theme = state.selectedTheme {
        emitLedPackage(for: theme, colorOverride: color, state: state, context: context)
    }
    emitSaveCustomization(colorOverride: color, state: state, context: context)
}

private func handleSetColorEffect(
    _ effect: ColorEffect,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    context.state {
        $0.colorEffect = effect
    }
    if let theme = state.selectedTheme {
        emitLedPackage(for: theme, colorEffectOverride: effect, state: state, context: context)
    }
    emitSaveCustomization(colorEffectOverride: effect, state: state, context: context)
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

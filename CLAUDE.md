# pulse5ctl

Pulse 5 speaker controller — macOS menu bar app (Swift) + CLI (Python).

## Project Structure

```
Sources/
  core/elm/           — CoreElm framework (Reducer, Feature, Effects, FlowHelpers)
  core/platform/      — Platform abstractions
  core/localization/  — L10n strings + resources
  feature/pulse/
    domain/           — Models, repository protocol, use cases
    data/             — PulseProtocol, schedule monitor
    data/platform/    — Untestable: BluetoothManager, NowPlaying, repository impl
    presentation/     — Reducers, state, actions, effects, effect handler
  feature/homescreen/ — DI wiring, SwiftUI views
  app/macos/          — App entry point, menu bar controller
cli/                  — Python CLI (separate package)
Tests/                — Swift test targets
```

## Module Dependencies

```
app → FeatureHomescreen → FeaturePulseData + FeaturePulsePresentation
FeaturePulsePresentation → CoreElm + FeaturePulseDomain
FeaturePulseData → FeaturePulseDomain
FeaturePulseDomain → CorePlatform + CoreLocalization
```

Test targets may depend on any source target. Use `@testable import` for internal access.

## Testing

- **TDD**: Write tests before or alongside implementation
- **Naming**: `test_unitOfWork_condition_expectedBehavior` (underscore-separated, enforced by SwiftLint)
- **Pattern**: Reducers tested via `ReducerContext.result(initialState:)` — needs `@testable import CoreElm`
- **Coverage target**: 90% on testable code
- **Excluded from coverage**: views, DI/wiring, constants, platform-specific code (CoreBluetooth, CoreAudio)

## Verification

```bash
make checkAll          # Runs all Swift tests + Python lint + Python tests
make installGitHooks   # Installs pre-commit hook that runs checkAll
swift test             # Swift tests only
```

## Git & GitHub

- **Always `git fetch origin` before starting work** — rebase onto latest `origin/main` before creating branches or committing
- PR descriptions are always written in English
- The device is referred to as "Pulse 5" everywhere — code, docs, commits, PR descriptions
- Commit messages: short summary line, optional 1–2 sentence body max — no essays

## Key Conventions

- Reducers are pure functions: `(Action, State, ReducerContext) -> Void`
- Elm architecture: unidirectional data flow (Action → Reducer → State + Effects)
- Effects are handled by `PulseEffectHandler`, which maps `PulseEffect → AsyncStream<PulseAction>`
- BluetoothManager exposes AsyncStream-based API (no delegates)
- State lives in reducers; data layer is stateless streams

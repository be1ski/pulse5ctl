public struct Effects<Command, Notification> {
    public let commands: [Command]
    public let notifications: [Notification]

    public init(commands: [Command] = [], notifications: [Notification] = []) {
        self.commands = commands
        self.notifications = notifications
    }
}

public struct ReducerResult<State, Command, Notification> {
    public let state: State
    public let effects: Effects<Command, Notification>

    public init(state: State, effects: Effects<Command, Notification>) {
        self.state = state
        self.effects = effects
    }
}

public typealias Reducer<Action, State, Command, Notification> =
    (_ action: Action, _ state: State) -> ReducerResult<State, Command, Notification>

public typealias EffectHandler<Command, Action> = (_ command: Command) -> AsyncStream<Action>

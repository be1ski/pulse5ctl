public final class ReducerContext<State, Command, Notification> {
    private var stateUpdate: ((State) -> State)?
    private var commands: [Command] = []
    private var notifications: [Notification] = []

    public init() {}

    public func state(_ transform: @escaping (State) -> State) {
        let previous = stateUpdate
        stateUpdate = { current in
            transform(previous?(current) ?? current)
        }
    }

    public func state(_ mutate: @escaping (inout State) -> Void) {
        let previous = stateUpdate
        stateUpdate = { current in
            var copy = previous?(current) ?? current
            mutate(&copy)
            return copy
        }
    }

    public func state(_ newState: State) {
        stateUpdate = { _ in newState }
    }

    public func command(_ command: Command) {
        commands.append(command)
    }

    public func commands(_ commands: Command...) {
        self.commands.append(contentsOf: commands)
    }

    public func commands(_ commands: [Command]) {
        self.commands.append(contentsOf: commands)
    }

    public func notify(_ notification: Notification) {
        notifications.append(notification)
    }

    public func notifications(_ notifications: Notification...) {
        self.notifications.append(contentsOf: notifications)
    }

    internal func result(initialState: State) -> ReducerResult<State, Command, Notification> {
        ReducerResult(
            state: stateUpdate?(initialState) ?? initialState,
            effects: Effects(commands: commands, notifications: notifications)
        )
    }
}

public func reducer<Action, State, Command, Notification>(
    _ reduce: @escaping (
        _ action: Action, _ state: State, _ context: ReducerContext<State, Command, Notification>
    ) -> Void
) -> Reducer<Action, State, Command, Notification> {
    { action, state in
        let context = ReducerContext<State, Command, Notification>()
        reduce(action, state, context)
        return context.result(initialState: state)
    }
}

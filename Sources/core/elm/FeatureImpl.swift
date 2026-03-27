import Foundation

@MainActor
public final class Feature<Action, State, Command, Notification>: ObservableObject
where Action: ElmAction, Notification: Sendable {
    @Published public private(set) var state: State
    public var notifications: AsyncStream<Notification> { notificationStream }

    private let reducer: Reducer<Action, State, Command, Notification>
    private let effectHandler: EffectHandler<Command, Action>
    private let initialCommands: [Command]

    private var hasLaunched = false
    private var actionQueue: [Action] = []
    private var isProcessingQueue = false
    private var commandTasks: [Task<Void, Never>] = []

    private let notificationStream: AsyncStream<Notification>
    private let notificationContinuation: AsyncStream<Notification>.Continuation

    public init(
        initialState: State,
        reducer: @escaping Reducer<Action, State, Command, Notification>,
        effectHandler: @escaping EffectHandler<Command, Action>,
        initialCommands: [Command] = []
    ) {
        self.state = initialState
        self.reducer = reducer
        self.effectHandler = effectHandler
        self.initialCommands = initialCommands

        var continuation: AsyncStream<Notification>.Continuation?
        self.notificationStream = AsyncStream { inner in
            continuation = inner
        }
        self.notificationContinuation = continuation!
    }

    public func launch() {
        guard !hasLaunched else { return }
        hasLaunched = true
        initialCommands.forEach(enqueueCommand)
    }

    public func send(_ action: Action) {
        actionQueue.append(action)
        processQueueIfNeeded()
    }

    private func processQueueIfNeeded() {
        guard !isProcessingQueue else { return }
        isProcessingQueue = true

        while !actionQueue.isEmpty {
            let next = actionQueue.removeFirst()
            dispatch(next)
        }

        isProcessingQueue = false
    }

    private func dispatch(_ action: Action) {
        let result = reducer(action, state)
        state = result.state

        for notification in result.effects.notifications {
            notificationContinuation.yield(notification)
        }

        for command in result.effects.commands {
            enqueueCommand(command)
        }
    }

    private func enqueueCommand(_ command: Command) {
        let stream = effectHandler(command)

        var taskRef: Task<Void, Never>?
        let task = Task { [weak self] in
            for await action in stream {
                await MainActor.run {
                    self?.send(action)
                }
            }
            await MainActor.run { [weak self] in
                if let task = taskRef {
                    self?.commandTasks.removeAll { $0 == task }
                }
            }
        }
        taskRef = task

        commandTasks.append(task)
    }
}

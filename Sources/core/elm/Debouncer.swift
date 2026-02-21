public actor Debouncer {
    private var task: Task<Void, Never>?

    public init() {}

    public func run(delay: Duration, operation: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await operation()
        }
    }

    public func cancel() {
        task?.cancel()
        task = nil
    }
}

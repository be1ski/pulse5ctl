public func action<A: ElmAction>(_ value: A) -> AsyncStream<A> {
    AsyncStream { continuation in
        continuation.yield(value)
        continuation.finish()
    }
}

public func actions<A: ElmAction>(
    _ build: @escaping (_ continuation: AsyncStream<A>.Continuation) async -> Void
) -> AsyncStream<A> {
    AsyncStream { continuation in
        Task {
            await build(continuation)
        }
    }
}

public func sideEffect<A: ElmAction>(_ operation: @escaping () async -> Void) -> AsyncStream<A> {
    AsyncStream { continuation in
        Task {
            await operation()
            continuation.finish()
        }
    }
}

public func noActions<A: ElmAction>() -> AsyncStream<A> {
    AsyncStream { continuation in
        continuation.finish()
    }
}

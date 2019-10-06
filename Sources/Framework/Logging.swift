import os

/// A unified protocol implemented by all logging services.
internal protocol Logger {
    /// Logs the passed `message`.
    ///
    /// - Parameters:
    ///   - message: The message to be logged.
    ///   - type: The type/severity of the log message, e.g. _error_.
    func log(_ message: StaticString, type: OSLogType)
}

/// A `Logger` implementation utilizing Apple's unified logging aka `os_log()`.
internal class OsLogger: Logger {
    internal required init() {}

    internal func log(_ message: StaticString, type: OSLogType) {
        os_log(message, type: type)
    }
}

extension OsLogger: ContainerInitializableComponent {
    internal static var publicType: Any.Type {
        return Logger.self
    }

    internal static func createFrom(container: DependencyInjectionContainer) throws -> Self {
        return self.init()
    }
}

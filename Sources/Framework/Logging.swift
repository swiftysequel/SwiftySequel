import os

/// A unified protocol implemented by all logging services.
public protocol Logger {
    /// Logs the passed `message`.
    ///
    /// - Parameters:
    ///   - message: The message to be logged.
    ///   - type: The type/severity of the log message, e.g. _error_.
    func log(_ message: StaticString, type: OSLogType)
}

/// A `Logger` implementation utilizing Apple's unified logging aka `os_log()`.
public class OsLogger: Logger {
    public required init() {}

    public func log(_ message: StaticString, type: OSLogType) {
        os_log(message, type: type)
    }
}

extension OsLogger: ContainerInitializableComponent { // swiftlint:disable:this explicit_acl
    public static var publicType: Any.Type {
        return Logger.self
    }

    public static func createFrom(container: DependencyInjectionContainer) throws -> Self {
        return self.init()
    }
}

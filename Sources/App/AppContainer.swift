internal class AppContainer: NestedDependencyInjectionContainer {
    internal init() throws {
        super.init()

        // Register any app-wide services here
        try self.register(OsLogger.self)
    }
}

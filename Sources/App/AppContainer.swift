public class AppContainer: NestedDependencyInjectionContainer {
    public init() throws {
        super.init()

        // Register any app-wide services here
        try self.register(OsLogger.self)
    }
}

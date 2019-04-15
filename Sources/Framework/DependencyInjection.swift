import AppKit

/// This protocol must be implemented by all classes that should be available via the DI container.
public protocol DependencyInjectionComponent {
    /// The protocol type defining the component's _public_ interface. That is, the functionality it provides to
    /// consumers.
    static var publicType: Any.Type { get }
}

/// This protocol needs to be implemented by DI components that can be initialized by the container itself.
public protocol ContainerInitializableComponent: DependencyInjectionComponent {
    /// Returns a new component instance whose dependencies were resolved from the passed `container`.
    ///
    /// Use this method to create an instance that should be added to a DI container (usually the one passed
    /// as `container`).
    ///
    /// - Parameter container: The DI container which is used to resolve any dependency of this component. Usually the
    ///                        same container the created component will be added to.
    /// - Returns: The created component.
    /// - Throws: An exception if the the container cannot resolve the dependencies of the created component.
    static func createFrom(container: DependencyInjectionContainer) throws -> Self
}

/// A simple struct representable as `String` to be used when registering components by a custom identifier/name. Use
/// extensions on this struct to add new `static let`s for new identifiers.
public struct DependencyInjectionComponentIdentifier: RawRepresentable {
    public typealias RawValue = String

    public let rawValue: RawValue

    public init?(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

/// The generic interface provided by all DI containers.
public protocol DependencyInjectionContainer {
    /// Registers a DI component with the receiving container, optionally using the passed `identifier`.
    ///
    /// If no identifier is passed, it is derived from the component's `publicType`.
    ///
    /// - Parameters:
    ///   - component: The DI component instance that shall be registered with the receiving container.
    ///   - identifier: The optional identifier by which the component should be retrievable from the container.
    /// - Throws: An exception if the resulting identifier is already registered with the receiving container.
    func register<T>(
        _ component: T,
        as identifier: DependencyInjectionComponentIdentifier?
    ) throws where T: DependencyInjectionComponent

    /// Returns the component implementing the passed protocol type and optionally being registerd by the passed
    /// `identifier`.
    ///
    /// If no identifier is passed, it is derived from the passed protocol type.
    ///
    /// **Implementation note:** If no matching component can be found, a fatal error should be raised, since that
    /// scenario is usually caused by a programming error.
    ///
    /// - Parameters:
    ///   - type: The protocol type for which the respective component shall be returned.
    ///   - identifier: The optional identifier by which the desired component is registered.
    /// - Returns: The component of the passed type and optionally registered by the passed `identifier`.
    func get<T>(_ type: T.Type, registeredAs identifier: DependencyInjectionComponentIdentifier?) -> T
}

/// A protocol for `NSViewController` subclasses to allow them can be initialized by a DI container.
public protocol ContainerAwareViewController where Self: NSViewController {
    /// - Parameter container: The DI container to be used by the new controller instance.
    init(container: DependencyInjectionContainer)
}

extension DependencyInjectionContainer { // swiftlint:disable:this explicit_acl
    /// Registers a new instance of the passed `componentType` with the receiving DI container, optionally using the
    /// passed `identifier`.
    ///
    /// If no identifier is passed, it is derived from the component's `publicType`.
    ///
    /// - Parameters:
    ///   - componentType: The type of which an instance shall be registered with the controller. This must be the type
    ///                    of the concrete `class`, `struct` etc. that can be initialized.
    ///   - identifier: The optional identifier by which the component should be retrievable from the container.
    /// - Throws: An exception if the resulting identifier is already registered with the receiving container.
    public func register<T>(
        _ componentType: T.Type,
        as identifier: DependencyInjectionComponentIdentifier? = nil
    ) throws where T: ContainerInitializableComponent {
        try self.register(componentType.createFrom(container: self), as: identifier)
    }

    /// Registers a DI component with the receiving container.
    ///
    /// This is a convenience method that does not expect any identifier to be passed. It is required to provided an
    /// extra method for this, since protocol definitions cannot contain default values (not even `nil` for
    /// optional types).
    ///
    /// - Parameter component: The DI component instance that shall be registered with the receiving container.
    /// - Throws: An exception if the resulting identifier is already registered with the receiving container.
    public func register<T>(_ component: T) throws where T: DependencyInjectionComponent {
        try self.register(component, as: nil)
    }

    /// Returns the component implementing the passed protocol type.
    ///
    /// This is a convenience method that does not expect any identifier to be passed. It is required to provided an
    /// extra method for this, since protocol definitions cannot contain default values (not even `nil` for
    /// optional types).
    ///
    /// - Parameter type: The protocol type for which the respective component shall be returned.
    /// - Returns: The component of the passed type and optionally registered by the passed `identifier`.
    public func get<T>(_ type: T.Type) -> T {
        return self.get(T.self, registeredAs: nil)
    }

    /// Creates and returns a new instance of the passed `controller` type.
    ///
    /// Any subclass of `NSViewController` conforming to `ContainerAwareViewController` should always be initialized
    /// using this method, to ensure it gets passed the right DI container.
    ///
    /// - Parameter controller: The type of which a new controller instance should be created.
    /// - Returns: The create controller.
    public func createViewController<T>(_ type: T.Type) -> T where T: ContainerAwareViewController {
        return T(container: self)
    }
}

public class NestedDependencyInjectionContainer: DependencyInjectionContainer {
    public enum ComponentError: Error {
        case alreadyRegistered(type: Any.Type, identifier: String)
    }

    private var resources: [String: DependencyInjectionComponent] = [:]

    /// The container that is checked for matching components if a requested component is not available in this
    /// container instance.
    private let parentContainer: DependencyInjectionContainer?

    /// - Parameter parentContainer: The optional container that should be the new instance's parent.
    public init(parentContainer: DependencyInjectionContainer? = nil) {
        self.parentContainer = parentContainer
    }

    public func register<T>(
        _ component: T,
        as identifier: DependencyInjectionComponentIdentifier?
    ) throws where T: DependencyInjectionComponent {
        let resolvedIdentifier = identifier?.rawValue ?? String(describing: T.publicType)
        if self.resources[resolvedIdentifier] != nil {
            throw ComponentError.alreadyRegistered(type: T.publicType, identifier: resolvedIdentifier)
        }

        self.resources[resolvedIdentifier] = component
    }

    public func get<T>(_ type: T.Type, registeredAs identifier: DependencyInjectionComponentIdentifier?) -> T {
        let resolvedIdentifier = identifier?.rawValue ?? String(describing: type)
        if let component = self.resources[resolvedIdentifier] as? T {
            return component
        }

        // Forward the call to the parent container, if available
        if let parent = self.parentContainer {
            return parent.get(type, registeredAs: identifier)
        }

        fatalError(
            "Component of type \(type) with identifier \(resolvedIdentifier) not found. Did you forget to register it"
            + "with the container using `register()`?"
        )
    }
}

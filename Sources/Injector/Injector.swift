// The Swift Programming Language
// https://docs.swift.org/swift-book

/// The macro is used to designate a class that possesses properties suitable for dependency injection.
/// By applying this macro to a class, you signal to the Injector that it should be aware of injectable properties within the class
///
/// - Parameters:
///   - access: Sets the access modifier for the class' initializer. Default value is the same as class modifier
///   - superInit: Optional string representing the call to a superclass initializer with placeholders for injected properties
///   - useSetup: Boolean flag indicating whether to call a `setup()` method after the superclass initializer. Default value is `false`
@attached(member, names: named(init))
public macro Injectable(
    access: AccessModifier? = nil,
    superInit: SuperInit? = nil,
    useSetup: Bool? = nil
) = #externalMacro(module: "InjectorMacros", type: "InjectableMacro")

/// Marks a property for dependency injection by the Injector
///
///  - Parameters:
///     - name: Optional string that specifies a custom initializer name for the injected dependency. Defaults to the variable name.
///     - escaping: Boolean flag indicating whether the injected value is a closure that escapes the initializer scope. Defaults to `false`.
@attached(peer)
public macro Injected(name: String? = nil, escaping: Bool? = nil) = #externalMacro(module: "InjectorMacros", type: "InjectedMacro")

// The Swift Programming Language
// https://docs.swift.org/swift-book

// MARK: - V1

@attached(member, names: named(init))
public macro Injectable(
    access: AccessModifier? = nil,
    superInit: SuperInit? = nil,
    useSetup: Bool? = nil
) = #externalMacro(module: "InjectorMacros", type: "InjectableMacro")

@attached(peer)
public macro Injected(name: String? = nil, escaping: Bool? = nil) = #externalMacro(module: "InjectorMacros", type: "InjectedMacro")

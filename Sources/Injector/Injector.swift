// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: arbitrary)
public macro Injectable() = #externalMacro(module: "InjectorMacros", type: "InjectableMacro")

@attached(accessor)
public macro Injected(name: String? = nil, escaping: Bool? = nil) = #externalMacro(module: "InjectorMacros", type: "InjectedMacro")

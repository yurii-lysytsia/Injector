import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct InjectorPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InjectableMacro.self,
        InjectedMacro.self
    ]
}

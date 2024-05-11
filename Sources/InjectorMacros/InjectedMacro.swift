import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

public struct InjectedMacro: AccessorMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        let variable = try InjectedVariable(decl: declaration)
        
        guard variable.bindingSpecifier == .var else {
            throw MacroExpansionErrorMessage("`let` properties aren't supported. Please use `var` for `@Injected` properties")
        }
        
        return ["get { dependencies.\(raw: variable.arguments.name ?? variable.identifier) }"]
    }
}

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

public struct InjectableMacro: MemberMacro {
    private struct Arguments {
        var autoInit: Bool = false
    }
    
    private class Dependencies {
        var variables: String = ""
        var initParameters: String = ""
        var initAssignments: String = ""
        
        var isEmpty: Bool {
            variables.isEmpty || initParameters.isEmpty || initAssignments.isEmpty
        }
    }
    
    // MARK: MemberMacro
    
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Get access modifier for dependencies
        let modifiers = MemberModifiers(modifiers: declaration.modifiers)
        let access = modifiers.access == .open ? "public" : modifiers.access.rawValue
        
        // Check each member to find all `@Injected` properties
        let dependencies = declaration.memberBlock.members.reduce(into: Dependencies()) { dependencies, member in
            guard let variable = try? InjectedVariable(decl: member.decl) else { return }
            
            // Add a new variable and init assignment for `struct Dependencies`
            let name = variable.arguments.name ?? variable.identifier
            let isClosure = variable.arguments.isEscaping || variable.type.is(FunctionTypeSyntax.self)
            
            var variableString = "\(access) let \(name): \(variable.type)\n"
            if dependencies.variables.isEmpty { variableString.insert("\n", at: variableString.startIndex) }
            dependencies.variables.append(variableString)
            
            var initParameter = "\(name): \(isClosure ? "@escaping " : "")\(variable.type)"
            if !dependencies.initParameters.isEmpty {
                initParameter.insert(contentsOf: ",\n", at: initParameter.startIndex)
            }
            dependencies.initParameters.append(initParameter)
            
            var initAssignment = "self.\(name) = \(name)\n"
            if dependencies.initAssignments.isEmpty {
                initAssignment.insert("\n", at: initAssignment.startIndex)
            }
            dependencies.initAssignments.append(initAssignment)
        }
        
        // Prepare blocks of generated codes if some variables existed
        guard !dependencies.isEmpty else { return [] }
        
        // Prepare independent parameters for each block
        var generatedCode = [DeclSyntax]()
        
        // 1. Add `Dependencies` structure to define all properties automatically
        let dependenciesInit = "\(access) init(\n\(dependencies.initParameters)\n) { \(dependencies.initAssignments) }"
        let dependenciesStruct = "\(access) struct Dependencies { \(dependencies.variables)\n\(dependenciesInit) }"
        generatedCode.append("\(raw: dependenciesStruct)")
        
        // 2. Add a required `dependencies` property
        generatedCode.append("private let dependencies: Dependencies")
        
        return generatedCode
    }
}

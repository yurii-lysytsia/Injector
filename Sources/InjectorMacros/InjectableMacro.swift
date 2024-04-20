import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

public struct InjectableMacro: MemberMacro {
    private struct Arguments {
        var access: String = ""
        var superInit: String?
        var useSetup: Bool = false
    }
    
    private struct VariableArguments {
        var name: String?
        var isEscaping: Bool = false
    }
    
    private static let supportingKinds: Set<SyntaxKind> = [.classDecl, .structDecl]
    
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Only `class` is suitable for this macro
        guard supportingKinds.contains(declaration.kind) else {
            return []
        }
        
        var parameters = [String]()
        var assignments = [CodeBlockItemListSyntax.Element]()
    
        // Check each member to find all `@Injected` properties
        declaration.memberBlock.members.forEach { member in
            guard
                let variable = member.decl.as(VariableDeclSyntax.self),
                let attribute = variable.attributes.first?.as(AttributeSyntax.self),
                attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Injected",
                let bindings = variable.bindings.as(PatternBindingListSyntax.self),
                let pattern = bindings.first?.as(PatternBindingSyntax.self),
                let identifier = pattern.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                let type = pattern.typeAnnotation?.as(TypeAnnotationSyntax.self)?.type
            else { return }
            
            // Get variable arguments given for this property
            let variableArguments = getVariableArguments(attribute: attribute)
            
            // Parameter's name
            let name = variableArguments.name ?? identifier
            
            // Define is `@escaping` parameter needed
            let isClosure = variableArguments.isEscaping || type.is(FunctionTypeSyntax.self)
            
            parameters.append("\(name): \(isClosure ? "@escaping " : "")\(type)")
            
            let assignment = "\(assignments.isEmpty ? "" : "\n")self.\(identifier) = \(name)"
            assignments.append("\(raw: assignment)")
        }
        
        // Continue only when parameters isn't empty
        guard !parameters.isEmpty, !assignments.isEmpty else {
            return []
        }
        
        // Get given arguments
        let arguments = getArguments(attribute: attribute, modifiers: declaration.modifiers)
        
        // Append `super.init(...)` to assignments if the value existed
        if let superInit = arguments.superInit {
            assignments.append("\(raw: "\nsuper.init(\(superInit))")")
        }
        
        // Append calling `setup()` method after `super.init()`
        if arguments.useSetup {
            assignments.append("\(raw: "\nsetup()")")
        }
        
        // Prepare `init` header values
        let initParameters = "\n\(parameters.joined(separator: ",\n"))\n"
        let initModifierString = arguments.access.isEmpty ? "" : "\(arguments.access) "
        
        let initDeclSyntax = try InitializerDeclSyntax(
            SyntaxNodeString(stringLiteral: "\(initModifierString)init(\(initParameters))"),
            bodyBuilder: { .init(assignments) }
        )
        
        return ["\(raw: initDeclSyntax)"]
    }
}

// MARK: - Arguments

extension InjectableMacro {
    private static func modifyAccess(expression: ExprSyntax, arguments: inout Arguments) -> Bool {
        guard let value = expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text else { return false }
        
        switch value {
        case "open":
            arguments.access = "public"
            
        case "internal":
            break
            
        default:
            arguments.access = value // public, fileprivate, private has the same value
        }
        
        return true
    }
    
    private static func modifySuperInit(expression: ExprSyntax, arguments: inout Arguments) {
        if let stringLiteral = expression.as(StringLiteralExprSyntax.self) {
            // The value is string liter of custom
            guard let segment = stringLiteral.segments.first.map(String.init) else { return }
            arguments.superInit = segment
        } else if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
            // Default empty string
            switch memberAccess.declName.baseName.text {
            case "default":
                arguments.superInit = ""
            default:
                break
            }
        }
    }
    
    private static func modifyUseSetup(expression: ExprSyntax, arguments: inout Arguments) {
        guard let value = expression.getBoolLiteral() else { return }
        arguments.useSetup = value
    }
    
    private static func getArguments(attribute: AttributeSyntax, modifiers: DeclModifierListSyntax) -> Arguments {
        var arguments = Arguments()
        
        // Get list of arguments that given with `@Injectable(...)` attribute
        guard let labeledList = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            return arguments
        }
        
        var hasCustomAccess = false
        
        // Map each given attribute to modify arguments
        labeledList.forEach { syntax in
            switch syntax.label?.text {
            case "access":
                hasCustomAccess = modifyAccess(expression: syntax.expression, arguments: &arguments)
            
            case "superInit":
                modifySuperInit(expression: syntax.expression, arguments: &arguments)
                
            case "useSetup":
                modifyUseSetup(expression: syntax.expression, arguments: &arguments)
                
            default:
                break
            }
        }
        
        // Get access level according to the given member's access modifier
        if !hasCustomAccess {
            for modifier in modifiers {
                guard case .keyword(let keyword) = modifier.name.tokenKind else { continue }
                
                if keyword == .public || keyword == .open {
                    arguments.access = "public"
                    break
                } else if keyword == .private {
                    arguments.access = "private"
                    break
                } else if keyword == .fileprivate {
                    arguments.access = "fileprivate"
                    break
                }
            }
        }
        
        return arguments
    }
}

// MARK: - Variable Arguments

extension InjectableMacro {
    private static func modifyVariableName(expression: ExprSyntax, arguments: inout VariableArguments) {
        guard let stringLiteral = expression.as(StringLiteralExprSyntax.self) else { return }
        arguments.name = stringLiteral.segments.first.map(String.init)
    }
    
    private static func modifyVariableEscaping(expression: ExprSyntax, arguments: inout VariableArguments) {
        guard let value = expression.getBoolLiteral() else { return }
        arguments.isEscaping = value
    }
    
    private static func getVariableArguments(attribute: AttributeSyntax) -> VariableArguments {
        var arguments = VariableArguments()
        
        // Get list of arguments that given with `@Injected(...)` attribute
        guard let labeledList = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            return arguments
        }
        
        // Map each given attribute to modify arguments
        labeledList.forEach { syntax in
            switch syntax.label?.text {
            case "name":
                modifyVariableName(expression: syntax.expression, arguments: &arguments)
            
            case "escaping":
                modifyVariableEscaping(expression: syntax.expression, arguments: &arguments)
                
            default:
                break
            }
        }
        
        return arguments
    }
}

// MARK: Extensions

extension ExprSyntax {
    func getBoolLiteral() -> Bool? {
        guard case .keyword(let keyword) = self.as(BooleanLiteralExprSyntax.self)?.literal.tokenKind else { return nil }
        
        switch keyword {
        case .true:
            return true
            
        case .false:
            return false
            
        default:
            return nil
        }
    }
}

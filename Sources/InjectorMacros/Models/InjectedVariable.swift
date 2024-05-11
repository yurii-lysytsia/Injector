import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

struct InjectedVariable {
    struct Arguments {
        var name: String?
        var isEscaping: Bool = false
    }
    
    enum BindingSpecifier: String {
        case `var`, `let`
    }
    
    // MARK: Properties
    
    let arguments: Arguments
    let bindingSpecifier: BindingSpecifier
    let identifier: String
    let type: TypeSyntax
    let isClosure: Bool
    
    // MARK: Init
    
    init(decl: DeclSyntaxProtocol) throws {
        // Supports only variables with `@Injected` macro
        guard
            let variableDecl = decl.as(VariableDeclSyntax.self),
            let attribute = variableDecl.attributes.first?.as(AttributeSyntax.self),
            attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Injected"
        else {
            throw MacroExpansionErrorMessage("`@Injeted` macro can be used only for variables")
        }
        
        // Get binding specifier
        guard let bindingSpecifier = InjectedVariable.BindingSpecifier(rawValue: variableDecl.bindingSpecifier.text) else {
            throw MacroExpansionErrorMessage("BindingSpecifier isn't defined")
        }
        
        // Get pattern for identifier and type
        guard
            let bindings = variableDecl.bindings.as(PatternBindingListSyntax.self),
            let pattern = bindings.first?.as(PatternBindingSyntax.self)
        else {
            throw MacroExpansionErrorMessage("Something went wrong. Couldn't define `bindings` and it's first `PatternBindingSyntax`")
        }
        
        // Get identifier of the property
        guard let identifier = pattern.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            throw MacroExpansionErrorMessage("Property's pattern doesn't contains identifier")
        }
        
        // Get type of the property
        guard let type = pattern.typeAnnotation?.as(TypeAnnotationSyntax.self)?.type else {
            throw MacroExpansionErrorMessage("Property's pattern doesn't contains type")
        }
        
        // Configure values
        let variableArguments = Arguments(attribute: attribute)
        
        self.arguments = variableArguments
        self.bindingSpecifier = bindingSpecifier
        self.identifier = identifier
        self.type = type
        self.isClosure = variableArguments.isEscaping || type.is(FunctionTypeSyntax.self)
    }
}


// MARK: - Arguments

extension InjectedVariable.Arguments {
    private mutating func modifyVariableName(expression: ExprSyntax) {
        guard let stringLiteral = expression.as(StringLiteralExprSyntax.self) else { return }
        name = stringLiteral.segments.first.map(String.init)
    }
    
    private mutating func modifyVariableEscaping(expression: ExprSyntax) {
        guard let value = expression.getBoolLiteral() else { return }
        isEscaping = value
    }
    
    // MARK: Init
    
    init(attribute: AttributeSyntax) {
        var arguments = InjectedVariable.Arguments()
        
        // Get list of arguments that given with `@Injected(...)` attribute
        guard let labeledList = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            self = arguments
            return
        }
        
        // Map each given attribute to modify arguments
        labeledList.forEach { syntax in
            switch syntax.label?.text {
            case "name":
                arguments.modifyVariableName(expression: syntax.expression)
            
            case "escaping":
                arguments.modifyVariableEscaping(expression: syntax.expression)
                
            default:
                break
            }
        }
        
        self = arguments
    }
}

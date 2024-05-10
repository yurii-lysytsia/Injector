import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

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

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

struct MemberModifiers {
    enum AccessModifier: String {
        case `private`, `fileprivate`, `internal`, `public`, `open`
    }
    
    // MARK: Properties
    
    var isFinal: Bool
    var access: AccessModifier
    
    // MARK: Init
    
    init(modifiers: DeclModifierListSyntax) {
        var isFinal: Bool?
        var access: AccessModifier?
        
        modifiers.forEach {
            guard case .keyword(let keyword) = $0.name.tokenKind else { return }
            
            switch keyword {
            case .final:
                isFinal = true
            case .private:
                access = .private
            case .fileprivate:
                access = .fileprivate
            case .internal:
                access = .internal
            case .public:
                access = .public
            case .open:
                access = .open
            default:
                return
            }
        }
        
        self.isFinal = isFinal ?? false
        self.access = access ?? .internal
    }
}

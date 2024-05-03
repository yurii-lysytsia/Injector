import Foundation

public struct SuperInit: ExpressibleByStringLiteral {
    public static let `default`: SuperInit = ""
    
    // MARK: Properties
    
    var rawValue: String
    
    // MARK: Init
    
    public init(stringLiteral value: StringLiteralType) {
        rawValue = value
    }
}

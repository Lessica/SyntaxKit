//
//  AttributedParser.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 9/24/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

public class AttributedParser: Parser {
    
    // MARK: - Types
    
    public typealias AttributedCallback = (scope: String, range: NSRange, attributes: Attributes?) -> Void
    
    
    // MARK: - Properties
    
    public let theme: Theme
    
    
    // MARK: - Initializers
    
    public required init(language: Language, theme: Theme) {
        self.theme = theme
        super.init(language: language)
    }
    
    
    // MARK: - Parsing
    
    public func parse(string: String, inRange bounds: NSRange? = nil, match callback: AttributedCallback) {
        parse(string, inRange: bounds) { scope, range in
            callback(scope: scope, range: range, attributes: self.attributesForScope(scope))
        }
    }
    
    public func attributedStringForString(string: String, baseAttributes: Attributes? = nil) -> NSAttributedString {
        let output = NSMutableAttributedString(string: string, attributes: baseAttributes)
        output.beginEditing()
        parse(string) { _, range, attributes in
            if let attributes = attributes {
                output.addAttributes(attributes, range: range)
            }
        }
        output.endEditing()
        return output
    }
    
    
    // MARK: - Private
    
    private func attributesForScope(scope: String) -> Attributes? {
        let components = scope.componentsSeparatedByString(".") as NSArray
        let count = components.count
        if count == 0 {
            return nil
        }
        
        var attributes = Attributes()
        for i in 0..<count {
            let key = (components.subarrayWithRange(NSMakeRange(0, i + 1)) as NSArray).componentsJoinedByString(".")
            if let attrs = theme.attributes[key] {
                for (k, v) in attrs {
                    attributes[k] = v
                }
            }
        }
        
        if attributes.isEmpty {
            return nil
        }
        
        return attributes
    }
}

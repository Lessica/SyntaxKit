//
//  AttributedParserTests.swift
//  SyntaxKitTests
//
//  Created by Sam Soffes on 9/19/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import XCTest
import SyntaxKit

class AttributedParserTests: XCTestCase {
    
    // MARK: - Properties
    
    let manager = getBundleManager()
    var parser: AttributedParser!
    
    
    // MARK: - Tests
    
    override func setUp() {
        super.setUp()
        let yaml = manager.languageWithIdentifier("source.YAML")!
        parser = AttributedParser(language: yaml, theme: simpleTheme())
    }
    
    func testParsing() {
        let string = parser.attributedStringForString("title: Hello World\ncount: 42\n")
        
        XCTAssertEqual(["color": "blue"] as NSDictionary, string.attributesAtIndex(0, effectiveRange: nil) as NSDictionary)
        XCTAssertEqual(["color": "red"] as NSDictionary, string.attributesAtIndex(7, effectiveRange: nil) as NSDictionary)
        XCTAssertEqual(["color": "blue"] as NSDictionary, string.attributesAtIndex(19, effectiveRange: nil) as NSDictionary)
        XCTAssertEqual(["color": "purple"] as NSDictionary, string.attributesAtIndex(25, effectiveRange: nil) as NSDictionary)
    }
}

//
//  SwiftBaselineHighlightingTests.swift
//  SyntaxKit
//
//  Created by Alexander Hedges on 19/01/16.
//  Copyright © 2016 Alexander Hedges. All rights reserved.
//

import Foundation
import XCTest
import SyntaxKit

class SwiftBaselineHighlightingTests: XCTestCase {

    // MARK: - Properties

    let manager = getBundleManager()
    var parser: AttributedParser!


    // MARK: - Tests

    override func setUp() {
        super.setUp()
        let swift = manager.languageWithIdentifier("source.Swift")!
        let solarized = manager.themeWithIdentifier("Solarized")!
        parser = AttributedParser(language: swift, theme: solarized)
    }

    func testColors() {
        let input = fixture("swifttest.swift", "txt")
        let string = parser.attributedStringForString(input)

        // line comment
        assertEqualColors(Color(hex: "#93A1A1"), string.attributesAtIndex(10, effectiveRange: nil)[NSForegroundColorAttributeName] as? Color)
        assertEqualColors(Color(hex: "#93A1A1"), string.attributesAtIndex(135, effectiveRange: nil)[NSForegroundColorAttributeName] as? Color)

        // block comment
//        print((string.string as NSString).substringWithRange(NSRange(location: 157, length: 20)))
        assertEqualColors(Color(hex: "#93A1A1"), string.attributesAtIndex(157, effectiveRange: nil)[NSForegroundColorAttributeName] as? Color)

        // string literal
//        print((string.string as NSString).substringWithRange(NSRange(location: 744, length: 6)))
        assertEqualColors(Color(hex: "#839496"), string.attributesAtIndex(744, effectiveRange: nil)[NSForegroundColorAttributeName] as? Color)
        var stringRange = NSRange()
        assertEqualColors(Color(hex: "#2aa198"), string.attributesAtIndex(745, effectiveRange: &stringRange)[NSForegroundColorAttributeName] as? Color)
        XCTAssertEqual(stringRange.length, 4)
        assertEqualColors(Color(hex: "#839496"), string.attributesAtIndex(749, effectiveRange: nil)[NSForegroundColorAttributeName] as? Color)

        // number literal
        var numberRange = NSRange()
//        print((string.string as NSString).substringWithRange(NSRange(location: 715, length: 3)))
        assertEqualColors(Color(hex: "#d33682"), string.attributesAtIndex(715, effectiveRange: &numberRange)[NSForegroundColorAttributeName] as? Color)
        XCTAssertEqual(numberRange, NSRange(location: 715, length: 1))
    }

    func testHighlightingPerformance() {
        let input = fixture("swifttest.swift", "txt")
        self.measureBlock {
            self.parser.attributedStringForString(input)
        }
    }
}

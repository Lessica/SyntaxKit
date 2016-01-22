//
//  ResultSet.swift
//  SyntaxKit
//
//  Created by Sam Soffes on 10/11/14.
//  Copyright © 2014-2015 Sam Soffes. All rights reserved.
//

import Foundation

struct ResultSet {

	// MARK: - Properties

	private var _results = [Result]()
	var results: [Result] {
		return _results
	}

	var range: NSRange

	var isEmpty: Bool {
		return results.isEmpty
	}
    
    init(startingRange range: NSRange) {
        self.range = range
    }
    
    // MARK: - Comparing
    
    func hasLowerPriorityThan(other: ResultSet?) -> Bool {
        if other == nil {
            return false
        } else if other!.range.location != self.range.location {
            return other!.range.location < self.range.location
        } else {
            return other!.range.length > self.range.length
        }
    }

	// MARK: - Adding

	mutating func addResult(result: Result) {
		_results.append(result)

		self.range = NSUnionRange(range, result.range)
	}

	mutating func addResults(resultSet: ResultSet) {
        self.range = NSUnionRange(range, resultSet.range)
		for result in resultSet.results {
			addResult(result)
		}
	}
}

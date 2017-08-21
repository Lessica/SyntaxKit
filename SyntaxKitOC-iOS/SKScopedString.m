//
//  SKScopedString.m
//  XXTExplorer
//
//  Created by Zheng on 13/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKScopedString.h"
#import "SKResult.h"
#import "SKRange.h"

@interface SKScopedString ()

@property (nonatomic, strong) NSMutableArray <NSMutableArray <SKScope *> *> *levels;

@end

@implementation SKScopedString

/// The inplicit scope at the base of each ScopedString
- (SKScope *)getBaseScope {
    return [[SKScope alloc] initWithIdentifier:@"BaseNameString" range:NSMakeRange(0, self.string.length) attribute:nil];
}

// MARK: - Initializers
- (instancetype)init {
    NSAssert(YES, @"Use -initWithString: instead.");
    return nil;
}

- (instancetype)initWithString:(NSString *)string {
    self = [super init];
    if (self) {
        _string = string;
        _levels = [[NSMutableArray alloc] init];
    }
    return self;
}

// MARK: - Interface
- (NSUInteger)numberOfScopes {
    NSUInteger sum = 1;
    for (NSArray <SKScope *> *level in self.levels) {
        sum += level.count;
    }
    return sum;
}

- (NSUInteger)numberOfLevels {
    return self.levels.count + 1;
}

- (BOOL)isInStringAtIndex:(NSUInteger)index {
    return index <= self.baseScope.range.length;
}

- (void)appendScopeAtTop:(SKScope *)scope {
    assert(scope.range.length != 0);
    assert(NSIntersectionRange(scope.range, self.baseScope.range).length == scope.range.length);
    BOOL added = NO;
    for (NSUInteger level = 0; level < self.levels.count; level++) {
        if ([self findScopeIntersectionWithRange:scope.range atLevel:self.levels[level]] == nil) {
            [self.levels[level] insertObject:scope atIndex:[self insertionPointForRange:scope.range atLevel:self.levels[level]]];
            added = YES;
            break;
        }
    }
    if (!added) {
        [self.levels addObject:[[NSMutableArray alloc] initWithArray:@[scope]]];
    }
}

- (void)appendScopeAtBottom:(SKScope *)scope {
    assert(scope.range.length != 0);
    assert(NSIntersectionRange(scope.range, self.baseScope.range).length == scope.range.length);
    BOOL added = NO;
    for (NSUInteger level = self.levels.count; level > 0; level--) {
        if ([self findScopeIntersectionWithRange:scope.range atLevel:self.levels[level - 1]] == nil) {
            [self.levels[level - 1] insertObject:scope atIndex:[self insertionPointForRange:scope.range atLevel:self.levels[level - 1]]];
            added = YES;
            break;
        }
    }
    if (!added) {
        [self.levels insertObject:[[NSMutableArray alloc] initWithArray:@[scope]] atIndex:0];
    }
}

- (SKScope *)topMostScopeAtIndex:(NSUInteger)index {
    NSRange indexRange = NSMakeRange(index, 0);
    for (NSUInteger i = self.levels.count; i > 0; i--) {
        NSArray <SKScope *> *level = self.levels[i - 1];
        SKScope *theScope = [self findScopeIntersectionWithRange:indexRange atLevel:level];
        if (theScope) {
            return theScope;
        }
    }
    return self.baseScope;
}

- (SKScope *)lowerScopeForScope:(SKScope *)scope atIndex:(NSUInteger)index {
    assert(index >= 0 && index <= self.baseScope.range.length);
    BOOL foundScope = NO;
    NSRange indexRange = NSMakeRange(index, 0);
    for (NSUInteger i = self.levels.count; i > 0; i--) {
        NSArray <SKScope *> *level = self.levels[i - 1];
        SKScope *theScope = [self findScopeIntersectionWithRange:indexRange atLevel:level];
        if (theScope) {
            if (foundScope) {
                return scope;
            } else if ([theScope isEqual:scope]) {
                foundScope = YES;
            }
        }
    }
    return self.baseScope;
}

- (NSUInteger)levelForScope:(SKScope *)scope {
    for (NSUInteger i = 0; i < self.levels.count; i++) {
        NSArray <SKScope *> *level = self.levels[i];
        if ([level containsObject:scope]) {
            return i + 1;
        }
    }
    if ([scope isEqual:self.baseScope]) {
        return 0;
    }
    return -1;
}

/// Removes all scopes that are entirely contained in the spcified range.
- (void)removeScopesInRange:(NSRange)range {
    assert(NSIntersectionRange(range, self.baseScope.range).length == range.length);
    for (NSUInteger level = self.levels.count; level > 0; level--) {
        for (NSUInteger scope = self.levels[level - 1].count; scope > 0; scope--) {
            SKScope *theScope = self.levels[level - 1][scope - 1];
            if (NSRangeEntirelyContains(range, theScope.range)) {
                [self.levels[level - 1] removeObjectAtIndex:scope - 1];
            }
        }
        if (self.levels[level - 1].count == 0) {
            [self.levels removeObjectAtIndex:level - 1];
        }
    }
}

/// Inserts the given string into the underlying string, stretching and
/// shifting ranges as needed. If the range starts before and ends after the
/// insertion point, it is stretched.
- (void)insertString:(NSString *)string atIndex:(NSUInteger)index {
    assert(index <= self.baseScope.range.length);
    NSString *s = self.string;
    NSUInteger length = string.length;
    NSMutableString *mutableString = [s mutableCopy];
    [mutableString insertString:string atIndex:index];
    self.string = mutableString ? [mutableString copy] : @"";
    for (NSUInteger level = 0; level < self.levels.count; level++) {
        for (NSUInteger scope = 0; self.levels[level].count; scope++) {
            self.levels[level][scope].range = NSRangeInsertIndexesFromRange(self.levels[level][scope].range, NSMakeRange(index, length));
        }
    }
}

/// Deletes the characters from the underlying string, shrinking and
/// deleting scopes as needed.
- (void)deleteCharactersInRange:(NSRange)range {
    assert(NSIntersectionRange(range, self.baseScope.range).length == range.length);
    NSMutableString *mutableString = [self.string mutableCopy];
    [mutableString deleteCharactersInRange:range];
    self.string = mutableString ? [mutableString copy] : @"";
    for (NSUInteger level = self.levels.count; level > 0; level--) {
        for (NSUInteger scope = self.levels[level - 1].count; scope > 0; scope--) {
            NSRange theRange = self.levels[level - 1][scope - 1].range;
            theRange = NSRangeRemoveIndexesFromRange(theRange, range);
            if (NSRangeEmpty(theRange)) {
                [self.levels[level - 1] removeObjectAtIndex:scope - 1];
            } else {
                self.levels[level - 1][scope - 1].range = theRange;
            }
        }
    }
}

/// - note: This representation is guaranteed not to change between releases
///         (except for releases with breaking changes) so it can be used
///         for unit testing.
/// - returns: A user-friendly description of the instance.
#ifdef DEBUG
- (NSString *)prettyRepresentation {
    NSMutableString *result = [[NSMutableString alloc] init];
    NSString *printableUnderlyingString = [self.string stringByReplacingOccurrencesOfString:@"\n" withString:@"¬"];
    printableUnderlyingString = [printableUnderlyingString stringByReplacingOccurrencesOfString:@"\t" withString:@"»"];
    [result appendString:printableUnderlyingString];
    [result appendString:@"\n"];
    for (NSUInteger level = self.levels.count; level > 0; level--) {
        NSString *levelString = [@"" stringByPaddingToLength:self.string.length withString:@" " startingAtIndex:0];
        for (SKScope *pattern in self.levels[level - 1]) {
            NSRange range = pattern.range;
            if (range.length == 0) {
                assert(false);
            } else if (range.length == 1) {
                levelString = [levelString stringByReplacingCharactersInRange:range withString:@"|"];
            } else {
                NSString *dashes = [@"" stringByPaddingToLength:range.length - 2 withString:@"-" startingAtIndex:0];
                levelString = [levelString stringByReplacingCharactersInRange:range withString:[NSString stringWithFormat:@"[%@]", dashes]];
            }
        }
        [result appendString:levelString];
        [result appendString:@"\n"];
    }
    NSMutableString *numberString = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i <= self.string.length / 10; i++) {
        NSString *numString = [@(i * 10) stringValue];
        NSUInteger numDigits = numString.length;
        NSString *dashes = [@"" stringByPaddingToLength:9 - numDigits withString:@"-" startingAtIndex:0];
        [numberString appendFormat:@"%@%@|", numString, dashes];
    }
    [result appendString:numberString];
    [result appendString:@"\n"];
    return [result copy];
}
#endif

// MARK: - Private
- (SKScope *)findScopeIntersectionWithRange:(NSRange)range atLevel:(NSArray <SKScope *> *)level {
    for (SKScope *scope in level) {
        if (NSRangePartiallyContains(scope.range, range)) {
            return scope;
        }
    }
    return nil;
}

- (NSUInteger)insertionPointForRange:(NSRange)range atLevel:(NSArray <SKScope *> *)level {
    NSUInteger i = 0;
    for (SKScope *scope in level) {
        if (range.location < scope.range.location) {
            return i;
        }
        i += 1;
    }
    return i;
}

@end

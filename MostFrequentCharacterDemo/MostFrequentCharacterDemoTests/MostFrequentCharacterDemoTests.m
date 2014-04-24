//
//  MostFrequentCharacterDemoTests.m
//  MostFrequentCharacterDemoTests
//
//  Created by Rinat Enikeev on 4/22/14.
//  Copyright (c) 2014 Rinat Enikeev. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "charfreq.h"

@interface MostFrequentCharacterDemoTests : XCTestCase

@end

@implementation MostFrequentCharacterDemoTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testDoubleAInAlphabet
{
    char* testArr = "abcdefghijklmnopqrstuvwxyza";
    u_long len = strlen(testArr);
    XCTAssert(_mostFrequentCharacter(testArr, (int)len) == 'a');
}

- (void)testMostFrequentAtStartAndEnd
{
    char* testArr = "aaaaaaaabbbbbbcccfgjcdefgbbbbbbbbb";
    u_long len = strlen(testArr);
    XCTAssert(_mostFrequentCharacter(testArr, (int)len) == 'b');
}


@end

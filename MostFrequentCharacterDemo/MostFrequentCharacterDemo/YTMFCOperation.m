
//
//  YTSnglThrdMFCOperation.m
//  MostFrequentCharacterDemo
//
//  Created by Rinat Enikeev on 4/23/14.
//  Copyright (c) 2014 Rinat Enikeev. All rights reserved.
//

#import "YTMFCOperation.h"
static int const DEFAULT_CHAR_ARR_SIZE = 65536;

@implementation YTMFCOperation

-(id)init
{
    self = [super init];
    if (self) {
        _randomArrSize = DEFAULT_CHAR_ARR_SIZE;
        [self fillCharArrWithRand];
    }
    return self;
}

-(void)fillCharArrWithRand
{
    free(_randomArr);
    _randomArr = malloc(_randomArrSize * sizeof(char));
    for (long i = 0; i < DEFAULT_CHAR_ARR_SIZE; i++) {
        _randomArr[i] = arc4random() % 256 - 128;
    }
}

-(void)refresh
{
    [self fillCharArrWithRand];
}

-(double)valueFor:(NSInteger)x
{
    NSLog(@"YTMFCOperation is superclass. Implement in subclasses");
    return 0;
}

-(NSString *)xAxisLabel
{
    return @"Char count";
}

-(void)dealloc
{
    free(_randomArr);
}

@end

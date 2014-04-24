//
//  YTOperationsProvider.m
//  MostFrequentCharacterDemo
//
//  Created by Rinat Enikeev on 4/25/14.
//  Copyright (c) 2014 Rinat Enikeev. All rights reserved.
//

#import "YTOperationsProvider.h"
#import "YTMFCOptmThrdCountOperation.h"
#import "YTMFCTimeOperation.h"

@interface YTOperationsProvider ()
@property (strong, nonatomic) NSArray* operations;
@end

@implementation YTOperationsProvider

-(id)init
{
    self = [super init];
    if (self) {
        NSObject<YTProfileOperation>* timeOp = [[YTMFCTimeOperation alloc] init];
        [timeOp setDelay:0.2];
        NSObject<YTProfileOperation>* mfcThreadsOp =  [[YTMFCOptmThrdCountOperation alloc] init];
        [mfcThreadsOp setDelay:0.1];
        self.operations = [NSArray arrayWithObjects:timeOp, mfcThreadsOp, nil];
    }
    return self;
}

-(NSArray *)allOperations
{
    return _operations;
}

@end

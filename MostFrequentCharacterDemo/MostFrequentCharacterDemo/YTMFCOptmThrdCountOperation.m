//
//  YTProfileOperation.m
//  MostFrequentCharacterDemo
//
//  Created by Rinat Enikeev on 4/23/14.
//  Copyright (c) 2014 Rinat Enikeev. All rights reserved.
//

#import "YTMFCOptmThrdCountOperation.h"
#import "charfreq.h"

static NSUInteger const DEFAULT_MIN_THREADS = 2;
static NSUInteger const DEFAULT_MAX_THREADS = 20;
static NSUInteger const DEFAULT_THREADS_STEP = 2;

static NSString* const kMinThreadsPropertyName = @"Min threads";
static NSString* const kMaxThreadsPropertyName = @"Max threads";
static NSString* const kThreadsStep = @"Threads step";

@implementation YTMFCOptmThrdCountOperation

-(id)init
{
    self = [super init];
    if (self) {
        self.params = @{kMinThreadsPropertyName: @(DEFAULT_MIN_THREADS),
                        kMaxThreadsPropertyName: @(DEFAULT_MAX_THREADS),
                        kThreadsStep:            @(DEFAULT_THREADS_STEP)};

    }
    return self;
}

-(NSString *)operationTitle
{
    return @"MFC optimal thread count";
}

-(NSString *)yAxisLabel
{
    return  @"Optimal threads #";
}

-(double)valueFor:(NSInteger)x
{
    NSInteger opt = INFINITY;
    double min = INFINITY;
    NSInteger minThreadCount = [[self.params valueForKey:kMinThreadsPropertyName] integerValue];
    NSInteger maxThreadCount = [[self.params valueForKey:kMaxThreadsPropertyName] integerValue];
    NSInteger threadStep     = [[self.params valueForKey:kThreadsStep] integerValue];

    for (int threadCount = minThreadCount; threadCount <= maxThreadCount; threadCount += threadStep) {
        most_freq_char_set_thread_count(threadCount);
        usleep(self.delay * 1000000);
        clock_t start = clock();
        _mostFrequentCharacter(_randomArr, x);
        double executionTime = (double)(clock() - start);
        
        if (min > executionTime) {
            min = executionTime;
            opt = threadCount;
        }
    }
    return opt;
}

@end

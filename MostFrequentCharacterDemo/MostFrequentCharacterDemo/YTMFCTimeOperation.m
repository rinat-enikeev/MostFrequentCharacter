//
//  YTMFCTime.m
//  MostFrequentCharacterDemo
//
//  Created by Rinat Enikeev on 4/24/14.
//  Copyright (c) 2014 Rinat Enikeev. All rights reserved.
//

#import "YTMFCTimeOperation.h"
#import "charfreq.h"

static NSUInteger DEFAULT_NUM_THREADS = 1;
static NSString* const kNumThreadsPropertyName = @"kNumThreadsProperty";

@implementation YTMFCTimeOperation

-(id)init
{
    self = [super init];
    if (self) {
        self.params = @{kNumThreadsPropertyName: @(DEFAULT_NUM_THREADS)};
        
    }
    return self;
}

-(NSString *)operationTitle
{
    return [NSString stringWithFormat:@"MFC search time with %@ threads",[self.params valueForKey:kNumThreadsPropertyName]];
}

-(NSString *)yAxisLabel
{
    return @"MFC search time, clocks";
}

-(double)valueFor:(NSInteger)x
{
    NSInteger threadCount = [[self.params valueForKey:kNumThreadsPropertyName] integerValue];
    most_freq_char_set_thread_count(threadCount);
    usleep(self.delay * 1000000);
    
    clock_t start = clock();
    _mostFrequentCharacter(_randomArr, x);
    return (double)(clock() - start);

}

@end

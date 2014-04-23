//
//  YTSnglThrdMFCOperation.h
//  MostFrequentCharacterDemo
//
//  Created by Rinat Enikeev on 4/23/14.
//  Copyright (c) 2014 Rinat Enikeev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YTProfileOperation.h"

@interface YTMFCOperation : NSObject<YTProfileOperation>
{
    char* _randomArr;
    int _randomArrSize;
}
@property (strong, nonatomic) NSDictionary * params;
@property double delay;

// refreshes car array with new random chars
-(void)refresh;

@end

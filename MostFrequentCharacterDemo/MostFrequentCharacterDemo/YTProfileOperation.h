//
//  YTProfileOperation.h
//  MostFrequentCharacterDemo
//
//  Created by Rinat Enikeev on 4/23/14.
//  Copyright (c) 2014 Rinat Enikeev. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol YTProfileOperation <NSObject>
@required
-(double)valueFor:(NSInteger)x;
@optional
@property (strong, nonatomic) NSDictionary * params;
@property double delay;
-(NSString *)xAxisLabel;
-(NSString *)yAxisLabel;
-(NSString *)operationTitle;
-(void)refresh; // refresh internals
@end

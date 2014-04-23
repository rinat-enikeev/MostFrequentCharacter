//
//  YTViewController.h
//  MostFrequentCharacterDemo
//
//  Created by Rinat Enikeev on 4/22/14.
//  Copyright (c) 2014 Rinat Enikeev. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol YTProfileOperation;

@interface YTProfilerViewController : UIViewController<UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
-(void)addProfileOperation:(NSObject<YTProfileOperation> *)operation;
-(void)addProfileOperations:(NSArray *)operations;
@end

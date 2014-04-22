//
//  YTViewController.m
//  MostFrequentCharacterDemo
//
//  Created by Rinat Enikeev on 4/22/14.
//  Copyright (c) 2014 Rinat Enikeev. All rights reserved.
//

#import "YTViewController.h"
#import "charfreq.h"

@interface YTViewController ()
@property (strong, nonatomic) IBOutlet UITextField *characterTextField;
@property (strong, nonatomic) IBOutlet UILabel *resultLabel;
@end

@implementation YTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.characterTextField setText:@"abcdefghijklmnopqrstuvwxyxa"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions
- (IBAction)calcMostFrequentCharacter:(id)sender {
    char result = _mostFrequentCharacter([[_characterTextField text] UTF8String], [[_characterTextField text] length]);
    [_resultLabel setText:[NSString stringWithFormat:@"%c", result]];
}

@end

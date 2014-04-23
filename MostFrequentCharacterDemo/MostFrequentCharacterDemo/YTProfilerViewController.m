//
//  YTViewController.m
//  MostFrequentCharacterDemo
//
//  Created by Rinat Enikeev on 4/22/14.
//  Copyright (c) 2014 Rinat Enikeev. All rights reserved.
//

#import "YTProfilerViewController.h"
#import "RealTimePlot.h"
#import "YTProfileOperation.h"
#import "YTMFCOptmThrdCountOperation.h"
#import "YTMFCTimeOperation.h"

@interface YTProfilerViewController ()
@property (strong, nonatomic) IBOutlet UIView *plotView;
@property (strong, nonatomic) IBOutlet UIButton *operationSelectButton;
@property (strong, nonatomic) IBOutlet UITextField *xMinTV;
@property (strong, nonatomic) IBOutlet UITextField *xStepTV;
@property (strong, nonatomic) IBOutlet UITextField *xMaxTV;
@property (strong, nonatomic) IBOutlet UITextField *delayTV;
@property (strong, nonatomic) NSCharacterSet * digitsCharSet;
@property (strong, nonatomic) RealTimePlot* plot;
@property (strong, nonatomic) NSObject<YTProfileOperation> *currentOp;
@property (strong, nonatomic) NSMutableArray* operations;
@end

@implementation YTProfilerViewController

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // 1. used to allow only digits in textfields
    self.digitsCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    
    // 2. Init ops
    NSObject<YTProfileOperation>* timeOp = [[YTMFCTimeOperation alloc] init];
    [timeOp setDelay:0.2];
    NSObject<YTProfileOperation>* mfcThreadsOp =  [[YTMFCOptmThrdCountOperation alloc] init];
    [mfcThreadsOp setDelay:0.1];
    [self addProfileOperations:@[timeOp, mfcThreadsOp]];
    
    [self.operationSelectButton setTitle:[_currentOp operationTitle] forState:UIControlStateNormal];
    [self.delayTV setText:[NSString stringWithFormat:@"%.01f", [_currentOp delay]]];
    
}

#pragma mark - Header methods
-(void)addProfileOperation:(NSObject<YTProfileOperation> *)operation
{
    if (_operations == nil) {
        self.operations = [NSMutableArray array];
    }
    if (![_operations count]) {
        self.currentOp = operation;
    }
    [_operations addObject:operation];
}

-(void)addProfileOperations:(NSArray *)operations
{
    for (NSObject<YTProfileOperation> * op in operations) {
        [self addProfileOperation:op];
    }
}

#pragma mark - IBActions
- (IBAction)startMeasurements:(UIButton *)sender
{
    // 1. Replace plotView in order to free plot
    UIView *newPlotView = [[UIView alloc] initWithFrame:[_plotView frame]];
    [_plotView removeFromSuperview];
    self.plotView = newPlotView;
    [[self view] addSubview:_plotView];
    
    [sender setEnabled:NO];
    
    // 2. Prepare plot
    self.plot = [[RealTimePlot alloc] init];
    _plot.xAxisText = [_currentOp xAxisLabel];
    _plot.yAxisText = [_currentOp yAxisLabel];
    [_plot renderInView:_plotView withTheme:nil animated:YES];
    
    // 3. Read params
    NSUInteger xMin = [[_xMinTV text] integerValue];
    NSUInteger xMax = [[_xMaxTV text] integerValue];
    NSUInteger xStep = [[_xStepTV text] integerValue];
    
    // 4. Setup plot
    _plot.xMinValue = xMin;
    _plot.xMaxValue = xMax;
    _plot.xStep = xStep;
    
    [_plot renderInView:_plotView withTheme:nil animated:YES];
    
    // 5. Perform operation on whole x values
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (int x = xMin; x <= xMax; x += xStep) {
            double y = [_currentOp valueFor:x];
            
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (y > _plot.yMaxValue) {
                     _plot.yMaxValue = y;
                 }
                [_plot newData:@(y) atIndex:x];
                 if (x == xMax) {
                     [sender setEnabled:YES];
                 }
            });
        }

    });
}

- (IBAction)showOperationSettings:(UIButton *)sender {
    
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)theTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    for (int i = 0; i < [string length]; i++) {
        unichar c = [string characterAtIndex:i];
        if (![_digitsCharSet characterIsMember:c]) {
            
            if (theTextField == _delayTV && c == '.'
                // and dot is not already present
                && [[theTextField text] rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]].location == NSNotFound) {
                return YES;
            }
            
            return NO;
        }
    }
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == _delayTV) {
        [_currentOp setDelay:[[textField text] doubleValue]];
    }
}

#pragma mark - Select operation UIPickerView Stuff

static NSInteger const _senderPickerOwnerTag = 23423;
static NSInteger const _senderPickerTag = 6546;
static NSTimeInterval const showHidePickerAnimDur = 0.15;
static CGFloat const pickerHeigth = 200;
static CGRect _prevoiusFrameOfOwner;

- (IBAction)operationSelect:(UIButton *)sender {
    
    CGRect superViewBounds = [[self view] bounds];
    
    // 1. Create hiding view
    UIView* hiding = [[UIView alloc] initWithFrame:superViewBounds];
    [hiding setBackgroundColor:[UIColor clearColor]];
    [[self view] addSubview:hiding];
    [sender setTag:_senderPickerOwnerTag];
    [hiding addSubview:sender];
    
    // 2. Calculate button text width to resize button
    CGFloat senderStringWidth = [[[sender titleLabel] text] sizeWithFont:[[sender titleLabel] font]].width + [sender titleEdgeInsets].left + [sender titleEdgeInsets].right + 20;
    
    
    _prevoiusFrameOfOwner = [sender frame];
    
    [UIView animateWithDuration:showHidePickerAnimDur animations:^{
        
        // 3. resize button
        [sender setFrame:CGRectMake(_prevoiusFrameOfOwner.origin.x + _prevoiusFrameOfOwner.size.width - senderStringWidth,
                                    _prevoiusFrameOfOwner.origin.y,
                                    senderStringWidth,
                                    _prevoiusFrameOfOwner.size.height)];
        [hiding setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7]];
        
    } completion:^(BOOL finished) {
        
        // 4. add picker
        UIPickerView *operationPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(sender.frame.origin.x, sender.frame.origin.y + sender.frame.size.height, sender.frame.size.width, pickerHeigth)];
        operationPickerView.delegate = self;
        operationPickerView.dataSource = self;
        operationPickerView.showsSelectionIndicator = YES;
        [operationPickerView setTag:_senderPickerTag];
        [hiding addSubview:operationPickerView];
        [operationPickerView reloadAllComponents];
        [operationPickerView selectRow:[_operations indexOfObject:_currentOp] inComponent:0 animated:NO];
        
        // 5. on pressing on hidingview - dismiss picker
        UITapGestureRecognizer* tapToDismiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPickerView:)];
        [hiding addGestureRecognizer:tapToDismiss];
    }];
}


-(void)dismissPickerView:(UITapGestureRecognizer *)recognizer {
    UIView* picker = [[recognizer view] viewWithTag:_senderPickerTag];
    [picker removeFromSuperview];
    [UIView animateWithDuration:showHidePickerAnimDur animations:^{
        UIView* pickerOwner = [[recognizer view] viewWithTag:_senderPickerOwnerTag];
        [pickerOwner setFrame:_prevoiusFrameOfOwner];
    } completion:^(BOOL finished) {
        [[[recognizer view] superview] addSubview:[[recognizer view] viewWithTag:_senderPickerOwnerTag]];
        [[recognizer view] removeFromSuperview];
    }];
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[_operations objectAtIndex:row] operationTitle];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    self.currentOp = [_operations objectAtIndex:row];
    [_delayTV setText:[NSString stringWithFormat:@"%.01f", [_currentOp delay]]];
    [_operationSelectButton setTitle:[_currentOp operationTitle] forState:UIControlStateNormal];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_operations count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return [_operationSelectButton frame].size.width - 20;
}

#pragma mark - Orientation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft
            || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end

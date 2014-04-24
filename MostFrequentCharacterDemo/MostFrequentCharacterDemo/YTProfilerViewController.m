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
#import "YTOperationsProvider.h"

static NSString* const kMinXUDKey = @"kUserDefaultsMinXYTProfilerViewController";
static NSString* const kMaxXUDKey = @"kUserDefaultsMaxXYTProfilerViewController";
static NSString* const kXStepUDKey = @"kUserDefaultsXStepYTProfilerViewController";

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
    YTOperationsProvider* opProvider = [[YTOperationsProvider alloc] init];
    [self addProfileOperations:[opProvider allOperations]];
    [self.operationSelectButton setTitle:[_currentOp operationTitle] forState:UIControlStateNormal];
    [self.delayTV setText:[NSString stringWithFormat:@"%.01f", [_currentOp delay]]];
    
    // 3. Restore interface values from user defaults
    NSString* minXUD = [[NSUserDefaults standardUserDefaults] valueForKey:kMinXUDKey];
    if (minXUD) [self.xMinTV setText:minXUD];
    NSString* maxXUD = [[NSUserDefaults standardUserDefaults] valueForKey:kMaxXUDKey];
    if (maxXUD) [self.xMaxTV setText:maxXUD];
    NSString *xStepUD = [[NSUserDefaults standardUserDefaults] valueForKey:kXStepUDKey];
    if (xStepUD) [self.xStepTV setText:xStepUD];
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
    
    // 1. Read params
    NSUInteger xMin = [[_xMinTV text] integerValue];
    NSUInteger xMax = [[_xMaxTV text] integerValue];
    NSUInteger xStep = [[_xStepTV text] integerValue];
    
    // 2. if no measurements required return
    if (xMax <= xMin) {
        UIColor*prevColor = [_xMaxTV textColor];
        [_xMaxTV setTextColor:[UIColor redColor]];
        [_xMaxTV performSelector:@selector(setTextColor:) withObject:prevColor afterDelay:1.0];
        return;
    }
    if ((xMin + xStep) > xMax) {
        UIColor*prevColor = [_xStepTV textColor];
        [_xStepTV setTextColor:[UIColor redColor]];
        [_xStepTV performSelector:@selector(setTextColor:) withObject:prevColor afterDelay:1.0];
        return;
    }
        
    // 3. Replace plotView in order to free plot
    UIView *newPlotView = [[UIView alloc] initWithFrame:[_plotView frame]];
    [_plotView removeFromSuperview];
    self.plotView = newPlotView;
    [[self view] addSubview:_plotView];
    UITapGestureRecognizer* looseTextFieldFocusGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignAllTextFields)];
    [_plotView addGestureRecognizer:looseTextFieldFocusGR];
    
    [sender setEnabled:NO];
    
    // 4. Prepare plot
    self.plot = [[RealTimePlot alloc] init];
    _plot.xAxisText = [_currentOp xAxisLabel];
    _plot.yAxisText = [_currentOp yAxisLabel];
    [_plot renderInView:_plotView withTheme:nil animated:YES];
    
    // 5. Setup plot
    _plot.xMinValue = xMin;
    _plot.xMaxValue = xMax;
    _plot.xStep = xStep;
    
    [_plot renderInView:_plotView withTheme:nil animated:YES];
    
    // 6. Perform operation on whole x values
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

static CGFloat const PARAMS_WIDTH = 300;
static CGFloat const PARAMS_VIEW_OFFSET = 10;
static int const SETTINGS_HIDDEN_VIEW_TAG = 9999;
static NSString *delayPlaceHolderKey = @"delay";
- (IBAction)showOperationSettings:(UIButton *)sender {
    int paramCount = [[_currentOp params] count];
    if (paramCount > 0) {
        
        // {{ 1. Create container view in hiding view
        CGRect superViewBounds = [[self view] bounds];
        UIView* hiding = [[UIView alloc] initWithFrame:superViewBounds];
        [hiding setTag:SETTINGS_HIDDEN_VIEW_TAG];
        [hiding setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7]];
        
        UIView* container = [[UIView alloc] initWithFrame:CGRectMake(sender.frame.origin.x - PARAMS_WIDTH + sender.frame.size.width,
                                                                     sender.frame.origin.y + sender.frame.size.height + PARAMS_VIEW_OFFSET,
                                                                     PARAMS_WIDTH,
                                                                     (sender.frame.size.height + PARAMS_VIEW_OFFSET) * (paramCount + 1))];
        [hiding addSubview:container];
        // }}
        
        
        // {{ 2. Create labels and textfields for params from dict
        int keyNum = 0;

        for (NSString* key in [_currentOp.params allKeys]) {
            
            // {{ 2.1 label
            UILabel* paramLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                            sender.frame.size.height * keyNum + PARAMS_VIEW_OFFSET * keyNum ,
                                                                            PARAMS_WIDTH / 2 - 10, sender.frame.size.height)];
            [paramLabel setBackgroundColor:[UIColor darkGrayColor]];
            [paramLabel setTextColor:[UIColor whiteColor]];
            paramLabel.layer.cornerRadius = 5.0;
            paramLabel.textAlignment = NSTextAlignmentCenter;
            [paramLabel setText:key];
            // }}
            
            // {{ 2.2 textfield
            UITextField* paramTextView = [[UITextField alloc] initWithFrame:CGRectMake(PARAMS_WIDTH / 2 ,
                                                                                       sender.frame.size.height * keyNum + PARAMS_VIEW_OFFSET * keyNum,
                                                                                       PARAMS_WIDTH / 2,
                                                                                       sender.frame.size.height)];
            [paramTextView addTarget:self
                          action:@selector(paramFieldDidChange:)
                forControlEvents:UIControlEventEditingChanged];
            [paramTextView setText:[[_currentOp.params valueForKey:key] stringValue]];
            [paramTextView setPlaceholder:key];
            [self configureParamTextField:paramTextView];
            // }}

            // {{ 2.3 add to container view
            [container addSubview:paramLabel];
            [container addSubview:paramTextView];
            [container bringSubviewToFront:paramTextView];
            keyNum++;
            // }}
        }
        
        // {{ 3. add common delay parameter
        // {{ 3.1 label
        UILabel* paramLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, sender.frame.size.height * keyNum + PARAMS_VIEW_OFFSET *                 keyNum,
                                                                        PARAMS_WIDTH / 2 - 10, sender.frame.size.height)];
        [paramLabel setBackgroundColor:[UIColor darkGrayColor]];
        [paramLabel setTextColor:[UIColor whiteColor]];
        paramLabel.layer.cornerRadius = 5.0;
        paramLabel.textAlignment = NSTextAlignmentCenter;
        [paramLabel setText:@"Delay"];
        // }}
    
        // {{3.2 textfield
        UITextField* paramTextView = [[UITextField alloc] initWithFrame:CGRectMake(PARAMS_WIDTH / 2 ,
                                                                                   sender.frame.size.height * keyNum + PARAMS_VIEW_OFFSET * keyNum,
                                                                                   PARAMS_WIDTH / 2,
                                                                                   sender.frame.size.height)];
        [paramTextView addTarget:self
                          action:@selector(paramFieldDidChange:)
                forControlEvents:UIControlEventEditingChanged];
        [paramTextView setText:[NSString stringWithFormat:@"%.1f", [_currentOp delay]]];
        [paramTextView setPlaceholder:delayPlaceHolderKey];
        [self configureParamTextField:paramTextView];
        // }}
        
        // {{ 3.3 add to container view
        [container addSubview:paramLabel];
        [container addSubview:paramTextView];
        [container bringSubviewToFront:paramTextView];
        // }}
        
        
        [[self view] addSubview:hiding];
        UITapGestureRecognizer* tapToDismissAndStoreParams = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissParamsView:)];
        [hiding addGestureRecognizer:tapToDismissAndStoreParams];
        
    }
}

-(void)configureParamTextField:(UITextField*)paramTextView
{
    [paramTextView setBackgroundColor:[UIColor grayColor]];
    [paramTextView setTextColor:[UIColor whiteColor]];
    paramTextView.borderStyle = UITextBorderStyleRoundedRect;
    paramTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    paramTextView.keyboardType = UIKeyboardTypeDefault;
    paramTextView.returnKeyType = UIReturnKeyDone;
    paramTextView.userInteractionEnabled = YES;
    paramTextView.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [paramTextView setDelegate:self];
    paramTextView.textAlignment = NSTextAlignmentRight;
    [paramTextView setKeyboardType:UIKeyboardTypeNumberPad];

}

-(void)paramFieldDidChange:(UITextField*)textField
{
    if ([[textField placeholder] isEqualToString:delayPlaceHolderKey]) {
        [_currentOp setDelay:[[textField text] doubleValue]];
        return;
    }
    [_currentOp.params setValue:[NSNumber numberWithInt:[[textField text] integerValue]] forKey:[textField placeholder]];
    [_operationSelectButton setTitle:[_currentOp operationTitle] forState:UIControlStateNormal];
}

-(void)dismissParamsView:(UITapGestureRecognizer *)recognizer {
    [[recognizer view] removeFromSuperview];
}

#pragma mark - UITextFieldDelegate
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self resignAllTextFields];
}
-(void)resignAllTextFields {
    for (UIView * txt in self.view.subviews){
        if ([txt isKindOfClass:[UITextField class]] && [txt isFirstResponder]) {
            [txt resignFirstResponder];
        }
    }
}

- (BOOL)textField:(UITextField *)theTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@"\n"])
    {
        [theTextField resignFirstResponder];
        return YES;
    }
    for (int i = 0; i < [string length]; i++) {
        unichar c = [string characterAtIndex:i];
        if (![_digitsCharSet characterIsMember:c]) {
            
            if ([[theTextField placeholder] isEqualToString:delayPlaceHolderKey] && c == '.'
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
    if([self stringIsEmpty:[textField text]])
    {
        [textField setText:@"0"];
    }
    
    if (textField == _delayTV) {
        [_currentOp setDelay:[[textField text] doubleValue]];
    }
    
    // store to user defaults x values
    if (textField == _xStepTV) {
        [[NSUserDefaults standardUserDefaults] setValue:[textField text] forKey:kXStepUDKey];
    }
    if (textField == _xMaxTV) {
        [[NSUserDefaults standardUserDefaults] setValue:[textField text] forKey:kMaxXUDKey];
    }
    if (textField == _xMinTV) {
        [[NSUserDefaults standardUserDefaults] setValue:[textField text] forKey:kMinXUDKey];
    }
}

-(BOOL)stringIsEmpty:(NSString *)string {
    if([string length] == 0) { //string is empty or nil
        return YES;
    }
    
    if(![[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        //string is all whitespace
        return YES;
    }
    
    return NO;
}

#pragma mark - Select operation UIPickerView Stuff

static NSInteger const _senderPickerOwnerTag = 23423;
static NSInteger const _senderPickerTag = 6546;
static NSTimeInterval const showHidePickerAnimDur = 0.15;
static CGFloat const pickerHeigth = 200;
static CGRect _prevoiusFrameOfOwner;

- (void)presentPickerUnder:(UIButton *)sender inHiding:(UIView *)hiding {
    // 4. add picker
    CGRect pickerRect = CGRectMake(sender.frame.origin.x, sender.frame.origin.y + sender.frame.size.height, sender.frame.size.width, pickerHeigth);
    UIPickerView *operationPickerView = [[UIPickerView alloc] initWithFrame:pickerRect];
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
}

- (IBAction)operationSelect:(UIButton *)sender {
    
    CGRect superViewBounds = [[self view] bounds];
    
    // 1. Create hiding view
    UIView* hiding = [[UIView alloc] initWithFrame:superViewBounds];
    [hiding setBackgroundColor:[UIColor clearColor]];
    [[self view] addSubview:hiding];
    [sender setTag:_senderPickerOwnerTag];
    [hiding addSubview:sender];
    [sender setEnabled:NO];
    
    // 2. Calculate button text width to resize button
    CGFloat senderStringWidth = [[[sender titleLabel] text] sizeWithFont:[[sender titleLabel] font]].width + [sender titleEdgeInsets].left + [sender titleEdgeInsets].right + 20;
    _prevoiusFrameOfOwner = [sender frame];
    
    if (_prevoiusFrameOfOwner.size.width < senderStringWidth) {
        
        [UIView animateWithDuration:showHidePickerAnimDur animations:^{
            
            // 3. resize button
            [sender setFrame:CGRectMake(_prevoiusFrameOfOwner.origin.x + _prevoiusFrameOfOwner.size.width - senderStringWidth,
                                        _prevoiusFrameOfOwner.origin.y,
                                        senderStringWidth,
                                        _prevoiusFrameOfOwner.size.height)];
            [hiding setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7]];
            
        } completion:^(BOOL finished) {
            [self presentPickerUnder:sender inHiding:hiding];
        }];
    } else {
        [UIView animateWithDuration:showHidePickerAnimDur animations:^{
            [hiding setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7]];
        } completion:^(BOOL finished) {
            [self presentPickerUnder:sender inHiding:hiding];
        }];

    }
    
}


-(void)dismissPickerView:(UITapGestureRecognizer *)recognizer {
    UIView* picker = [[recognizer view] viewWithTag:_senderPickerTag];
    [picker removeFromSuperview];
    UIButton* pickerOwner = (UIButton*)[[recognizer view] viewWithTag:_senderPickerOwnerTag];
    [UIView animateWithDuration:showHidePickerAnimDur animations:^{
        [pickerOwner setFrame:_prevoiusFrameOfOwner];
    } completion:^(BOOL finished) {
        [[[recognizer view] superview] addSubview:pickerOwner];
        [[recognizer view] removeFromSuperview];
        [pickerOwner setEnabled:YES];
    }];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel* tView = (UILabel*)view;
    if (!tView){
        tView = [[UILabel alloc] init];
        UIColor* pickerTextColor = [UIColor colorWithRed:189.0/255.0 green:183.0/255.0 blue:107.0/255.0 alpha:1.0];
        [tView setTextColor:pickerTextColor];
        [tView setText:[[_operations objectAtIndex:row] operationTitle]];
    }
    return tView;
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

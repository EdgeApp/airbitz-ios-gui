//
//  QuestionAnswerView.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/22/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "QuestionAnswerView.h"
#import "Theme.h"
#import "PopupWheelPickerView.h"

#define QA_TABLE_HEIGHT     200.0

@interface QuestionAnswerView () <UITextFieldDelegate, PopupWheelPickerViewDelegate>
{
	BOOL            _bQuestionExpanded;
//	UITableView     *_qaTable;
	CGRect          _originalFrame;
    NSDictionary    *_dict;
    BOOL            _bDisableSelecting;
}

@property (nonatomic, weak) IBOutlet UIButton       *questionButtonBig;
@property (nonatomic, strong) PopupWheelPickerView  *popupWheelPicker;
@property (nonatomic, copy) NSString                *strPrevQuestion;
@property (nonatomic, weak) UIView                  *parentView;

@end

@implementation QuestionAnswerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code
        self.strPrevQuestion = @"";
        [self setThemeValues];
    }
    return self;
}

- (void)setThemeValues {
    self.questionButtonBig.backgroundColor = [Theme Singleton].colorDarkPrimary;
    self.answerField.textColor = [Theme Singleton].colorWhite;
    self.labelQuestion.textColor = [Theme Singleton].colorWhite;
}

#pragma mark - static Methods

+ (QuestionAnswerView *)CreateInsideView:(UIView *)parentView withDelegate:(id<QuestionAnswerViewDelegate>)delegate
{
	QuestionAnswerView *qav;
	
    qav = [[[NSBundle mainBundle] loadNibNamed:@"QuestionAnswerView~iphone" owner:nil options:nil] objectAtIndex:0];

	[parentView addSubview:qav];
	qav.delegate = delegate;
	
	qav.answerField.delegate = qav;
    qav.labelQuestion.text = NSLocalizedString(@"Choose a Question", nil);
    qav.parentView = parentView;
	return qav;
}

#pragma mark - Misc Methods

- (void)closeTable
{
	if (_bQuestionExpanded)
	{
		[self QuestionButton];
	}
	[self.answerField resignFirstResponder];
}

- (NSString *)question
{
	return self.labelQuestion.text;
}

- (NSString *)answer
{
	return self.answerField.text;
}

- (void)showTable
{
    [self.delegate QuestionAnswerView:self];
    
    NSMutableArray *arrayQuestions = [[NSMutableArray alloc] init];
    NSMutableArray *array = [[NSMutableArray alloc] init];

    for (NSDictionary *d in self.availableQuestions)
    {
        [arrayQuestions addObject:d[@"question"]];
    }
    
    [array addObject:arrayQuestions];
    
    self.popupWheelPicker = [PopupWheelPickerView CreateForView:self.parentView
                                             positionRelativeTo:self
                                                   withPosition:PopupWheelPickerPosition_Above
                                                    withChoices:[array copy]
                                             startingSelections:nil
                                                       userData:nil
                                                    andDelegate:self];

}

- (void)presentQuestionChoices
{
    [self QuestionButton];
}

- (void)disableSelecting
{
    _bDisableSelecting = YES;
}

#pragma mark - Popup Wheel Picker Delegate Methods

- (void)PopupWheelPickerViewExit:(PopupWheelPickerView *)view withSelections:(NSArray *)arraySelections userData:(id)data
{
    _dict = [self.availableQuestions objectAtIndex:[(NSNumber *)arraySelections[0] intValue]];
    
    if (_dict)
    {
        self.strPrevQuestion = self.labelQuestion.text;
        self.labelQuestion.text = [_dict objectForKey:@"question"];
        self.answerField.minimumCharacters = [[_dict objectForKey:@"minLength"] intValue];
        _questionSelected = YES;
        
        [self performSelector:@selector(notifyQuestionSelected) withObject:nil afterDelay:[Theme Singleton].animationDurationTimeDefault];
    }
    [self dismissPopupPicker];
}

- (void)PopupWheelPickerViewCancelled:(PopupWheelPickerView *)view userData:(id)data
{
    [self dismissPopupPicker];
}

- (void)dismissPopupPicker;
{
    if (self.popupWheelPicker)
    {
        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                              delay:[Theme Singleton].animationDelayTimeDefault
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             [self.popupWheelPicker removeFromSuperview];
         }
                         completion:^(BOOL finished)
         {
             self.popupWheelPicker = nil;
         }];
    }
}

#pragma mark - Action Methods

- (IBAction)QuestionButton
{
    if (_bDisableSelecting == NO)
    {
        [self.superview bringSubviewToFront:self];
        
        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                              delay:[Theme Singleton].animationDelayTimeDefault
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             [self showTable];
         }
                         completion:^(BOOL finished)
         {
             
         }];
    }
}

- (void)notifyQuestionSelected
{
	[self.delegate QuestionAnswerView:self didSelectQuestion:_dict oldQuestion:self.strPrevQuestion];
}

#pragma mark - UITextField delegates

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	[self.delegate QuestionAnswerView:self didSelectAnswerField:textField];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
    [self.delegate QuestionAnswerView:self didReturnOnAnswerField:textField];
	return YES;
}

@end

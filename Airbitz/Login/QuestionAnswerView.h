//
//  QuestionAnswerView.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/22/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MinCharTextField.h"

#define QA_TABLE_ROW_HEIGHT	30.0;

@protocol QuestionAnswerViewDelegate;

@interface QuestionAnswerView : UIView

@property (nonatomic, assign)   id<QuestionAnswerViewDelegate>  delegate;
@property (nonatomic, strong)   NSArray                         *availableQuestions; /* these show up in the table */
@property (nonatomic, readonly) BOOL                            questionSelected;
@property (nonatomic, assign)   BOOL                            isLastQuestion;

@property (weak, nonatomic) IBOutlet UILabel            *labelQuestion;
@property (nonatomic, weak) IBOutlet MinCharTextField   *answerField;

+ (QuestionAnswerView *)CreateInsideView:(UIView *)parentView withDelegate:(id<QuestionAnswerViewDelegate>)delegate;
- (void)closeTable;
- (NSString *)question;
- (NSString *)answer;
- (void)presentQuestionChoices;
- (void)disableSelecting;
- (void)dismissPopupPicker;

@end

@protocol QuestionAnswerViewDelegate <NSObject>

@required
- (void)QuestionAnswerView:(QuestionAnswerView *)view;
- (void)QuestionAnswerViewTableDismissed:(QuestionAnswerView *)view;
- (void)QuestionAnswerView:(QuestionAnswerView *)view didSelectQuestion:(NSDictionary *)question oldQuestion:(NSString *)oldQuestion; //dict contains 'question' and 'minLength'
- (void)QuestionAnswerView:(QuestionAnswerView *)view didSelectAnswerField:(UITextField *)textField;
- (void)QuestionAnswerView:(QuestionAnswerView *)view didReturnOnAnswerField:(UITextField *)textField;

@optional

@end

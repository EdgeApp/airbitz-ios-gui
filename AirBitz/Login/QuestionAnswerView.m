//
//  QuestionAnswerView.m
//
 
//  Copyright (c) 2014, Airbitz
//  All rights reserved.
//
//  Redistribution and use in source and binary forms are permitted provided that
//  the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//  3. Redistribution or use of modified source code requires the express written
//  permission of Airbitz Inc.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the Airbitz Project.
//
//  See AUTHORS for contributing developers
//


#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end



#import "QuestionAnswerView.h"


#define QA_TABLE_HEIGHT     200.0
#define QA_TABLE_ROW_HEIGHT	30.0;

#define QA_ANIM_TIME_SECS   0.35

@interface QuestionAnswerView () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
	BOOL            _bQuestionExpanded;
	UITableView     *_qaTable;
	CGRect          _originalFrame;
    NSDictionary    *_dict;
    BOOL            _bDisableSelecting;
}

@property (nonatomic, weak) IBOutlet UIButton       *questionButtonBig;
@property (nonatomic, weak) IBOutlet UIImageView    *expandCollapseImage;

@property (nonatomic, copy) NSString                *strPrevQuestion;

@end

@implementation QuestionAnswerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code
        self.strPrevQuestion = @"";
    }
    return self;
}

#pragma mark - static Methods

+ (QuestionAnswerView *)CreateInsideView:(UIView *)parentView withDelegate:(id<QuestionAnswerViewDelegate>)delegate
{
	QuestionAnswerView *qav;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		qav = [[[NSBundle mainBundle] loadNibNamed:@"QuestionAnswerView~iphone" owner:nil options:nil] objectAtIndex:0];
	}
	else
	{
		qav = [[[NSBundle mainBundle] loadNibNamed:@"QuestionAnswerView~ipad" owner:nil options:nil] objectAtIndex:0];
		
	}
	[parentView addSubview:qav];
	qav.delegate = delegate;
	qav.expandCollapseImage.transform = CGAffineTransformRotate(qav.expandCollapseImage.transform, M_PI);
	
	qav.answerField.delegate = qav;
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
	float yOriginOffset = self.questionButtonBig.frame.size.height / 2;
	
	CGRect tableFrame = self.questionButtonBig.frame;
	tableFrame.origin.x += 1.0;
	tableFrame.size.width -= 2.0;
	tableFrame.origin.y += yOriginOffset;
	tableFrame.size.height = 0.0;
	
	_qaTable = [[UITableView alloc] initWithFrame:tableFrame];
	_qaTable.delegate = self;
	_qaTable.dataSource = self;
	_qaTable.layer.cornerRadius = 6.0;
	
	[self insertSubview:_qaTable belowSubview:self.questionButtonBig];
	
	_originalFrame = self.frame;
	self.answerField.enabled = NO;
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = _qaTable.frame;
		 frame.size.height = QA_TABLE_HEIGHT;
		 _qaTable.frame = frame;
		 
		 CGRect myFrame = _originalFrame;
		 myFrame.size.height = frame.origin.y + frame.size.height;
		 self.frame = myFrame;
		 
		 [self.delegate QuestionAnswerView:self tablePresentedWithFrame:myFrame];
	 }
	 completion:^(BOOL finished)
	 {
		 
	 }];
	
}

- (void)hideTable
{
	[self.delegate QuestionAnswerViewTableDismissed:self];
	self.answerField.enabled = YES;
	[UIView animateWithDuration:QA_ANIM_TIME_SECS
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = _qaTable.frame;
		 frame.size.height = 0.0;
		 _qaTable.frame = frame;
		 
		 self.frame = _originalFrame;
		 
	 }
	 completion:^(BOOL finished)
	 {
		 
	 }];
}

- (void)presentQuestionChoices
{
    [self QuestionButton];
}

- (void)disableSelecting
{
    _bDisableSelecting = YES;
    self.expandCollapseImage.hidden = YES;
}

#pragma mark - Action Methods

- (IBAction)QuestionButton
{
    if (_bDisableSelecting == NO)
    {
        if (_bQuestionExpanded)
        {
            _bQuestionExpanded = NO;
            [UIView animateWithDuration:QA_ANIM_TIME_SECS
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^
             {
                 self.expandCollapseImage.transform = CGAffineTransformRotate(self.expandCollapseImage.transform, M_PI);
             }
                             completion:^(BOOL finished)
             {

             }];

            [self hideTable];
        }
        else
        {
            _bQuestionExpanded = YES;

            [self.superview bringSubviewToFront:self];

            [UIView animateWithDuration:0.35
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^
             {
                 self.expandCollapseImage.transform = CGAffineTransformRotate(self.expandCollapseImage.transform, -M_PI);
             }
                             completion:^(BOOL finished)
             {
                 
             }];
            
            [self showTable];
        }
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

#pragma mark - TableView delegates

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	//default section header color was gray.  Needed to add this in order to set the bkg color to white
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, self.questionButtonBig.frame.size.height / 2.0)];
	[headerView setBackgroundColor:[UIColor whiteColor]];
	
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return self.questionButtonBig.frame.size.height / 2.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.availableQuestions.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return QA_TABLE_ROW_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSInteger row = [indexPath row];
	UITableViewCell *cell;
	
	//wallet cell
	static NSString *cellIdentifier = @"QACell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	
	NSDictionary *dict = [self.availableQuestions objectAtIndex:indexPath.row];
    [cell.textLabel setFont:[UIFont systemFontOfSize:12]];
	//cell.textLabel.minimumScaleFactor = 0.5;
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.numberOfLines = 0;
	cell.textLabel.text = [dict objectForKey:@"question"];
	//NSLog(@"Row: %i, text: %@", indexPath.row, cell.textLabel.text);
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"Selected row: %i", indexPath.row);
	_dict = [self.availableQuestions objectAtIndex:indexPath.row];
	//[self hideTable];
    [self QuestionButton];

    self.strPrevQuestion = self.labelQuestion.text;
    self.labelQuestion.text = [_dict objectForKey:@"question"];
	self.answerField.minimumCharacters = [[_dict objectForKey:@"minLength"] intValue];
	_questionSelected = YES;

    [self performSelector:@selector(notifyQuestionSelected) withObject:nil afterDelay:QA_ANIM_TIME_SECS];
}

@end

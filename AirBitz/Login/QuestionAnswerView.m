//
//  QuestionAnswerView.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/22/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "QuestionAnswerView.h"


#define QA_TABLE_HEIGHT	200.0
#define QA_TABLE_ROW_HEIGHT	30.0;

@interface QuestionAnswerView () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
	BOOL questionExpanded;
	UITableView *qaTable;
	CGRect originalFrame;
}
@property (nonatomic, weak) IBOutlet UIButton *questionButton;

@property (nonatomic, weak) IBOutlet UIImageView *expandCollapseImage;
@end

@implementation QuestionAnswerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code
    }
    return self;
}

+(QuestionAnswerView *)CreateInsideView:(UIView *)parentView withDelegate:(id<QuestionAnswerViewDelegate>)delegate
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

-(void)closeTable
{
	if(questionExpanded)
	{
		[self QuestionButton];
	}
	[self.answerField resignFirstResponder];
}

-(NSString *)question
{
	return self.questionButton.titleLabel.text;
}

-(NSString *)answer
{
	return self.answerField.text;
}

-(IBAction)QuestionButton
{
	if(questionExpanded)
	{
		questionExpanded = NO;
		[UIView animateWithDuration:0.35
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
		questionExpanded = YES;
		
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

-(void)showTable
{
	float yOriginOffset = self.questionButton.frame.size.height / 2;
	
	CGRect tableFrame = self.questionButton.frame;
	tableFrame.origin.x += 1.0;
	tableFrame.size.width -= 2.0;
	tableFrame.origin.y += yOriginOffset;
	tableFrame.size.height = 0.0;
	
	qaTable = [[UITableView alloc] initWithFrame:tableFrame];
	qaTable.delegate = self;
	qaTable.dataSource = self;
	qaTable.layer.cornerRadius = 6.0;
	
	[self insertSubview:qaTable belowSubview:self.questionButton];
	
	originalFrame = self.frame;
	self.answerField.enabled = NO;
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = qaTable.frame;
		 frame.size.height = QA_TABLE_HEIGHT;
		 qaTable.frame = frame;
		 
		 CGRect myFrame = originalFrame;
		 myFrame.size.height = frame.origin.y + frame.size.height;
		 self.frame = myFrame;
		 
		 [self.delegate QuestionAnswerView:self tablePresentedWithFrame:myFrame];
	 }
	 completion:^(BOOL finished)
	 {
		 
	 }];
	
}

-(void)hideTable
{
	[self.delegate QuestionAnswerViewTableDismissed:self];
	self.answerField.enabled = YES;
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = qaTable.frame;
		 frame.size.height = 0.0;
		 qaTable.frame = frame;
		 
		 self.frame = originalFrame;
		 
	 }
	 completion:^(BOOL finished)
	 {
		 
	 }];
}

#pragma mark UITextField delegates

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	[self.delegate QuestionAnswerView:self didSelectAnswerField:textField];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

#pragma mark TableView delegates

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	//default section header color was gray.  Needed to add this in order to set the bkg color to white
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, self.questionButton.frame.size.height / 2.0)];
	[headerView setBackgroundColor:[UIColor whiteColor]];
	
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return self.questionButton.frame.size.height / 2.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.availableQuestions.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return QA_TABLE_ROW_HEIGHT;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
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
	cell.textLabel.text = [dict objectForKey:@"question"];
	cell.textLabel.minimumScaleFactor = 0.5;
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	//NSLog(@"Row: %i, text: %@", indexPath.row, cell.textLabel.text);
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"Selected row: %i", indexPath.row);
	NSDictionary *dict = [self.availableQuestions objectAtIndex:indexPath.row];
	[self.delegate QuestionAnswerView:self didSelectQuestion:dict oldQuestion:self.questionButton.titleLabel.text];
	[self hideTable];
	
	[self.questionButton setTitle:[dict objectForKey:@"question" ] forState:UIControlStateNormal];
	self.answerField.minimumCharacters = [[dict objectForKey:@"minLength"] intValue];
	_questionSelected = YES;
}

@end

//
//  PasswordRecoveryViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/20/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "PasswordRecoveryViewController.h"
#import "QuestionAnswerView.h"
#import "ABC.h"
#import "User.h"

#define NUM_QUESTION_ANSWER_BLOCKS	6
#define QA_STARTING_Y_POSITION	67.0;

typedef enum eAlertType
{
	ALERT_TYPE_SETUP_COMPLETE,
	ALERT_TYPE_SKIP_THIS_STEP
}tAlertType;

@interface PasswordRecoveryViewController () <UIScrollViewDelegate, QuestionAnswerViewDelegate, UIAlertViewDelegate>
{
	BOOL bSuccess;
	NSString *strReason;
	float completeButtonToEmbossImageDistance;
	NSMutableArray *arrayCategoryString;
	NSMutableArray *arrayCategoryNumeric;
	NSMutableArray *arrayCategoryAddress;
	NSMutableArray *arrayChosenQuestions;
	UITextField *activeTextField;
	CGSize defaultContentSize;
	tAlertType alertType;
}
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIButton *completeSignupButton;
@property (nonatomic, weak) IBOutlet UIImageView *embossImage;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityView;
@end

@implementation PasswordRecoveryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	arrayCategoryString		= [[NSMutableArray alloc] init];
	arrayCategoryNumeric	= [[NSMutableArray alloc] init];
	arrayCategoryAddress	= [[NSMutableArray alloc] init];
	arrayChosenQuestions	= [[NSMutableArray alloc] init];
	
	tABC_Error Error;
    ABC_GetQuestionChoices([self.userName UTF8String],
                           PW_ABC_Request_Callback,
                           (__bridge void *)self,
                           &Error);
    [self printABC_Error:&Error];
	
	completeButtonToEmbossImageDistance = (self.embossImage.frame.origin.y + self.embossImage.frame.size.height) - self.completeSignupButton.frame.origin.y;
	
    if (ABC_CC_Ok == Error.code)
    {
       // [self blockUser:YES];
    }
    else
    {
        NSLog(@"%@",  [NSString stringWithFormat:@"GetQuestionChoices failed:\n%s", Error.szDescription]);
    }
	
	//NSLog(@"Adding keyboard notification");
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)Back
{
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = self.view.frame;
		 frame.origin.x = frame.size.width;
		 self.view.frame = frame;
	 }
	 completion:^(BOOL finished)
	 {
		 [self.delegate passwordRecoveryViewControllerDidFinish:self];
	 }];
}

-(IBAction)SkipThisStep
{
	alertType = ALERT_TYPE_SKIP_THIS_STEP;
	
	
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:NSLocalizedString(@"Skip this step", @"Title of Skip this step alert")
						  message:@"Warning: You will never be able to recover your password if it is forgotten"
						  delegate:self
						  cancelButtonTitle:@"Cancel"
						  otherButtonTitles:@"OK", nil];
	[alert show];
	
}

-(IBAction)CompleteSignup
{
	//NSLog(@"Complete Signup");
	//verify that all six questions have been selected
	BOOL allQuestionsSelected = YES;
	BOOL allAnswersValid = YES;
	NSMutableString *questions = [[NSMutableString alloc] init];
	NSMutableString *answers = [[NSMutableString alloc] init];
	
	[self.activityView startAnimating];
	
	int count = 0;
	for(UIView *view in self.scrollView.subviews)
	{
		if([view isKindOfClass:[QuestionAnswerView class]])
		{
			QuestionAnswerView *qaView = (QuestionAnswerView *)view;
			if(qaView.questionSelected == NO)
			{
				allQuestionsSelected = NO;
				break;
			}
			//verify that all six answers have achieved their minimum character limit
			if(qaView.answerField.satisfiesMinimumCharacters == NO)
			{
				allAnswersValid = NO;
			}
			else
			{
				//add question and answer to arrays
				if(count)
				{
					[questions appendString:@"\n"];
					[answers appendString:@"\n"];
				}
				[questions appendString:[qaView question]];
				[answers appendString:[qaView answer]];
			}
		}
		count++;
	}
	if(allQuestionsSelected)
	{
		if(allAnswersValid)
		{
			[self commitQuestions:questions andAnswersToABC:answers];
		}
		else
		{
			UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle:NSLocalizedString(@"Password Recovery Setup", @"Title of account password recovery setup alert")
								  message:@"You must answer all six questions.  Make sure your answers are long enough."
								  delegate:nil
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil];
			[alert show];
		}
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Password Recovery Setup", @"Title of account password recovery setup alert")
							  message:@"You must choose all six questions before proceeding"
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
	}
}

-(void)commitQuestions:(NSString *)questions andAnswersToABC:(NSString *)answers
{
	tABC_Error Error;
	tABC_CC result;
				

	 result = ABC_SetAccountRecoveryQuestions([[User Singleton].name UTF8String],
	 [[User Singleton].password UTF8String],
	 [questions UTF8String],
	 [answers UTF8String],
	 PW_ABC_Request_Callback,
	 (__bridge void *)self,
	 &Error);
	 
	[self printABC_Error:&Error];
	
	if (ABC_CC_Ok == result)
	{
	}
	else
	{
		
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Account Sign Up", @"Title of account signup error alert")
							  message:[NSString stringWithFormat:@"Sign-up failed:\n%s", Error.szDescription]
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
		//NSLog(@"%@", [NSString stringWithFormat:@"Sign-up failed:\n%s", Error.szDescription]);
	}
	
}

- (void)printABC_Error:(const tABC_Error *)pError
{
    if (pError)
    {
        if (pError->code != ABC_CC_Ok)
        {
            printf("Code: %d, Desc: %s, Func: %s, File: %s, Line: %d\n",
                   pError->code,
                   pError->szDescription,
                   pError->szSourceFunc,
                   pError->szSourceFile,
                   pError->nSourceLine
                   );
        }
    }
}

-(NSArray *)prunedQuestionsFor:(NSArray *)questions
{
	NSMutableArray *prunedQuestions = [[NSMutableArray alloc] init];
	
	for(NSDictionary *question in questions)
	{
		BOOL wasChosen = NO;
		for(NSString *string in arrayChosenQuestions)
		{
			if([string isEqualToString:[question objectForKey:@"question"]])
			{
				wasChosen = YES;
				break;
			}
			
		}
		if(!wasChosen)
		{
			[prunedQuestions addObject:question];
		}
	}
	return prunedQuestions;
}

#pragma mark AlertView delegates

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(alertType == ALERT_TYPE_SETUP_COMPLETE)
	{
		//user dismissed recovery questions complete alert
		[self.delegate passwordRecoveryViewControllerDidFinish:self];
	}
	else
	{
		//SKIP THIS STEP alert
		if(buttonIndex == 1)
		{
			[self.delegate passwordRecoveryViewControllerDidFinish:self];
		}
	}
}

#pragma mark keyboard callbacks

- (void)keyboardWillShow:(NSNotification *)notification
{
	if(activeTextField)
	{
		//Get KeyboardFrame (in Window coordinates)
		NSDictionary *userInfo = [notification userInfo];
		CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
		
		CGRect ownFrame = [self.view.window convertRect:keyboardFrame toView:self.view];
		
		//get textfield frame in window coordinates
		CGRect textFieldFrame = [activeTextField.superview convertRect:activeTextField.frame toView:self.view];
		
		//calculate offset
		float distanceToMove = (textFieldFrame.origin.y + textFieldFrame.size.height + 20.0) - ownFrame.origin.y;
		
		if(distanceToMove > 0)
		{
			//need to scroll
			//NSLog(@"Scrolling %f", distanceToMove);
			CGPoint curContentOffset = self.scrollView.contentOffset;
			curContentOffset.y += distanceToMove;
			[self.scrollView setContentOffset:curContentOffset animated:YES];
		}
		CGSize size = defaultContentSize;
		size.height += keyboardFrame.size.height;
		self.scrollView.contentSize = size;
	}
	
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	if(activeTextField)
	{
		//NSLog(@"Keyboard will hide for Login View Controller");

		activeTextField = nil;
	}
	self.scrollView.contentSize = defaultContentSize;
}

#pragma mark ABC Callbacks

- (void)getPasswordRecoveryQuestionsComplete
{
    //NSLog(@"Get Questions complete");
    if (bSuccess)
    {
		//NSLog(@"Got questions");
		float posY = QA_STARTING_Y_POSITION;
		CGSize size = self.scrollView.contentSize;
		size.height = posY;
		
		//add QA blocks
		for(int i=0; i<NUM_QUESTION_ANSWER_BLOCKS; i++)
		{
			QuestionAnswerView *qav = [QuestionAnswerView CreateInsideView:self.scrollView withDelegate:self];
			
			CGRect frame = qav.frame;
			frame.origin.x = (self.scrollView.frame.size.width - frame.size.width ) / 2;
			frame.origin.y = posY;
			qav.frame = frame;
			
			qav.tag = i;
			//qav.alpha = 0.5;
			
			//CGSize size = self.scrollView.contentSize;
			size.height += qav.frame.size.height;
			
			
			posY += frame.size.height;
		}
		
		//position complete Signup button below QA views
		CGRect btnFrame = self.completeSignupButton.frame;
		btnFrame.origin.y = posY;
		self.completeSignupButton.frame = btnFrame;
		size.height += btnFrame.size.height + 20.0;
		
		//stretch emboss image to encompass Complete Signup button at its new location
		CGRect embossFrame = self.embossImage.frame;
		embossFrame.size.height = btnFrame.origin.y + completeButtonToEmbossImageDistance - embossFrame.origin.y;
		self.embossImage.frame = embossFrame;
		
		self.scrollView.contentSize = size;
		defaultContentSize = size;
    }
    else
    {
        //NSLog(@"%@", [NSString stringWithFormat:@"Account creation failed\n%@", strReason]);
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Account Sign Up", @"Title of account signup error alert")
							  message:[NSString stringWithFormat:@"Sign-up failed:\n%@", strReason]
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
    }
}

- (void)categorizeQuestionChoices:(tABC_QuestionChoices *)pChoices
{
	//splits wad of questions into three categories:  string, numeric and address
    if (pChoices)
    {
        if (pChoices->aChoices)
        {
            for (int i = 0; i < pChoices->numChoices; i++)
            {
                tABC_QuestionChoice *pChoice = pChoices->aChoices[i];
				NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
				
				[dict setObject: [NSString stringWithFormat:@"%s", pChoice->szQuestion] forKey:@"question"];
				[dict setObject: [NSNumber numberWithInt:pChoice->minAnswerLength] forKey:@"minLength"];
				
                printf("question: %s, category: %s, min: %d\n", pChoice->szQuestion, pChoice->szCategory, pChoice->minAnswerLength);
				
				NSString *category = [NSString stringWithFormat:@"%s", pChoice->szCategory];
				if([category isEqualToString:@"string"])
				{
					[arrayCategoryString addObject:dict];
				}
				else if([category isEqualToString:@"numeric"])
				{
					[arrayCategoryNumeric addObject:dict];
				}
				else if([category isEqualToString:@"address"])
				{
					[arrayCategoryAddress addObject:dict];
				}
            }
        }
    }
}

- (void)setRecoveryComplete
{
   // NSLog(@"Recovery set complete");
	[self.activityView stopAnimating];
    if (bSuccess)
    {
		alertType = ALERT_TYPE_SETUP_COMPLETE;
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Recovery Questions Set", @"Title of recovery questions setup complete alert")
							  message:@"Your password recovery questions and answers are now set up.  When recovering your password, your answers must match exactly in order to succeed."
							  delegate:self
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
    }
    else
    {
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Recovery Questions not set", @"Title of recovery questions setup error alert")
							  message:[NSString stringWithFormat:@"Setting recovery questions failed:\n%@", strReason]
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
    }
}

void PW_ABC_Request_Callback(const tABC_RequestResults *pResults)
{
   // NSLog(@"Request callback");
    
    if (pResults)
    {
        PasswordRecoveryViewController *controller = (__bridge id)pResults->pData;
        controller->bSuccess = (BOOL)pResults->bSuccess;
        controller->strReason = [NSString stringWithFormat:@"%s", pResults->errorInfo.szDescription];
        if (pResults->requestType == ABC_RequestType_GetQuestionChoices)
        {
			//NSLog(@"GetQuestionChoices completed with cc: %ld (%s)", (unsigned long) pResults->errorInfo.code, pResults->errorInfo.szDescription);
            if (pResults->bSuccess)
            {
                tABC_QuestionChoices *pQuestionChoices = (tABC_QuestionChoices *)pResults->pRetData;
                [controller categorizeQuestionChoices:pQuestionChoices];
                ABC_FreeQuestionChoices(pQuestionChoices);
            }
            [controller performSelectorOnMainThread:@selector(getPasswordRecoveryQuestionsComplete) withObject:nil waitUntilDone:FALSE];
        }
		else if(pResults->requestType == ABC_RequestType_SetAccountRecoveryQuestions)
		{
			//NSLog(@"Set recovery completed with cc: %ld (%s)", (unsigned long) pResults->errorInfo.code, pResults->errorInfo.szDescription);
            [controller performSelectorOnMainThread:@selector(setRecoveryComplete) withObject:nil waitUntilDone:FALSE];
		}
    }
}

#pragma mark QuestionAnswerView delegates

-(void)QuestionAnswerView:(QuestionAnswerView *)view tablePresentedWithFrame:(CGRect)frame
{
	//programmatically scroll scrollView so that frame is entirely on screen
	//Increase contentSize if necessary
	self.scrollView.scrollEnabled = NO;
	
	//close any other open QAView tables
	for (UIView *qaView in self.scrollView.subviews)
	{
		if([qaView isKindOfClass:[QuestionAnswerView class]])
		{
			if(qaView != view)
			{
				[((QuestionAnswerView *)qaView) closeTable];
			}
		}
	}
	
	//populate available questions
	if(view.tag < 2)
	{
		view.availableQuestions = [self prunedQuestionsFor:arrayCategoryString];
	}
	else if(view.tag < 4)
	{
		view.availableQuestions = [self prunedQuestionsFor:arrayCategoryNumeric];
	}
	else
	{
		view.availableQuestions = [self prunedQuestionsFor:arrayCategoryAddress];
	}
	CGSize contentSize = self.scrollView.contentSize;
	
	if((frame.origin.y + frame.size.height) > self.scrollView.contentSize.height)
	{
		contentSize.height = frame.origin.y + frame.size.height;
		self.scrollView.contentSize = contentSize;
	}
	
	if((frame.origin.y + frame.size.height) > (self.scrollView.contentOffset.y + self.scrollView.frame.size.height))
	{
		[self.scrollView setContentOffset:CGPointMake(0, frame.origin.y + frame.size.height - self.scrollView.frame.size.height) animated:YES];
	}
}

-(void)QuestionAnswerViewTableDismissed:(QuestionAnswerView *)view
{
	self.scrollView.scrollEnabled = YES;
}

-(void)QuestionAnswerView:(QuestionAnswerView *)view didSelectQuestion:(NSDictionary *)question oldQuestion:(NSString *)oldQuestion
{
	//NSLog(@"Selected Question: %@", [question objectForKey:@"question"]);
	[arrayChosenQuestions addObject:[question objectForKey:@"question"]];
	
	[arrayChosenQuestions removeObject:oldQuestion];
}

-(void)QuestionAnswerView:(QuestionAnswerView *)view didSelectAnswerField:(UITextField *)textField
{
	//NSLog(@"Answer field selected");
	activeTextField = textField;
}

@end

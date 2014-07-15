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
#import "MontserratLabel.h"
#import "Util.h"
#import "CoreBridge.h"
#import "SignUpViewController.h"

#define IS_IPHONE5                  (([[UIScreen mainScreen] bounds].size.height == 568) ? YES : NO)

#define NUM_QUESTION_ANSWER_BLOCKS	6
#define QA_STARTING_Y_POSITION      67.0

#define TOOLBAR_HEIGHT              54
#define EXTRA_HEGIHT_FOR_IPHONE4    80

typedef enum eAlertType
{
	ALERT_TYPE_SETUP_COMPLETE,
	ALERT_TYPE_SKIP_THIS_STEP
} tAlertType;

@interface PasswordRecoveryViewController () <UIScrollViewDelegate, QuestionAnswerViewDelegate, SignUpViewControllerDelegate, UIAlertViewDelegate>
{
	float                   _completeButtonToEmbossImageDistance;
	UITextField             *_activeTextField;
	CGSize                  _defaultContentSize;
	tAlertType              _alertType;
    SignUpViewController    *_signUpController;
}

@property (nonatomic, weak) IBOutlet UIScrollView               *scrollView;
@property (nonatomic, weak) IBOutlet UIButton                   *completeSignupButton;
@property (nonatomic, weak) IBOutlet UIImageView                *embossImage;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView    *activityView;
@property (weak, nonatomic) IBOutlet UIButton                   *buttonSkip;
@property (weak, nonatomic) IBOutlet UIButton                   *buttonBack;
@property (weak, nonatomic) IBOutlet MontserratLabel            *labelTitle;
@property (weak, nonatomic) IBOutlet UIImageView                *imageSkip;
@property (nonatomic, weak) IBOutlet UIView                     *spinnerView;

@property (nonatomic, strong) UIButton        *buttonBlocker;
@property (nonatomic, strong) NSMutableArray  *arrayCategoryString;
@property (nonatomic, strong) NSMutableArray  *arrayCategoryNumeric;
@property (nonatomic, strong) NSMutableArray  *arrayCategoryAddress;
@property (nonatomic, strong) NSMutableArray  *arrayChosenQuestions;
@property (nonatomic, copy)   NSString        *strReason;
@property (nonatomic, assign) BOOL            bSuccess;

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

    _completeButtonToEmbossImageDistance = (self.embossImage.frame.origin.y + self.embossImage.frame.size.height) - self.completeSignupButton.frame.origin.y;

	self.arrayCategoryString	= [[NSMutableArray alloc] init];
	self.arrayCategoryNumeric	= [[NSMutableArray alloc] init];
	self.arrayCategoryAddress	= [[NSMutableArray alloc] init];
	self.arrayChosenQuestions	= [[NSMutableArray alloc] init];

	//NSLog(@"Adding keyboard notification");
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self updateDisplayForMode:_mode];

    // set up our user blocking button
    self.buttonBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonBlocker.backgroundColor = [UIColor clearColor];
    [self.buttonBlocker addTarget:self action:@selector(buttonBlockerTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonBlocker.frame = self.view.bounds;
    self.buttonBlocker.hidden = YES;
    self.spinnerView.hidden = YES;
    [self.view addSubview:self.buttonBlocker];

    if ((self.mode == PassRecovMode_SignUp) || (self.mode == PassRecovMode_Change))
    {
        // get the questions
        [self blockUser:YES];
        tABC_Error Error;
        tABC_CC result = ABC_GetQuestionChoices([[User Singleton].name UTF8String],
                                                PW_ABC_Request_Callback,
                                                (__bridge void *)self,
                                                &Error);
        [Util printABC_Error:&Error];

        if (ABC_CC_Ok != result)
        {
            [self blockUser:NO];
            //NSLog(@"%@",  [NSString stringWithFormat:@"GetQuestionChoices failed:\n%s", Error.szDescription]);
        }
    }
    else
    {
        _bSuccess = YES;
        [self getPasswordRecoveryQuestionsComplete];
    }
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

#pragma mark - Action Methods

- (IBAction)Back
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
         [self exit];
	 }];
}

- (IBAction)SkipThisStep
{
	_alertType = ALERT_TYPE_SKIP_THIS_STEP;
	
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:NSLocalizedString(@"Skip this step", @"Title of Skip this step alert")
						  message:NSLocalizedString(@"Warning: You will never be able to recover your password if it is forgotten.", @"")
						  delegate:self
						  cancelButtonTitle:@"Cancel"
						  otherButtonTitles:@"OK", nil];
	[alert show];
}

- (IBAction)CompleteSignup
{
	//NSLog(@"Complete Signup");
	//verify that all six questions have been selected
	BOOL allQuestionsSelected = YES;
	BOOL allAnswersValid = YES;
	NSMutableString *questions = [[NSMutableString alloc] init];
	NSMutableString *answers = [[NSMutableString alloc] init];

	int count = 0;
	for (UIView *view in self.scrollView.subviews)
	{
		if ([view isKindOfClass:[QuestionAnswerView class]])
		{
			QuestionAnswerView *qaView = (QuestionAnswerView *)view;
			if ((self.mode != PassRecovMode_Recover) && (qaView.questionSelected == NO))
			{
				allQuestionsSelected = NO;
				break;
			}
			//verify that all six answers have achieved their minimum character limit
			if ((self.mode != PassRecovMode_Recover) && (qaView.answerField.satisfiesMinimumCharacters == NO))
			{
				allAnswersValid = NO;
			}
			else
			{
				//add question and answer to arrays
				if (count)
				{
					[questions appendString:@"\n"];
					[answers appendString:@"\n"];
				}
				[questions appendString:[qaView question]];
				[answers appendString:[qaView answer]];
			}
            count++;
		}
	}
	if (allQuestionsSelected)
	{
		if (allAnswersValid)
		{
            if (self.mode == PassRecovMode_Recover)
            {
                [self recoverWithAnswers:answers];
            }
            else
            {
                [self commitQuestions:questions andAnswersToABC:answers];
            }
		}
		else
		{
			UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle:self.labelTitle.text
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
							  initWithTitle:self.labelTitle.text
							  message:@"You must choose all six questions before proceeding."
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
	}
}

- (IBAction)buttonBlockerTouched:(id)sender
{
}

#pragma mark - Misc Methods

- (void)showSpinner:(BOOL)bShow
{
    self.spinnerView.hidden = !bShow;
}

- (void)updateDisplayForMode:(tPassRecovMode)mode
{
    if (mode == PassRecovMode_SignUp)
    {
        self.buttonSkip.hidden = NO;
        self.imageSkip.hidden = NO;
        self.buttonBack.hidden = YES;
        [self.completeSignupButton setTitle:NSLocalizedString(@"Complete Signup", @"") forState:UIControlStateNormal];
        [self.labelTitle setText:NSLocalizedString(@"Password Recovery Setup", @"")];
    }
    else if (mode == PassRecovMode_Change)
    {
        self.buttonSkip.hidden = YES;
        self.imageSkip.hidden = YES;
        self.buttonBack.hidden = NO;
        [self.completeSignupButton setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
        [self.labelTitle setText:NSLocalizedString(@"Password Recovery Setup", @"")];
    }
    else if (mode == PassRecovMode_Recover)
    {
        self.buttonSkip.hidden = YES;
        self.imageSkip.hidden = YES;
        self.buttonBack.hidden = NO;
        [self.completeSignupButton setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
        [self.labelTitle setText:NSLocalizedString(@"Password Recovery", @"")];
    }
}

- (void)recoverWithAnswers:(NSString *)strAnswers
{
    _bSuccess = NO;
    [self showSpinner:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        BOOL bSuccess = [CoreBridge recoveryAnswers:strAnswers areValidForUserName:self.strUserName];
        NSArray *params = [NSArray arrayWithObjects:strAnswers, nil];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            _bSuccess = bSuccess;
            [self performSelectorOnMainThread:@selector(checkRecoveryAnswersResponse:) withObject:params waitUntilDone:NO];
        });
    });
}

- (void)checkRecoveryAnswersResponse:(NSArray *)params
{
    [self showSpinner:NO];
    if (_bSuccess)
    {
        NSString *strAnswers = params[0];
        [self bringUpSignUpViewWithAnswers:strAnswers];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Wrong Answers", nil)
							  message:NSLocalizedString(@"The given answers were incorrect. Please try again.", nil)
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
    }
}

- (void)commitQuestions:(NSString *)strQuestions andAnswersToABC:(NSString *)strAnswers
{
    [self blockUser:YES];
	tABC_Error Error;
	tABC_CC result;
    result = ABC_SetAccountRecoveryQuestions([[User Singleton].name UTF8String],
                                             [[User Singleton].password UTF8String],
                                             [strQuestions UTF8String],
                                             [strAnswers UTF8String],
                                             PW_ABC_Request_Callback,
                                             (__bridge void *)self,
                                             &Error);
	[Util printABC_Error:&Error];

	if (ABC_CC_Ok != result)
	{
        [self blockUser:NO];
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:self.labelTitle.text
							  message:[NSString stringWithFormat:@"%@ failed:\n%s", self.labelTitle.text, Error.szDescription]
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
		//NSLog(@"%@", [NSString stringWithFormat:@"Sign-up failed:\n%s", Error.szDescription]);
	}
	
}

- (NSArray *)prunedQuestionsFor:(NSArray *)questions
{
	NSMutableArray *prunedQuestions = [[NSMutableArray alloc] init];
	
	for (NSDictionary *question in questions)
	{
		BOOL wasChosen = NO;
		for (NSString *string in self.arrayChosenQuestions)
		{
			if ([string isEqualToString:[question objectForKey:@"question"]])
			{
				wasChosen = YES;
				break;
			}
			
		}
		if (!wasChosen)
		{
			[prunedQuestions addObject:question];
		}
	}
	return prunedQuestions;
}

- (void)blockUser:(BOOL)bBlock
{
    if (bBlock)
    {
        [self.activityView startAnimating];
        self.buttonBlocker.hidden = NO;
    }
    else
    {
        [self.activityView stopAnimating];
        self.buttonBlocker.hidden = YES;
    }
}

// searches the question and answer views for the view with the given tag
// NULL is returned if it can't be found
- (QuestionAnswerView *)findQAViewWithTag:(NSInteger)tag
{
    QuestionAnswerView *retVal = NULL;

    // look through all our subviews
    for (id subview in self.scrollView.subviews)
    {
        // if this is a the right kind of view
        if ([subview isMemberOfClass:[QuestionAnswerView class]])
        {
            QuestionAnswerView *view = (QuestionAnswerView *)subview;

            // if the tag is right
            if (tag == view.tag)
            {
                retVal = view;
                break;
            }
        }
    }

    return retVal;
}

- (void)bringUpSignUpViewWithAnswers:(NSString *)strAnswers
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    _signUpController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SignUpViewController"];

    _signUpController.mode = SignUpMode_ChangePasswordUsingAnswers;
    _signUpController.strUserName = self.strUserName;
    _signUpController.strAnswers = strAnswers;
    _signUpController.delegate = self;

    CGRect frame = self.view.bounds;
    frame.origin.x = frame.size.width;
    _signUpController.view.frame = frame;
    [self.view addSubview:_signUpController.view];

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         _signUpController.view.frame = self.view.bounds;
     }
                     completion:^(BOOL finished)
     {
     }];
}

- (void)exit
{
    [self.delegate passwordRecoveryViewControllerDidFinish:self];
}

#pragma mark - AlertView delegates

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (_alertType == ALERT_TYPE_SETUP_COMPLETE)
	{
		if ((buttonIndex == 1) || (_mode == PassRecovMode_Change))
		{
			//user dismissed recovery questions complete alert
            [self performSelector:@selector(exit) withObject:nil afterDelay:0.0];
		}
	}
	else
	{
		//SKIP THIS STEP alert
		if (buttonIndex == 1)
		{
            [self performSelector:@selector(exit) withObject:nil afterDelay:0.0];
		}
	}
}

#pragma mark - keyboard callbacks

- (void)keyboardWillShow:(NSNotification *)notification
{
	if (_activeTextField)
	{
		//Get KeyboardFrame (in Window coordinates)
		NSDictionary *userInfo = [notification userInfo];
		CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
		
		CGRect ownFrame = [self.view.window convertRect:keyboardFrame toView:self.view];
		
		//get textfield frame in window coordinates
		CGRect textFieldFrame = [_activeTextField.superview convertRect:_activeTextField.frame toView:self.view];
		
		//calculate offset
		float distanceToMove = (textFieldFrame.origin.y + textFieldFrame.size.height + 20.0) - ownFrame.origin.y;
		
		if (distanceToMove > 0)
		{
			//need to scroll
			//NSLog(@"Scrolling %f", distanceToMove);
			CGPoint curContentOffset = self.scrollView.contentOffset;
			curContentOffset.y += distanceToMove;
			[self.scrollView setContentOffset:curContentOffset animated:YES];
		}
		CGSize size = _defaultContentSize;
		size.height += keyboardFrame.size.height;
		self.scrollView.contentSize = size;
	}
	
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	if (_activeTextField)
	{
		//NSLog(@"Keyboard will hide for Login View Controller");

		_activeTextField = nil;
	}
	self.scrollView.contentSize = _defaultContentSize;
}

#pragma mark - ABC Callbacks

- (void)getPasswordRecoveryQuestionsComplete
{
    [self blockUser:NO];

    //NSLog(@"Get Questions complete");
    if (_bSuccess)
    {
		//NSLog(@"Got questions");
		float posY = QA_STARTING_Y_POSITION;
		CGSize size = self.scrollView.contentSize;
		size.height = posY;
		
		//add QA blocks
		for(int i = 0; i < NUM_QUESTION_ANSWER_BLOCKS; i++)
		{
			QuestionAnswerView *qav = [QuestionAnswerView CreateInsideView:self.scrollView withDelegate:self];

            if (self.mode == PassRecovMode_Recover)
            {
                [qav disableSelecting];
                if ([self.arrayQuestions count] > i)
                {
                    qav.labelQuestion.text = [self.arrayQuestions objectAtIndex:i];
                }
            }
			
			CGRect frame = qav.frame;
			frame.origin.x = (self.scrollView.frame.size.width - frame.size.width ) / 2;
			frame.origin.y = posY;
			qav.frame = frame;
			
			qav.tag = i;
			//qav.alpha = 0.5;

            if (i == (NUM_QUESTION_ANSWER_BLOCKS - 1))
            {
                qav.answerField.returnKeyType = UIReturnKeyDone;
            }
            else
            {
                qav.answerField.returnKeyType = UIReturnKeyNext;
            }
			
			size.height += qav.frame.size.height;

			posY += frame.size.height;
		}
		
		//position complete Signup button below QA views
		CGRect btnFrame = self.completeSignupButton.frame;
		btnFrame.origin.y = posY;
		self.completeSignupButton.frame = btnFrame;
		size.height += btnFrame.size.height + 36.0;

        // add more if we have a tool bar
        if (_mode == PassRecovMode_Change)
        {
            size.height += TOOLBAR_HEIGHT;
        }

        // add more if not iPhone5
        if (NO == IS_IPHONE5)
        {
            size.height += EXTRA_HEGIHT_FOR_IPHONE4;
        }
		
		//stretch emboss image to encompass Complete Signup button at its new location
		CGRect embossFrame = self.embossImage.frame;
		embossFrame.size.height = btnFrame.origin.y + _completeButtonToEmbossImageDistance - embossFrame.origin.y;
		self.embossImage.frame = embossFrame;
		
		self.scrollView.contentSize = size;
		_defaultContentSize = size;
    }
    else
    {
        //NSLog(@"%@", [NSString stringWithFormat:@"Account creation failed\n%@", strReason]);
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:self.labelTitle.text
							  message:[NSString stringWithFormat:@"%@ failed:\n%@", self.labelTitle.text, self.strReason]
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
				
                //printf("question: %s, category: %s, min: %d\n", pChoice->szQuestion, pChoice->szCategory, pChoice->minAnswerLength);
				
				NSString *category = [NSString stringWithFormat:@"%s", pChoice->szCategory];
				if([category isEqualToString:@"string"])
				{
					[self.arrayCategoryString addObject:dict];
				}
				else if([category isEqualToString:@"numeric"])
				{
					[self.arrayCategoryNumeric addObject:dict];
				}
				else if([category isEqualToString:@"address"])
				{
					[self.arrayCategoryAddress addObject:dict];
				}
            }
        }
    }
}

- (void)setRecoveryComplete
{
   // NSLog(@"Recovery set complete");
	[self blockUser:NO];
    if (_bSuccess)
    {
		_alertType = ALERT_TYPE_SETUP_COMPLETE;
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Recovery Questions Set", @"Title of recovery questions setup complete alert")
							  message:@"Your password recovery questions and answers are now set up.  When recovering your password, your answers must match exactly in order to succeed."
							  delegate:self
							  cancelButtonTitle:(_mode == PassRecovMode_SignUp ? @"Back" : nil)
							  otherButtonTitles:@"OK", nil];
		[alert show];
    }
    else
    {
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Recovery Questions Not Set", @"Title of recovery questions setup error alert")
							  message:[NSString stringWithFormat:@"Setting recovery questions failed:\n%@", self.strReason]
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
        controller.bSuccess = (BOOL)pResults->bSuccess;
        controller.strReason = [NSString stringWithFormat:@"%s", pResults->errorInfo.szDescription];
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
		else if (pResults->requestType == ABC_RequestType_SetAccountRecoveryQuestions)
		{
			//NSLog(@"Set recovery completed with cc: %ld (%s)", (unsigned long) pResults->errorInfo.code, pResults->errorInfo.szDescription);
            [controller performSelectorOnMainThread:@selector(setRecoveryComplete) withObject:nil waitUntilDone:FALSE];
		}
    }
}

#pragma mark - QuestionAnswerView delegates

- (void)QuestionAnswerView:(QuestionAnswerView *)view tablePresentedWithFrame:(CGRect)frame
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
	if (view.tag < 2)
	{
		view.availableQuestions = [self prunedQuestionsFor:self.arrayCategoryString];
	}
	else if (view.tag < 4)
	{
		view.availableQuestions = [self prunedQuestionsFor:self.arrayCategoryNumeric];
	}
	else
	{
		view.availableQuestions = [self prunedQuestionsFor:self.arrayCategoryAddress];
	}
	CGSize contentSize = self.scrollView.contentSize;
	
	if ((frame.origin.y + frame.size.height) > self.scrollView.contentSize.height)
	{
		contentSize.height = frame.origin.y + frame.size.height;
		self.scrollView.contentSize = contentSize;
	}
	
	if ((frame.origin.y + frame.size.height) > (self.scrollView.contentOffset.y + self.scrollView.frame.size.height))
	{
		[self.scrollView setContentOffset:CGPointMake(0, frame.origin.y + frame.size.height - self.scrollView.frame.size.height) animated:YES];
	}
}

- (void)QuestionAnswerViewTableDismissed:(QuestionAnswerView *)view
{
	self.scrollView.scrollEnabled = YES;
}

- (void)QuestionAnswerView:(QuestionAnswerView *)view didSelectQuestion:(NSDictionary *)question oldQuestion:(NSString *)oldQuestion
{
	//NSLog(@"Selected Question: %@", [question objectForKey:@"question"]);
	[self.arrayChosenQuestions addObject:[question objectForKey:@"question"]];
	
	[self.arrayChosenQuestions removeObject:oldQuestion];

    // place the cursor in the answer
    [view.answerField becomeFirstResponder];
}

- (void)QuestionAnswerView:(QuestionAnswerView *)view didSelectAnswerField:(UITextField *)textField
{
	//NSLog(@"Answer field selected");
	_activeTextField = textField;
}

- (void)QuestionAnswerView:(QuestionAnswerView *)view didReturnOnAnswerField:(UITextField *)textField
{
    QuestionAnswerView *viewNext = NULL;

    viewNext = [self findQAViewWithTag:view.tag + 1];

    if (viewNext != NULL)
    {
        if (self.mode == PassRecovMode_Recover)
        {
            // place the cursor in the answer
            [viewNext.answerField becomeFirstResponder];
        }
        else
        {
            [viewNext presentQuestionChoices];
        }
    }
}

#pragma mark - SignUpViewControllerDelegates

-(void)signupViewControllerDidFinish:(SignUpViewController *)controller withBackButton:(BOOL)bBack
{
	[controller.view removeFromSuperview];
	_signUpController = nil;

    // if they didn't just hit the back button
    if (!bBack)
    {
        // then we are all done
        [self exit];
    }
}

@end

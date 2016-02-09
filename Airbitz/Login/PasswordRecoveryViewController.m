//
//  PasswordRecoveryViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/20/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "PasswordRecoveryViewController.h"
#import "TwoFactorMenuViewController.h"
#import "QuestionAnswerView.h"
#import "User.h"
#import "LatoLabel.h"
#import "Util.h"
#import "AirbitzCore.h"
#import "SignUpViewController.h"
#import "CommonTypes.h"
#import "MainViewController.h"
#import "Theme.h"
#import "ABCUtil.h"

#define NUM_QUESTION_ANSWER_BLOCKS	6
#define QA_STARTING_Y_POSITION      120
#define RECOVER_STARTING_Y_POSITION 75

#define EXTRA_HEGIHT_FOR_IPHONE4    80

typedef enum eAlertType
{
	ALERT_TYPE_SETUP_COMPLETE,
	ALERT_TYPE_SKIP_THIS_STEP,
	ALERT_TYPE_EXIT
} tAlertType;

@interface PasswordRecoveryViewController ()
    <UIScrollViewDelegate, QuestionAnswerViewDelegate, SignUpViewControllerDelegate,
     UIAlertViewDelegate, UIGestureRecognizerDelegate, TwoFactorMenuViewControllerDelegate>
{
//	float                   _completeButtonToEmbossImageDistance;
	UITextField             *_activeTextField;
	CGSize                  _defaultContentSize;
	tAlertType              _alertType;
    TwoFactorMenuViewController *_tfaMenuViewController;
    NSString                    *_secret;
}

@property (nonatomic, weak) IBOutlet UIScrollView               *scrollView;
@property (nonatomic, strong)          UIButton                   *completeSignupButton;
@property (weak, nonatomic) IBOutlet UIButton                   *buttonSkip;
@property (weak, nonatomic) IBOutlet UIButton                   *buttonBack;
@property (weak, nonatomic) IBOutlet LatoLabel                  *labelTitle;
@property (weak, nonatomic) IBOutlet UIImageView                *imageSkip;
@property (nonatomic, weak) IBOutlet UIView                     *spinnerView;
@property (nonatomic, weak) IBOutlet UIView                     *passwordView;
@property (nonatomic, weak) IBOutlet StylizedTextField          *passwordField;

@property (nonatomic, strong) SignUpViewController  *signUpController;
@property (nonatomic, strong) UIButton              *buttonBlocker;
@property (nonatomic, strong) NSMutableArray        *arrayCategoryString;
@property (nonatomic, strong) NSMutableArray        *arrayCategoryNumeric;
@property (nonatomic, strong) NSMutableArray        *arrayCategoryMust;
@property (nonatomic, strong) NSMutableArray        *arrayChosenQuestions;

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
    
	self.arrayCategoryString	= [[NSMutableArray alloc] init];
	self.arrayCategoryNumeric	= [[NSMutableArray alloc] init];
	self.arrayCategoryMust      = [[NSMutableArray alloc] init];
	self.arrayChosenQuestions	= [[NSMutableArray alloc] init];

	//ABCLog(2,@"Adding keyboard notification");
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

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
        [self showSpinner:YES];
        [abc getRecoveryQuestionsChoices:^(NSMutableArray *arrayCategoryString, NSMutableArray *arrayCategoryNumeric, NSMutableArray *arrayCategoryMust) {

            self.arrayCategoryString = arrayCategoryString;
            self.arrayCategoryNumeric = arrayCategoryNumeric;
            self.arrayCategoryMust = arrayCategoryMust;

            [self getPasswordRecoveryQuestionsComplete];

        } error:^(ABCConditionCode ccode, NSString *errorString)
        {
            self.arrayCategoryString = nil;
            self.arrayCategoryNumeric = nil;
            self.arrayCategoryMust = nil;

            UIAlertView *alert = [[UIAlertView alloc]
                    initWithTitle:self.labelTitle.text
                          message:[NSString stringWithFormat:@"%@ failed:\n%@", self.labelTitle.text, errorString]
                         delegate:nil
                cancelButtonTitle:okButtonText
                otherButtonTitles:nil];
            [alert show];
        }];
    }
    else
    {
        [self getPasswordRecoveryQuestionsComplete];
    }

    [self updateDisplayForMode:_mode];

    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self updateViews];
}

-(void)updateViews
{
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBarTitle:self title:passwordRecoveryText];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Back) fromObject:self];
    [MainViewController changeNavBar:self title:importText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
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

- (void)Back
{
    if (!self.buttonBack.hidden)
    {
        if ([self isFormDirty]) {
            _alertType = ALERT_TYPE_EXIT;
            UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:NSLocalizedString(@"Warning!", nil)
                message:NSLocalizedString(@"You are about to exit password recovery and questions & answers have not yet been set.", nil)
                delegate:self
                cancelButtonTitle:@"Cancel"
                otherButtonTitles:@"OK", nil];
            [alert show];
        } else {
            [self exit];
        }
    }
}

- (IBAction)SkipThisStep
{
	_alertType = ALERT_TYPE_SKIP_THIS_STEP;
	
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:NSLocalizedString(@"Skip this step", @"Title of Skip this step alert")
						  message:NSLocalizedString(@"**WARNING** You will NEVER be able to recover your password if it is forgotten!!", @"")
						  delegate:self
						  cancelButtonTitle:@"Go Back"
						  otherButtonTitles:@"OK", nil];
	[alert show];
}

- (BOOL)isFormDirty
{
    for (UIView *view in self.scrollView.subviews) {
        if ([view isKindOfClass:[QuestionAnswerView class]]) {
            QuestionAnswerView *qaView = (QuestionAnswerView *)view;
            if ((self.mode != PassRecovMode_Recover) && (qaView.questionSelected == YES)) {
                return YES;
            }
            //verify that all six answers have achieved their minimum character limit
            if ((self.mode != PassRecovMode_Recover) && ([qaView.answerField.text length] > 0)) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)CompleteSignup
{
	//ABCLog(2,@"Complete Signup");
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
								  message:@"You must answer all six questions. Make sure your answers are long enough."
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
        self.passwordView.hidden = YES;
        self.buttonBack.hidden = YES;
        [self.completeSignupButton setTitle:NSLocalizedString(@"Complete Signup", @"") forState:UIControlStateNormal];
        [self.labelTitle setText:NSLocalizedString(@"Password Recovery Setup", @"")];
    }
    else if (mode == PassRecovMode_Change)
    {
        self.buttonSkip.hidden = YES;
        self.imageSkip.hidden = YES;
        self.buttonBack.hidden = NO;
        self.passwordView.hidden = ![abcUser passwordExists];
        [self.completeSignupButton setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
        [self.labelTitle setText:NSLocalizedString(@"Password Recovery Setup", @"")];
    }
    else if (mode == PassRecovMode_Recover)
    {
        self.buttonSkip.hidden = YES;
        self.imageSkip.hidden = YES;
        self.buttonBack.hidden = NO;
        self.passwordView.hidden = YES;
        [self.completeSignupButton setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
        [self.labelTitle setText:NSLocalizedString(@"Password Recovery", @"")];
    }
}

- (void)recoverWithAnswers:(NSString *)strAnswers
{
    [self showSpinner:YES];

    [abc checkRecoveryAnswers:self.strUserName answers:strAnswers otp:_secret complete:^(BOOL validAnswers)
    {
        [self showSpinner:NO];
        if (validAnswers)
        {
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
    } error:^(ABCConditionCode ccode, NSString *errorString)
    {
        [self showSpinner:NO];
        if (ABCConditionCodeInvalidOTP == ccode)
        {
            [self launchTwoFactorMenu];
        }
        else
        {
//            UIAlertView *alert = [[UIAlertView alloc]
//                    initWithTitle:errorRecoveringAccountTitle
//                          message:errorRecoveringAccountText
//                         delegate:nil
//                cancelButtonTitle:okButtonText
//                otherButtonTitles:nil];
//            [alert show];
//
            // XXX Not a good assumption, but if we get ANY error, assume it's because answers are wrong.
            // Core should change to set error to OK but change validAnswers -paul
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Wrong Answers", nil)
                                  message:NSLocalizedString(@"The given answers were incorrect. Please try again.", nil)
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }

    }];

}

- (void)launchTwoFactorMenu
{
    _tfaMenuViewController = (TwoFactorMenuViewController *)[Util animateIn:@"TwoFactorMenuViewController" storyboard:@"Settings" parentController:self];
    _tfaMenuViewController.delegate = self;
    _tfaMenuViewController.username = self.strUserName;
    _tfaMenuViewController.bStoreSecret = NO;
    _tfaMenuViewController.bTestSecret = NO;
}

#pragma mark - TwoFactorScanViewControllerDelegate

- (void)twoFactorMenuViewControllerDone:(TwoFactorMenuViewController *)controller withBackButton:(BOOL)bBack
{
    BOOL __bSuccess = controller.bSuccess;
    _secret = controller.secret;
    [Util animateOut:controller parentController:self complete:^(void) {
        _tfaMenuViewController = nil;
        BOOL success = __bSuccess;
        if (success) {
            ABCConditionCode ccode = [abc setOTPKey:self.strUserName key:_secret];
            if (ABCConditionCodeOk == ccode) {
                // Try again with OTP
                [self CompleteSignup];
            } else {
                success = NO;
            }
        }
        if (!success && !bBack) {
            UIAlertView *alert = [[UIAlertView alloc]
                                initWithTitle:NSLocalizedString(@"Unable to import token", nil)
                                message:NSLocalizedString(@"We are sorry we are unable to import the token at this time.", nil)
                                delegate:nil
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (void)commitQuestions:(NSString *)strQuestions andAnswersToABC:(NSString *)strAnswers
{
    // Check Password
    NSString *password = nil;
    if (self.mode == PassRecovMode_Change) {
        password = _passwordField.text;
    } else {
        password = abcUser.password;
    }
    if ([abcUser passwordExists] && ![abcUser passwordOk:password]) {
        UIAlertView *alert = [[UIAlertView alloc]
                             initWithTitle:NSLocalizedString(@"Password mismatch", nil)
                             message:NSLocalizedString(@"Please enter your correct password.", nil)
                             delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil];
        [alert show];
        return;
    }
    [self blockUser:YES];
    [self showSpinner:YES];

    [abcUser
            setRecoveryQuestions:password
                       questions:strQuestions
                         answers:strAnswers
                        complete:^(void)
                        {
                            [self blockUser:NO];
                            [self showSpinner:NO];
                            _alertType = ALERT_TYPE_SETUP_COMPLETE;
                            UIAlertView *alert = [[UIAlertView alloc]
                                    initWithTitle:recoveryQuestionsSet
                                          message:recoveryQuestionsSetWarning
                                         delegate:self
                                cancelButtonTitle:(_mode == PassRecovMode_SignUp ? backButtonText : nil)
                                otherButtonTitles:okButtonText, nil];
                            [alert show];

                        }
                           error: ^(ABCConditionCode ccode, NSString *errorString)
                           {
                               [self blockUser:NO];
                               [self showSpinner:NO];
                               UIAlertView *alert = [[UIAlertView alloc]
                                       initWithTitle:recoveryQuestionsNotSet
                                             message:[NSString stringWithFormat:setRecoveryQuestionsFailed, errorString]
                                            delegate:nil
                                   cancelButtonTitle:okButtonText
                                   otherButtonTitles:nil];
                               [alert show];

                           }];

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
        [self showSpinner:YES];
//        [self.activityView startAnimating];
//        self.buttonBlocker.hidden = NO;
    }
    else
    {
        [self showSpinner:NO];
//        [self.activityView stopAnimating];
//        self.buttonBlocker.hidden = YES;
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
    self.signUpController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SignUpViewController"];

    self.signUpController.mode = SignUpMode_ChangePasswordUsingAnswers;
    self.signUpController.strUserName = self.strUserName;
    self.signUpController.strAnswers = strAnswers;
    self.signUpController.delegate = self;

    [MainViewController animateView:self.signUpController withBlur:NO];
}


- (void)installLeftToRightSwipeDetection
{
	UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeftToRight:)];
	gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:gesture];
}

// used by the guesture recognizer to ignore exit
- (BOOL)haveSubViewsShowing
{
    return (self.signUpController != nil);
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
    else if (_alertType == ALERT_TYPE_EXIT)
    {
		if (buttonIndex == 1)
		{
            [self exit];
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
			//ABCLog(2,@"Scrolling %f", distanceToMove);
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
		//ABCLog(2,@"Keyboard will hide for Login View Controller");

		_activeTextField = nil;
	}
	self.scrollView.contentSize = _defaultContentSize;
}

#pragma mark - ABC Callbacks

- (void)getPasswordRecoveryQuestionsComplete
{
    [self blockUser:NO];
    [self showSpinner:NO];

    {
        float posY = 0;
        if(self.mode == PassRecovMode_Recover)
        {
            posY = RECOVER_STARTING_Y_POSITION;
        }
        else
        {
            posY = QA_STARTING_Y_POSITION;
        }
        
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
                qav.isLastQuestion = YES;
            }
            else
            {
                qav.answerField.returnKeyType = UIReturnKeyNext;
            }
			
			size.height += qav.frame.size.height;

			posY += frame.size.height;
		}

        //position complete Signup button below QA views
        self.completeSignupButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self updateDisplayForMode:self.mode];

        self.completeSignupButton.backgroundColor = [Theme Singleton].colorButtonGreen;
        [self.completeSignupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.completeSignupButton.hidden = NO;
        self.completeSignupButton.enabled = YES;
        [self.completeSignupButton addTarget:self action:@selector(CompleteSignup) forControlEvents:UIControlEventTouchDown];

        [self.scrollView addSubview:self.completeSignupButton];
        CGRect btnFrame = self.completeSignupButton.frame;
		btnFrame.origin.y = posY;
        btnFrame.origin.x = 0;
        btnFrame.size.width = [MainViewController getWidth];
        btnFrame.size.height = [Theme Singleton].heightButton;
		self.completeSignupButton.frame = btnFrame;

        size.height += btnFrame.size.height + 36.0;

        // add more if we have a tool bar
        if (_mode == PassRecovMode_Change)
        {
            size.height += [MainViewController getFooterHeight];
        }

        // add more if not iPhone5
        if (NO == !IS_IPHONE4)
        {
            size.height += EXTRA_HEGIHT_FOR_IPHONE4;
        }
		
		self.scrollView.contentSize = size;
		_defaultContentSize = size;
    }
}

#pragma Password field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _passwordField) {
        [_passwordField resignFirstResponder];

        QuestionAnswerView *viewNext = NULL;
        viewNext = [self findQAViewWithTag:0];
        if (viewNext != NULL) {
            [viewNext presentQuestionChoices];
        }
    }
    return NO;
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
		view.availableQuestions = [self prunedQuestionsFor:self.arrayCategoryMust];
	}

    CGSize contentSize = self.scrollView.contentSize;
	
	if ((frame.origin.y + frame.size.height) > self.scrollView.contentSize.height)
	{
		contentSize.height = frame.origin.y + frame.size.height;
		self.scrollView.contentSize = contentSize;
	}
    
    CGFloat questionsHeight = [view.availableQuestions count] * QA_TABLE_ROW_HEIGHT;
	if ((frame.origin.y + frame.size.height + questionsHeight) > (self.scrollView.contentOffset.y + self.scrollView.frame.size.height))
	{
		[self.scrollView setContentOffset:CGPointMake(0, frame.origin.y + frame.size.height + questionsHeight - self.scrollView.frame.size.height) animated:YES];
	}
}

- (void)QuestionAnswerViewTableDismissed:(QuestionAnswerView *)view
{
	self.scrollView.scrollEnabled = YES;
}

- (void)QuestionAnswerView:(QuestionAnswerView *)view didSelectQuestion:(NSDictionary *)question oldQuestion:(NSString *)oldQuestion
{
	//ABCLog(2,@"Selected Question: %@", [question objectForKey:@"question"]);
	[self.arrayChosenQuestions addObject:[question objectForKey:@"question"]];
	
	[self.arrayChosenQuestions removeObject:oldQuestion];

    // place the cursor in the answer
    [view.answerField becomeFirstResponder];
}

- (void)QuestionAnswerView:(QuestionAnswerView *)view didSelectAnswerField:(UITextField *)textField
{
	//ABCLog(2,@"Answer field selected");
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
    [MainViewController animateOut:controller withBlur:NO complete:^
    {
        self.signUpController = nil;

        if (!bBack)
        {
            // then we are all done
            [self exit];
        }
        else
        {
            [self updateViews];
        }

    }];
    // if they didn't just hit the back button
}

#pragma mark - GestureReconizer methods

- (void)didSwipeLeftToRight:(UIGestureRecognizer *)gestureRecognizer
{
    if (![self haveSubViewsShowing])
    {
        [self Back];
    }
}

#pragma mark - Custom Notification Handlers

// called when a tab bar button that is already selected, is reselected again
- (void)tabBarButtonReselect:(NSNotification *)notification
{
    if (![self haveSubViewsShowing])
    {
        [self Back];
    }
}

@end

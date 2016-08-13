//
//  PasswordRecoveryViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/20/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <AddressBook/AddressBook.h>
#import "PasswordRecoveryViewController.h"
#import "TwoFactorMenuViewController.h"
#import "QuestionAnswerView.h"
#import "User.h"
#import "LatoLabel.h"
#import "Util.h"
#import "ABCContext.h"
#import "SignUpViewController.h"
#import "CommonTypes.h"
#import "MainViewController.h"
#import "Theme.h"
#import "ABCUtil.h"
#import "PopupWheelPickerView.h"

//#define NUM_QUESTION_ANSWER_BLOCKS	6
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
    <UIScrollViewDelegate, QuestionAnswerViewDelegate, MFMailComposeViewControllerDelegate, SignUpViewControllerDelegate,
     UIAlertViewDelegate, UIGestureRecognizerDelegate, TwoFactorMenuViewControllerDelegate>
{
//	float                   _completeButtonToEmbossImageDistance;
	UITextField             *_activeTextField;
	CGSize                  _defaultContentSize;
	tAlertType              _alertType;
    TwoFactorMenuViewController *_tfaMenuViewController;
    NSString                    *_secret;
    QuestionAnswerView          *_activeQAView;
    NSString                    *_recoveryToken;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint         *contentViewHeight;
@property (nonatomic, weak) IBOutlet UIScrollView               *scrollView;
@property (weak, nonatomic) IBOutlet UIView                     *contentView;
@property (nonatomic, strong)          UIButton                 *completeSignupButton;
@property (weak, nonatomic) IBOutlet UIButton                   *buttonSkip;
@property (weak, nonatomic) IBOutlet UIButton                   *buttonBack;
@property (weak, nonatomic) IBOutlet LatoLabel                  *labelTitle;
@property (weak, nonatomic) IBOutlet UIImageView                *imageSkip;
@property (nonatomic, weak) IBOutlet UIView                     *spinnerView;
@property (nonatomic, weak) IBOutlet UIView                     *passwordView;
@property (nonatomic, weak) IBOutlet StylizedTextField          *passwordField;
@property (nonatomic, strong)        UIAlertView                *saveTokenAlert;
@property (nonatomic, strong)        UIAlertView                *sendEmailAlert;


@property (nonatomic, strong) PopupWheelPickerView  *popupWheelPicker;
@property (nonatomic, strong) SignUpViewController  *signUpController;
@property (nonatomic, strong) UIButton              *buttonBlocker;
@property (nonatomic, strong) NSArray               *arrayQuestionChoices;
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
    
	self.arrayChosenQuestions	= [[NSMutableArray alloc] init];

	//ABCLog(2,@"Adding keyboard notification");
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

}
-(void)viewDidAppear:(BOOL)animated
{
    if ((self.mode == PassRecovMode_SignUp) || (self.mode == PassRecovMode_Change))
    {
        // get the questions
        [self blockUser:YES];
        [self showSpinner:YES];
        
        [ABCContext listRecoveryQuestionChoices:^(ABCError *error, NSArray *arrayQuestions)
        {
            if (!error)
            {
                self.arrayQuestionChoices = arrayQuestions;
                [self getPasswordRecoveryQuestionsComplete];
                if (self.passwordView.hidden == NO)
                    [self.passwordField becomeFirstResponder];
            }
            else
            {
                self.arrayQuestionChoices = nil;
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:self.labelTitle.text
                                      message:[NSString stringWithFormat:@"%@ failed:\n%@", self.labelTitle.text, error.userInfo[NSLocalizedDescriptionKey]]
                                      delegate:nil
                                      cancelButtonTitle:okButtonText
                                      otherButtonTitles:nil];
                [alert show];
            }
        }];
        
    }
    else
    {
        [self getPasswordRecoveryQuestionsComplete];
    }

    [self updateDisplayForMode:_mode];
    if (self.passwordView.hidden == NO)
        [self.passwordField becomeFirstResponder];

    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];

    [MainViewController changeNavBarOwner:self];
    [self updateViews];
}

-(void)updateViews
{
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
                initWithTitle:warningExclamationText
                message:aboutToExitPasswordRecovery
                delegate:self
                cancelButtonTitle:cancelButtonText
                otherButtonTitles:okButtonText, nil];
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
						  initWithTitle:skipThisStepText
						  message:warningYouWillNeverBeAbleToRecover
						  delegate:self
						  cancelButtonTitle:goBackButtonText
						  otherButtonTitles:okButtonText, nil];
	[alert show];
}

- (BOOL)isFormDirty
{
    for (UIView *view in self.contentView.subviews) {
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
	for (UIView *view in self.contentView.subviews)
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
								  message:youMustAnswerAllSix
								  delegate:nil
								  cancelButtonTitle:okButtonText
								  otherButtonTitles:nil];
			[alert show];
		}
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:self.labelTitle.text
							  message:youMustChooseAllSix
							  delegate:nil
							  cancelButtonTitle:okButtonText
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
        [self.completeSignupButton setTitle:completeSignupText forState:UIControlStateNormal];
        [self.labelTitle setText:passwordRecoverySetup];
    }
    else if (mode == PassRecovMode_Change)
    {
        self.buttonSkip.hidden = YES;
        self.imageSkip.hidden = YES;
        self.buttonBack.hidden = NO;
        self.passwordView.hidden = ![abcAccount accountHasPassword];
        [self.completeSignupButton setTitle:doneButtonText forState:UIControlStateNormal];
        [self.labelTitle setText:passwordRecoverySetup];
    }
    else if (mode == PassRecovMode_Recover)
    {
        self.buttonSkip.hidden = YES;
        self.imageSkip.hidden = YES;
        self.buttonBack.hidden = NO;
        self.passwordView.hidden = YES;
        [self.completeSignupButton setTitle:doneButtonText forState:UIControlStateNormal];
        [self.labelTitle setText:passwordRecoveryText];
    }
}

- (void)recoverWithAnswers:(NSString *)strAnswers
{
    [self showSpinner:YES];

    if (self.recoveryToken)
    {
        [abc loginWithRecoveryToken:self.strUserName
                            answers:strAnswers
                      recoveryToken:self.recoveryToken
                           delegate:[MainViewController Singleton]
                                otp:_secret
                           callback:^(ABCError *error, ABCAccount *account) {
                               [self showSpinner:NO];
                               [User login:account];
                               [self bringUpSignUpViewWithAnswers:strAnswers];
                               [MainViewController fadingAlert:recovery_successful holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
                           }];
    }
    else
    {
        [abc recoveryLogin:self.strUserName
                   answers:strAnswers
                  delegate:[MainViewController Singleton]
                       otp:_secret
                  complete:^(ABCAccount *account)
         {
             [self showSpinner:NO];
             [User login:account];
             [self bringUpSignUpViewWithAnswers:strAnswers];
         } error:^(NSError *error, NSDate *resetDate, NSString *resetToken)
         {
             [self showSpinner:NO];
             if (ABCConditionCodeInvalidOTP == error.code)
             {
                 [self launchTwoFactorMenu:resetDate token:resetToken];
             }
             else
             {
                 // XXX Not a good assumption, but if we get ANY error, assume it's because answers are wrong.
                 // Core should change to set error to OK but change validAnswers -paul
                 UIAlertView *alert = [[UIAlertView alloc]
                                       initWithTitle:wrongAnswersText
                                       message:givenAnswersAreIncorrect
                                       delegate:nil
                                       cancelButtonTitle:okButtonText
                                       otherButtonTitles:nil];
                 [alert show];
             }
             
         }];
    }
}

- (void)launchTwoFactorMenu:(NSDate *)resetDate token:(NSString *)resetToken;
{
    _tfaMenuViewController = (TwoFactorMenuViewController *)[Util animateIn:@"TwoFactorMenuViewController" storyboard:@"Settings" parentController:self];
    _tfaMenuViewController.delegate = self;
    _tfaMenuViewController.username = self.strUserName;
    _tfaMenuViewController.bStoreSecret = NO;
    _tfaMenuViewController.bTestSecret = NO;
    _tfaMenuViewController.resetDate = resetDate;
    _tfaMenuViewController.resetToken = resetToken;
}

#pragma mark - TwoFactorScanViewControllerDelegate

- (void)twoFactorMenuViewControllerDone:(TwoFactorMenuViewController *)controller withBackButton:(BOOL)bBack
{
    BOOL __bSuccess = controller.bSuccess;
    _secret = controller.secret;
    [Util animateOut:controller parentController:self complete:^(void) {
        _tfaMenuViewController = nil;
        [MainViewController changeNavBarOwner:self];

        BOOL success = __bSuccess;
        if (success) {
            // Try again with OTP
            [self CompleteSignup];
        }
        if (!success && !bBack) {
            UIAlertView *alert = [[UIAlertView alloc]
                                initWithTitle:unableToImportToken
                                message:errorImportingTokenTryAgain
                                delegate:nil
                                cancelButtonTitle:okButtonText
                                otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (void)commitQuestions:(NSString *)strQuestions andAnswersToABC:(NSString *)strAnswers
{
    // Check Password
    if (self.mode == PassRecovMode_Change) {
        NSString *password = nil;
        password = _passwordField.text;
        if ([abcAccount accountHasPassword] && ![abcAccount checkPassword:password]) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:passwordMismatchTitle
                                  message:pleaseEnterCorrectPassword
                                  delegate:nil
                                  cancelButtonTitle:okButtonText
                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    [self blockUser:YES];
    [self showSpinner:YES];

    if (self.useRecovery2)
    {
        [abcAccount setupRecoveryQuestions2:strQuestions answers:strAnswers callback:^(ABCError *error, NSString *recoveryToken) {
            [self blockUser:NO];
            [self showSpinner:NO];
            if (error)
            {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:recoveryQuestionsNotSet
                                      message:[NSString stringWithFormat:setRecoveryQuestionsFailed, error.userInfo[NSLocalizedDescriptionKey]]
                                      delegate:nil
                                      cancelButtonTitle:okButtonText
                                      otherButtonTitles:nil];
                [alert show];
            }
            else
            {
                _recoveryToken = recoveryToken;
                [self launchSaveTokenAlert:save_recovery_token_popup];
            }
        }];
    }
    else
    {
    }
}

- (void) launchSaveTokenAlert:(NSString *)title;
{
    // Check if the dataStore has the user's email. If so prepopulate it.
    NSMutableString *email = [[NSMutableString alloc] init];
    ABCError *error = [abcAccount.dataStore dataRead:DataStorePersonalInfoFolder withKey:DataStorePersonalInfo_Email data:email];

    NSString *emailStr = nil;
    if (!error)
    {
        emailStr = [NSString stringWithString:email];
    }
    
    // Generate alert letting user know they need to send token to themselves
    self.saveTokenAlert = [[UIAlertView alloc]
                           initWithTitle:title
                           message:save_recovery_token_popup_message
                           delegate:self
                           cancelButtonTitle:cancelButtonText
                           otherButtonTitles:emailText,nil];
    self.saveTokenAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    if (email && [email length])
    {
        UITextField *textField = [self.saveTokenAlert textFieldAtIndex:0];
        textField.text = email;
    }

    [self.saveTokenAlert show];
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
    for (id subview in self.contentView.subviews)
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

#pragma mark - UIAlertView delegates

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView == self.sendEmailAlert)
    {
        // Call exit
        [self performSelector:@selector(exit) withObject:nil afterDelay:0.0];
    }
    if (alertView == self.saveTokenAlert)
    {
        if (0 == buttonIndex)
        {
            [MainViewController fadingAlert:recoveryQuestionsNotSet];
        }
        else if (1 == buttonIndex)
        {
            UITextField *textField = [self.saveTokenAlert textFieldAtIndex:0];

            if ([self stringIsValidEmail:textField.text])
            {
                // Save the email in the dataStore incase we need it in the future.
                [abcAccount.dataStore dataWrite:DataStorePersonalInfoFolder withKey:DataStorePersonalInfo_Email withValue:textField.text];
                
                // Email to themselves
                [self sendTokenEMail:textField.text];
            }
            else
            {
                [self launchSaveTokenAlert:invalid_email];
            }
        }
    } else if (_alertType == ALERT_TYPE_SETUP_COMPLETE)
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
    NSDictionary* info = [notification userInfo];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbRect.size.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbRect.size.height;
    if (!CGRectContainsPoint(aRect, _activeTextField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:_activeTextField.frame animated:YES];
    }
    if (_activeQAView)
        [_activeQAView dismissPopupPicker];
    _activeQAView = nil;
    
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
//	if (_activeTextField)
//	{
//		//ABCLog(2,@"Keyboard will hide for Login View Controller");
//
//		_activeTextField = nil;
//	}
//	self.scrollView.contentSize = _defaultContentSize;
}

#pragma mark - MFMailComposeViewController Delegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    NSString *strTitle = save_recovery_token_popup;
    NSString *strMsg = nil;
    BOOL    success = NO;
    
    switch (result)
    {
        case MFMailComposeResultCancelled:
            strMsg = emailCancelled;
            break;
            
        case MFMailComposeResultSaved:
            strMsg = emailSavedToSendLater;
            break;
            
        case MFMailComposeResultSent:
            strMsg = emailSent;
            success = YES;
            break;
            
        case MFMailComposeResultFailed:
        {
            strTitle = errorSendingEmail;
            strMsg = [error localizedDescription];
            break;
        }
        default:
            break;
    }
    
    [[controller presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    
    if (success)
    {        
        _sendEmailAlert = [[UIAlertView alloc] initWithTitle:strTitle
                                                     message:strMsg
                                                    delegate:self
                                           cancelButtonTitle:okButtonText
                                           otherButtonTitles:nil];
        [_sendEmailAlert show];
    }
    else
    {
        [MainViewController fadingAlert:[NSString stringWithFormat:@"%@\n\n%@", strTitle, strMsg]];
    }
    
}


#pragma mark - Misc

- (void)sendTokenEMail:(NSString *)emailAddress
{
    // if mail is available
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
        
        NSString *obfuscatedUsername = abcAccount.name;
        unsigned long acctlen = [abcAccount.name length];
        if (acctlen <= 3)
        {
            obfuscatedUsername = [obfuscatedUsername stringByReplacingCharactersInRange:NSMakeRange(acctlen - 1, 1) withString:@"*"];
        }
        else if(acctlen <= 6)
        {            
            obfuscatedUsername = [obfuscatedUsername stringByReplacingCharactersInRange:NSMakeRange(acctlen - 2, 2) withString:@"**"];
        }
        else if(acctlen <= 9)
        {
            obfuscatedUsername = [obfuscatedUsername stringByReplacingCharactersInRange:NSMakeRange(acctlen - 3, 3) withString:@"***"];
        }
        else if(acctlen <= 12)
        {
            obfuscatedUsername = [obfuscatedUsername stringByReplacingCharactersInRange:NSMakeRange(acctlen - 4, 4) withString:@"****"];
        }
        else
        {
            obfuscatedUsername = [obfuscatedUsername stringByReplacingCharactersInRange:NSMakeRange(acctlen - 5, 5) withString:@"*****"];
        }
        
        NSString *subject = [NSString stringWithFormat:recovery_token_email_subject, appTitle];
        
        [mailComposer setSubject:subject];
        [mailComposer setToRecipients:@[emailAddress]];
        
        NSString *iosLink = [NSString stringWithFormat:@"iOS<br>\n<a href=\"%@://recovery?token=%@\">%@://recovery?token=%@</a>",
                             [MainViewController Singleton].appUrlPrefix,
                             _recoveryToken,
                             [MainViewController Singleton].appUrlPrefix,
                             _recoveryToken];
        NSString *androidLink = [NSString stringWithFormat:@"Android<br>\n<a href=\"https://recovery.airbitz.co/recovery?token=%@\">https://recovery.airbitz.co/recovery?token=%@</a>", _recoveryToken, _recoveryToken];


        NSString *htmlLink = [NSString stringWithFormat:@"%@<br><br>\n\n%@", iosLink, androidLink];
        
        NSString *content = [NSString stringWithFormat:recovery_token_email_body, appTitle, obfuscatedUsername, htmlLink];
        [mailComposer setMessageBody:content isHTML:YES];
        
        mailComposer.mailComposeDelegate = self;
        
        [self presentViewController:mailComposer animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:cantSendEmailText
                                                       delegate:nil
                                              cancelButtonTitle:okButtonText
                                              otherButtonTitles:nil];
        [alert show];
    }
}

-(BOOL) stringIsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

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
        
		CGSize size = self.contentView.frame.size;
		size.height = posY;
		
		//add QA blocks
		for(int i = 0; i < self.numQABlocks; i++)
		{
			QuestionAnswerView *qav = [QuestionAnswerView CreateInsideView:self.contentView withDelegate:self];

            if (self.mode == PassRecovMode_Recover)
            {
                [qav disableSelecting];
                if ([self.arrayQuestions count] > i)
                {
                    qav.labelQuestion.text = [self.arrayQuestions objectAtIndex:i];
                }
            }
			
			CGRect frame = qav.frame;
			frame.origin.x = (self.contentView.frame.size.width - frame.size.width ) / 2;
			frame.origin.y = posY;
			qav.frame = frame;
			
			qav.tag = i;
			//qav.alpha = 0.5;

            if (i == (self.numQABlocks - 1))
            {
                qav.answerField.returnKeyType = UIReturnKeyDone;
                qav.isLastQuestion = YES;
            }
            else
            {
                qav.answerField.returnKeyType = UIReturnKeyNext;
            }
            qav.answerField.placeholder = answersAreCaseSensitiveText;
			
			size.height += qav.frame.size.height;

			posY += frame.size.height;
		}

//        [self.passwordView removeFromSuperview];
//        [self.contentView addSubview:self.passwordView];
        
        //position complete Signup button below QA views
        self.completeSignupButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self updateDisplayForMode:self.mode];

        self.completeSignupButton.backgroundColor = [Theme Singleton].colorButtonGreen;
        [self.completeSignupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.completeSignupButton.hidden = NO;
        self.completeSignupButton.enabled = YES;
        [self.completeSignupButton addTarget:self action:@selector(CompleteSignup) forControlEvents:UIControlEventTouchDown];

        [self.contentView addSubview:self.completeSignupButton];
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
        self.contentViewHeight.constant = size.height;
    }
}

#pragma Password field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _passwordField) {
        [_passwordField resignFirstResponder];
    }
    return NO;
}

#pragma mark - QuestionAnswerView delegates

- (void)QuestionAnswerView:(QuestionAnswerView *)view;
{
    if (_activeTextField)
        [_activeTextField resignFirstResponder];
    [_passwordField resignFirstResponder];
    _activeTextField = nil;
    _activeQAView = view;
    
    //populate available questions
    view.availableQuestions = [self prunedQuestionsFor:self.arrayQuestionChoices];
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
    _activeQAView = nil;
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

    if (_activeTextField)
        [_activeTextField resignFirstResponder];
    _activeTextField = nil;

    if (viewNext != NULL)
    {
        if (self.mode == PassRecovMode_Recover)
        {
            // place the cursor in the answer
            [viewNext.answerField becomeFirstResponder];
        }
        else
        {
//            [viewNext presentQuestionChoices];
        }
    }
}

#pragma mark - SignUpViewControllerDelegates

-(void)signupViewControllerDidFinish:(SignUpViewController *)controller withBackButton:(BOOL)bBack
{
    [MainViewController animateOut:controller withBlur:NO complete:^
    {

        self.signUpController = nil;
        [MainViewController changeNavBarOwner:self];

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

//
//  SignUpViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "SignUpViewController.h"
#import "PasswordVerifyView.h"
#import "MinCharTextField.h"
#import "User.h"
#import "Config.h"
#import "LatoLabel.h"
#import "LatoLabel.h"
#import "Util.h"
#import "AirbitzCore.h"
#import "MinCharTextField.h"
#import "CommonTypes.h"
#import "FadingAlertView.h"
#import "MainViewController.h"
#import "Theme.h"
#import "LocalSettings.h"
#import "Strings.h"

#define KEYBOARD_MARGIN         10.0
#define DOLLAR_CURRENCY_NUMBER	840

@interface SignUpViewController () <UITextFieldDelegate, PasswordVerifyViewDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, FadingAlertViewDelegate>
{
	UITextField                     *_activeTextField;
	PasswordVerifyView              *_passwordVerifyView;
	float                           _keyboardFrameOriginY;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordTextHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordFieldHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordReenterHeight;
@property (weak, nonatomic) IBOutlet LatoLabel                  *labelUserName;
@property (weak, nonatomic) IBOutlet UIButton                   *buttonNextStep;
@property (weak, nonatomic) IBOutlet UIImageView                *imageUserName;
@property (weak, nonatomic) IBOutlet UIImageView                *imageReenterPassword;
@property (weak, nonatomic) IBOutlet LatoLabel                  *labelPIN;
@property (weak, nonatomic) IBOutlet UIImageView                *imagePIN;
@property (nonatomic, weak) IBOutlet MinCharTextField           *userNameTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField           *passwordTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField           *reenterPasswordTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField           *pinTextField;
@property (nonatomic, weak) IBOutlet UIView                     *contentView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView    *activityView;
@property (weak, nonatomic) IBOutlet LatoLabel                  *labelPasswordInfo;
@property (weak, nonatomic) IBOutlet UIImageView                *imagePassword;

@property (nonatomic, copy)     NSString                        *strReason;
@property (nonatomic, copy)     NSString                        *titleString;
@property (nonatomic, assign)   BOOL                            bSuccess;
@property (nonatomic, strong)   UIButton                        *buttonBlocker;
@property (nonatomic, strong)   NSMutableArray                  *arrayCategories;

@end

@implementation SignUpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	self.userNameTextField.delegate = self;
    self.userNameTextField.minimumCharacters = [AirbitzCore getMinimumUsernamedLength];
	self.passwordTextField.delegate = self;
    self.passwordTextField.minimumCharacters = [AirbitzCore getMinimumPasswordLength];
	self.reenterPasswordTextField.delegate = self;
    self.reenterPasswordTextField.minimumCharacters = [AirbitzCore getMinimumPasswordLength];
	self.pinTextField.delegate = self;
	self.pinTextField.minimumCharacters = [AirbitzCore getMinimumPINLength];
    if (self.strUserName)
    {
        self.userNameTextField.text = self.strUserName;
    }

    // set up our user blocking button
    self.buttonBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonBlocker.backgroundColor = [UIColor clearColor];
    [self.buttonBlocker addTarget:self action:@selector(buttonBlockerTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonBlocker.frame = self.view.bounds;
    self.buttonBlocker.hidden = YES;
    [self.view addSubview:self.buttonBlocker];

    if (_mode == SignUpMode_ChangePasswordNoVerify) {
        [self.passwordTextField becomeFirstResponder];
    } else {
        [self.userNameTextField becomeFirstResponder];
    }

    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
	//ABCLog(2,@"Adding keyboard notification");
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	[self.pinTextField addTarget:self action:@selector(pinTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
	[self.passwordTextField addTarget:self action:@selector(passwordTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];

    [MainViewController changeNavBarOwner:self];

    [MainViewController changeNavBar:self title:cancelButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Back:) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];

    [self updateDisplayForMode:_mode];
}

- (void)viewWillDisappear:(BOOL)animated
{
   // ABCLog(2,@"%s", __FUNCTION__);
    
	//ABCLog(2,@"Removing keyboard notification");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action Methods

-(IBAction)Back:(id)sender
{
     [self exitWithBackButton:YES];
}

- (IBAction)NextStep:(id)sender
{
    // if they entered a valid username or old password
    if ([self userNameFieldIsValid] == YES)
    {
        // check the new password fields
        if ([self newPasswordFieldsAreValid] == YES)
        {
            // check the username and pin field
            if ([self fieldsAreValid] == YES)
            {
                if (_mode == SignUpMode_ChangePassword ||
                    _mode == SignUpMode_ChangePasswordNoVerify)
                {
                    [self blockUser:YES];
                    // We post this to the Data Sync queue, so password is updated in between sync's
                    // NOTE: userNameTextField is repurposed for current password
                    [abcAccount changePassword:self.passwordTextField.text callback:^(NSError *error)
                    {
                        if (!error)
                        {
                            [self changePasswordComplete:YES errorMessage:nil];
                        }
                        else
                        {                            
                            [self changePasswordComplete:NO errorMessage:error.userInfo[NSLocalizedDescriptionKey]];
                        }
                    }];
                }
                else if (_mode == SignUpMode_ChangePasswordUsingAnswers)
                {
                    [self blockUser:YES];
                    [abcAccount changePassword:self.passwordTextField.text callback:^(NSError *error){
                        if (!error)
                        {
                            [abcAccount changePIN:self.pinTextField.text callback:^(NSError *error) {
                                [self blockUser:NO];
                                if (!error)
                                {
                                    [self changePasswordComplete:YES errorMessage:nil];
                                }
                                else
                                {
                                    [self.activityView stopAnimating];
                                    
                                    UIAlertView *alert = [[UIAlertView alloc]
                                                          initWithTitle:self.titleString
                                                          message:[NSString stringWithFormat:@"%@ failed:\n%@",
                                                                   self.titleString,
                                                                   error]
                                                          delegate:nil
                                                          cancelButtonTitle:okButtonText
                                                          otherButtonTitles:nil];
                                    [alert show];
                                    [self changePasswordComplete:YES errorMessage:nil];
                                }
                            }];
                            
                        }
                        else
                        {
                            [self blockUser:NO];
                            [self changePasswordComplete:NO errorMessage:error.userInfo[NSLocalizedDescriptionKey]];
                        }
                    }];
                }
                else
                {
                    [self blockUser:YES];
                    [abcAccount changePIN:self.pinTextField.text callback:^(NSError *error) {
                        if (!error)
                        {
                            // no callback on this one so tell them it was a success
                            UIAlertView *alert = [[UIAlertView alloc]
                                                  initWithTitle:pinSuccessfullyChanged
                                                  message:nil
                                                  delegate:self
                                                  cancelButtonTitle:okButtonText
                                                  otherButtonTitles:nil];
                            [alert show];
                        }
                        else
                        {
                            // no callback on this one so tell them it was a success
                            UIAlertView *alert = [[UIAlertView alloc]
                                                  initWithTitle:errorChangingPIN
                                                  message:error.userInfo[NSLocalizedDescriptionKey]
                                                  delegate:self
                                                  cancelButtonTitle:okButtonText
                                                  otherButtonTitles:nil];
                            [alert show];
                        }
                     }];
                }
            }
        }
    }
}

- (IBAction)buttonBlockerTouched:(id)sender
{
}

#pragma mark - Fading Alert Delegate

- (void)dismissFading:(BOOL)animated
{
    [FadingAlertView dismiss:FadingAlertDismissFast];
}

#pragma mark - Misc Methods

- (void)updateDisplayForMode:(tSignUpMode)mode
{
    // start with everything hidden
    self.labelUserName.hidden = YES;
    self.imageUserName.hidden = YES;
    self.imageReenterPassword.hidden = YES;
    self.labelPIN.hidden = YES;
    self.imagePIN.hidden = YES;
    self.userNameTextField.hidden = YES;
    self.passwordTextField.hidden = YES;
    self.reenterPasswordTextField.hidden = YES;
    self.pinTextField.hidden = YES;
    self.labelPasswordInfo.hidden = YES;
    self.imagePassword.hidden = YES;

    if (mode == SignUpMode_ChangePasswordNoVerify ||
        mode == SignUpMode_ChangePasswordUsingAnswers)
    {
        [MainViewController changeNavBar:self title:cancelButtonText side:NAV_BAR_LEFT button:true enable:false action:@selector(Back:) fromObject:self];
    }
    
    if (mode == SignUpMode_ChangePasswordNoVerify
            || (_mode == SignUpMode_ChangePassword && ![abcAccount accountHasPassword]))
    {
        self.titleString = changePasswordText;
        [MainViewController changeNavBarTitle:self title:self.titleString];
        self.labelUserName.text = [NSString stringWithFormat:usernameFormatString, abcAccount.name];
        [self.buttonNextStep setTitle:doneButtonText forState:UIControlStateNormal];
        self.passwordTextField.placeholder = newPasswordText;
        self.reenterPasswordTextField.placeholder = reenterNewPasswordText;
        
        self.imageUserName.hidden = NO;
        self.imageReenterPassword.hidden = NO;
        self.passwordTextField.hidden = NO;
        self.reenterPasswordTextField.hidden = NO;
        self.labelPasswordInfo.hidden = NO;
        self.imagePassword.hidden = NO;
        
        self.reenterPasswordTextField.returnKeyType = UIReturnKeyDone;
        
        self.userNameTextField.secureTextEntry = YES;
    }
    else if (mode == SignUpMode_ChangePassword)
    {
        self.labelUserName.text = [NSString stringWithFormat:usernameFormatString, abcAccount.name];
        self.titleString = changePasswordText;
        [MainViewController changeNavBarTitle:self title:self.titleString];
        [self.buttonNextStep setTitle:doneButtonText forState:UIControlStateNormal];
        self.passwordTextField.placeholder = newPasswordText;
        self.reenterPasswordTextField.placeholder = reenterNewPasswordText;
        self.userNameTextField.placeholder = currentPasswordText;

        self.imageUserName.hidden = NO;
        self.userNameTextField.hidden = NO; // used for old password in this case
        self.imageReenterPassword.hidden = NO;
        self.passwordTextField.hidden = NO;
        self.reenterPasswordTextField.hidden = NO;
        self.labelPasswordInfo.hidden = NO;
        self.imagePassword.hidden = NO;

        self.reenterPasswordTextField.returnKeyType = UIReturnKeyDone;

        self.userNameTextField.secureTextEntry = YES;
    }
    else if (mode == SignUpMode_ChangePasswordUsingAnswers)
    {
        self.titleString = changePasswordText;
        [MainViewController changeNavBarTitle:self title:self.titleString];
        [self.buttonNextStep setTitle:doneButtonText forState:UIControlStateNormal];
        self.passwordTextField.placeholder = newPasswordText;
        self.reenterPasswordTextField.placeholder = reenterNewPasswordText;

        self.labelPIN.hidden = NO;
        self.pinTextField.hidden = NO;
        self.imagePIN.hidden = NO;
        self.imageReenterPassword.hidden = NO;
        self.passwordTextField.hidden = NO;
        self.reenterPasswordTextField.hidden = NO;
        self.labelPasswordInfo.hidden = NO;
        self.imagePassword.hidden = NO;

        self.reenterPasswordTextField.returnKeyType = UIReturnKeyNext;

        self.userNameTextField.secureTextEntry = YES;
    }
    else if (mode == SignUpMode_ChangePIN)
    {
        self.labelUserName.text = [NSString stringWithFormat:usernameFormatString, abcAccount.name];
        self.titleString = changePINText;
        [MainViewController changeNavBarTitle:self title:self.titleString];
        [self.buttonNextStep setTitle:doneButtonText forState:UIControlStateNormal];
        self.pinTextField.placeholder = newPINText;
        self.userNameTextField.placeholder = currentPasswordText;
        self.userNameTextField.hidden = ![abcAccount accountHasPassword];

        self.labelPIN.hidden = NO;
        self.pinTextField.hidden = NO;
        self.imagePIN.hidden = NO;
        self.imageUserName.hidden = NO;

        self.passwordTextHeight.constant = 0;
        self.passwordFieldHeight.constant = 0;
        self.passwordReenterHeight.constant = 0;

        self.reenterPasswordTextField.returnKeyType = UIReturnKeyNext;

        self.userNameTextField.secureTextEntry = YES;
    }
}

// checks the username field (non-blank or matches old password depending on the mode)
// returns YES if field is good
// if the field is bad, an appropriate message box is displayed
// note: this function is aware of the 'mode' of the view controller and will check and display appropriately
- (BOOL)userNameFieldIsValid
{
    BOOL bUserNameFieldIsValid = YES;

    if (_mode == SignUpMode_ChangePasswordNoVerify
            || (![abcAccount accountHasPassword]
                && (_mode == SignUpMode_ChangePassword
                    || _mode == SignUpMode_ChangePIN)))
    {
        bUserNameFieldIsValid = YES;
    }
    else if (_mode != SignUpMode_ChangePasswordUsingAnswers) // the user name field is used for the old password in this case
    {
        // if the password is wrong
        if ([abcAccount checkPassword:self.userNameTextField.text] == NO)
        {
            bUserNameFieldIsValid = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:self.titleString
                                  message:[NSString stringWithFormat:pinOrPasswordCheckFailedFormatString,
                                           self.titleString,
                                           incorrectCurrentPassword]
                                  delegate:nil
                                  cancelButtonTitle:okButtonText
                                  otherButtonTitles:nil];
            [alert show];
        }
    }

    return bUserNameFieldIsValid;
}

// checks the password against the password rules
// returns YES if new password fields are good, NO if the new password fields failed the checks
// if the new password fields are bad, an appropriate message box is displayed
// note: this function is aware of the 'mode' of the view controller and will check and display appropriately
- (BOOL)newPasswordFieldsAreValid
{
	BOOL bNewPasswordFieldsAreValid = YES;

    // if we are signing up for a new account or changing our password
    if ((_mode == SignUpMode_ChangePassword) || (_mode == SignUpMode_ChangePasswordNoVerify) || (_mode == SignUpMode_ChangePasswordUsingAnswers))
    {
        ABCPasswordRuleResult *result = [AirbitzCore checkPasswordRules:self.passwordTextField.text];
        
        if (!result.passed)
        {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:insufficientPasswordText
                                  message:[Util checkPasswordResultsMessage:result]
                                  delegate:nil
                                  cancelButtonTitle:okButtonText
                                  otherButtonTitles:nil];
            bNewPasswordFieldsAreValid = NO;
            [alert show];
        }
        else if ([self.passwordTextField.text isEqualToString:self.reenterPasswordTextField.text] == NO)
        {
            bNewPasswordFieldsAreValid = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:self.titleString
                                  message:[NSString stringWithFormat:pinOrPasswordCheckFailedFormatString,
                                           self.titleString,
                                           passwordMismatchText]
                                  delegate:nil
                                  cancelButtonTitle:okButtonText
                                  otherButtonTitles:nil];
            [alert show];
        }
    }

	return bNewPasswordFieldsAreValid;
}

// checks the pin field
// returns YES if field is good
// if the field is bad, an appropriate message box is displayed
// note: this function is aware of the 'mode' of the view controller and will check and display appropriately
- (BOOL)fieldsAreValid
{
    BOOL valid = YES;

    // if we are signing up for a new account
    if ((_mode == SignUpMode_ChangePIN) || (_mode == SignUpMode_ChangePasswordUsingAnswers))
    {
        if ([abcAccount accountHasPassword] && self.userNameTextField.text.length < [AirbitzCore getMinimumUsernamedLength])
        {
            valid = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:self.titleString
                                  message:[NSString stringWithFormat:pinOrPasswordCheckFailedFormatString,
                                           self.titleString,
                                           [NSString stringWithFormat:usernameMustBeAtLeastXXXCharacters, [AirbitzCore getMinimumUsernamedLength]]]
                                  delegate:nil
                                  cancelButtonTitle:okButtonText
                                  otherButtonTitles:nil];
            [alert show];
        }
        // if the pin isn't long enough
        else if (self.pinTextField.text.length < [AirbitzCore getMinimumPINLength])
        {
            valid = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:self.titleString
                                  message:[NSString stringWithFormat:pinOrPasswordCheckFailedFormatString,
                                           self.titleString,
                                           [NSString stringWithFormat:pingMustBeXXXDigitsFormatString, [AirbitzCore getMinimumPINLength]]]
                                  delegate:nil
                                  cancelButtonTitle:okButtonText
                                  otherButtonTitles:nil];
            [alert show];
        }
    }

    return valid;
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

-(void)scrollTextFieldAboveKeyboard:(UITextField *)textField
{
	if(_keyboardFrameOriginY) //set when keyboard is visible
	{
		CGRect textFieldFrame = [self.contentView convertRect:_activeTextField.frame toView:self.view.window];
		float overlap = self.contentView.frame.origin.y + _keyboardFrameOriginY - KEYBOARD_MARGIN - (textFieldFrame.origin.y + textFieldFrame.size.height);
		//ABCLog(2,@"Overlap: %f", overlap);
		if(overlap < 0)
		{
            [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                                  delay:[Theme Singleton].animationDelayTimeDefault
								options: UIViewAnimationOptionCurveEaseInOut
							 animations:^
			 {
				 CGRect frame = self.contentView.frame;
				 frame.origin.y = overlap;
				 self.contentView.frame = frame;
			 }
			 completion:^(BOOL finished)
			 {
				 
			 }];
		}
	}
}

- (void)installLeftToRightSwipeDetection
{
	UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeftToRight:)];
	gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:gesture];
}

- (void)exit
{
    [self exitWithBackButton:NO];
}

- (void)exitWithBackButton:(BOOL)bBack
{
	[self.delegate signupViewControllerDidFinish:self withBackButton:bBack];
}

#pragma mark - keyboard callbacks

- (void)keyboardWillShow:(NSNotification *)notification
{
	//Get KeyboardFrame (in Window coordinates)
	if(_activeTextField)
	{
		//ABCLog(2,@"Keyboard will show for SignUpView");
		NSDictionary *userInfo = [notification userInfo];
		CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

		_keyboardFrameOriginY = keyboardFrame.origin.y;

		[self scrollTextFieldAboveKeyboard:_activeTextField];
	}
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	if(_activeTextField)
	{
		//ABCLog(2,@"Keyboard will hide for SignUpView");
		_activeTextField = nil;
	}
	_keyboardFrameOriginY = 0.0;
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
	 {
		 CGRect frame = self.contentView.frame;
		 frame.origin.y = 0;
		 self.contentView.frame = frame;
	 }
                     completion:^(BOOL finished)
	 {
	 }];
}

#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	//called when user taps on either search textField or location textField
	
	//ABCLog(2,@"TextField began editing");
	_activeTextField = textField;
	if(textField == self.passwordTextField)
	{
//		if(textField.text.length)
		{
			if(_passwordVerifyView == nil)
			{
				_passwordVerifyView = [PasswordVerifyView CreateInsideView:self.contentView withDelegate:self];
                CGRect frame = _passwordVerifyView.frame;
                frame.origin.y = [MainViewController getHeaderHeight];
                frame.size.width = [MainViewController getWidth];
                _passwordVerifyView.frame = frame;
			}
			_passwordVerifyView.password = textField.text;
		}
	}
	else
	{
		if(_passwordVerifyView)
		{
			[_passwordVerifyView dismiss];
		}
	}
	//won't do anything when a textField is tapped for the first time and no keyboard is visible because
	//keyboardFrameOriginY isn't set yet (doestn' get set until KeyboardWillShow notification which occurs after this
	//method is called.  But -scrollTextFieldAboveKeyboard gets called from the KeyboardWillShow notification
	[self scrollTextFieldAboveKeyboard:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ((_mode == SignUpMode_ChangePassword || _mode == SignUpMode_ChangePasswordNoVerify) && (textField == self.reenterPasswordTextField))
    {
		[textField resignFirstResponder];
    }
    else
    {
        UIView *view = [self.contentView viewWithTag:textField.tag + 1];
        if (view)
        {
            if ((_mode == SignUpMode_ChangePIN) && (textField == self.userNameTextField))
            {
                // skip to the pin
                view = self.pinTextField;
            }

            [view becomeFirstResponder];
        }
        else
        {
            [textField resignFirstResponder];
        }
    }
    
	return YES;
}

- (void)pinTextFieldChanged:(UITextField *)textField
{
	if (textField.text.length == 4)
	{
		[textField resignFirstResponder];
	}
}

- (void)passwordTextFieldChanged:(UITextField *)textField
{
	if (_passwordVerifyView == nil)
	{
		_passwordVerifyView = [PasswordVerifyView CreateInsideView:self.contentView withDelegate:self];
        CGRect frame = _passwordVerifyView.frame;
        frame.origin.y = [MainViewController getHeaderHeight];
        frame.size.width = [MainViewController getWidth];
        _passwordVerifyView.frame = frame;
	}
	_passwordVerifyView.password = textField.text;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(_activeTextField)
	{
		
		if(_activeTextField == self.passwordTextField)
		{
			if(_passwordVerifyView)
			{
				[_passwordVerifyView dismiss];
			}
		}
		[_activeTextField resignFirstResponder];
	}
}

#pragma mark - PasswordVerifyViewDelegates

- (void)PasswordVerifyViewDismissed:(PasswordVerifyView *)pv
{
	[_passwordVerifyView removeFromSuperview];
	_passwordVerifyView = nil;
}

#pragma mark - ABC Callbacks

- (void)changePasswordComplete:(BOOL)success errorMessage:(NSString *)errorMessage;
{
    [self blockUser:NO];

    UIAlertView *alert;
    if (success)
    {
        // set up the user password to the new one
        NSString *username = abcAccount.name;
        if (self.strUserName) {
            username = self.strUserName;
        }

        alert = [[UIAlertView alloc]
                 initWithTitle:self.titleString
                 message:passwordSuccessfullyChanged
                 delegate:self
                 cancelButtonTitle:okButtonText
                 otherButtonTitles:nil];
        
    }
    else
    {
        alert = [[UIAlertView alloc]
                 initWithTitle:self.titleString
                 message:[NSString stringWithFormat:passwordChangeFailedFormatString, errorMessage]
                 delegate:nil
                 cancelButtonTitle:okButtonText
                 otherButtonTitles:nil];
    }

    [alert show];
}

#pragma mark - UIAlertView delegates

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // we only use an alert view delegate when we are delaying the exit
    // so we can exit now
    [self performSelector:@selector(exit) withObject:nil afterDelay:0.0];
}

#pragma mark - GestureReconizer methods

- (void)didSwipeLeftToRight:(UIGestureRecognizer *)gestureRecognizer
{
    [self Back:nil];
}

#pragma mark - Custom Notification Handlers

// called when a tab bar button that is already selected, is reselected again
- (void)tabBarButtonReselect:(NSNotification *)notification
{
    [self Back:nil];
}

@end

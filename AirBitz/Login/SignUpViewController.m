//
//  SignUpViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "SignUpViewController.h"
#import "ABC.h"
#import "PasswordVerifyView.h"
#import "PasswordRecoveryViewController.h"
#import "MinCharTextField.h"
#import "User.h"
#import "Config.h"
#import "MontserratLabel.h"
#import "LatoLabel.h"
#import "User.h"
#import "Util.h"

#define KEYBOARD_MARGIN         10.0
#define DOLLAR_CURRENCY_NUMBER	840

#define MIN_PIN_LENGTH          4

@interface SignUpViewController () <UITextFieldDelegate, PasswordVerifyViewDelegate, PasswordRecoveryViewControllerDelegate, UIAlertViewDelegate>
{
	UITextField                     *_activeTextField;
	PasswordVerifyView              *_passwordVerifyView;
	float                           _keyboardFrameOriginY;
	PasswordRecoveryViewController  *_passwordRecoveryController;
}

@property (weak, nonatomic) IBOutlet MontserratLabel            *labelTitle;
@property (weak, nonatomic) IBOutlet MontserratLabel            *labelUserName;
@property (weak, nonatomic) IBOutlet UIButton                   *buttonNextStep;
@property (weak, nonatomic) IBOutlet UIImageView                *imageUserName;
@property (weak, nonatomic) IBOutlet UIImageView                *imageReenterPassword;
@property (weak, nonatomic) IBOutlet MontserratLabel            *labelPIN;
@property (weak, nonatomic) IBOutlet UIImageView                *imagePIN;
@property (nonatomic, weak) IBOutlet UITextField                *userNameTextField;
@property (nonatomic, weak) IBOutlet UITextField                *passwordTextField;
@property (nonatomic, weak) IBOutlet UITextField                *reenterPasswordTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField           *pinTextField;
@property (nonatomic, weak) IBOutlet UIView                     *contentView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView    *activityView;
@property (weak, nonatomic) IBOutlet LatoLabel                  *labelPasswordInfo;
@property (weak, nonatomic) IBOutlet UIImageView                *imagePassword;


@property (nonatomic, copy)     NSString                        *strReason;
@property (nonatomic, assign)   BOOL                            bSuccess;
@property (nonatomic, strong)   UIButton                        *buttonBlocker;

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
	self.passwordTextField.delegate = self;
	self.reenterPasswordTextField.delegate = self;
	self.pinTextField.delegate = self;
	self.pinTextField.minimumCharacters = MIN_PIN_LENGTH;

    // set up our user blocking button
    self.buttonBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonBlocker.backgroundColor = [UIColor clearColor];
    [self.buttonBlocker addTarget:self action:@selector(buttonBlockerTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonBlocker.frame = self.view.bounds;
    self.buttonBlocker.hidden = YES;
    [self.view addSubview:self.buttonBlocker];
}

-(void)viewWillAppear:(BOOL)animated
{
	//NSLog(@"Adding keyboard notification");
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	[self.pinTextField addTarget:self action:@selector(pinTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
	[self.passwordTextField addTarget:self action:@selector(passwordTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];

    [self updateDisplayForMode:_mode];
}

- (void)viewWillDisappear:(BOOL)animated
{
   // NSLog(@"%s", __FUNCTION__);
    
	//NSLog(@"Removing keyboard notification");
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

- (IBAction)NextStep:(id)sender
{
#if SKIP_PW_VALIDATION_CHECKS
	[self showPasswordRecoveryController];
#else
    // if they entered a valid username or old password
    if ([self userNameFieldIsValid] == YES)
    {
        // check the new password fields
        if ([self newPasswordFieldsAreValid] == YES)
        {
            // check the pin field
            if ([self pinFieldIsValid] == YES)
            {
                tABC_Error Error;
                tABC_CC result = ABC_CC_Ok;

                // if we are signing up a new account
                if (_mode == SignUpMode_SignUp)
                {
                    [self blockUser:YES];
                    result = ABC_CreateAccount([self.userNameTextField.text UTF8String],
                                               [self.passwordTextField.text UTF8String],
                                               [self.pinTextField.text UTF8String],
                                               ABC_SignUp_Request_Callback,
                                               (__bridge void *)self,
                                               &Error);
                }
                else if (_mode == SignUpMode_ChangePassword)
                {
                    // get their old pen
                    char *szOldPIN = NULL;
                    ABC_GetPIN([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &szOldPIN, nil);

                    [self blockUser:YES];
                    result = ABC_ChangePassword([[User Singleton].name UTF8String],
                                                [[User Singleton].password UTF8String],
                                                [self.passwordTextField.text UTF8String],
                                                szOldPIN,
                                                ABC_SignUp_Request_Callback,
                                                (__bridge void *)self,
                                                &Error);

                    free(szOldPIN);
                }
                else
                {
                    result = ABC_SetPIN([[User Singleton].name UTF8String],
                                        [[User Singleton].password UTF8String],
                                        [self.pinTextField.text UTF8String],
                                        &Error);
                }

                // if success
                if (ABC_CC_Ok == result)
                {
                    if (_mode == SignUpMode_ChangePIN)
                    {
                        // no callback on this one so tell them it was a success
                        UIAlertView *alert = [[UIAlertView alloc]
                                              initWithTitle:self.labelTitle.text
                                              message:NSLocalizedString(@"PIN successfully changed.", @"")
                                              delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
                        [alert show];
                    }
                }
                else
                {
                    [self.activityView stopAnimating];
                    [Util printABC_Error:&Error];
                    UIAlertView *alert = [[UIAlertView alloc]
                                          initWithTitle:self.labelTitle.text
                                          message:[NSString stringWithFormat:@"%@ failed:\n%s",
                                                   self.labelTitle.text,
                                                   Error.szDescription]
                                          delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                    [alert show];
                }
            }
        }
    }
#endif
}

- (IBAction)buttonBlockerTouched:(id)sender
{
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

    if (mode == SignUpMode_SignUp)
    {
        self.labelTitle.text = NSLocalizedString(@"Sign Up", @"screen title");
        [self.buttonNextStep setTitle:NSLocalizedString(@"Next Step", @"") forState:UIControlStateNormal];
        self.passwordTextField.placeholder = NSLocalizedString(@"Password", @"");
        self.reenterPasswordTextField.placeholder = NSLocalizedString(@"Re-enter Password", @"");
        self.userNameTextField.placeholder = NSLocalizedString(@"User Name", @"");
        self.pinTextField.placeholder = NSLocalizedString(@"Create Pin", @"");

        self.imageUserName.hidden = NO;
        self.imageReenterPassword.hidden = NO;
        self.labelPIN.hidden = NO;
        self.imagePIN.hidden = NO;
        self.userNameTextField.hidden = NO;
        self.passwordTextField.hidden = NO;
        self.reenterPasswordTextField.hidden = NO;
        self.pinTextField.hidden = NO;
        self.labelPasswordInfo.hidden = NO;
        self.imagePassword.hidden = NO;

        self.reenterPasswordTextField.returnKeyType = UIReturnKeyNext;
        self.userNameTextField.secureTextEntry = NO;
    }
    else if (mode == SignUpMode_ChangePassword)
    {
        self.labelUserName.text = [NSString stringWithFormat:@"User Name: %@", [User Singleton].name];
        self.labelTitle.text = NSLocalizedString(@"Change Password", @"screen title");
        [self.buttonNextStep setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
        self.passwordTextField.placeholder = NSLocalizedString(@"New Password", @"");
        self.reenterPasswordTextField.placeholder = NSLocalizedString(@"Re-enter New Password", @"");
        self.userNameTextField.placeholder = NSLocalizedString(@"Old Password", @"");

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
    else if (mode == SignUpMode_ChangePIN)
    {
        self.labelUserName.text = [NSString stringWithFormat:@"User Name: %@", [User Singleton].name];
        self.labelTitle.text = NSLocalizedString(@"Change Withdrawal PIN", @"screen title");
        [self.buttonNextStep setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
        self.pinTextField.placeholder = NSLocalizedString(@"New Pin", @"");
        self.userNameTextField.placeholder = NSLocalizedString(@"Password", @"");

        self.labelPIN.hidden = NO;
        self.pinTextField.hidden = NO;
        self.imagePIN.hidden = NO;
        self.imageUserName.hidden = NO;
        self.userNameTextField.hidden = NO; // used for old password in this case

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

    // if we are signing up for a new account
    if (_mode == SignUpMode_SignUp)
    {
        // if nothing was entered
        if ([self.userNameTextField.text length] == 0)
        {
            bUserNameFieldIsValid = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:self.labelTitle.text
                                  message:[NSString stringWithFormat:@"%@ failed:\n%@",
                                           self.labelTitle.text,
                                           NSLocalizedString(@"You must entere a user name", @"")]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }
    }
    else // the user name field is used for the old password in this case
    {
        // if the password is wrong
        if ([[User Singleton].password isEqualToString:self.userNameTextField.text] == NO)
        {
            bUserNameFieldIsValid = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:self.labelTitle.text
                                  message:[NSString stringWithFormat:@"%@ failed:\n%@",
                                           self.labelTitle.text,
                                           NSLocalizedString(@"Incorrect password", @"")]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
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
    if ((_mode == SignUpMode_SignUp) || (_mode == SignUpMode_ChangePassword))
    {
        double secondsToCrack;
        tABC_Error Error;
        tABC_CC result;
        unsigned int count = 0;
        tABC_PasswordRule **aRules = NULL;
        result = ABC_CheckPassword([self.passwordTextField.text UTF8String],
                                   &secondsToCrack,
                                   &aRules,
                                   &count,
                                   &Error);

        //printf("Password results:\n");
        NSMutableString *message = [[NSMutableString alloc] init];
        [message appendString:@"Your password...\n"];
        for (int i = 0; i < count; i++)
        {
            tABC_PasswordRule *pRule = aRules[i];
            if (!pRule->bPassed)
            {
                bNewPasswordFieldsAreValid = NO;
                [message appendFormat:@"%s.\n", pRule->szDescription];
            }

            //printf("%s - %s\n", pRule->bPassed ? "pass" : "fail", pRule->szDescription);
        }

        ABC_FreePasswordRuleArray(aRules, count);
        if (bNewPasswordFieldsAreValid == NO)
        {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Insufficient Password", @"Title of password check popup alert")
                                  message:message
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }
        else if ([self.passwordTextField.text isEqualToString:self.reenterPasswordTextField.text] == NO)
        {
            bNewPasswordFieldsAreValid = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:self.labelTitle.text
                                  message:[NSString stringWithFormat:@"%@ failed:\n%@",
                                           self.labelTitle.text,
                                           NSLocalizedString(@"Password does not match re-entered password", @"")]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
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
- (BOOL)pinFieldIsValid
{
    BOOL bpinNameFieldIsValid = YES;

    // if we are signing up for a new account
    if ((_mode == SignUpMode_SignUp) || (_mode == SignUpMode_ChangePIN))
    {
        // if the pin isn't long enough
        if (self.pinTextField.text.length < MIN_PIN_LENGTH)
        {
            bpinNameFieldIsValid = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:self.labelTitle.text
                                  message:[NSString stringWithFormat:@"%@ failed:\n%@",
                                           self.labelTitle.text,
                                           NSLocalizedString(@"Withdrawl PIN must be 4 digits", @"")]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }
    }

    return bpinNameFieldIsValid;
}

-(void)showPasswordRecoveryController
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_passwordRecoveryController = [mainStoryboard instantiateViewControllerWithIdentifier:@"PasswordRecoveryViewController"];
	
	_passwordRecoveryController.delegate = self;
	_passwordRecoveryController.mode = PassRecovMode_SignUp;
	
	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
	_passwordRecoveryController.view.frame = frame;
	[self.view addSubview:_passwordRecoveryController.view];


	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 _passwordRecoveryController.view.frame = self.view.bounds;
	 }
					 completion:^(BOOL finished)
	 {
	 }];
}

-(void)createFirstWallet
{
    [self blockUser:YES];

	tABC_CC result;
	tABC_Error Error;
	result = ABC_CreateWallet([self.userNameTextField.text UTF8String],
                              [self.passwordTextField.text UTF8String],
                              [NSLocalizedString(@"My Wallet", @"Name of initial wallet") UTF8String],
                              DOLLAR_CURRENCY_NUMBER,
                              0,
                              ABC_SignUp_Request_Callback,
                              (__bridge void *)self,
                              &Error);
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
		//NSLog(@"Overlap: %f", overlap);
		if(overlap < 0)
		{
			[UIView animateWithDuration:0.35
								  delay: 0.0
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

- (void)exit
{
	[self.delegate signupViewControllerDidFinish:self];
}

#pragma mark - keyboard callbacks

- (void)keyboardWillShow:(NSNotification *)notification
{
	//Get KeyboardFrame (in Window coordinates)
	if(_activeTextField)
	{
		//NSLog(@"Keyboard will show for SignUpView");
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
		//NSLog(@"Keyboard will hide for SignUpView");
		_activeTextField = nil;
	}
	_keyboardFrameOriginY = 0.0;
	[UIView animateWithDuration:0.35
                          delay:0.0
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
	
	//NSLog(@"TextField began editing");
	_activeTextField = textField;
	if(textField == self.passwordTextField)
	{
		if(textField.text.length)
		{
			if(_passwordVerifyView == nil)
			{
				_passwordVerifyView = [PasswordVerifyView CreateInsideView:self.contentView withDelegate:self];
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
    if ((_mode == SignUpMode_ChangePassword) && (textField == self.reenterPasswordTextField))
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

#pragma mark - PasswordRecoveryViewController Delegates

- (void)passwordRecoveryViewControllerDidFinish:(PasswordRecoveryViewController *)controller
{
	[controller.view removeFromSuperview];
	_passwordRecoveryController = nil;
    [self exit];
}

#pragma mark - ABC Callbacks

- (void)createAccountComplete
{
    [self blockUser:NO];

    //NSLog(@"Account create complete");
    if (_bSuccess)
    {
		//NSLog(@"Account created");
		//set username and password for app
		[User Singleton].name = self.userNameTextField.text;
		[User Singleton].password = self.passwordTextField.text;

        // now that the account is created, create the first wallet
		[self createFirstWallet];
    }
    else
    {
        //NSLog(@"%@", [NSString stringWithFormat:@"Account creation failed\n%@", strReason]);
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Account Sign Up", @"Title of account signup error alert")
							  message:[NSString stringWithFormat:@"Sign-up failed:\n%@", _strReason]
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];

    }
}

- (void)createWalletComplete
{
    [self blockUser:NO];

    //NSLog(@"Wallet create complete");
    if (_bSuccess)
    {
        //self.labelStatus.text = [NSString stringWithFormat:@"Wallet created: %@", self.strWalletUUID];
		//NSLog(@"Successfully created wallet");

        [self showPasswordRecoveryController];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Account Sign Up", @"Title of account signup error alert")
							  message:[NSString stringWithFormat:@"Wallet creation failed:\n%@", _strReason]
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
    }
}

- (void)changePasswordComplete
{
    [self blockUser:NO];

    UIAlertView *alert;
    if (_bSuccess)
    {
        // set up the user password to the new one
        [[User Singleton] setPassword:self.passwordTextField.text];

        alert = [[UIAlertView alloc]
                 initWithTitle:self.labelTitle.text
                 message:NSLocalizedString(@"Password successfully changed.", @"")
                 delegate:self
                 cancelButtonTitle:@"OK"
                 otherButtonTitles:nil];
    }
    else
    {
        alert = [[UIAlertView alloc]
                 initWithTitle:self.labelTitle.text
                 message:[NSString stringWithFormat:@"Password change failed:\n%@", _strReason]
                 delegate:nil
                 cancelButtonTitle:@"OK"
                 otherButtonTitles:nil];
    }

    [alert show];
}

void ABC_SignUp_Request_Callback(const tABC_RequestResults *pResults)
{
    //NSLog(@"Request callback");

    if (pResults)
    {
        SignUpViewController *controller = (__bridge id)pResults->pData;
        controller.bSuccess = (BOOL)pResults->bSuccess;
        controller.strReason = [NSString stringWithFormat:@"%s", pResults->errorInfo.szDescription];
        if (pResults->requestType == ABC_RequestType_CreateAccount)
        {
           // NSLog(@"Create account completed with cc: %ld (%s)", (unsigned long) pResults->errorInfo.code, pResults->errorInfo.szDescription);
            [controller performSelectorOnMainThread:@selector(createAccountComplete) withObject:nil waitUntilDone:FALSE];
        }
		else if (pResults->requestType == ABC_RequestType_CreateWallet)
		{
			if (pResults->pRetData)
            {
                //controller.strWalletUUID = [NSString stringWithFormat:@"%s", (char *)pResults->pRetData];
                free(pResults->pRetData);
            }
            else
            {
                //controller.strWalletUUID = @"(Unknown UUID)";
            }
            //NSLog(@"Create wallet completed with cc: %ld (%s)", (unsigned long) pResults->errorInfo.code, pResults->errorInfo.szDescription);
            [controller performSelectorOnMainThread:@selector(createWalletComplete) withObject:nil waitUntilDone:FALSE];
		}
        else if (pResults->requestType == ABC_RequestType_ChangePassword)
        {
            [controller performSelectorOnMainThread:@selector(changePasswordComplete) withObject:nil waitUntilDone:FALSE];
        }
    }
}

#pragma mark - UIAlertView delegates

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // we only use an alert view delegate when we are delaying the exit
    // so we can exit now
    [self performSelector:@selector(exit) withObject:nil afterDelay:0.0];
}

@end

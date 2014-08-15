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
#import "Util.h"
#import "CoreBridge.h"
#import "MinCharTextField.h"

#define KEYBOARD_MARGIN         10.0
#define DOLLAR_CURRENCY_NUMBER	840

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
@property (nonatomic, weak) IBOutlet MinCharTextField           *userNameTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField           *passwordTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField           *reenterPasswordTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField           *pinTextField;
@property (nonatomic, weak) IBOutlet UIView                     *contentView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView    *activityView;
@property (weak, nonatomic) IBOutlet LatoLabel                  *labelPasswordInfo;
@property (weak, nonatomic) IBOutlet UIImageView                *imagePassword;


@property (nonatomic, copy)     NSString                        *strReason;
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
    self.userNameTextField.minimumCharacters = ABC_MIN_USERNAME_LENGTH;
	self.passwordTextField.delegate = self;
    self.passwordTextField.minimumCharacters = ABC_MIN_PASS_LENGTH;
	self.reenterPasswordTextField.delegate = self;
    self.reenterPasswordTextField.minimumCharacters = ABC_MIN_PASS_LENGTH;
	self.pinTextField.delegate = self;
	self.pinTextField.minimumCharacters = ABC_MIN_PIN_LENGTH;
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

    // put the cursor in the user name field
    [self.userNameTextField becomeFirstResponder];
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
		 [self exitWithBackButton:YES];
	 }];
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
                    [self blockUser:YES];

                    result = ABC_CC_Ok;
                    // We post this to the Data Sync queue, so password is updated in between sync's
                    [CoreBridge postToSyncQueue:^(void) {
                        tABC_Error Error;
                        [CoreBridge stopWatchers];
                        [CoreBridge stopQueues];

                        char *szOldPIN = NULL;
                        ABC_GetPIN([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &szOldPIN, nil);
                        tABC_CC result = ABC_ChangePassword([[User Singleton].name UTF8String],
                                                    [[User Singleton].password UTF8String],
                                                    [self.passwordTextField.text UTF8String],
                                                    szOldPIN,
                                                    NULL,
                                                    NULL,
                                                    &Error);
                        free(szOldPIN);

                        _bSuccess = result == ABC_CC_Ok;
                        _strReason = [NSString stringWithFormat:@"%@", [Util errorMap:&Error]];

                        [CoreBridge startWatchers];
                        [CoreBridge startQueues];
                        [self performSelectorOnMainThread:@selector(changePasswordComplete) withObject:nil waitUntilDone:FALSE];
                    }];
                }
                else if (_mode == SignUpMode_ChangePasswordUsingAnswers)
                {
                    [self blockUser:YES];
                    result = ABC_ChangePasswordWithRecoveryAnswers([self.strUserName UTF8String],
                                                                   [self.strAnswers UTF8String],
                                                                   [self.passwordTextField.text UTF8String],
                                                                   [self.pinTextField.text UTF8String],
                                                                   ABC_SignUp_Request_Callback,
                                                                   (__bridge void *)self,
                                                                   &Error);
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
                    [self blockUser:NO];
                    [self.activityView stopAnimating];
                    [Util printABC_Error:&Error];
                    UIAlertView *alert = [[UIAlertView alloc]
                                          initWithTitle:self.labelTitle.text
                                          message:[NSString stringWithFormat:@"%@ failed:\n%@",
                                                   self.labelTitle.text,
                                                   [Util errorMap:&Error]]
                                          delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                    [alert show];
                }
            }
        }
    }
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
    else if (mode == SignUpMode_ChangePasswordUsingAnswers)
    {
        self.labelTitle.text = NSLocalizedString(@"Change Password", @"screen title");
        [self.buttonNextStep setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
        self.passwordTextField.placeholder = NSLocalizedString(@"New Password", @"");
        self.reenterPasswordTextField.placeholder = NSLocalizedString(@"Re-enter New Password", @"");

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
                                           NSLocalizedString(@"You must enter a user name", @"")]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }
    }
    else if (_mode != SignUpMode_ChangePasswordUsingAnswers) // the user name field is used for the old password in this case
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
    if ((_mode == SignUpMode_SignUp) || (_mode == SignUpMode_ChangePassword) || (_mode == SignUpMode_ChangePasswordUsingAnswers))
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
- (BOOL)fieldsAreValid
{
    BOOL valid = YES;

    // if we are signing up for a new account
    if ((_mode == SignUpMode_SignUp) || (_mode == SignUpMode_ChangePIN) || (_mode == SignUpMode_ChangePasswordUsingAnswers))
    {
        if (self.userNameTextField.text.length < ABC_MIN_USERNAME_LENGTH)
        {
            valid = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:self.labelTitle.text
                                  message:[NSString stringWithFormat:@"%@ failed:\n%@",
                                           self.labelTitle.text,
                                           [NSString stringWithFormat:NSLocalizedString(@"Username must be at least %d characters.", @""), ABC_MIN_USERNAME_LENGTH]]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }
        // if the pin isn't long enough
        else if (self.pinTextField.text.length < ABC_MIN_PIN_LENGTH)
        {
            valid = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:self.labelTitle.text
                                  message:[NSString stringWithFormat:@"%@ failed:\n%@",
                                           self.labelTitle.text,
                                           [NSString stringWithFormat:NSLocalizedString(@"Withdrawl PIN must be 4 digits", @""), ABC_MIN_PIN_LENGTH]]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }
    }

    return valid;
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
    if (_bSuccess)
    {
        [self blockUser:YES];
        [User login:self.userNameTextField.text
           password:self.passwordTextField.text];

        //
        // Add default categories to core
        //
        tABC_Error Error;

        self.arrayCategories = [[NSMutableArray alloc] init];
        
        //
        // Should these go in a header file of some sort? -pvp
        //
        
        //
        // Expense categories
        //
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Air Travel", @"default category Expense:Air Travel")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Alcohol & Bars", @"default category Expense:Alcohol & Bars")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Allowance", @"default category Expense:Allowance")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Amusement", @"default category Expense:Amusement")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Arts", @"default category Expense:Arts")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:ATM Fee", @"default category Expense:ATM Fee")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Auto & Transport", @"default category Expense:Auto & Transport")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Auto Insurance", @"default category Expense:Auto Insurance")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Auto Payment", @"default category Expense:Auto Payment")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Baby Supplies", @"default category Expense:Baby Supplies")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Babysitter & Daycare", @"default category Expense:Babysitter & Daycare")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Bank Fee", @"default category Expense:Bank Fee")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Bills & Utilities", @"default category Expense:Bills & Utilities")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Books", @"default category Expense:Books")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Books & Supplies", @"default category Expense:Books & Supplies")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Car Wash", @"default category Expense:Car Wash")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Cash & ATM", @"default category Expense:Cash & ATM")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Charity", @"default category Expense:Charity")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Clothing", @"default category Expense:Clothing")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Coffee Shops", @"default category Expense:Coffee Shops")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Credit Card Payment", @"default category Expense:Credit Card Payment")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Dentist", @"default category Expense:Dentist")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Deposit to Savings", @"default category Expense:Deposit to Savings")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Doctor", @"default category Expense:Doctor")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Education", @"default category Expense:Education")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Electronics & Software", @"default category Expense:Electronics & Software")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Entertainment", @"default category Expense:Entertainment")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Eyecare", @"default category Expense:Eyecare")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Fast Food", @"default category Expense:Fast Food")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Fees & Charges", @"default category Expense:Fees & Charges")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Financial", @"default category Expense:Financial")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Financial Advisor", @"default category Expense:Financial Advisor")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Food & Dining", @"default category Expense:Food & Dining")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Furnishings", @"default category Expense:Furnishings")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Gas & Fuel", @"default category Expense:Gas & Fuel")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Gift", @"default category Expense:Gift")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Gifts & Donations", @"default category Expense:Gifts & Donations")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Groceries", @"default category Expense:Groceries")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Gym", @"default category Expense:Gym")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Hair", @"default category Expense:Hair")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Health & Fitness", @"default category Expense:Health & Fitness")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:HOA Dues", @"default category Expense:HOA Dues")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Hobbies", @"default category Expense:Hobbies")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Home", @"default category Expense:Home")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Home Improvement", @"default category Expense:Home Improvement")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Home Insurance", @"default category Expense:Home Insurance")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Home Phone", @"default category Expense:Home Phone")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Home Services", @"default category Expense:Home Services")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Home Supplies", @"default category Expense:Home Supplies")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Hotel", @"default category Expense:Hotel")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Interest Exp", @"default category Expense:Interest Exp")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Internet", @"default category Expense:Internet")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:IRA Contribution", @"default category Expense:IRA Contribution")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Kids", @"default category Expense:Kids")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Kids Activities", @"default category Expense:Kids Activities")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Late Fee", @"default category Expense:Late Fee")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Laundry", @"default category Expense:Laundry")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Lawn & Garden", @"default category Expense:Lawn & Garden")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Life Insurance", @"default category Expense:Life Insurance")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Misc.", @"default category Expense:Misc.")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Mobile Phone", @"default category Expense:Mobile Phone")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Mortgage & Rent", @"default category Expense:Mortgage & Rent")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Mortgage Interest", @"default category Expense:Mortgage Interest")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Movies & DVDs", @"default category Expense:Movies & DVDs")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Music", @"default category Expense:Music")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Newspaper & Magazines", @"default category Expense:Newspaper & Magazines")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Not Sure", @"default category Expense:Not Sure")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Parking", @"default category Expense:Parking")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Personal Care", @"default category Expense:Personal Care")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Pet Food & Supplies", @"default category Expense:Pet Food & Supplies")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Pet Grooming", @"default category Expense:Pet Grooming")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Pets", @"default category Expense:Pets")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Pharmacy", @"default category Expense:Pharmacy")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Property", @"default category Expense:Property")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Public Transportation", @"default category Expense:Public Transportation")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Registration", @"default category Expense:Registration")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Rental Car & Taxi", @"default category Expense:Rental Car & Taxi")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Restaurants", @"default category Expense:Restaurants")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Service & Parts", @"default category Expense:Service & Parts")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Service Fee", @"default category Expense:Service Fee")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Shopping", @"default category Expense:Shopping")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Spa & Massage", @"default category Expense:Spa & Massage")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Sporting Goods", @"default category Expense:Sporting Goods")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Sports", @"default category Expense:Sports")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Student Loan", @"default category Expense:Student Loan")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Tax", @"default category Expense:Tax")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Television", @"default category Expense:Television")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Tolls", @"default category Expense:Tolls")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Toys", @"default category Expense:Toys")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Trade Commissions", @"default category Expense:Trade Commissions")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Travel", @"default category Expense:Travel")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Tuition", @"default category Expense:Tuition")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Utilities", @"default category Expense:Utilities")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Vacation", @"default category Expense:Vacation")];
        [self.arrayCategories addObject:NSLocalizedString(@"Expense:Vet", @"default category Expense:Vet")];
        
        //
        // Income categories
        //
        [self.arrayCategories addObject:NSLocalizedString(@"Income:Consulting Income", @"default category Income:Consulting Income")];
        [self.arrayCategories addObject:NSLocalizedString(@"Income:Div Income", @"default category Income:Div Income")];
        [self.arrayCategories addObject:NSLocalizedString(@"Income:Net Salary", @"default category Income:Net Salary")];
        [self.arrayCategories addObject:NSLocalizedString(@"Income:Other Income", @"default category Income:Other Income")];
        [self.arrayCategories addObject:NSLocalizedString(@"Income:Rent", @"default category Income:Rent")];
        [self.arrayCategories addObject:NSLocalizedString(@"Income:Sales", @"default category Income:Sales")];
        
        //
        // Exchange Categories
        //
        [self.arrayCategories addObject: NSLocalizedString(@"Exchange:Buy Bitcoin", @"default category Exchange:Buy Bitcoin")]; 
        [self.arrayCategories addObject: NSLocalizedString(@"Exchange:Sell Bitcoin", @"default category Exchange:Sell Bitcoin")]; 

        //
        // Transfer Categories
        //
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Bitcoin.de", @"default category Transfer:Bitcoin.de")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Bitfinex", @"default category Transfer:Bitfinex")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Bitstamp", @"default category Transfer:Bitstamp")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:BTC-e", @"default category Transfer:BTC-e")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:BTCChina", @"default category Transfer:BTCChina")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Bter", @"default category Transfer:Bter")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:CAVirtex", @"default category Transfer:CAVirtex")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Coinbase", @"default category Transfer:Coinbase")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:CoinMKT", @"default category Transfer:CoinMKT")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Huobi", @"default category Transfer:Huobi")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Kraken", @"default category Transfer:Kraken")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:MintPal", @"default category Transfer:MintPal")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:OKCoin", @"default category Transfer:OKCoin")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Vault of Satoshi", @"default category Transfer:Vault of Satoshi")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Wallet:Airbitz", @"default category Transfer:Wallet:Airbitz")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Wallet:Armory", @"default category Transfer:Wallet:Armory")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Wallet:Bitcoin Core", @"default category Transfer:Wallet:Bitcoin Core")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Wallet:Blockchain", @"default category Transfer:Wallet:Blockchain")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Wallet:Electrum", @"default category Transfer:Wallet:Electrum")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Wallet:Multibit", @"default category Transfer:Wallet:Multibit")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Wallet:Mycelium", @"default category Transfer:Wallet:Mycelium")];
        [self.arrayCategories addObject: NSLocalizedString(@"Transfer:Wallet:Dark Wallet", @"default category Transfer:Wallet:Dark Wallet")]; 
        
        // add default categories to core
        for (int i = 0; i < [self.arrayCategories count]; i++)
        {
            NSString *strCategory = [self.arrayCategories objectAtIndex:i];
            ABC_AddCategory([[User Singleton].name UTF8String],
                            [[User Singleton].password UTF8String],
                            (char *)[strCategory UTF8String], &Error);
            [Util printABC_Error:&Error];
        }

        // now that the account is created, create the first wallet
		[self createFirstWallet];
    }
    else
    {
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Account Sign In", @"Title of account signin error alert")
							  message:[NSString stringWithFormat:@"Sign-in failed:\n%@", _strReason]
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
    }
}

- (void)createWalletComplete
{
    [self blockUser:NO];
    if (_bSuccess)
    {
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
        NSString *username = [User Singleton].name;
        if (self.strUserName)
        {
            username = self.strUserName;
        }
        [CoreBridge stopWatchers];
        [User login:username password:self.passwordTextField.text];

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
    if (pResults)
    {
        SignUpViewController *controller = (__bridge id)pResults->pData;
        controller.bSuccess = (BOOL)pResults->bSuccess;
        controller.strReason = [Util errorMap:&(pResults->errorInfo)];
        if (pResults->requestType == ABC_RequestType_CreateAccount)
        {
            [controller performSelectorOnMainThread:@selector(createAccountComplete) withObject:nil waitUntilDone:FALSE];
        }
		else if (pResults->requestType == ABC_RequestType_CreateWallet)
		{
            [CoreBridge startWatchers];
			if (pResults->pRetData)
            {
                //controller.strWalletUUID = [NSString stringWithFormat:@"%s", (char *)pResults->pRetData];
                free(pResults->pRetData);
            }
            else
            {
                //controller.strWalletUUID = @"(Unknown UUID)";
            }
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

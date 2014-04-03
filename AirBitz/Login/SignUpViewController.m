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

#define KEYBOARD_MARGIN	10.0
#define DOLLAR_CURRENCY_NUMBER	840

@interface SignUpViewController () <UITextFieldDelegate, PasswordVerifyViewDelegate, PasswordRecoveryViewControllerDelegate>
{
	UITextField *activeTextField;
	BOOL bSuccess;
	NSString *strReason;
	PasswordVerifyView *passwordVerifyView;
	float keyboardFrameOriginY;
	PasswordRecoveryViewController *passwordRecoveryController;
}

@property (nonatomic, weak) IBOutlet UITextField *userNameTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UITextField *reenterPasswordTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField *pinTextField;
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityView;
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
	self.pinTextField.minimumCharacters = 4;
}

-(void)viewWillAppear:(BOOL)animated
{
	//NSLog(@"Adding keyboard notification");
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	[self.pinTextField addTarget:self action:@selector(pinTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
	[self.passwordTextField addTarget:self action:@selector(passwordTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
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
		 [self.delegate signupViewControllerDidFinish:self];
	 }];
}

-(BOOL)checkPassword
{
	BOOL passwordGood = YES;
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
	[message appendString:@"Your password is missing the following:\n"];
    for (int i = 0; i < count; i++)
    {
		tABC_PasswordRule *pRule = aRules[i];
		if(!pRule->bPassed)
		{
			passwordGood = NO;
			[message appendFormat:@"%s. ", pRule->szDescription];
		}
       
        //printf("%s - %s\n", pRule->bPassed ? "pass" : "fail", pRule->szDescription);
    }
	
    ABC_FreePasswordRuleArray(aRules, count);
	if(passwordGood == NO)
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Insufficient Password", @"Title of password check popup alert")
							  message:message
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
	}
	return passwordGood;
}

-(void)showPasswordRecoveryController
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	passwordRecoveryController = [mainStoryboard instantiateViewControllerWithIdentifier:@"PasswordRecoveryViewController"];
	
	passwordRecoveryController.delegate = self;
	passwordRecoveryController.userName = self.userNameTextField.text;
	
	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
	passwordRecoveryController.view.frame = frame;
	[self.view addSubview:passwordRecoveryController.view];
	
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 passwordRecoveryController.view.frame = self.view.bounds;
	 }
					 completion:^(BOOL finished)
	 {
	 }];
}

-(void)createFirstWallet
{
	tABC_CC result;
	tABC_Error Error;
	result = ABC_CreateWallet([self.userNameTextField.text UTF8String],
                             [self.passwordTextField.text UTF8String],
                             [NSLocalizedString(@"My Wallet", @"Name of initial wallet") UTF8String],
                             DOLLAR_CURRENCY_NUMBER,
                             0,
                             SignUp_Request_Callback,
                             (__bridge void *)self,
                             &Error);
}

-(IBAction)NextStep:(id)sender
{
	
	
	#if SKIP_PW_VALIDATION_CHECKS
	[self showPasswordRecoveryController];
	#else
	tABC_Error Error;
	tABC_CC result;
	
	if([self.passwordTextField.text isEqualToString:self.reenterPasswordTextField.text])
	{
		if([self checkPassword] == YES)
		{
			if(self.pinTextField.text.length < 4)
			{
				UIAlertView *alert = [[UIAlertView alloc]
									  initWithTitle:NSLocalizedString(@"Account Sign Up", @"Title of account signup error alert")
									  message:@"Withdrawl PIN must be 4 digits"
									  delegate:nil
									  cancelButtonTitle:@"OK"
									  otherButtonTitles:nil];
				[alert show];
			}
			else
			{
				[self.activityView startAnimating];
				result = ABC_CreateAccount([self.userNameTextField.text UTF8String],
										  [self.passwordTextField.text UTF8String],
										  [self.pinTextField.text UTF8String],
										  SignUp_Request_Callback,
										  (__bridge void *)self,
										  &Error);
				[self printABC_Error:&Error];
				
				if (ABC_CC_Ok == result)
				{
					
				}
				else
				{
					[self.activityView stopAnimating];
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
		}
		else
		{
			NSLog(@"Password check didn't fly");
		}
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Account Sign Up", @"Title of account signup error alert")
							  message:[NSString stringWithFormat:@"Sign-up failed:\n%@", @"Password does not match re-entered password"]
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
	}
	#endif
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

-(void)scrollTextFieldAboveKeyboard:(UITextField *)textField
{
	if(keyboardFrameOriginY) //set when keyboard is visible
	{
		CGRect textFieldFrame = [self.contentView convertRect:activeTextField.frame toView:self.view.window];
		float overlap = self.contentView.frame.origin.y + keyboardFrameOriginY - KEYBOARD_MARGIN - (textFieldFrame.origin.y + textFieldFrame.size.height);
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

#pragma mark keyboard callbacks

- (void)keyboardWillShow:(NSNotification *)notification
{
	//Get KeyboardFrame (in Window coordinates)
	if(activeTextField)
	{
		//NSLog(@"Keyboard will show for SignUpView");
		NSDictionary *userInfo = [notification userInfo];
		CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
				
		keyboardFrameOriginY = keyboardFrame.origin.y;
		
		[self scrollTextFieldAboveKeyboard:activeTextField];
	}
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	if(activeTextField)
	{
		//NSLog(@"Keyboard will hide for SignUpView");
		activeTextField = nil;
	}
	keyboardFrameOriginY = 0.0;
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

#pragma mark UITextField delegates

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	//called when user taps on either search textField or location textField
	
	//NSLog(@"TextField began editing");
	activeTextField = textField;
	if(textField == self.passwordTextField)
	{
		if(textField.text.length)
		{
			if(passwordVerifyView == nil)
			{
				passwordVerifyView = [PasswordVerifyView CreateInsideView:self.contentView withDelegate:self];
			}
			passwordVerifyView.password = textField.text;
		}
	}
	else
	{
		if(passwordVerifyView)
		{
			[passwordVerifyView dismiss];
		}
	}
	//won't do anything when a textField is tapped for the first time and no keyboard is visible because
	//keyboardFrameOriginY isn't set yet (doestn' get set until KeyboardWillShow notification which occurs after this
	//method is called.  But -scrollTextFieldAboveKeyboard gets called from the KeyboardWillShow notification
	[self scrollTextFieldAboveKeyboard:textField];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	UIView *view = [self.contentView viewWithTag:textField.tag + 1];
	if(view)
	{
		[view becomeFirstResponder];
	}
	else
	{
		[textField resignFirstResponder];
	}
	return YES;
}

-(void)pinTextFieldChanged:(UITextField *)textField
{
	if(textField.text.length > 4)
	{
		textField.text = [textField.text substringToIndex:4];
	}
}

-(void)passwordTextFieldChanged:(UITextField *)textField
{
	if(passwordVerifyView == nil)
	{
		passwordVerifyView = [PasswordVerifyView CreateInsideView:self.contentView withDelegate:self];
	}
	passwordVerifyView.password = textField.text;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(activeTextField)
	{
		
		if(activeTextField == self.passwordTextField)
		{
			if(passwordVerifyView)
			{
				[passwordVerifyView dismiss];
			}
		}
		[activeTextField resignFirstResponder];
	}
}

#pragma mark PasswordVerifyViewDelegates

-(void)PasswordVerifyViewDismissed:(PasswordVerifyView *)pv
{
	[passwordVerifyView removeFromSuperview];
	passwordVerifyView = nil;
}

#pragma mark PasswordRecoveryViewController Delegates

-(void)passwordRecoveryViewControllerDidFinish:(PasswordRecoveryViewController *)controller
{
	[controller.view removeFromSuperview];
	passwordRecoveryController = nil;
	[self.delegate signupViewControllerDidFinish:self];
}

#pragma mark ABC Callbacks

- (void)createAccountComplete
{
	[self.activityView stopAnimating];
    //NSLog(@"Account create complete");
    if (bSuccess)
    {
		//NSLog(@"Account created");
		//set username and password for app
		[User Singleton].name = self.userNameTextField.text;
		[User Singleton].password = self.passwordTextField.text;
		
		[self createFirstWallet];
		
		[self showPasswordRecoveryController];
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

-(void)setRecoveryComplete
{
	//NSLog(@"Set Recovery Complete");
}

- (void)createWalletComplete
{
    NSLog(@"Wallet create complete");
    if (bSuccess)
    {
        //self.labelStatus.text = [NSString stringWithFormat:@"Wallet created: %@", self.strWalletUUID];
		NSLog(@"Successfully created wallet");
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Account Sign Up", @"Title of account signup error alert")
							  message:[NSString stringWithFormat:@"Wallet creation failed:\n%@", strReason]
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
    }
}

void SignUp_Request_Callback(const tABC_RequestResults *pResults)
{
    //NSLog(@"Request callback");
    
    if (pResults)
    {
        SignUpViewController *controller = (__bridge id)pResults->pData;
        controller->bSuccess = (BOOL)pResults->bSuccess;
        controller->strReason = [NSString stringWithFormat:@"%s", pResults->errorInfo.szDescription];
        if (pResults->requestType == ABC_RequestType_CreateAccount)
        {
           // NSLog(@"Create account completed with cc: %ld (%s)", (unsigned long) pResults->errorInfo.code, pResults->errorInfo.szDescription);
            [controller performSelectorOnMainThread:@selector(createAccountComplete) withObject:nil waitUntilDone:FALSE];
        }
		else if(pResults->requestType == ABC_RequestType_CreateWallet)
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
            NSLog(@"Create wallet completed with cc: %ld (%s)", (unsigned long) pResults->errorInfo.code, pResults->errorInfo.szDescription);
            [controller performSelectorOnMainThread:@selector(createWalletComplete) withObject:nil waitUntilDone:FALSE];
		}
    }
}
@end

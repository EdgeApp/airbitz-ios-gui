//
//  LoginViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "LoginViewController.h"
#import "ABC.h"
#import "SignUpViewController.h"
#import "User.h"
#import "StylizedTextField.h"

#define CONTENT_VIEW_SCALE_WITH_KEYBOARD	0.75
#define LOGO_IMAGE_SHRINK_SCALE_FACTOR		0.5

typedef enum eLoginMode
{
	MODE_ENTERING_NEITHER,
	MODE_ENTERING_USERNAME,
	MODE_ENTERING_PASSWORD
} tLoginMode;

@interface LoginViewController () <UITextFieldDelegate, SignUpViewControllerDelegate>
{
	tLoginMode mode;
	CGRect originalContentFrame;
	CGRect originalLogoFrame;
	CGRect originalSwipeArrowFrame;
	CGPoint firstTouchPoint;
	BOOL bSuccess;
	NSString *strReason;
	SignUpViewController *signUpController;
	UITextField *activeTextField;
}
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet StylizedTextField *userNameTextField;
@property (nonatomic, weak) IBOutlet StylizedTextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UIImageView *swipeArrow;
@property (nonatomic, weak) IBOutlet UILabel *swipeText;
@property (nonatomic, weak) IBOutlet UILabel *titleText;
@property (nonatomic, weak) IBOutlet UIImageView *logoImage;
@property (nonatomic, weak) IBOutlet UIView *userEntryView;
@property (nonatomic, weak) IBOutlet UILabel *invalidMessage;

@end

@implementation LoginViewController

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
	mode = MODE_ENTERING_NEITHER;
	originalContentFrame = self.contentView.frame;
	originalLogoFrame = self.logoImage.frame;
	originalSwipeArrowFrame = self.swipeArrow.frame;
	
	self.userNameTextField.delegate = self;
	self.passwordTextField.delegate = self;
	self.invalidMessage.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
	//NSLog(@"Adding keyboard notification");
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[self animateSwipeArrowWithRepetitions:3 andDelay:1.0];
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

-(IBAction)SignIn
{
	[self.userNameTextField resignFirstResponder];
	[self.passwordTextField resignFirstResponder];
	[self animateToInitialPresentation];
	

		bSuccess = NO;
		//NSLog(@"Calling sign-in");
		//self.labelStatus.text = @"Calling sign-in";
		//NSLog(@"Signing in");
		tABC_Error Error;
		ABC_SignIn([self.userNameTextField.text UTF8String],
				   [self.passwordTextField.text UTF8String],
				   ABC_Request_Callback,
				   (__bridge void *)self,
				   &Error);
		[self printABC_Error:&Error];
		
		if (ABC_CC_Ok == Error.code)
		{
			[User Singleton].name = self.userNameTextField.text;
			[User Singleton].password = self.passwordTextField.text;
		}
		else
		{
			NSLog(@"%@", [NSString stringWithFormat:@"Sign-in failed:\n%s", Error.szDescription]);
			self.invalidMessage.hidden = NO;
		}
		
		//NSLog(@"Done calling sign-in");

}

-(IBAction)SignUp
{
	[self.userNameTextField resignFirstResponder];
	[self.passwordTextField resignFirstResponder];
	[self animateToInitialPresentation];
	
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	signUpController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SignUpViewController"];
	
	signUpController.delegate = self;
	
	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
	signUpController.view.frame = frame;
	[self.view addSubview:signUpController.view];
	
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 signUpController.view.frame = self.view.bounds;
	 }
	 completion:^(BOOL finished)
	 {
	 }];
	
}

-(void)animateSwipeArrowWithRepetitions:(int)repetitions andDelay:(float)delay;
{
	static int repetitionCount;
	
	if(repetitions)
	{
		repetitionCount = repetitions;
	}
	[UIView animateWithDuration:0.35
						  delay:delay
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = self.swipeArrow.frame;
		 frame.origin.x = originalSwipeArrowFrame.origin.x - originalSwipeArrowFrame.size.width;
		 self.swipeArrow.frame = frame;
		 
	 }
	 completion:^(BOOL finished)
	 {
		 [UIView animateWithDuration:0.45
							   delay:0.0
							 options:UIViewAnimationOptionCurveEaseInOut
						  animations:^
		  {
			  CGRect frame = self.swipeArrow.frame;
			  frame.origin.x = originalSwipeArrowFrame.origin.x;
			  self.swipeArrow.frame = frame;
			  
		  }
						  completion:^(BOOL finished)
		  {
			  //self.dividerView.alpha = 0.0;
			  repetitionCount--;
			  if(repetitionCount)
			  {
				  [self animateSwipeArrowWithRepetitions:0 andDelay:0];
			  }
		  }];
	 }];
}

-(CGFloat)StatusBarHeight
{
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    return MIN(statusBarSize.width, statusBarSize.height);
}

-(void)animateToInitialPresentation
{
	[UIView animateWithDuration:0.35
						  delay: 0.0
						options: UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 self.contentView.frame = originalContentFrame;
		 
		 self.swipeArrow.alpha = 1.0;
		 self.swipeText.alpha = 1.0;
		 self.titleText.alpha = 1.0;
		 
		 self.logoImage.transform = CGAffineTransformMakeScale(1.0, 1.0);
		 self.logoImage.frame = originalLogoFrame;
		 self.logoImage.alpha = 1.0;
	 }
					 completion:^(BOOL finished)
	 {
		 mode = MODE_ENTERING_NEITHER;
	 }];
}

#pragma mark keyboard callbacks

- (void)keyboardWillShow:(NSNotification *)notification
{
	BOOL shrinkLogo = NO;
	//Get KeyboardFrame (in Window coordinates)
	if(activeTextField)
	{
		//NSLog(@"Keyboard will show for Login View");
		NSDictionary *userInfo = [notification userInfo];
		CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
		
		CGRect ownFrame = [self.view.window convertRect:keyboardFrame toView:self.view];
		
		float remainingSpace = ownFrame.origin.y - [self StatusBarHeight];
		
		//NSLog(@"Remaining space: %f, user entry height: %f", remainingSpace, self.userEntryView.frame.size.height);
		remainingSpace -= self.userEntryView.frame.size.height;
		
		//NSLog(@"Remaining space: %f, logo height: %f", remainingSpace, self.logoImage.frame.size.height);
		float logoScaleFactor = remainingSpace / self.logoImage.frame.size.height;
		//NSLog(@"Logo scale factor: %f", logoScaleFactor);
		if(logoScaleFactor >= LOGO_IMAGE_SHRINK_SCALE_FACTOR)
		{
			shrinkLogo = YES;
		}
		[UIView animateWithDuration:0.35
							  delay: 0.0
							options: UIViewAnimationOptionCurveEaseInOut
						 animations:^
		 {
			 CGRect frame = self.contentView.frame;
			 
			 
			 self.swipeArrow.alpha = 0.0;
			 self.swipeText.alpha = 0.0;
			 self.titleText.alpha = 0.0;
			 
			 if(shrinkLogo)
			 {
				 frame.origin.y = 22.0 + originalLogoFrame.size.height * logoScaleFactor;
				 frame.size.height = keyboardFrame.origin.y - frame.origin.y;
				 self.contentView.frame = frame;
				 
				 self.logoImage.transform = CGAffineTransformMakeScale(logoScaleFactor, logoScaleFactor);
				 frame = self.logoImage.frame;
				 frame.origin.y = 22.0;
				 self.logoImage.frame = frame;
			}
			else
			{
				frame.origin.y = [self StatusBarHeight];
				frame.size.height = keyboardFrame.origin.y - frame.origin.y;
				self.contentView.frame = frame;

				self.logoImage.alpha = 0.0;
			}
		 }
						 completion:^(BOOL finished)
		 {
			 
		 }];
	}
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	if(activeTextField)
	{
		 activeTextField = nil;
	}
}

#pragma mark touch events (for swiping)

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog(@"Touches Began");
	UITouch *touch = [touches anyObject];
	firstTouchPoint = [touch locationInView:self.view.window];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self.view.window];
	
	CGRect frame = self.view.frame;
	CGFloat xPos;
	
	xPos = touchPoint.x - firstTouchPoint.x;
	
	frame.origin.x = xPos;
	self.view.frame = frame;
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	float xOffset = self.view.frame.origin.x;
	if(xOffset < 0) xOffset = -xOffset;
	if(xOffset < self.view.frame.size.width / 2)
	{
		//spring back
		[UIView animateWithDuration:0.35
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^
		 {
			 CGRect frame = self.view.frame;
			frame.origin.x = 0.0;
			 self.view.frame = frame;
		 }
		completion:^(BOOL finished)
		 {
		 }];
	}
	else
	{
		//spring out
		[UIView animateWithDuration:0.35
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^
		 {
			 CGRect frame = self.view.frame;
			 if(frame.origin.x < 0)
			 {
				 frame.origin.x = -frame.size.width;
			 }
			 else
			 {
				 frame.origin.x = frame.size.width;
			 }
			 self.view.frame = frame;
		 }
		 completion:^(BOOL finished)
		 {
			 self.invalidMessage.hidden = YES;
			 [self.delegate loginViewControllerDidAbort];
		 }];
	}
}

#pragma mark UITextField delegates

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	//called when user taps on either search textField or location textField
	self.invalidMessage.hidden = YES;
	activeTextField = textField;
	
	//NSLog(@"TextField began editing");
	if(mode == MODE_ENTERING_NEITHER)
	{
		if(textField == self.userNameTextField)
		{
			mode = MODE_ENTERING_USERNAME;
		}
		else
		{
			mode = MODE_ENTERING_PASSWORD;
		}
	}
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self animateToInitialPresentation];
	[textField resignFirstResponder];
	return YES;
}
/*
- (void)setRecoveryComplete
{
    //[self blockUser:NO];
    NSLog(@"Recovery set complete");
    if (bSuccess)
    {
        NSLog(@"%@", @"Recovery set");
    }
    else
    {
        NSLog(@"%@", [NSString stringWithFormat:@"Set recovery failed\n%@", strReason]);
    }
}*/

- (void)signInComplete
{
    //[self blockUser:NO];
   // NSLog(@"SignIn complete");
    if (bSuccess)
    {
       // NSLog(@"%@", @"Successfully Signed In");
		[self.delegate loginViewControllerDidLogin];
		self.invalidMessage.hidden = YES;
    }
    else
    {
        NSLog(@"%@", [NSString stringWithFormat:@"Sign-in failed\n%@", strReason]);
		self.invalidMessage.hidden = NO;
    }
}

#pragma mark SignUpViewControllerDelegates

-(void)signupViewControllerDidFinish:(SignUpViewController *)controller
{
	[controller.view removeFromSuperview];
	signUpController = nil;
	//NSLog(@"Signup finished");
	
	if([User Singleton].name.length && [User Singleton].password.length)
	{
		bSuccess = YES;
		[self signInComplete];
	}
}

#pragma mark ABC Callbacks

void ABC_Request_Callback(const tABC_RequestResults *pResults)
{
   // NSLog(@"Request callback");
    
    if (pResults)
    {
        LoginViewController *controller = (__bridge id)pResults->pData;
        controller->bSuccess = (BOOL)pResults->bSuccess;
        controller->strReason = [NSString stringWithFormat:@"%s", pResults->errorInfo.szDescription];
 
        if (pResults->requestType == ABC_RequestType_AccountSignIn)
        {
            //NSLog(@"Sign-in completed with cc: %ld (%s)", (unsigned long) pResults->errorInfo.code, pResults->errorInfo.szDescription);
            [controller performSelectorOnMainThread:@selector(signInComplete) withObject:nil waitUntilDone:FALSE];
        }
    }
}

@end

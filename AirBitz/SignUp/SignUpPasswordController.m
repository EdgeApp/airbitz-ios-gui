//
//  SignUpPasswordController.m
//  AirBitz
//

#import "SignUpPasswordController.h"
#import "MinCharTextField.h"
#import "PasswordVerifyView.h"
#import "ABC.h"
#import "Util.h"
#import "User.h"

#define KEYBOARD_MARGIN         10.0
#define PASSWORD_VERIFY_FRAME_Y_OFFSET 20

@interface SignUpPasswordController () <UITextFieldDelegate, PasswordVerifyViewDelegate>
{
    UITextField                     *_activeTextField;
    PasswordVerifyView              *_passwordVerifyView;
    FadingAlertView                 *_fadingAlert;
    float                           _keyboardFrameOriginY;

}

@property (nonatomic, weak) IBOutlet MinCharTextField *passwordTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField *reenterPasswordTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField *pinTextField;
@property (nonatomic, weak) IBOutlet UIView                     *masterView;
@property (nonatomic, weak) IBOutlet UIView                     *contentView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView    *activityView;
@property (nonatomic, strong)   UIButton                        *buttonBlocker;
@property (nonatomic)           CGFloat                         contentViewY;
@property (nonatomic, copy)     NSString                        *labelString;
@property (nonatomic, assign)   BOOL                            bSuccess;
@property (nonatomic, copy)     NSString                        *strReason;





@end

@implementation SignUpPasswordController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.passwordTextField.delegate = self;
    self.passwordTextField.minimumCharacters = ABC_MIN_PASS_LENGTH;
    self.reenterPasswordTextField.delegate = self;
    self.reenterPasswordTextField.minimumCharacters = ABC_MIN_PASS_LENGTH;
    self.pinTextField.delegate = self;
    self.pinTextField.minimumCharacters = ABC_MIN_PIN_LENGTH;
    self.contentViewY = self.contentView.frame.origin.y;

    self.labelString = NSLocalizedString(@"Sign Up", @"Sign Up");


}

-(void)viewWillAppear:(BOOL)animated
{
    //NSLog(@"Adding keyboard notification");
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self.pinTextField addTarget:self action:@selector(pinTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordTextField addTarget:self action:@selector(passwordTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    
    // Only needed for old SignUpViewController which is multipurpose. Used when changing password or PIN
//    [self updateDisplayForMode:_mode];
    [self.passwordTextField becomeFirstResponder];

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

-(IBAction)back:(id)sender
{
//    [UIView animateWithDuration:0.35
//                          delay:0.0
//                        options:UIViewAnimationOptionCurveEaseInOut
//                     animations:^
//                     {
//                         CGRect frame = self.view.frame;
//                         frame.origin.x = frame.size.width;
//                         self.view.frame = frame;
//                     }
//                     completion:^(BOOL finished)
//                     {
//                         [self exitWithBackButton:YES];
//                     }];
    [super back];
}

- (void)next
{
    // check the new password fields
    if ([self newPasswordFieldsAreValid] == YES)
    {
        // check the username and pin field
        if ([self fieldsAreValid] == YES)
        {
            // if we are signing up a new account
            _fadingAlert = [FadingAlertView CreateInsideView:self.view withDelegate:self];
            _fadingAlert.message = NSLocalizedString(@"Creating and securing account", nil);
            _fadingAlert.fadeDuration = 0;
            _fadingAlert.fadeDelay = 0;
            [_fadingAlert blockModal:YES];
            [_fadingAlert showSpinner:YES];
            [_fadingAlert show];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                tABC_Error error;
//                ABC_CreateAccount([self.manager.strUserName UTF8String], [self.passwordTextField.text UTF8String], &error);
//                if (error.code == ABC_CC_Ok) {
//                    ABC_SetPIN([[User Singleton].name UTF8String], [self.manager.strUserName UTF8String],
//                            [self.pinTextField.text UTF8String], &error);
//                }
                error.code = ABC_CC_Ok;
                _bSuccess = (error.code == ABC_CC_Ok);
                _strReason = [Util errorMap:&error];
                [self performSelectorOnMainThread:@selector(createAccountComplete) withObject:nil waitUntilDone:FALSE];
            });
        }
    }
}


#pragma mark - Fading Alert Delegate

- (void)dismissFading:(BOOL)animated
{
    if (_fadingAlert) {
        [_fadingAlert dismiss:animated];
    }
}

- (void)fadingAlertDismissed:(FadingAlertView *)view
{
    _fadingAlert = nil;
}

// checks the password against the password rules
// returns YES if new password fields are good, NO if the new password fields failed the checks
// if the new password fields are bad, an appropriate message box is displayed
// note: this function is aware of the 'mode' of the view controller and will check and display appropriately
- (BOOL)newPasswordFieldsAreValid
{
    BOOL bNewPasswordFieldsAreValid = YES;

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
                    initWithTitle:self.labelString
                          message:[NSString stringWithFormat:@"%@ failed:\n%@",
                                                             self.labelString,
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
    {
        // if the pin isn't long enough
        if (self.pinTextField.text.length < ABC_MIN_PIN_LENGTH)
        {
            valid = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                    initWithTitle:self.labelString
                          message:[NSString stringWithFormat:@"%@ failed:\n%@",
                                                             self.labelString,
                                                             [NSString stringWithFormat:NSLocalizedString(@"PIN must be 4 digits", @""), ABC_MIN_PIN_LENGTH]]
                         delegate:nil
                cancelButtonTitle:@"OK"
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
        CGRect textFieldFrame = [self.contentView convertRect:textField.frame toView:self.view.window];

        float overlap = _keyboardFrameOriginY - (textFieldFrame.origin.y + textFieldFrame.size.height + KEYBOARD_MARGIN);

        if(overlap < 0)
        {
            [UIView animateWithDuration:0.35
                                  delay: 0.0
                                options: UIViewAnimationOptionCurveEaseInOut
                             animations:^
             {
                 CGRect frame = self.contentView.frame;
                 frame.origin.y += overlap;
                 self.contentView.frame = frame;
             }
                             completion:^(BOOL finished)
             {
                 
             }];
        }
    }
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
         frame.origin.y = self.contentViewY;
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
        if(_passwordVerifyView == nil)
        {
            _passwordVerifyView = [PasswordVerifyView CreateInsideView:self.masterView withDelegate:self];
            CGRect frame = _passwordVerifyView.frame;
            frame.origin.y += PASSWORD_VERIFY_FRAME_Y_OFFSET;
            _passwordVerifyView.frame = frame;
        }
        _passwordVerifyView.password = textField.text;
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
        UIView *view = [self.contentView viewWithTag:textField.tag + 1];
        if (view)
        {
            [view becomeFirstResponder];
        }
        else
        {
            [textField resignFirstResponder];
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
        _passwordVerifyView = [PasswordVerifyView CreateInsideView:self.masterView withDelegate:self];
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
#pragma mark - ABC Callbacks

- (void)createAccountComplete
{
    if (_bSuccess) {
//        [User login:self.manager.strUserName
//           password:self.passwordTextField.text];
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
//        {
//            [CoreBridge setupLoginPIN];
//        });
        [super next];
    } else {
        [self dismissFading:NO];
        UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:NSLocalizedString(@"Account Sign In", @"Title of account signin error alert")
                      message:[NSString stringWithFormat:@"Sign-in failed:\n%@", _strReason]
                     delegate:nil
            cancelButtonTitle:@"OK"
            otherButtonTitles:nil];
        [alert show];
    }
    [self blockUser:NO];
}

#pragma mark - PasswordVerifyViewDelegates

- (void)PasswordVerifyViewDismissed:(PasswordVerifyView *)pv
{
    [_passwordVerifyView removeFromSuperview];
    _passwordVerifyView = nil;
}


@end

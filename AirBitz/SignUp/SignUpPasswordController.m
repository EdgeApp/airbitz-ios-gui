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
#import "MainViewController.h"
#import "Theme.h"

#define KEYBOARD_MARGIN         10.0

@interface SignUpPasswordController () <UITextFieldDelegate, PasswordVerifyViewDelegate>
{
    UITextField                     *_activeTextField;
    PasswordVerifyView              *_passwordVerifyView;
}

@property (nonatomic, weak) IBOutlet MinCharTextField *passwordTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField *reenterPasswordTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField *pinTextField;
@property (nonatomic, weak) IBOutlet UIView                     *masterView;
@property (nonatomic, weak) IBOutlet UIView                     *contentView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint         *contentStartConstraint;
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
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [self.pinTextField addTarget:self action:@selector(pinTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordTextField addTarget:self action:@selector(passwordTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    
//    [self.passwordTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // ABLog(2,@"%s", __FUNCTION__);
    
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
    [super back];
}

- (void)next
{
    // check the new password fields
    if ([self newPasswordFieldsAreValid] == YES && [self fieldsAreValid] == YES)
    {
        [FadingAlertView create:self.view message:NSLocalizedString(@"Creating and securing account", nil) holdTime:FADING_ALERT_HOLD_TIME_FOREVER_WITH_SPINNER];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            tABC_Error error;
            char *szPassword = [self.passwordTextField.text length] == 0 ? NULL : [self.passwordTextField.text UTF8String];
            ABC_CreateAccount([self.manager.strUserName UTF8String], szPassword, &error);
            if (error.code == ABC_CC_Ok)
            {
                ABC_SetPIN([self.manager.strUserName UTF8String], [self.passwordTextField.text UTF8String],
                        [self.pinTextField.text UTF8String], &error);
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [FadingAlertView dismiss:YES];
                if (error.code == ABC_CC_Ok)
                {
                    _bSuccess = true;
                    
                    self.manager.strPassword = [NSString stringWithFormat:@"%@",self.passwordTextField.text];
                    self.manager.strPIN = [NSString stringWithFormat:@"%@",self.pinTextField.text];
                    
                    [User login:self.manager.strUserName password:self.passwordTextField.text setupPIN:YES];
                    [CoreBridge setupNewAccount];
                    [super next];
                }
                else
                {
                    _bSuccess = false;
                    _strReason = [Util errorMap:&error];

                    [FadingAlertView create:self.view message:_strReason holdTime:FADING_ALERT_HOLD_TIME_DEFAULT];
                }
            });
        });
    }
}


// checks the password against the password rules
// returns YES if new password fields are good, NO if the new password fields failed the checks
// if the new password fields are bad, an appropriate message box is displayed
// note: this function is aware of the 'mode' of the view controller and will check and display appropriately
- (BOOL)newPasswordFieldsAreValid
{
    // Allow accounts with an empty password
    if ([self.passwordTextField.text length] == 0) {
        return YES;
    }

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

#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGFloat contentTop = [MainViewController getHeaderHeight]; // raise the view
    //called when user taps on either search textField or location textField
    
    //ABLog(2,@"TextField began editing");
    _activeTextField = textField;
    if(textField == self.passwordTextField)
    {
        if(_passwordVerifyView == nil)
        {
            _passwordVerifyView = [PasswordVerifyView CreateInsideView:self.masterView withDelegate:self];
            CGRect frame = _passwordVerifyView.frame;
            frame.origin.y = [MainViewController getHeaderHeight];
            frame.size.width = [MainViewController getWidth];
            _passwordVerifyView.frame = frame;

            contentTop += _passwordVerifyView.frame.size.height - textField.frame.origin.y + [Theme Singleton].elementPadding;
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

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
                     {

                         _contentStartConstraint.constant = contentTop;
                         [self.view layoutIfNeeded];

                     }
                     completion:^(BOOL finished)
                     {
                     }];

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == self.passwordTextField) {
        [_reenterPasswordTextField becomeFirstResponder];
    }
    else if (textField == self.reenterPasswordTextField)
    {
        [_pinTextField becomeFirstResponder];
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

#pragma mark - PasswordVerifyViewDelegates

- (void)PasswordVerifyViewDismissed:(PasswordVerifyView *)pv
{
    [_passwordVerifyView removeFromSuperview];
    _passwordVerifyView = nil;
}


@end

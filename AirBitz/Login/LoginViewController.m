//
//  LoginViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "LoginViewController.h"
#import "ABC.h"
#import "PickerTextView.h"
#import "SignUpViewController.h"
#import "User.h"
#import "StylizedTextField.h"
#import "Util.h"
#import "CoreBridge.h"
#import "Config.h"
#import "SignUpManager.h"
#import "PasswordRecoveryViewController.h"
#import "TwoFactorMenuViewController.h"
#import "CoreBridge.h"
#import "CommonTypes.h"
#import "LocalSettings.h"
#import "MainViewController.h"

typedef enum eLoginMode
{
    MODE_ENTERING_NEITHER,
    MODE_ENTERING_USERNAME,
    MODE_ENTERING_PASSWORD
} tLoginMode;

#define SWIPE_ARROW_ANIM_PIXELS 10

@interface LoginViewController () <UITextFieldDelegate, SignUpManagerDelegate, PasswordRecoveryViewControllerDelegate, PickerTextViewDelegate,
    TwoFactorMenuViewControllerDelegate, UIAlertViewDelegate >
{
    tLoginMode                      _mode;
    CGPoint                         _firstTouchPoint;
    BOOL                            _bSuccess;
    BOOL                            _bTouchesEnabled;
    NSString                        *_strReason;
    NSString                        *_account;
    tABC_CC                         _resultCode;
    SignUpManager                   *_signupManager;
    UITextField                     *_activeTextField;
    PasswordRecoveryViewController  *_passwordRecoveryController;
    TwoFactorMenuViewController     *_tfaMenuViewController;
    FadingAlertView                 *_fadingAlert;
    float                           _keyboardFrameOriginY;
    CGFloat                         _originalLogoHeight;
    CGFloat                         _originalTextBitcoinWalletHeight;

}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textBitcoinWalletHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoHeight;
@property (nonatomic, weak) IBOutlet UIView             *contentView;
@property (weak, nonatomic) IBOutlet UIView             *credentialsView;
@property (nonatomic, weak) IBOutlet StylizedTextField  *passwordTextField;
@property (nonatomic, weak) IBOutlet UIButton           *backButton;
@property (nonatomic, weak) IBOutlet UIImageView        *swipeRightArrow;
@property (nonatomic, weak) IBOutlet UILabel            *swipeText;
@property (nonatomic, weak) IBOutlet UILabel            *titleText;
@property (nonatomic, weak) IBOutlet UIImageView        *logoImage;
@property (nonatomic, weak) IBOutlet UIView             *userEntryView;
@property (nonatomic, weak) IBOutlet UIView             *spinnerView;

@property (nonatomic, weak) IBOutlet UIView				*errorMessageView;
@property (nonatomic, weak) IBOutlet UILabel			*errorMessageText;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *swipeArrowLeft;

@property (nonatomic, weak) IBOutlet PickerTextView   *usernameSelector;
@property (nonatomic, strong) NSArray   *arrayAccounts;

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
    _mode = MODE_ENTERING_NEITHER;

    self.usernameSelector.textField.delegate = self;
    self.usernameSelector.delegate = self;
    self.passwordTextField.delegate = self;
    self.spinnerView.hidden = YES;

    _originalLogoHeight = self.logoHeight.constant;
    _originalTextBitcoinWalletHeight = self.textBitcoinWalletHeight.constant;
    
    #if HARD_CODED_LOGIN
    
    self.usernameSelection.textField.text = HARD_CODED_LOGIN_NAME;
    self.passwordTextField.text = HARD_CODED_LOGIN_PASSWORD;
    #endif

	self.errorMessageView.alpha = 0.0;
    
    [self getAllAccounts];
    
    // set up the specifics on our picker text view
    self.usernameSelector.textField.borderStyle = UITextBorderStyleNone;
    self.usernameSelector.textField.backgroundColor = [UIColor clearColor];
    self.usernameSelector.textField.font = [UIFont systemFontOfSize:16];
    self.usernameSelector.textField.clearButtonMode = UITextFieldViewModeNever;
    self.usernameSelector.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.usernameSelector.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.usernameSelector.textField.spellCheckingType = UITextSpellCheckingTypeNo;
    self.usernameSelector.textField.textColor = [UIColor whiteColor];
    self.usernameSelector.textField.returnKeyType = UIReturnKeyDone;
    self.usernameSelector.textField.tintColor = [UIColor whiteColor];
    self.usernameSelector.textField.textAlignment = NSTextAlignmentLeft;
    self.usernameSelector.textField.placeholder = NSLocalizedString(@"Username", nil);
    self.usernameSelector.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.usernameSelector.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor lightTextColor]}];
    [self.usernameSelector setTopMostView:self.view];
    self.usernameSelector.pickerMaxChoicesVisible = 3;
    [self.usernameSelector setAccessoryImage:[UIImage imageNamed:@"btn_close.png"]];
    [Util stylizeTextField:self.usernameSelector.textField];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self animateSwipeArrowWithRepetitions:3 andDelay:1.0 direction:1];

    _bTouchesEnabled = YES;

#if !HARD_CODED_LOGIN
    NSString *username = [LocalSettings controller].cachedUsername;
    if (username && 0 < username.length)
    {
        self.usernameSelector.textField.text = username;
    }
    self.passwordTextField.text = [User Singleton].password;
#endif
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self dismissErrorMessage];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action Methods

- (IBAction)Back
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
         [self.delegate loginViewControllerDidAbort];
     }];
}

- (IBAction)SignIn
{
    [self.usernameSelector resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self animateToInitialPresentation];

    _bSuccess = NO;
    [self showSpinner:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        tABC_Error error;
        ABC_SignIn([self.usernameSelector.textField.text UTF8String],
            [self.passwordTextField.text UTF8String], &error);
        _bSuccess = error.code == ABC_CC_Ok ? YES: NO;
        _strReason = [Util errorMap:&error];
        _resultCode = error.code;
        [self performSelectorOnMainThread:@selector(signInComplete) withObject:nil waitUntilDone:FALSE];
    });
}

- (IBAction)SignUp
{
    [self dismissErrorMessage];

    [self.usernameSelector.textField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self animateToInitialPresentation];
    
    _signupManager = [[SignUpManager alloc] initWithController:self];
    _signupManager.delegate = self;
    if (self.usernameSelector.textField.text) {
        _signupManager.strInUserName = self.usernameSelector.textField.text;
    }
    [_signupManager startSignup];
}

- (IBAction)buttonForgotTouched:(id)sender
{
    [self dismissErrorMessage];

    [self.usernameSelector.textField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];

    // if they have a username
    if ([self.usernameSelector.textField.text length])
    {
        [self showSpinner:YES];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            BOOL bSuccess = NO;
            NSMutableString *error = [[NSMutableString alloc] init];
            NSArray *arrayQuestions = [CoreBridge getRecoveryQuestionsForUserName:self.usernameSelector.textField.text
                                                                        isSuccess:&bSuccess
                                                                         errorMsg:error];
            NSArray *params = [NSArray arrayWithObjects:arrayQuestions, nil];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self showSpinner:NO];
                _bSuccess = bSuccess;
                _strReason = error;
                [self performSelectorOnMainThread:@selector(launchQuestionRecovery:) withObject:params waitUntilDone:NO];
            });
        });
    }
    else
    {
        [self showFadingError:NSLocalizedString(@"Please enter a User Name", nil)];
    }
}

- (void)launchQuestionRecovery:(NSArray *)params
{
    if (_bSuccess && [params count] > 0)
    {
        NSArray *arrayQuestions = params[0];
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
        _passwordRecoveryController = [mainStoryboard instantiateViewControllerWithIdentifier:@"PasswordRecoveryViewController"];

        _passwordRecoveryController.delegate = self;
        _passwordRecoveryController.mode = PassRecovMode_Recover;
        _passwordRecoveryController.arrayQuestions = arrayQuestions;
        _passwordRecoveryController.strUserName = self.usernameSelector.textField.text;

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
    else
    {
        [self showFadingError:_strReason];
    }
}

#pragma mark - Misc Methods

- (void)animateSwipeArrowWithRepetitions:(int)repetitions 
                                andDelay:(float)delay 
                               direction:(int)dir
{
    if (!repetitions)
    {
        return;
    }
    [UIView animateWithDuration:0.35
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         if (dir > 0)
             self.swipeArrowLeft.constant = SWIPE_ARROW_ANIM_PIXELS;
         else
             self.swipeArrowLeft.constant = -SWIPE_ARROW_ANIM_PIXELS;
         [self.view layoutIfNeeded];


     }
     completion:^(BOOL finished)
     {
         [UIView animateWithDuration:0.45
                               delay:0.0
                             options:UIViewAnimationOptionCurveEaseInOut
                          animations:^
          {
              self.swipeArrowLeft.constant = 0;
              [self.view layoutIfNeeded];

          }
                          completion:^(BOOL finished)
          {
            [self animateSwipeArrowWithRepetitions:repetitions - 1
                                          andDelay:0
                                         direction:dir];
          }];
     }];
}

- (CGFloat)StatusBarHeight
{
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    return MIN(statusBarSize.width, statusBarSize.height);
}

- (void)animateToInitialPresentation
{
//    [UIView animateWithDuration:0.35
//                          delay: 0.0
//                        options: UIViewAnimationOptionCurveEaseInOut
//                     animations:^
//     {
//         self.contentView.frame = _originalContentFrame;
//
//         _backButton.alpha = 1.0;
//         _swipeRightArrow.alpha = 1.0;
//         _swipeText.alpha = 1.0;
//         _titleText.alpha = 1.0;
//
//         self.logoImage.transform = CGAffineTransformMakeScale(1.0, 1.0);
//         self.logoImage.frame = _originalLogoFrame;
//         self.logoImage.alpha = 1.0;
//     }
//                     completion:^(BOOL finished)
//     {
//         _mode = MODE_ENTERING_NEITHER;
//     }];
}

#pragma mark - keyboard callbacks

- (void)keyboardWillShow:(NSNotification *)notification
{
    [self updateDisplayForKeyboard:YES];

    //NSLog(@"Keyboard will show for SignUpView");
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    _keyboardFrameOriginY = keyboardFrame.origin.y;


}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if(_activeTextField)
    {
         _activeTextField = nil;
    }
    [self updateDisplayForKeyboard:NO];
    _keyboardFrameOriginY = 0.0;
}

- (void)updateDisplayForKeyboard:(BOOL)up
{
    if(up)
    {
        [UIView animateWithDuration:0.35
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^
        {
////             [self.usernameSelector dismissPopupPicker];
////             self.swipeText.hidden = YES;
////             self.swipeRightArrow.hidden = YES;
////             self.titleText.hidden = YES;
////             int iphone4heightadjust = 0;
////             if(IS_IPHONE4) {
////                 self.logoImage.frame = CGRectMake(_originalLogoFrame.origin.x, _originalLogoFrame.origin.y, _originalLogoFrame.size.width, _originalLogoFrame.size.height * 0.35);
////                 iphone4heightadjust = -75;
////             }
////             self.credentialsView.frame = CGRectMake(_originalCredentialsFrame.origin.x, _originalLogoFrame.origin.y + _originalLogoFrame.size.height + 10 + iphone4heightadjust, _originalCredentialsFrame.size.width, _originalCredentialsFrame.size.height);
////             self.userEntryView.frame = CGRectMake(_originalUserEntryFrame.origin.x, _originalLogoFrame.origin.y + _originalLogoFrame.size.height + _originalCredentialsFrame.size.height + iphone4heightadjust, _originalUserEntryFrame.size.width, _originalUserEntryFrame.size.height);
                 if(self.usernameSelector.textField.isEditing)
                 {
                     [self.usernameSelector updateChoices:self.arrayAccounts];
                 }

                 self.logoHeight.constant /= 2;
                 self.textBitcoinWalletHeight.constant = 0;

                 [self.view layoutIfNeeded];

         }
            completion:^(BOOL finished)
         {

         }];
    }
    else
    {
        [UIView animateWithDuration:0.35
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             self.logoHeight.constant = _originalLogoHeight;
             self.textBitcoinWalletHeight.constant = _originalTextBitcoinWalletHeight;
             [self.view layoutIfNeeded];

//             self.swipeText.hidden = NO;
//             self.swipeRightArrow.hidden = NO;
//             self.titleText.hidden = NO;
//             if(IS_IPHONE4) {
//                 self.logoImage.frame = CGRectMake(_originalLogoFrame.origin.x, _originalLogoFrame.origin.y, _originalLogoFrame.size.width, _originalLogoFrame.size.height);
//             }
//             self.credentialsView.frame = CGRectMake(_originalCredentialsFrame.origin.x, _originalCredentialsFrame.origin.y, _originalCredentialsFrame.size.width, _originalCredentialsFrame.size.height);
//             self.userEntryView.frame = CGRectMake(_originalUserEntryFrame.origin.x, _originalUserEntryFrame.origin.y, _originalUserEntryFrame.size.width, _originalUserEntryFrame.size.height);
         }
                         completion:^(BOOL finished)
         {
         }];

    }

}

#pragma mark - touch events (for swiping)

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_bTouchesEnabled) {
        return;
    }

    UITouch *touch = [touches anyObject];
    _firstTouchPoint = [touch locationInView:self.view.window];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_bTouchesEnabled) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view.window];
    
    CGRect frame = self.view.frame;
    CGFloat xPos;


    xPos = touchPoint.x - _firstTouchPoint.x;

    if (xPos < 0)
    {
        [MainViewController moveSelectedViewController:(frame.size.width + xPos)];
    }
    else
    {
        [MainViewController moveSelectedViewController:(-frame.size.width + xPos)];
    }
    frame.origin.x = xPos;
    self.view.frame = frame;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_bTouchesEnabled) {
        return;
    }
    
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
             if (self.view.frame.origin.x > 0)
             {
                 // sliding to right. Move directory back to left
                 [MainViewController moveSelectedViewController:-self.view.frame.size.width];
             }
             else
             {
                 // sliding to left. Move directory back to right
                 [MainViewController moveSelectedViewController:self.view.frame.size.width];
             }

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
             [MainViewController moveSelectedViewController:0.0];

             self.view.frame = frame;
         }
         completion:^(BOOL finished)
         {
             [self.delegate loginViewControllerDidAbort];
         }];
    }
}

#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self dismissErrorMessage];
    
    //called when user taps on either search textField or location textField
    _activeTextField = textField;
    
    if(_mode == MODE_ENTERING_NEITHER)
    {
        if(textField == self.usernameSelector.textField)
        {
            _mode = MODE_ENTERING_USERNAME;
        }
        else
        {
            _mode = MODE_ENTERING_PASSWORD;
        }
    }

    // highlight all of the text
    if (textField == self.usernameSelector.textField)
    {
        [self getAllAccounts];
        [self.usernameSelector updateChoices:self.arrayAccounts];

        [textField setSelectedTextRange:[textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.endOfDocument]];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    if (textField == self.usernameSelector.textField)
    {
        [self.usernameSelector dismissPopupPicker];
        [self.passwordTextField becomeFirstResponder];
    }
    else
    {
        [self animateToInitialPresentation];
    }

    return NO;
}

- (void)signInComplete
{
    [self showSpinner:NO];
    [CoreBridge otpSetError:_resultCode];
    if (_bSuccess)
    {
        [User login:self.usernameSelector.textField.text
           password:self.passwordTextField.text];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [CoreBridge setupLoginPIN];
        });
        [self.delegate loginViewControllerDidLogin:NO];
    } else if (ABC_CC_InvalidOTP == _resultCode) {
        [self launchTwoFactorMenu];
    } else {
        if (ABC_CC_InvalidOTP == _resultCode) {
            [self launchTwoFactorMenu];
        } else {
            [self showFadingError:_strReason];
        }
        [User Singleton].name = nil;
        [User Singleton].password = nil; 
    }
}

- (void)launchTwoFactorMenu
{
    _tfaMenuViewController = (TwoFactorMenuViewController *)[Util animateIn:@"TwoFactorMenuViewController" parentController:self];
    _tfaMenuViewController.delegate = self;
    _tfaMenuViewController.username = self.usernameSelector.textField.text;
    _tfaMenuViewController.bStoreSecret = NO;
    _tfaMenuViewController.bTestSecret = NO;
}

#pragma mark - SignUpManagerDelegate

-(void)signupAborted
{
    [self finishIfLoggedIn:YES];
}

-(void)signupFinished
{
    [self finishIfLoggedIn:YES];
}

#pragma mark - TwoFactorScanViewControllerDelegate

- (void)twoFactorMenuViewControllerDone:(TwoFactorMenuViewController *)controller withBackButton:(BOOL)bBack
{
    BOOL success = controller.bSuccess;
    NSString *secret = controller.secret;
    [Util animateOut:controller parentController:self complete:^(void) {
        _tfaMenuViewController = nil;

        if (!success) {
            return;
        }
        [self.usernameSelector.textField resignFirstResponder];
        [self.passwordTextField resignFirstResponder];
        [self animateToInitialPresentation];

        [self showSpinner:YES];
        // Perform the two factor sign in
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [self twoFactorSignIn:secret];
        });
    }];
}

- (void)twoFactorSignIn:(NSString *)secret
{
    _bSuccess = NO;
    tABC_Error error;

    ABC_OtpKeySet([self.usernameSelector.textField.text UTF8String], (char *)[secret UTF8String], &error);
    tABC_CC cc = ABC_SignIn([self.usernameSelector.textField.text UTF8String],
                            [self.passwordTextField.text UTF8String], &error);
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        _bSuccess = cc == ABC_CC_Ok; 
        _strReason = [Util errorMap:&error];
        _resultCode = error.code;
        [self signInComplete];
    });
}

#pragma mark - PasswordRecoveryViewController Delegate

- (void)passwordRecoveryViewControllerDidFinish:(PasswordRecoveryViewController *)controller
{
    [controller.view removeFromSuperview];
    _passwordRecoveryController = nil;

    [self finishIfLoggedIn:NO];
}

#pragma mark - Error Message

- (void)dismissErrorMessage
{
    [self.errorMessageView.layer removeAllAnimations];
}

- (void)showFadingError:(NSString *)message
{
    _fadingAlert = [FadingAlertView CreateInsideView:self.view withDelegate:nil];
    _fadingAlert.message = message;
    _fadingAlert.fadeDuration = 2;
    _fadingAlert.fadeDelay = 5;
    [_fadingAlert blockModal:NO];
    [_fadingAlert showSpinner:NO];
    [_fadingAlert showFading];
}

#pragma mark - Misc

- (void)showSpinner:(BOOL)bShow
{
    _spinnerView.hidden = !bShow;
    
    // disable touches while the spinner is visible
    _bTouchesEnabled = _spinnerView.hidden;
}

- (void)finishIfLoggedIn:(BOOL)bNewAccount
{
    if([User isLoggedIn])
    {
        _bSuccess = YES;

        [self.delegate loginViewControllerDidLogin:bNewAccount];
    }
}

- (void)getAllAccounts
{
    char * pszUserNames;
    tABC_Error error;
    __block tABC_CC result = ABC_ListAccounts(&pszUserNames, &error);
    switch (result)
    {
        case ABC_CC_Ok:
        {
            NSString *str = [NSString stringWithCString:pszUserNames encoding:NSUTF8StringEncoding];
            NSArray *arrayAccounts = [str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            NSMutableArray *stringArray = [[NSMutableArray alloc] init];
            for(NSString *str in arrayAccounts)
            {
                if(str && str.length!=0)
                {
                    [stringArray addObject:str];
                }
            }
            self.arrayAccounts = [stringArray copy];
            break;
        }
        default:
        {
            [self showFadingError:[Util errorMap:&error]];
            break;
        }
    }
}

#pragma mark - PickerTextView delegates

- (void)pickerTextViewPopupSelected:(PickerTextView *)pickerTextView onRow:(NSInteger)row
{
    [self.usernameSelector.textField resignFirstResponder];
    [self.usernameSelector dismissPopupPicker];
    
    // set the text field to the choice
    NSString *account = [self.arrayAccounts objectAtIndex:row];
    if([CoreBridge PINLoginExists:account])
    {
        [LocalSettings controller].cachedUsername = account;
        [self.delegate loginViewControllerDidAbort];
        [self.delegate loginViewControllerDidSwitchAccount];
    }
    else {
        self.usernameSelector.textField.text = account;
        [self.usernameSelector dismissPopupPicker];
    }
}

- (void)removeAccount:(NSString *)account
{
    // TODO delete the account, update array - current implementation is fake
    tABC_Error error;
    tABC_CC cc = ABC_AccountDelete((const char*)[account UTF8String], &error);
    if(cc == ABC_CC_Ok) {
        [self getAllAccounts];
        [self.usernameSelector updateChoices:self.arrayAccounts];
    }
    else {
        [self showFadingError:[Util errorMap:&error]];
    }
}

- (void)pickerTextViewDidTouchAccessory:(PickerTextView *)pickerTextView categoryString:(NSString *)string
{
    _account = string;
    NSString *message = [NSString stringWithFormat:@"Delete %@ on this device only?",
                       string];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Delete Account", nil)
                          message:NSLocalizedString(message, nil)
                          delegate:self
                          cancelButtonTitle:@"No"
                          otherButtonTitles:@"Yes", nil];
    [alert show];
    [self.usernameSelector dismissPopupPicker];
}

- (void)pickerTextViewFieldDidShowPopup:(PickerTextView *)pickerTextView
{
    CGRect frame = pickerTextView.popupPicker.frame;
    pickerTextView.popupPicker.frame = frame;

    CGRect pickerWindowFrame = [self.contentView convertRect:frame toView:self.view.window];

    // Shrink the popup if it would be behind the keyboard.

    float overlap = _keyboardFrameOriginY - (pickerWindowFrame.origin.y + pickerWindowFrame.size.height);

    if (overlap < 0)
    {
        frame.size.height += overlap;
    }
    pickerTextView.popupPicker.frame = frame;

}



#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.usernameSelector.textField resignFirstResponder];
    // if they said they wanted to delete the account
    if (buttonIndex == 1)
    {
        [self removeAccount:_account];
        self.usernameSelector.textField.text = @"";
        [self.usernameSelector dismissPopupPicker];
    }
}


@end

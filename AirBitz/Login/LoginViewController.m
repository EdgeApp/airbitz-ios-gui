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
#import "ButtonSelectorView.h"
#import "APPINView.h"
#import "Theme.h"
#import "FadingAlertView.h"

typedef enum eLoginMode
{
    MODE_NO_USERS,
    MODE_ENTERING_NEITHER,
    MODE_ENTERING_USERNAME,
    MODE_ENTERING_PASSWORD
} tLoginMode;

#define SWIPE_ARROW_ANIM_PIXELS 10

@interface LoginViewController () <UITextFieldDelegate, SignUpManagerDelegate, PasswordRecoveryViewControllerDelegate, PickerTextViewDelegate,
    TwoFactorMenuViewControllerDelegate, APPINViewDelegate, UIAlertViewDelegate, FadingAlertViewDelegate, ButtonSelectorDelegate >
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
    float                           _keyboardFrameOriginY;
    CGFloat                         _originalLogoHeight;
    CGFloat                         _originalUsernameHeight;
    CGFloat                         _originalPasswordHeight;
    CGFloat                         _originalPasswordWidth;
    CGFloat                         _originalPINSelectorWidth;
    CGFloat                         _originalTextBitcoinWalletHeight;

}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *usernameHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordHeight;
@property (weak, nonatomic) IBOutlet UIButton           *forgotPassworddButton;
@property (weak, nonatomic) IBOutlet APPINView          *PINCodeView;
@property (weak, nonatomic) IBOutlet ButtonSelectorView *PINusernameSelector;
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
@property (weak, nonatomic) IBOutlet UIView             *credentialsPINView;

@property (nonatomic, weak) IBOutlet UILabel			*errorMessageText;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *swipeArrowLeft;

@property (nonatomic, weak) IBOutlet PickerTextView   *usernameSelector;
@property (nonatomic, strong) NSArray   *arrayAccounts;
@property (nonatomic, strong) NSArray   *otherAccounts;

@end

static BOOL bPINModeEnabled = false;
static BOOL bInitialized = false;

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
    self.PINCodeView.delegate = self;
    self.PINusernameSelector.delegate = self;
    self.spinnerView.hidden = YES;

    [self getAllAccounts];

    if (!bInitialized)
    {
        bInitialized = true;
        _originalLogoHeight = self.logoHeight.constant = [Theme Singleton].heightLoginScreenLogo;
        _originalTextBitcoinWalletHeight = self.textBitcoinWalletHeight.constant;
        _originalUsernameHeight = self.usernameHeight.constant;
        _originalPasswordHeight = self.passwordHeight.constant;
        _originalPasswordWidth = self.passwordTextField.frame.size.width;
        _originalPINSelectorWidth = self.PINusernameSelector.frame.size.width;

        if ([self.arrayAccounts count] == 0)
        {
            _mode = MODE_NO_USERS;
        }
    }

    #if HARD_CODED_LOGIN
    
    self.usernameSelection.textField.text = HARD_CODED_LOGIN_NAME;
    self.passwordTextField.text = HARD_CODED_LOGIN_PASSWORD;
    #endif

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

    // Add shadows to some text for visibility
    self.PINusernameSelector.textLabel.layer.shadowRadius = 3.0f;
    self.PINusernameSelector.textLabel.layer.shadowOpacity = 1.0f;
    self.PINusernameSelector.textLabel.layer.masksToBounds = NO;
    self.PINusernameSelector.textLabel.layer.shadowColor = [[UIColor whiteColor] CGColor];
    self.PINusernameSelector.textLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);

    self.swipeText.layer.shadowRadius = 3.0f;
    self.swipeText.layer.shadowOpacity = 1.0f;
    self.swipeText.layer.masksToBounds = NO;
    self.swipeText.layer.shadowColor = [[UIColor darkGrayColor] CGColor];
    self.swipeText.layer.shadowOffset = CGSizeMake(0.0, 0.0);

    self.titleText.layer.shadowRadius = 3.0f;
    self.titleText.layer.shadowOpacity = 1.0f;
    self.titleText.layer.masksToBounds = NO;
    self.titleText.layer.shadowColor = [[UIColor whiteColor] CGColor];
    self.titleText.layer.shadowOffset = CGSizeMake(0.0, 0.0);

    self.forgotPassworddButton.layer.shadowRadius = 3.0f;
    self.forgotPassworddButton.layer.shadowOpacity = 1.0f;
    self.forgotPassworddButton.layer.masksToBounds = NO;
    self.forgotPassworddButton.layer.shadowColor = [[UIColor darkGrayColor] CGColor];
    self.forgotPassworddButton.layer.shadowOffset = CGSizeMake(0.0, 0.0);

    self.usernameSelector.textField.placeholder = NSLocalizedString(@"Username", @"Username");
    self.usernameSelector.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.usernameSelector.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor lightTextColor]}];

    [self.usernameSelector setTopMostView:self.view];
    self.usernameSelector.pickerMaxChoicesVisible = 3;
    [self.usernameSelector setAccessoryImage:[UIImage imageNamed:@"btn_close.png"]];
    [Util stylizeTextField:self.usernameSelector.textField];

    [self.PINusernameSelector.button setBackgroundImage:nil forState:UIControlStateNormal];
    [self.PINusernameSelector.button setBackgroundImage:nil forState:UIControlStateSelected];
    [self.PINusernameSelector.button setBackgroundColor:[UIColor clearColor]];

    self.PINusernameSelector.textLabel.text = NSLocalizedString(@"", @"username");
    [self.PINusernameSelector setButtonWidth:_originalPINSelectorWidth];
    self.PINusernameSelector.accessoryImage = [UIImage imageNamed:@"btn_close.png"];

}

- (void)viewWillAppear:(BOOL)animated
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self animateSwipeArrowWithRepetitions:3 andDelay:1.0 direction:1];

    _bTouchesEnabled = YES;

    [self getAllAccounts];
    [self updateUsernameSelector:[LocalSettings controller].cachedUsername];

    if (bPINModeEnabled)
    {
        self.textBitcoinWalletHeight.constant = 0;
        self.credentialsPINView.hidden = false;
        self.credentialsView.hidden = true;
        self.userEntryView.hidden = true;
        [self.passwordTextField resignFirstResponder];
        [self.usernameSelector.textField resignFirstResponder];
        [self.PINCodeView becomeFirstResponder];
    }
    else
    {
        self.textBitcoinWalletHeight.constant = _originalTextBitcoinWalletHeight;
        self.credentialsPINView.hidden = true;
        self.credentialsView.hidden = false;
        self.userEntryView.hidden = false;
        [self.passwordTextField resignFirstResponder];
        [self.usernameSelector.textField resignFirstResponder];
        [self.PINCodeView resignFirstResponder];
    }

    if (_mode == MODE_NO_USERS)
    {
        self.usernameSelector.textField.hidden = true;
        self.usernameHeight.constant = 0;
        self.passwordHeight.constant = 0;
        self.forgotPassworddButton.hidden = true;
    }
    else
    {
        self.usernameSelector.textField.hidden = false;
        self.usernameHeight.constant = _originalUsernameHeight;
        self.passwordHeight.constant = _originalPasswordHeight;
        self.forgotPassworddButton.hidden = false;
    }


}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [self dismissErrorMessage];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.PINCodeView.PINCode = nil;
    [super viewWillDisappear:animated];
}

#pragma mark - APPINViewDelegate Methods

- (void)PINCodeView:(APPINView *)view didEnterPIN:(NSString *)PINCode
{
    [view resignFirstResponder];
    [self showSpinner:YES];
    [self signIn:PINCode];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - FadingAlertView delegate

- (void)fadingAlertDismissedNew
{
    if (bPINModeEnabled)
        [self.PINCodeView becomeFirstResponder];
    else
        [self.PINCodeView resignFirstResponder];
}



#pragma mark - Action Methods

- (IBAction)Back
{
    //spring out
    [MainViewController moveSelectedViewController:-self.view.frame.size.width];
    [self.view layoutIfNeeded];

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         [MainViewController moveSelectedViewController:0.0];
         [MainViewController setAlphaOfSelectedViewController:1.0];
         self.leftConstraint.constant = self.view.frame.size.width;
         [self.view.superview layoutIfNeeded];
     }
                     completion:^(BOOL finished)
     {
         [self.delegate loginViewControllerDidAbort];
     }];
}

#pragma mark - Misc Methods

- (void)updateUsernameSelector:(NSString *)username
{
    [self setUsernameText:username];
    NSMutableArray *stringArray = [[NSMutableArray alloc] init];
    for(NSString *str in self.arrayAccounts)
    {
        [stringArray addObject:str];
    }
    self.otherAccounts = [stringArray copy];
    self.PINusernameSelector.arrayItemsToSelect = self.otherAccounts;
}

- (void)setUsernameText:(NSString *)username
{
    // Update non-PIN username
#if !HARD_CODED_LOGIN
    if (username && 0 < username.length)
    {
        //
        // Set the PIN username default
        //
        UIFont *boldFont = [UIFont fontWithName:@"Lato-Bold" size:[Theme Singleton].fontSizeEnterPINText];
        UIFont *regularFont = [UIFont fontWithName:@"Lato-Regular" size:[Theme Singleton].fontSizeEnterPINText];
        UIColor *boldColor = [UIColor colorWithRed:60./255. green:140.5/255. blue:200/255. alpha:1.];
        UIColor *regularColor = [UIColor grayColor];
        NSString *title = [NSString stringWithFormat:@"Enter PIN for (%@)",
                           username];
        // Define general attributes like color and fonts for the entire text
        NSDictionary *attr = @{NSForegroundColorAttributeName:regularColor,
                               NSFontAttributeName:regularFont};
        NSMutableAttributedString *attributedText = [ [NSMutableAttributedString alloc]
                                                     initWithString:title
                                                     attributes:attr];
        // blue and bold text attributes
        NSRange usernameTextRange = [title rangeOfString:username];
        [attributedText setAttributes:@{NSForegroundColorAttributeName:boldColor,
                                        NSFontAttributeName:boldFont}
                                range:usernameTextRange];
        [self.PINusernameSelector.button setAttributedTitle:attributedText forState:UIControlStateNormal];

        //
        // Set the regular username field
        //
        self.usernameSelector.textField.text = username;
    }
    self.passwordTextField.text = [User Singleton].password;
#endif

}


- (IBAction)SignIn
{
    if (_mode == MODE_NO_USERS)
    {
        _mode = MODE_ENTERING_USERNAME;
        [self viewWillAppear:true];
    }
    else
    {
        [self.usernameSelector resignFirstResponder];
        [self.passwordTextField resignFirstResponder];

        _bSuccess = NO;
        [self showSpinner:YES];
        [MainViewController showBackground:YES animate:YES];
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
}

- (IBAction)SignUp
{
    [self dismissErrorMessage];

    [MainViewController showBackground:YES animate:YES completion:^(BOOL finished)
    {
        [self.usernameSelector.textField resignFirstResponder];
        [self.passwordTextField resignFirstResponder];

        _signupManager = [[SignUpManager alloc] initWithController:self];
        _signupManager.delegate = self;
        if (self.usernameSelector.textField.text) {
            _signupManager.strInUserName = self.usernameSelector.textField.text;
        }
        [MainViewController animateFadeOut:self.view];

        [_signupManager startSignup];

    }];
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
        [MainViewController fadingAlert:NSLocalizedString(@"Please enter a User Name", nil)];
    }
}

- (IBAction)buttonLoginWithPasswordTouched:(id)sender
{
    [self dismissErrorMessage];
    bPINModeEnabled = false;

    [self viewDidLoad];
    [self viewWillAppear:true];
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

        [MainViewController showNavBarAnimated:YES];
        [MainViewController animateView:_passwordRecoveryController withBlur:NO];
    }
    else
    {
        [MainViewController fadingAlert:_strReason];
    }
}

#pragma mark - ReLogin Methods

- (void)signIn:(NSString *)PINCode
{
    [MainViewController showBackground:YES animate:YES];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
    {
        tABC_Error error;
        [CoreBridge PINLoginWithPIN:PINCode error:&error];
        dispatch_async(dispatch_get_main_queue(), ^
        {
            switch (error.code)
            {
                case ABC_CC_Ok:
                {
                    [User login:[LocalSettings controller].cachedUsername password:NULL];
                    [[User Singleton] resetPINLoginInvalidEntryCount];
                    [self.delegate LoginViewControllerDidPINLogin];
                    break;
                }
                case ABC_CC_BadPassword:
                {
                    [MainViewController showBackground:NO animate:YES];
                    if ([[User Singleton] haveExceededPINLoginInvalidEntries])
                    {
                        [[User Singleton] resetPINLoginInvalidEntryCount];
                        [self PINabortPermanently];
                    }
                    else
                    {
                        [MainViewController fadingAlert:NSLocalizedString(@"Invalid PIN", nil)];
                        [self.PINCodeView becomeFirstResponder];
                    }
                    break;
                }
                default:
                {
                    [MainViewController showBackground:NO animate:YES];
                    [MainViewController fadingAlert:[Util errorMap:&error]];
                    [self.PINCodeView becomeFirstResponder];

                }
            }
            [self showSpinner:NO];
            self.PINCodeView.PINCode = nil;
        });
    });
}

- (void)PINabortPermanently
{
    [MainViewController fadingAlert:NSLocalizedString(@"Invalid PIN. Please log in.", nil)];

    bPINModeEnabled = false;
    [self viewDidLoad];
    [self viewWillAppear:true];


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
                 if(self.usernameSelector.textField.isEditing)
                 {
                     [self.usernameSelector updateChoices:self.arrayAccounts];
                 }

                 self.logoHeight.constant = _originalLogoHeight * 0.75;
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
    CGFloat alpha;


    xPos = touchPoint.x - _firstTouchPoint.x;

    if (xPos < 0)
    {
        // Swiping to left
        [MainViewController moveSelectedViewController:(frame.size.width + xPos)];
        alpha = -xPos / frame.size.width;
    }
    else
    {
        // Swiping to right
        [MainViewController moveSelectedViewController:(-frame.size.width + xPos)];
        alpha = xPos / frame.size.width;
    }

    [MainViewController setAlphaOfSelectedViewController:alpha];
//    frame.origin.x = xPos;
//    self.view.frame = frame;
    self.leftConstraint.constant = xPos;
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
        [self.view.superview layoutIfNeeded];

        //spring back
        if (self.view.frame.origin.x > 0)
        {
            // sliding to right. Move directory back to left
            [MainViewController moveSelectedViewController:-self.view.frame.size.width];
        }
        else if (self.view.frame.origin.x < 0)
        {
            // sliding to left. Move directory back to right
            [MainViewController moveSelectedViewController:self.view.frame.size.width];
        }

//        [MainViewController setAlphaOfSelectedViewController:0.0];
        self.leftConstraint.constant = 0;

        [UIView animateWithDuration:0.35
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             [self.view.superview layoutIfNeeded];
         }
        completion:^(BOOL finished)
         {
         }];
    }
    else
    {
        //spring out
        [self.view.superview layoutIfNeeded];

        CGRect frame = self.view.frame;
        if(frame.origin.x < 0)
        {
            self.leftConstraint.constant = -frame.size.width;
        }
        else
        {
            self.leftConstraint.constant = frame.size.width;
        }
        [MainViewController moveSelectedViewController:0.0];
        [MainViewController setAlphaOfSelectedViewController:1.0];

        [UIView animateWithDuration:0.35
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             [self.view setAlpha:0];
             [self.view.superview layoutIfNeeded];
         }
         completion:^(BOOL finished)
         {
             self.leftConstraint.constant = 0;
             [self.view layoutIfNeeded];
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
    else if (_mode == MODE_NO_USERS)
    {
        NSLog(@"XXX error. should not happen");
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

    return NO;
}

- (void)signInComplete
{
    [self showSpinner:NO];
    [CoreBridge otpSetError:_resultCode];
    if (_bSuccess)
    {
        [User login:self.usernameSelector.textField.text
           password:self.passwordTextField.text
           setupPIN:YES];
        [self.delegate loginViewControllerDidLogin:NO];
    } else if (ABC_CC_InvalidOTP == _resultCode) {
        [MainViewController showBackground:NO animate:YES];
        [self launchTwoFactorMenu];
    } else {
        [MainViewController showBackground:NO animate:YES];
        if (ABC_CC_InvalidOTP == _resultCode) {
            [self launchTwoFactorMenu];
        } else {
            [MainViewController fadingAlert:_strReason];
        }
        [User Singleton].name = nil;
        [User Singleton].password = nil; 
    }
}

- (void)launchTwoFactorMenu
{
    _tfaMenuViewController = (TwoFactorMenuViewController *)[Util animateIn:@"TwoFactorMenuViewController" storyboard:@"Settings" parentController:self];
    _tfaMenuViewController.delegate = self;
    _tfaMenuViewController.username = self.usernameSelector.textField.text;
    _tfaMenuViewController.bStoreSecret = NO;
    _tfaMenuViewController.bTestSecret = NO;
    _bTouchesEnabled = NO;
}

#pragma mark - SignUpManagerDelegate

-(void)signupAborted
{
    [MainViewController showBackground:NO animate:YES];
    [MainViewController animateFadeIn:self.view];
    _bTouchesEnabled = YES;
}

-(void)signupFinished
{
    [self finishIfLoggedIn:YES];
    _bTouchesEnabled = YES;
}

#pragma mark - TwoFactorScanViewControllerDelegate

- (void)twoFactorMenuViewControllerDone:(TwoFactorMenuViewController *)controller withBackButton:(BOOL)bBack
{
    BOOL success = controller.bSuccess;
    NSString *secret = controller.secret;

    [MainViewController hideNavBarAnimated:YES];
    _bTouchesEnabled = YES;

    [MainViewController animateOut:controller withBlur:NO complete:^(void)
    {
        _tfaMenuViewController = nil;

        if (!success) {
            return;
        }
        [self.usernameSelector.textField resignFirstResponder];
        [self.passwordTextField resignFirstResponder];

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

    [MainViewController showBackground:YES animate:YES];
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
    [MainViewController animateOut:controller withBlur:NO complete:^(void)
    {
        _passwordRecoveryController = nil;
        [MainViewController hideNavBarAnimated:YES];
        [self finishIfLoggedIn:NO];
        _bTouchesEnabled = YES;

    }];
}

#pragma mark - Error Message

- (void)dismissErrorMessage
{
//    [self.errorMessageView.layer removeAllAnimations];
//    [_fadingAlert dismiss:NO];
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
            [MainViewController fadingAlert:[Util errorMap:&error]];
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
        bPINModeEnabled = true;
        [self viewDidLoad];
        [self viewWillAppear:true];
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
        [MainViewController fadingAlert:[Util errorMap:&error]];
    }
}

- (void)pickerTextViewDidTouchAccessory:(PickerTextView *)pickerTextView categoryString:(NSString *)string
{
    _account = string;
    NSString *message = [NSString stringWithFormat:[Theme Singleton].deleteAccountWarning,
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

    if (_keyboardFrameOriginY > 0)
    {
        float overlap = _keyboardFrameOriginY - (pickerWindowFrame.origin.y + pickerWindowFrame.size.height);
        
        if (overlap < 0)
        {
            frame.size.height += overlap;
        }
        pickerTextView.popupPicker.frame = frame;
        
    }

}

- (void)pickerTextViewFieldDidChange:(PickerTextView *)pickerTextView;
{
    //
    // Do not show popup if user has text in the field
    //
    if ([pickerTextView.textField.text length] > 0)
    {
        [pickerTextView dismissPopupPicker];
    }
    else if ([pickerTextView.textField.text length] == 0)
    {
        [pickerTextView createPopupPicker];
    }
}

- (void)pickerTextViewFieldDidEndEditing:(PickerTextView *)pickerTextView;
{
    [pickerTextView dismissPopupPicker];
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

#pragma mark - ButtonSelectorView delegates

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
    [LocalSettings controller].cachedUsername = [self.otherAccounts objectAtIndex:itemIndex];
    if([CoreBridge PINLoginExists:[LocalSettings controller].cachedUsername])
    {
        [self updateUsernameSelector:[LocalSettings controller].cachedUsername];
    }
    else
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self viewDidLoad];
            [self viewWillAppear:true];
        }];
    }
}

- (void)ButtonSelectorWillShowTable:(ButtonSelectorView *)view
{
    [self.PINusernameSelector.textLabel resignFirstResponder];
    [self.PINCodeView resignFirstResponder];

}

- (void)ButtonSelectorWillHideTable:(ButtonSelectorView *)view
{
    [self.PINCodeView becomeFirstResponder];

}

- (void)ButtonSelectorDidTouchAccessory:(ButtonSelectorView *)selector accountString:(NSString *)string
{
    _account = string;
    NSString *message = [NSString stringWithFormat:[Theme Singleton].deleteAccountWarning,
                                                   string];
    UIAlertView *alert = [[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"Delete Account", @"Delete Account")
                  message:NSLocalizedString(message, nil)
                 delegate:self
        cancelButtonTitle:@"No"
        otherButtonTitles:@"Yes", nil];
    [alert show];
    [self.PINCodeView becomeFirstResponder];

}


+ (void)setModePIN:(BOOL)enable
{
    if (enable)
        bPINModeEnabled = true;
    else
        bPINModeEnabled = false;

}

@end

//
//  LoginViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "LoginViewController.h"
#import "PickerTextView.h"
#import "SignUpViewController.h"
#import "User.h"
#import "StylizedTextField.h"
#import "Util.h"
#import "ABCContext.h"
#import "Config.h"
#import "SignUpManager.h"
#import "PasswordRecoveryViewController.h"
#import "TwoFactorMenuViewController.h"
#import "ABCContext.h"
#import "CommonTypes.h"
#import "LocalSettings.h"
#import "MainViewController.h"
#import "ButtonSelectorView.h"
#import "Theme.h"
#import "FadingAlertView.h"
#import "SettingsViewController.h"
#import "InfoView.h"

typedef enum eLoginMode
{
    MODE_NO_USERS,
    MODE_ENTERING_NEITHER,
    MODE_ENTERING_USERNAME,
    MODE_ENTERING_PASSWORD
} tLoginMode;

#define SWIPE_ARROW_ANIM_PIXELS 10

@interface LoginViewController () <UITextFieldDelegate, SignUpManagerDelegate, PasswordRecoveryViewControllerDelegate, PickerTextViewDelegate,
    TwoFactorMenuViewControllerDelegate, UIAlertViewDelegate, FadingAlertViewDelegate, ButtonSelectorDelegate, InfoViewDelegate >
{
    tLoginMode                      _mode;
    CGPoint                         _firstTouchPoint;
    BOOL                            _bSuccess;
    BOOL                            _bTouchesEnabled;
    BOOL                            _bUsedTouchIDToLogin;
    BOOL                            _bDisallowTouchID;
    NSString                        *_strReason;
    NSString                        *_accountToDelete;
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
    UIAlertView                     *_enableTouchIDAlertView;
    UIAlertView                     *_passwordCheckAlert;
    UIAlertView                     *_passwordIncorrectAlert;
    UIAlertView                     *_uploadLogAlert;
    UIAlertView                     *_deleteAccountAlert;
    UIAlertView                     *_recoverPasswordAlert;
    NSString                        *_tempPassword;
    NSString                        *_tempPin;
    NSString                        *_recoveryToken;
    BOOL                            _bNewDeviceLogin;
    


}

@property (weak, nonatomic) IBOutlet UIButton           *fingerprintButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *usernameHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordHeight;
@property (weak, nonatomic) IBOutlet UIButton           *forgotPassworddButton;
//@property (weak, nonatomic) IBOutlet APPINView          *PINCodeView;
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
@property (weak, nonatomic) IBOutlet StylizedTextField  *PINTextField;

@property (nonatomic, weak) IBOutlet UILabel			*errorMessageText;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *swipeArrowLeft;

@property (nonatomic, weak) IBOutlet    PickerTextView      *usernameSelector;
@property (nonatomic, strong)           NSArray             *arrayAccounts;
@property (nonatomic, strong)           NSArray             *otherAccounts;
@property (weak, nonatomic) IBOutlet    UIButton            *buttonOutsideTap;
@property (weak, nonatomic) IBOutlet    InfoView            *disclaimerInfoView;

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
//    self.PINCodeView.delegate = self;
    self.PINTextField.delegate = self;
    self.PINusernameSelector.delegate = self;
    self.spinnerView.hidden = YES;
    self.buttonOutsideTap.enabled = NO;

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

    // set up the specifics on our picker text view
    self.usernameSelector.textField.borderStyle = UITextBorderStyleNone;
    self.usernameSelector.textField.backgroundColor = [UIColor clearColor];
    self.usernameSelector.textField.font = [UIFont fontWithName:AppFont size:16.0];
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
    self.PINusernameSelector.textLabel.layer.shadowColor = [ColorPinUserNameSelectorShadow CGColor];
    self.PINusernameSelector.textLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.PINusernameSelector.textLabel.font = [UIFont fontWithName:@"Lato-Regular" size:24.0];

    self.swipeText.layer.shadowRadius = 3.0f;
    self.swipeText.layer.shadowOpacity = 1.0f;
    self.swipeText.layer.masksToBounds = NO;
    self.swipeText.layer.shadowColor = [[UIColor darkGrayColor] CGColor];
    self.swipeText.layer.shadowOffset = CGSizeMake(0.0, 0.0);

    self.titleText.layer.shadowRadius = LoginTitleTextShadowRadius;
    self.titleText.layer.shadowOpacity = 1.0f;
    self.titleText.layer.masksToBounds = NO;
    self.titleText.layer.shadowColor = [[UIColor whiteColor] CGColor];
    self.titleText.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.titleText.textColor = ColorLoginTitleText;

    self.PINusernameSelector.button.layer.shadowRadius = PinEntryTextShadowRadius;
    self.PINusernameSelector.button.layer.shadowOpacity = 1.0f;
    self.PINusernameSelector.button.layer.masksToBounds = NO;
    self.PINusernameSelector.button.layer.shadowColor = [ColorPinUserNameSelectorShadow CGColor];
    self.PINusernameSelector.button.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    
    self.forgotPassworddButton.layer.shadowRadius = 3.0f;
    self.forgotPassworddButton.layer.shadowOpacity = 1.0f;
    self.forgotPassworddButton.layer.masksToBounds = NO;
    self.forgotPassworddButton.layer.shadowColor = [ColorLoginTitleTextShadow CGColor];
    self.forgotPassworddButton.layer.shadowOffset = CGSizeMake(0.0, 0.0);

    self.usernameSelector.textField.placeholder = usernameText;
    self.usernameSelector.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.usernameSelector.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor lightTextColor]}];

    [self.usernameSelector setTopMostView:self.view];
    self.usernameSelector.pickerMaxChoicesVisible = 3;
    [self.usernameSelector setAccessoryImage:[UIImage imageNamed:@"btn_close.png"]];
    [Util stylizeTextField:self.usernameSelector.textField];

    [self.PINusernameSelector.button setBackgroundImage:nil forState:UIControlStateNormal];
    [self.PINusernameSelector.button setBackgroundImage:nil forState:UIControlStateSelected];
    [self.PINusernameSelector.button setBackgroundColor:[UIColor clearColor]];

    self.PINusernameSelector.textLabel.text = @"";
    [self.PINusernameSelector setButtonWidth:_originalPINSelectorWidth];
    self.PINusernameSelector.accessoryImage = [UIImage imageNamed:@"btn_close.png"];
    
//    [self.PINTextField addTarget:self
//                          action:@selector(PINTextFieldDidChange:)
//                forControlEvents:UIControlEventEditingChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnteredForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    if (![abc hasDeviceCapability:ABCDeviceCapsTouchID])
        self.fingerprintButton.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self animateSwipeArrowWithRepetitions:3 andDelay:1.0 direction:1];

    _bTouchesEnabled = YES;
    _bUsedTouchIDToLogin = NO;
    _bNewDeviceLogin = NO;

//    [self getAllAccounts];
//    if (self.arrayAccounts.count > 0 && ![abc accountExistsLocal:[abc getLastAccessedAccount])
//        [LocalSettings controller].cachedUsername = self.arrayAccounts[0];
//
    [self updateUsernameSelector:[abc getLastAccessedAccount]];

    if (bPINModeEnabled)
    {
        self.textBitcoinWalletHeight.constant = 0;
        self.credentialsPINView.hidden = false;
        self.credentialsView.hidden = true;
        self.userEntryView.hidden = true;
        [self.passwordTextField resignFirstResponder];
        [self.usernameSelector.textField resignFirstResponder];
//        [self.PINCodeView becomeFirstResponder];
        [self.PINTextField becomeFirstResponder];
    }
    else
    {
        self.textBitcoinWalletHeight.constant = _originalTextBitcoinWalletHeight;
        self.credentialsPINView.hidden = true;
        self.credentialsView.hidden = false;
        self.userEntryView.hidden = false;
        [self.passwordTextField resignFirstResponder];
        [self.usernameSelector.textField resignFirstResponder];
        [self.PINTextField resignFirstResponder];
//        [self.PINCodeView resignFirstResponder];
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
        [self.view.superview layoutIfNeeded];
        self.usernameHeight.constant = _originalUsernameHeight;
        self.passwordHeight.constant = _originalPasswordHeight;
        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeFast
                              delay:[Theme Singleton].animationDelayTimeDefault
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
                         {
                             self.usernameSelector.textField.hidden = false;
                             self.forgotPassworddButton.hidden = false;
                             [self.view.superview layoutIfNeeded];
                         }
                         completion:^(BOOL finished)
                         {
                         }];
    }


    UITapGestureRecognizer *debug = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(uploadLog)];
    debug.numberOfTapsRequired = 5;
    [_logoImage addGestureRecognizer:debug];
    [_logoImage setUserInteractionEnabled:YES];

    if (HARD_CODED_LOGIN)
    {
        self.usernameSelector.textField.text = HARD_CODED_LOGIN_NAME;
        self.passwordTextField.text = HARD_CODED_LOGIN_PASSWORD;
    }
}

- (void)applicationEnteredForeground:(NSNotification *)notification {
//    [self autoReloginOrTouchIDIfPossible];

}

- (void)uploadLog {
    [self resignAllResponders];
    NSString *title = uploadLogText;
    NSString *message = enterAnyNotesForSupportStaff;
    // show password reminder test
    _uploadLogAlert = [[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:cancelButtonText
                                           otherButtonTitles:uploadLogText, nil];
    _uploadLogAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_uploadLogAlert show];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    //
    // Check if Disclaimer has ever been displayed on this device. If not, display it now
    //
    if (![LocalSettings controller].bDisclaimerViewed)
    {
        [self.passwordTextField resignFirstResponder];
        [self.usernameSelector.textField resignFirstResponder];
        [self.PINTextField resignFirstResponder];
//        [self.PINCodeView resignFirstResponder];

        self.disclaimerInfoView = [InfoView CreateWithHTML:@"info_disclaimer" forView:self.view agreeButton:YES delegate:self];
    }
    else
    {
        if (!_bDisallowTouchID)
            [self autoReloginOrTouchIDIfPossible];
    }
    
}

#pragma InfoViewDelegate
- (void) InfoViewFinished:(InfoView *)infoView
{
    [infoView removeFromSuperview];
    if (infoView == self.disclaimerInfoView)
    {
        [LocalSettings controller].bDisclaimerViewed = YES;
        [LocalSettings saveAll];
    }
    if (bPINModeEnabled)
        [self.PINTextField becomeFirstResponder];
    else
        [self.PINTextField resignFirstResponder];

    [self autoReloginOrTouchIDIfPossible];
}

- (void)autoReloginOrTouchIDIfPossible
{
    [self resignAllResponders];
    
    _bNewDeviceLogin = NO;

    [abc autoReloginOrTouchIDIfPossible:[abc getLastAccessedAccount] delegate:[MainViewController Singleton] doBeforeLogin:^{
        [self showSpinner:YES];
        [MainViewController showBackground:YES animate:YES];
    } completionWithLogin:^(ABCAccount *user, BOOL usedTouchID) {
        _bUsedTouchIDToLogin = usedTouchID;
        [self signInComplete:user newAccount:NO];
    } completionNoLogin:^{
        [self assignFirstResponder];
    } error:^(NSError *error) {
        [self showSpinner:NO];
        [MainViewController showBackground:NO animate:YES];
        [MainViewController fadingAlert:error.userInfo[NSLocalizedDescriptionKey]];
        [self assignFirstResponder];
    }];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [self dismissErrorMessage];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    self.PINCodeView.PINCode = nil;
    self.PINTextField.text = nil;
    _tempPin = nil;
    _tempPassword = nil;
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - FadingAlertView delegate

- (void)fadingAlertDismissedNew
{
    if (bPINModeEnabled)
        [self.PINTextField becomeFirstResponder];
    else
        [self.PINTextField resignFirstResponder];
}



#pragma mark - Action Methods

- (IBAction)PINTextFieldChanged:(id)sender
{
    if ([self.PINTextField.text length] >= 4)
    {
        [self.PINTextField resignFirstResponder];
        [self showSpinner:YES];
        [self SignInPIN:self.PINTextField.text];

    }
}

- (IBAction)Back
{
    //spring out
    [MainViewController moveSelectedViewController:-self.view.frame.size.width];
    [self.view layoutIfNeeded];

    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
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

- (IBAction)OutsideTapButton:(id)sender {
    [self.PINusernameSelector close];
    [self.usernameSelector dismissPopupPicker];
    self.buttonOutsideTap.enabled = NO;
}

- (IBAction)FingerprintButton:(id)sender {
    [self autoReloginOrTouchIDIfPossible];
}

#pragma mark - Misc Methods

- (void)updateUsernameSelector:(NSString *)username
{
    [self setUsernameText:username];
    NSMutableArray *stringArray = [[NSMutableArray alloc] init];
    [self getAllAccounts];
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
    if (!username || 0 == username.length)
    {
        if (self.arrayAccounts && [self.arrayAccounts count] > 0)
            username = self.arrayAccounts[0];
    }
    
    if (username && username.length)
    {
        //
        // Set the PIN username default
        //
        UIFont *boldFont = [UIFont fontWithName:@"Lato-Regular" size:[Theme Singleton].fontSizeEnterPINText];
        UIFont *regularFont = [UIFont fontWithName:@"Lato-Regular" size:[Theme Singleton].fontSizeEnterPINText];
        NSString *title = [NSString stringWithFormat:@"%@",
                           username];        // Define general attributes like color and fonts for the entire text
        NSDictionary *attr = @{NSForegroundColorAttributeName:ColorPinEntryText,
                               NSFontAttributeName:regularFont};
        NSMutableAttributedString *attributedText = [ [NSMutableAttributedString alloc]
                                                     initWithString:title
                                                     attributes:attr];
        // blue and bold text attributes
        NSRange usernameTextRange = [title rangeOfString:username];
        [attributedText setAttributes:@{NSForegroundColorAttributeName:ColorPinEntryUsernameText,
                                        NSFontAttributeName:boldFont}
                                range:usernameTextRange];
        [self.PINusernameSelector.button setAttributedTitle:attributedText forState:UIControlStateNormal];

        //
        // Set the regular username field
        //
        self.usernameSelector.textField.text = username;
    }
//    self.passwordTextField.text = abcAccount.password;

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

//        _bSuccess = NO;
        [self showSpinner:YES];
        [MainViewController showBackground:YES animate:YES];
        _bNewDeviceLogin = ![abc accountExistsLocal:self.usernameSelector.textField.text];
        ABCLog(1, @"_bNewDeviceLogin=%d", (int) _bNewDeviceLogin);

        [abc loginWithPassword:self.usernameSelector.textField.text
                      password:self.passwordTextField.text
                      delegate:[MainViewController Singleton]
                           otp:nil callback:^(ABCError *error, ABCAccount *account)
        {
            if (!error)
            {
                [self signInComplete:account newAccount:NO];
            }
            else
            {
                [self showSpinner:NO];
                
                if (ABCConditionCodeInvalidOTP == error.code)
                {
                    [MainViewController showBackground:NO animate:YES];
                    [self launchTwoFactorMenu:error.otpResetDate token:error.otpResetToken];
                }
                else if (ABCConditionCodeError == error.code)
                {
                    [MainViewController fadingAlert:anErrorOccurredNetworkOrIncorrectPassword];
                    [MainViewController showBackground:NO animate:YES];
                }
                else
                {
                    [MainViewController showBackground:NO animate:YES];
                    [MainViewController fadingAlert:error.userInfo[NSLocalizedDescriptionKey]];
                }
            }
        }];
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
        _signupManager.strInUserName = nil;
        [MainViewController animateFadeOut:self.view];

        [_signupManager startSignup];

    }];
}

- (IBAction)buttonForgotTouched:(id)sender
{
    [self launchRecoveryPopup:self.usernameSelector.textField.text recoveryToken:nil];
}

- (void) launchRecoveryPopup:(NSString *)username recoveryToken:(NSString *)recoveryToken
{
    [self.usernameSelector.textField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self.PINTextField resignFirstResponder]; 
    
    if (recoveryToken)
        _recoveryToken = recoveryToken;
    
    _bDisallowTouchID = YES;
    _recoverPasswordAlert = [[UIAlertView alloc] initWithTitle:passwordRecoveryText
                                                     message:enter_username_to_recover
                                                    delegate:self
                                           cancelButtonTitle:cancelButtonText
                                           otherButtonTitles:nextButtonText, nil];
    _recoverPasswordAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    if ([username length])
    {
        UITextField *textField = [_recoverPasswordAlert textFieldAtIndex:0];
        textField.text = username;
    }
    [_recoverPasswordAlert show];
}

- (void)recoverPassword:(NSString *)username
{
    [self dismissErrorMessage];
    [self.usernameSelector.textField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];

    // if they have a username
    if (username)
    {
        ABCError *error;
        NSString *recoveryToken;
        
        // Check if recovery token was passed in via URL
        if (_recoveryToken)
        {
            recoveryToken = _recoveryToken;
            _recoveryToken = nil;
        }
        
        if (!recoveryToken)
        {
            // Second check to see if user has a recovery2 token on the device
            recoveryToken = [abc getRecovery2Token:username error:&error];
        }
        if (recoveryToken)
        {
            // Next check if they have recovery1 set on the server
            [self showSpinner:YES];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                ABCError *error;
                NSArray *arrayQuestions = [abc getRecovery2Questions:username
                                                       recoveryToken:recoveryToken
                                                               error:&error];
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self showSpinner:NO];
                    [self launchQuestionRecovery:username questions:arrayQuestions recoveryToken:recoveryToken error:error];
                });
            });
        }
        else
        {
            // Next check if they have recovery1 set on the server
            [self showSpinner:YES];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                ABCError *error;
                NSArray *arrayQuestions = [abc getRecoveryQuestionsForUserName:self.usernameSelector.textField.text
                                                                         error:&error];
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self showSpinner:NO];
                    [self launchQuestionRecovery:username questions:arrayQuestions recoveryToken:nil error:error];
                });
            });
        }
        
    }
    else
    {
        [MainViewController fadingAlert:pleaseEnterAUsername];
    }
}



- (IBAction)buttonLoginWithPasswordTouched:(id)sender
{
    [self dismissErrorMessage];
    bPINModeEnabled = false;

    [self viewDidLoad];
    [self viewWillAppear:true];
}


- (void)launchQuestionRecovery:(NSString *)username questions:(NSArray *)arrayQuestions recoveryToken:(NSString *)recoveryToken error:(ABCError *)error;
{
    if (!error && arrayQuestions)
    {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
        _passwordRecoveryController = [mainStoryboard instantiateViewControllerWithIdentifier:@"PasswordRecoveryViewController"];

        _passwordRecoveryController.delegate = self;
        _passwordRecoveryController.mode = PassRecovMode_Recover;
        _passwordRecoveryController.arrayQuestions = arrayQuestions;
        _passwordRecoveryController.strUserName = username;
        _passwordRecoveryController.numQABlocks = (int)[arrayQuestions count];
        _passwordRecoveryController.useRecovery2 = !!recoveryToken;
        _passwordRecoveryController.recoveryToken = recoveryToken;

        [MainViewController showNavBarAnimated:YES];
        [Util addSubviewControllerWithConstraints:self child:_passwordRecoveryController];
        [MainViewController animateSlideIn:_passwordRecoveryController];
//        [MainViewController animateView:_passwordRecoveryController withBlur:NO];
    }
    else
    {
        if (error && error.code != ABCConditionCodeNoRecoveryQuestions)
            [MainViewController fadingAlert:error.userInfo[NSLocalizedDescriptionKey]];
        else
        {
            if (recoveryToken)
            {
                [MainViewController fadingAlert:recovery_token_invalid holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
            }
            else
            {
                [MainViewController fadingAlert:recovery_not_setup holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP notify:nil complete:^{
                    [MainViewController fadingAlert:recovery_not_setup2 holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP notify:nil complete:^{
                        [MainViewController fadingAlert:recovery_not_setup3 holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP notify:nil complete:^{
                        }];
                    }];
                }];
            }
        }
    }
}

#pragma mark - ReLogin Methods

- (void)SignInPIN:(NSString *)pin
{
    [MainViewController showBackground:YES animate:YES];

    [abc
     pinLogin:[abc getLastAccessedAccount]
     pin:pin
     delegate:[MainViewController Singleton] complete:^(ABCAccount *user) {
         [User login:user];
         [self.delegate LoginViewControllerDidPINLogin];
         [MainViewController showWalletsLoadingAlert];
         
         if ([abcAccount shouldAskUserToEnableTouchID])
         {
             //
             // Ask if they want TouchID enabled for this user on this device
             //
             NSString *title = enableTouchIDText;
             NSString *message = wouldYouLikeToEnableTouchID;
             _enableTouchIDAlertView = [[UIAlertView alloc] initWithTitle:title
                                                                  message:message
                                                                 delegate:self
                                                        cancelButtonTitle:laterButtonText
                                                        otherButtonTitles:okButtonText, nil];
             _enableTouchIDAlertView.alertViewStyle = UIAlertViewStyleDefault;
             [_enableTouchIDAlertView show];
         }
         [self showSpinner:NO];
         self.PINTextField.text = nil;
         
     } error:^(NSError *error) {
         
         [MainViewController showBackground:NO animate:YES];
         [self.PINTextField becomeFirstResponder];
         [self showSpinner:NO];
         self.PINTextField.text = nil;
         
         if (ABCConditionCodeBadPassword == error.code ||
             ABCConditionCodeInvalidPinWait == error.code)
         {
             [MainViewController fadingAlert:error.userInfo[NSLocalizedDescriptionKey]];
             [self.PINTextField becomeFirstResponder];
         }
         else if (ABCConditionCodeInvalidOTP == error.code)
         {
             [MainViewController showBackground:NO animate:YES];
             [self launchTwoFactorMenu:nil token:nil];
         }
         else
         {
             NSString *reason;
             // Core doesn't return anything specific for the case where network is down.
             // Make up a better response in this case
             if (ABCConditionCodeError == error.code)
                 reason = pinLoginErrorText;
             else
                 reason = error.userInfo[NSLocalizedDescriptionKey];
             
             [MainViewController fadingAlert:reason];
         }
     }];
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
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeSlow
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
         [UIView animateWithDuration:[Theme Singleton].animationDurationTimeSlow
                               delay:[Theme Singleton].animationDelayTimeDefault
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

    //ABCLog(2,@"Keyboard will show for SignUpView");
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
        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeFast
                              delay:[Theme Singleton].animationDelayTimeDefault
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^
        {
                 if(self.usernameSelector.textField.isEditing)
                 {
                     [self getAllAccounts];
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
        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeFast
                              delay:[Theme Singleton].animationDelayTimeDefault
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

        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeSlow
                              delay:[Theme Singleton].animationDelayTimeDefault
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

        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeSlow
                              delay:[Theme Singleton].animationDelayTimeDefault
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
        ABCLog(2,@"XXX error. should not happen");
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

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.PINTextField)
    {
        NSString *editedString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        textField.text = editedString;
        if ([textField.text length] >= 4)
        {
            [textField resignFirstResponder];
            [self showSpinner:YES];
            [self SignInPIN:textField.text];
        }
        return NO;
    }
    return YES;
}

- (void)signInComplete:(ABCAccount *)user newAccount:(BOOL)bNewAccount
{
    [self showSpinner:NO];

    self.passwordTextField.text = nil;
    [User login:user];
    [self.delegate loginViewControllerDidLogin:bNewAccount newDevice:_bNewDeviceLogin usedTouchID:_bUsedTouchIDToLogin];
    
    if (bNewAccount) return;
    
    [MainViewController showWalletsLoadingAlert];

    if ([abcAccount shouldAskUserToEnableTouchID])
    {
        //
        // Ask if they want TouchID enabled for this user on this device
        //
        NSString *title = enableTouchIDText;
        NSString *message = wouldYouLikeToEnableTouchID;
        _enableTouchIDAlertView = [[UIAlertView alloc] initWithTitle:title
                                                             message:message
                                                            delegate:self
                                                   cancelButtonTitle:laterButtonText
                                                   otherButtonTitles:okButtonText, nil];
        _enableTouchIDAlertView.alertViewStyle = UIAlertViewStyleDefault;
        [_enableTouchIDAlertView show];
    }
}

- (void)launchTwoFactorMenu:(NSDate *)resetDate token:(NSString *)resetToken;
{
    _tfaMenuViewController = (TwoFactorMenuViewController *)[Util animateIn:@"TwoFactorMenuViewController" storyboard:@"Settings" parentController:self];
    _tfaMenuViewController.delegate = self;
    _tfaMenuViewController.username = self.usernameSelector.textField.text;
    _tfaMenuViewController.bStoreSecret = NO;
    _tfaMenuViewController.bTestSecret = NO;
    _tfaMenuViewController.resetDate = resetDate;
    _tfaMenuViewController.resetToken = resetToken;
    
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
        [MainViewController showBackground:YES animate:YES];
        _bNewDeviceLogin = ![abc accountExistsLocal:self.usernameSelector.textField.text];
        ABCLog(1, @"_bNewDeviceLogin=%d", (int) _bNewDeviceLogin);

        // Perform the two factor sign in
        [abc loginWithPassword:self.usernameSelector.textField.text
                      password:self.passwordTextField.text
                      delegate:[MainViewController Singleton]
                           otp:secret
                      callback:^(ABCError *error, ABCAccount *account)
        {
            if (!error)
            {
                [self signInComplete:account newAccount:NO];
            }
            else
            {
                [self showSpinner:NO];
                if (ABCConditionCodeError == error.code)
                    [MainViewController fadingAlert:anErrorOccurredNetworkOrIncorrectPassword];
                else
                    [MainViewController fadingAlert:error.userInfo[NSLocalizedDescriptionKey]];
            }
        }];
    }];
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

        [MainViewController showBackground:YES animate:YES];
        [self signInComplete:abcAccount newAccount:bNewAccount];
    }
}

- (void)getAllAccounts
{
    NSError *error;
    self.arrayAccounts = [abc listUsernames:&error];
    if (error)
    {
        [MainViewController fadingAlert:error.userInfo[NSLocalizedDescriptionKey]];
    }
}

#pragma mark - PickerTextView delegates

- (void)pickerTextViewPopupSelected:(PickerTextView *)pickerTextView onRow:(NSInteger)row
{
    [self.usernameSelector.textField resignFirstResponder];
    [self.usernameSelector dismissPopupPicker];
    self.buttonOutsideTap.enabled = NO;
    
    // set the text field to the choice
    NSString *account = [self.arrayAccounts objectAtIndex:row];
    if([abc pinLoginEnabled:account error:nil])
    {
        [abc setLastAccessedAccount:account];
        bPINModeEnabled = true;
        [self viewDidLoad];
        [self viewWillAppear:true];
        [self autoReloginOrTouchIDIfPossible];
    }
    else
    {
        self.usernameSelector.textField.text = account;
        [self.usernameSelector dismissPopupPicker];
        [self autoReloginOrTouchIDIfPossible];
    }
}

- (void)removeAccount:(NSString *)account
{
    NSError *error = [abc deleteLocalAccount:account];
    if (!error)
    {
        NSString *username = [abc getLastAccessedAccount];
        [self updateUsernameSelector:username];
        
        if (!username)
            [self buttonLoginWithPasswordTouched:nil];
    }
    else
    {
        [MainViewController fadingAlert:error.userInfo[NSLocalizedDescriptionKey]];
    }
}

- (void)pickerTextViewDidTouchAccessory:(PickerTextView *)pickerTextView categoryString:(NSString *)string
{
    [self deleteAccountPopup:string];
    [self.usernameSelector dismissPopupPicker];
    self.buttonOutsideTap.enabled = NO;
}

- (void)deleteAccountPopup:(NSString *)acct;
{
    NSString *warningText;
    if ([abc accountHasPassword:acct error:nil])
        warningText = deleteAccountWarning;
    else
        warningText = deleteAccountNoPasswordWarningText;
    
    _accountToDelete = acct;
    NSString *message = [NSString stringWithFormat:warningText, acct];
    _deleteAccountAlert = [[UIAlertView alloc]
                          initWithTitle:deleteAccountText
                          message:message
                          delegate:self
                          cancelButtonTitle:noButtonText
                          otherButtonTitles:yesButtonText, nil];
    [_deleteAccountAlert show];
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
    self.buttonOutsideTap.enabled = YES;

}

- (void)pickerTextViewFieldDidChange:(PickerTextView *)pickerTextView;
{
    //
    // Do not show popup if user has text in the field
    //
    if ([pickerTextView.textField.text length] > 0)
    {
        [pickerTextView dismissPopupPicker];
        self.buttonOutsideTap.enabled = NO;
    }
    else if ([pickerTextView.textField.text length] == 0)
    {
        [pickerTextView createPopupPicker];
        self.buttonOutsideTap.enabled = YES;
    }
}

- (void)pickerTextViewFieldDidEndEditing:(PickerTextView *)pickerTextView;
{
    [pickerTextView dismissPopupPicker];
    self.buttonOutsideTap.enabled = NO;
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView == _enableTouchIDAlertView)
    {
        if (0 == buttonIndex)
        {
            [abcAccount.settings disableTouchID];
        }
        else
        {
            if ([abcAccount accountHasPassword])
                [abcAccount.settings enableTouchID];
            else
            {
                [self showPasswordCheckAlertForTouchID];
            }
        }

        return;
    }
    else if (alertView == _recoverPasswordAlert)
    {
        if (1 == buttonIndex)
        {
            UITextField *textField = [_recoverPasswordAlert textFieldAtIndex:0];
            [self recoverPassword:textField.text];
        }
        _bDisallowTouchID = NO;
    }
    else if (alertView == _passwordCheckAlert)
    {
        if (0 == buttonIndex)
        {
            //
            // Need to disable TouchID in settings.
            //
            // Disable TouchID in LocalSettings
            [abcAccount.settings disableTouchID];
            [MainViewController fadingAlert:touchIDDisabled];
        }
        else
        {
            //
            // Check the password
            //
            _tempPassword = [[alertView textFieldAtIndex:0] text];
            [FadingAlertView create:self.view
                            message:checkingPasswordText
                           holdTime:FADING_ALERT_HOLD_TIME_FOREVER_WITH_SPINNER notify:^(void) {
                if ([abcAccount.settings enableTouchID:_tempPassword])
                {
                    _tempPassword = nil;
                    [MainViewController fadingAlert:touchIDEnabledText];
                    
                    
                }
                else
                {
                    [MainViewController fadingAlertDismiss];
                    _tempPassword = nil;
                    _passwordIncorrectAlert = [[UIAlertView alloc]
                                               initWithTitle:incorrectPasswordText
                                               message:tryAgainText
                                               delegate:self
                                               cancelButtonTitle:noButtonText
                                               otherButtonTitles:yesButtonText, nil];
                    [_passwordIncorrectAlert show];
                }
            }];
        }
        return;
    }
    else if (_passwordIncorrectAlert == alertView)
    {
        if (buttonIndex == 0)
        {
            [MainViewController fadingAlert:touchIDDisabled];
            [abcAccount.settings disableTouchID];
        }
        else if (buttonIndex == 1)
        {
            [self showPasswordCheckAlertForTouchID];
        }
    }
    else if (_uploadLogAlert == alertView)
    {
        if (1 == buttonIndex)
        {
            [_logoImage setUserInteractionEnabled:NO];
            _spinnerView.hidden = NO;
            [abc uploadLogs:[[alertView textFieldAtIndex:0] text] complete:^
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:debugLogFileText
                                                                message:uploadSuccessfulText
                                                               delegate:self
                                                      cancelButtonTitle:okButtonText
                                                      otherButtonTitles:nil];
                [alert show];
                [_logoImage setUserInteractionEnabled:YES];
                _spinnerView.hidden = YES;
                [self assignFirstResponder];
            } error:^(NSError *error)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:debugLogFileText
                                                                message:uploadFailedText
                                                               delegate:self
                                                      cancelButtonTitle:okButtonText
                                                      otherButtonTitles:nil];
                [alert show];
                [_logoImage setUserInteractionEnabled:YES];
                _spinnerView.hidden = YES;
                [self assignFirstResponder];
            }];
        }
        [self assignFirstResponder];
    }
    else if (_deleteAccountAlert == alertView)
    {
        [self.usernameSelector.textField resignFirstResponder];
        // if they said they wanted to delete the account
        if (buttonIndex == 1)
        {
            [self removeAccount:_accountToDelete];
            self.usernameSelector.textField.text = @"";
            [self.usernameSelector dismissPopupPicker];
        }
    }
}

- (void)resignAllResponders
{
    [self.passwordTextField resignFirstResponder];
    [self.usernameSelector.textField resignFirstResponder];
    [self.PINTextField resignFirstResponder];
}

- (void)assignFirstResponder
{
    if (bPINModeEnabled)
    {
        [self.PINTextField becomeFirstResponder];
    }
    else
    {
        if (_mode != MODE_NO_USERS)
        {
            if ([self.usernameSelector.textField.text length] > 0)
            {
                [self.passwordTextField becomeFirstResponder];
            }
            else
            {
                [self.usernameSelector.textField becomeFirstResponder];
            }
        }
    }
}

- (void)showPasswordCheckAlertForTouchID
{
    // Popup to ask user for their password
    NSString *title = touchIDText;
    NSString *message = enterYourPasswordToEnableTouchID;
    // show password reminder test
    _passwordCheckAlert = [[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:laterButtonText
                                           otherButtonTitles:okButtonText, nil];
    _passwordCheckAlert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [_passwordCheckAlert show];
}

- (void)handlePasswordResults:(NSNumber *)authenticated
{
}


#pragma mark - ButtonSelectorView delegates

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
    [abc setLastAccessedAccount:[self.otherAccounts objectAtIndex:itemIndex]];
    if([abc pinLoginEnabled:[abc getLastAccessedAccount] error:nil])
    {
        [self updateUsernameSelector:[abc getLastAccessedAccount]];
        [self autoReloginOrTouchIDIfPossible];
    }
    else
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self viewDidLoad];
            [self viewWillAppear:true];
            [self autoReloginOrTouchIDIfPossible];
        }];
    }
}

- (void)ButtonSelectorWillShowTable:(ButtonSelectorView *)view
{
    [self.PINusernameSelector.textLabel resignFirstResponder];
    [self.PINTextField resignFirstResponder];
    self.buttonOutsideTap.enabled = YES;

}

- (void)ButtonSelectorWillHideTable:(ButtonSelectorView *)view
{
    [self.PINTextField becomeFirstResponder];
    self.buttonOutsideTap.enabled = NO;

}

- (void)ButtonSelectorDidTouchAccessory:(ButtonSelectorView *)selector accountString:(NSString *)string
{
    [self deleteAccountPopup:string];
    [self.PINTextField becomeFirstResponder];
}


+ (void)setModePIN:(BOOL)enable
{
    if (enable)
        bPINModeEnabled = true;
    else
        bPINModeEnabled = false;

}

@end

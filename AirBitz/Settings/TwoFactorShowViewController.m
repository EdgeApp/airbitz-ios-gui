
#import "TwoFactorShowViewController.h"
#import "TwoFactorMenuViewController.h"
#import "NotificationChecker.h"
#import "MinCharTextField.h"
#import "FadingAlertView.h"
#import "ABC.h"
#import "CoreBridge.h"
#import "Util.h"
#import "User.h"

@interface TwoFactorShowViewController () <UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, TwoFactorMenuViewControllerDelegate>
{
    NSString                    *_secret;
    TwoFactorMenuViewController *_tfaMenuViewController;
    FadingAlertView             *_fadingAlert;
    BOOL                        isOn;
    long                        timeout;
}

@property (nonatomic, weak) IBOutlet UIScrollView            *scrollView;
@property (nonatomic, weak) IBOutlet MinCharTextField        *passwordTextField;
@property (nonatomic, weak) IBOutlet UIButton                *buttonImport;
@property (nonatomic, weak) IBOutlet UIView                  *requestView;
@property (nonatomic, weak) IBOutlet UIButton                *buttonApprove;
@property (nonatomic, weak) IBOutlet UIButton                *buttonCancel;
@property (nonatomic, weak) IBOutlet UISwitch                *tfaEnabledSwitch;
@property (nonatomic, weak) IBOutlet UIImageView             *qrCodeImageView;
@property (nonatomic, weak) IBOutlet UIView                  *viewQRCodeFrame;
@property (nonatomic, weak) IBOutlet UIView                  *loadingSpinner;
@property (nonatomic, weak) IBOutlet UILabel                 *onOffLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *requestSpinner;

@end

@implementation TwoFactorShowViewController

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

    CGSize size = CGSizeMake(_scrollView.frame.size.width, _scrollView.frame.size.height);
    _scrollView.contentSize = size;
    [self initUI];
}

- (void)initUI
{
    _passwordTextField.text = @"";
    _passwordTextField.delegate = self;
    _passwordTextField.minimumCharacters = ABC_MIN_PASS_LENGTH;
    _passwordTextField.delegate = self;
    _passwordTextField.returnKeyType = UIReturnKeyDone;

    isOn = NO;
    [self updateTwoFactorUi:NO];
    _loadingSpinner.hidden = NO;

    // Check for any pending reset requests
    [self checkStatus:NO];
}

- (void)checkStatus:(BOOL)bMsg
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self doCheckStatus:bMsg];
    });
}

- (void)doCheckStatus:(BOOL)bMsg
{
    tABC_Error Error;
    BOOL on = NO;
    long timeout = 0;
    tABC_CC cc = ABC_StatusTwoFactor([[User Singleton].name UTF8String],
            [[User Singleton].password UTF8String], &on, &timeout, &Error);
    if (cc == ABC_CC_Ok) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            isOn = on;
            [self updateTwoFactorUi:isOn == true];
            [self checkSecret:bMsg];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            isOn = on;
            [self updateTwoFactorUi:NO];
            [self showFadingAlert:NSLocalizedString(@"Unable to determine two factor status", nil)];
        });
    }
}

- (void)checkSecret:(BOOL)bMsg
{
    char *szSecret = NULL;
    _secret = nil;
    tABC_Error error;
    if (isOn) {
        tABC_CC cc = ABC_GetTwoFactorSecret([[User Singleton].name UTF8String],
            [[User Singleton].password UTF8String], &szSecret, &error);
        if (cc == ABC_CC_Ok && szSecret) {
            _secret = [NSString stringWithUTF8String:szSecret];
        } else {
            _secret = nil;
            _viewQRCodeFrame.hidden = YES;
        }
        if (szSecret) {
            free(szSecret);
            _requestSpinner.hidden = NO;
        }
    }
    [self showQrCode:isOn];

    if (_secret != nil) {
        _requestSpinner.hidden = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [self checkRequest];
        });
        if (bMsg) {
            [self showFadingAlert:NSLocalizedString(@"Two Factor Enabled", nil)];
        }
    } else {
        if (bMsg) {
            [self showFadingAlert:NSLocalizedString(@"Two Factor Disabled", nil)];
        }
    }
}

- (void)showQrCode:(BOOL)show
{
    if (show) {
        unsigned char *pData = NULL;
        unsigned int width;

        tABC_Error error;
        tABC_CC cc = ABC_GetTwoFactorQrCode([[User Singleton].name UTF8String],
            [[User Singleton].password UTF8String], &pData, &width, &error);
        if (cc == ABC_CC_Ok) {
            UIImage *qrImage = [Util dataToImage:pData withWidth:width andHeight:width];
            _qrCodeImageView.image = qrImage;
            _qrCodeImageView.layer.magnificationFilter = kCAFilterNearest;
            [self animateQrCode:YES];
        } else {
            _viewQRCodeFrame.hidden = YES;
        }
        if (pData) {
            free(pData);
        }
    } else {
        [self animateQrCode:NO];
    }
}
- (void)animateQrCode:(BOOL)show
{
    if (show) {
        if (_viewQRCodeFrame.hidden) {
            _viewQRCodeFrame.hidden = NO;
            _viewQRCodeFrame.alpha = 0;
            [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^ {
                _viewQRCodeFrame.alpha = 1.0;
            } completion:^(BOOL finished) {
            }];
        }
    } else {
        if (!_viewQRCodeFrame.hidden) {
            _viewQRCodeFrame.alpha = 1;
            [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^ {
                _viewQRCodeFrame.alpha = 0;
            } completion:^(BOOL finished) {
                _viewQRCodeFrame.hidden = YES;
            }];
        }
    }
}

- (void)checkRequest
{
    tABC_Error error;
    BOOL pending = [self isResetPending:&error];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (error.code == ABC_CC_Ok) {
            _requestView.hidden = !pending;
        } else {
            _requestView.hidden = YES;
            [self showFadingAlert:[Util errorMap:&error]];
        }
        _requestSpinner.hidden = YES;
    });
}

- (BOOL)isResetPending:(tABC_Error *)error
{
    BOOL bPending = NO;
    const char *szUsernames = NULL;
    tABC_CC cc = ABC_IsTwoFactorResetPending(&szUsernames, error);
    if (cc == ABC_CC_Ok) {
        bPending = [[[NSString alloc] initWithUTF8String:szUsernames] containsString:[User Singleton].name];
    }
    return bPending;
}

#pragma mark - Keyboard Notifications

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Action Methods

- (IBAction)switchFlipped:(UISwitch *)uiSwitch
{
    [self checkPasswordAsync:@selector(handleSwitchFlip:)];
}

- (void)checkPasswordAsync:(SEL)selector
{
    if (!_passwordTextField.text || [_passwordTextField.text length] == 0) {
        [self performSelectorOnMainThread:selector
                            withObject:[NSNumber numberWithBool:NO]
                            waitUntilDone:NO];
    } else {
        _loadingSpinner.hidden = NO;
        [_passwordTextField resignFirstResponder];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            BOOL matched = [CoreBridge passwordOk:_passwordTextField.text];
            [self performSelectorOnMainThread:selector
                                withObject:[NSNumber numberWithBool:matched]
                                waitUntilDone:NO];
        });
    }
}

- (void)invalidPasswordAlert
{
    UIAlertView *alert = [[UIAlertView alloc]
                        initWithTitle:NSLocalizedString(@"Incorrect password", nil)
                        message:NSLocalizedString(@"Incorrect password", nil)
                        delegate:self
                        cancelButtonTitle:@"Cancel"
                        otherButtonTitles:@"OK", nil];
    [alert show];
}

- (void)handleSwitchFlip:(NSNumber *)authenticated
{
    _loadingSpinner.hidden = YES;
    BOOL bAuthenticated = [authenticated boolValue];
    if (bAuthenticated) {
        [self switchTwoFactor:_tfaEnabledSwitch.on];
    } else {
        [_passwordTextField becomeFirstResponder];
        _tfaEnabledSwitch.on = !_tfaEnabledSwitch.on;
        _loadingSpinner.hidden = YES;
        [self invalidPasswordAlert];
    }
}

- (void)updateTwoFactorUi:(BOOL)on
{
    if (on) {
        _requestView.hidden = YES;
        _requestView.hidden = YES;
        _requestSpinner.hidden = YES;
        _buttonImport.hidden = NO;
    } else {
        _requestView.hidden = YES;
        _requestView.hidden = YES;
        _requestSpinner.hidden = YES;
        _viewQRCodeFrame.hidden = YES;
        _buttonImport.hidden = YES;
    }
    [self setText:on];
    _tfaEnabledSwitch.on = on;
    _loadingSpinner.hidden = YES;
}

- (void)setText:(BOOL)on
{
    if (on) {
        _onOffLabel.text = NSLocalizedString(@"Enabled", nil);
    } else {
        _onOffLabel.text = NSLocalizedString(@"Disabled", nil);
    }
}

- (void)switchTwoFactor:(BOOL)on
{
    tABC_Error error;
    tABC_CC cc;
    if (on) {
        cc = [self enableTwoFactor:&error];
    } else {
        cc = [self disableTwoFactor:&error];
    }
    [self updateTwoFactorUi:on];
    [self checkSecret:YES];
}

- (tABC_CC)enableTwoFactor:(tABC_Error *)error
{
    tABC_CC cc = ABC_EnableTwoFactor([[User Singleton].name UTF8String],
        [[User Singleton].password UTF8String], &error);
    if (cc == ABC_CC_Ok) {
        isOn = YES;
    }
    return cc;
}

- (tABC_CC)disableTwoFactor:(tABC_Error *)error
{
    tABC_CC cc = ABC_DisableTwoFactor([[User Singleton].name UTF8String],
        [[User Singleton].password UTF8String], &error);
    if (cc == ABC_CC_Ok) {
        _secret = nil;
        isOn = NO;
    }
    return cc;
}

- (IBAction)Back:(id)sender
{
    [self exitWithBackButton:YES];
}

- (IBAction)Import:(id)sender
{
    _tfaMenuViewController = (TwoFactorMenuViewController *)[Util animateIn:@"TwoFactorMenuViewController" parentController:self];
    _tfaMenuViewController.delegate = self;
    _tfaMenuViewController.bStoreSecret = YES;
    [self initUI];
}

- (IBAction)confirmRequest:(id)sender
{
    [NotificationChecker resetOtpNotifications];
    [self checkPasswordAsync:@selector(doConfirmRequest:)];
}

- (void)doConfirmRequest:(NSNumber *)object
{
    BOOL authenticated = [object boolValue];
    if (authenticated) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            tABC_Error error;
            tABC_CC cc = [self disableTwoFactor:&error];
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if (cc == ABC_CC_Ok) {
                    [self showFadingAlert:NSLocalizedString(@"Request confirmed, Two Factor off.", nil)];
                    [self updateTwoFactorUi:NO];
                } else {
                    [self showFadingAlert:[Util errorMap:&error]];
                }
                _loadingSpinner.hidden = YES;
            });

        });
    } else {
        [self invalidPasswordAlert];
        _loadingSpinner.hidden = YES;
    }
}

- (IBAction)cancelRequest:(id)sender
{
    [NotificationChecker resetOtpNotifications];
    [self checkPasswordAsync:@selector(doCancelRequest:)];
}

- (void)doCancelRequest:(NSNumber *)object
{
    BOOL authenticated = [object boolValue];
    if (authenticated) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            tABC_Error Error;
            tABC_CC cc = ABC_CancelTwoFactorReset([[User Singleton].name UTF8String],
                                                [[User Singleton].password UTF8String],
                                                &Error);
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if (cc == ABC_CC_Ok) {
                    [self showFadingAlert:NSLocalizedString(@"Reset Cancelled", nil)];
                    _requestView.hidden = YES;
                } else {
                    [self showFadingAlert:[Util errorMap:&Error]];
                }
                _loadingSpinner.hidden = YES;
            });
        });
    } else {
        [self invalidPasswordAlert];
        _loadingSpinner.hidden = YES;
    }
}

#pragma mark - TwoFactorMenuViewControllerDelegate

- (void)twoFactorMenuViewControllerDone:(TwoFactorMenuViewController *)controller withBackButton:(BOOL)bBack
{
    BOOL success = controller.bSuccess;
    [Util animateOut:controller parentController:self complete:^(void) {
        _tfaMenuViewController = nil;
    }];
    if (!bBack && !success) {
        [self showFadingAlert:NSLocalizedString(@("Unable to import secret"), nil)];
    }
    [self checkStatus:success];
}

#pragma mark - Misc Methods

- (void)showFadingAlert:(NSString *)message
{
    _fadingAlert = [FadingAlertView CreateInsideView:self.view withDelegate:nil];
    _fadingAlert.message = message;
    _fadingAlert.fadeDelay = 2;
    _fadingAlert.fadeDuration = 1;
    [_fadingAlert showFading];
}

- (void)dismissErrorMessage
{
    [_fadingAlert dismiss:NO];
    _fadingAlert = nil;
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
    [self dismissErrorMessage];
    [self.delegate twoFactorShowViewControllerDone:self withBackButton:bBack];
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

/* vim:set ft=objc sw=4 ts=4 et: */

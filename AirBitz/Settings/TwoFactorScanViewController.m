
#import "TwoFactorScanViewController.h"
#import "MinCharTextField.h"
#import "ScanView.h"
#import "User.h"
#import "Util.h"
#import "ABC.h"
#import "CoreBridge.h"

@interface TwoFactorScanViewController () 
    <UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate,
    ScanViewDelegate, FadingAlertViewDelegate>
{
    ScanView        *_scanView;
    UIAlertView     *_alertView;
    FadingAlertView *_fadingAlert;
}

@property (nonatomic, weak) IBOutlet UIView             *scanViewHolder;

@end

@implementation TwoFactorScanViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _bSuccess = NO;
        _bStoreSecret = NO;
        _bTestSecret = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _scanView = [ScanView CreateView:_scanViewHolder];
    _scanView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_scanView startQRReader];
}

- (void)viewWillDisappear:(BOOL)animated
{
#if !TARGET_IPHONE_SIMULATOR
	[_scanView stopQRReader];
#endif
}

- (IBAction)Back:(id)sender
{
    [self exitWithBackButton:YES];
}

#pragma mark - Misc Methods

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
    [self.delegate twoFactorScanViewControllerDone:self withBackButton:bBack];
}

#pragma mark - ScanView Delegate

- (BOOL)processResultArray:(NSArray *)results
{
    if (results && [results count] > 0) {
        _secret = results[0];
        if (_bStoreSecret) {
            _bSuccess = [self storeSecret];
        } else {
            _bSuccess = YES;
        }
        if (_bTestSecret) {
            [self testSecret];
        } else {
            [self exit];
        }
        return YES;
    } else {
        // TODO: unable to parse...
        return NO;
    }
}

- (BOOL)storeSecret
{
    tABC_Error Error;
    tABC_CC cc = ABC_OtpKeySet([[User Singleton].name UTF8String], [_secret UTF8String], &Error);
    return cc == ABC_CC_Ok;
}

- (void)testSecret
{
    dispatch_async(dispatch_get_main_queue(), ^ {
        if (YES) {
            [self exit];
        } else {
            _alertView = [[UIAlertView alloc]
                            initWithTitle:NSLocalizedString(@"Unable to import token", nil)
                            message:NSLocalizedString(@"The two factor authentication token import failed. Please ensure you have the correct token!", nil)
                            delegate:self
                            cancelButtonTitle:NSLocalizedString(@"No thanks", nil)
                            otherButtonTitles:NSLocalizedString(@"Try Again?", nil), nil];
            [_alertView show];
        }
    });
}

#pragma mark - ABC Alert delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    _alertView = nil;
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
    [self exit];
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

#pragma mark - Fading Alert Methods

- (void)showFadingAlert:(NSString *)message
{
    _fadingAlert = [FadingAlertView CreateInsideView:self.view withDelegate:self];
    _fadingAlert.message = message;
    _fadingAlert.fadeDelay = 2;
    _fadingAlert.fadeDuration = 1;
    [_fadingAlert blockModal:NO];
    [_fadingAlert showFading];
}

- (void)dismissErrorMessage
{
    [_fadingAlert dismiss:NO];
    _fadingAlert = nil;
}

- (void)fadingAlertDismissed:(FadingAlertView *)view
{
    _fadingAlert = nil;
}

@end

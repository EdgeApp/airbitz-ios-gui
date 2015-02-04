
#import "TwoFactorMenuViewController.h"
#import "TwoFactorScanViewController.h"
#import "MinCharTextField.h"
#import "ScanView.h"
#import "User.h"
#import "Util.h"
#import "ABC.h"
#import "CoreBridge.h"

@interface TwoFactorMenuViewController ()
    <UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate,
    TwoFactorScanViewControllerDelegate, FadingAlertViewDelegate>
{
    FadingAlertView             *_fadingAlert;
    TwoFactorScanViewController *_tfaScanViewController;
}

@property (nonatomic, weak) IBOutlet UIButton *buttonReset;
@property (nonatomic, weak) IBOutlet UIButton *buttonScan;

@end

@implementation TwoFactorMenuViewController

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
}

- (IBAction)Back:(id)sender
{
    [self exitWithBackButton:YES];
}

- (IBAction)Scan:(id)sender
{
    _tfaScanViewController = (TwoFactorScanViewController *)[Util animateIn:@"TwoFactorScanViewController" parentController:self];
    _tfaScanViewController.delegate = self;
    _tfaScanViewController.bStoreSecret = _bStoreSecret;
    _tfaScanViewController.bTestSecret = _bTestSecret;
}

- (IBAction)Reset:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        tABC_Error error;
        tABC_CC cc = ABC_RequestTwoFactorReset([[User Singleton].name UTF8String],
            [[User Singleton].password UTF8String], &error);
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (cc == ABC_CC_Ok) {
                [self showFadingAlert:NSLocalizedString(@"Reset requested.", nil)];
            } else {
                [self showFadingAlert:[Util errorMap:&error]];
            }
        });
    });
}

- (void)twoFactorScanViewControllerDone:(TwoFactorScanViewController *)controller withBackButton:(BOOL)bBack
{
    _secret = controller.secret;
    _bSuccess = controller.bSuccess;
    if (!bBack) {
        [self exit];
    } else {
        [Util animateOut:controller parentController:self complete:^(void) {
            _tfaScanViewController = nil;
        }];
    }
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
    [self.delegate twoFactorMenuViewControllerDone:self withBackButton:bBack];
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

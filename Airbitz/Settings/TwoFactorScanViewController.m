
#import "TwoFactorScanViewController.h"
#import "MinCharTextField.h"
#import "ScanView.h"
#import "User.h"
#import "Util.h"
#import "AirbitzCore.h"
#import "MainViewController.h"
#import "Theme.h"
#import "FadingAlertView.h"

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willRotate:) name:NOTIFICATION_ROTATION_CHANGED object:nil];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBarTitle:self title:twoFactorText];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Back:) fromObject:self];
    [MainViewController changeNavBar:self title:importText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
    [_scanView startQRReader];
}

- (void)willRotate:(NSNotification *)notification
{
    NSDictionary *dictData = [notification userInfo];
    NSNumber *orientation = [dictData objectForKey:KEY_ROTATION_ORIENTATION];

    [_scanView willRotateOrientation:[orientation intValue]];
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
    NSError *error = [abc setOTPKey:abcAccount.name key:_secret];
    return !error;
}

- (void)testSecret
{
    dispatch_async(dispatch_get_main_queue(), ^ {
//        if (YES) {
            [self exit];
//        } else {
//            _alertView = [[UIAlertView alloc]
//                            initWithTitle:NSLocalizedString(@"Unable to import token", nil)
//                            message:NSLocalizedString(@"The two factor authentication token import failed. Please ensure you have the correct token!", nil)
//                            delegate:self
//                            cancelButtonTitle:NSLocalizedString(@"No thanks", nil)
//                            otherButtonTitles:NSLocalizedString(@"Try Again?", nil), nil];
//            [_alertView show];
//        }
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

@end

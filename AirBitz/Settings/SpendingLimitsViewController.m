
#import "SpendingLimitsViewController.h"
#import "MinCharTextField.h"
#import "CommonTypes.h"
#import "CoreBridge.h"
#import "User.h"
#import "Util.h"
#import "ABC.h"

@interface SpendingLimitsViewController () <UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>
{
	tABC_AccountSettings            *_pAccountSettings;
}

@property (nonatomic, weak) IBOutlet MinCharTextField           *passwordTextField;
@property (nonatomic, weak) IBOutlet UIButton                   *buttonComplete;
@property (nonatomic, weak) IBOutlet UISwitch                   *dailySpendLimitSwitch;
@property (nonatomic, weak) IBOutlet UITextField                *dailySpendLimitField;
@property (nonatomic, weak) IBOutlet UILabel                    *dailyDenomination;

@property (nonatomic, weak) IBOutlet UISwitch                   *pinSpendLimitSwitch;
@property (nonatomic, weak) IBOutlet UITextField                *pinSpendLimitField;
@property (nonatomic, weak) IBOutlet UILabel                    *pinDenomination;

@end

@implementation SpendingLimitsViewController

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
	self.passwordTextField.delegate = self;
    self.passwordTextField.minimumCharacters = ABC_MIN_PASS_LENGTH;

    // put the cursor in the user name field
    [self.passwordTextField becomeFirstResponder];

    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];

    _pAccountSettings = NULL;
    tABC_Error Error;
    ABC_LoadAccountSettings([[User Singleton].name UTF8String],
                            [[User Singleton].password UTF8String],
                            &_pAccountSettings,
                            &Error);
    [Util printABC_Error:&Error];

    if (_pAccountSettings->bDailySpendLimit > 0) {
        _dailySpendLimitField.text = [CoreBridge formatSatoshi:_pAccountSettings->dailySpendLimitSatoshis withSymbol:false];
        _dailySpendLimitSwitch.on = YES;
    } else {
        _dailySpendLimitSwitch.on = NO;
    }
    if (_pAccountSettings->bDailySpendLimit > 0) {
        _pinSpendLimitField.text = [CoreBridge formatSatoshi:_pAccountSettings->spendRequirePinSatoshis withSymbol:false];
        _pinSpendLimitSwitch.on = YES;
    } else {
        _pinSpendLimitSwitch.on = NO;
    }
    _dailySpendLimitField.enabled = _dailySpendLimitSwitch.on;
    _pinSpendLimitField.enabled = _pinSpendLimitSwitch.on;

    _dailyDenomination.text = [User Singleton].denominationLabelShort;
    _pinDenomination.text = [User Singleton].denominationLabelShort;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action Methods

-(IBAction)Back:(id)sender
{
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = self.view.frame;
		 frame.origin.x = frame.size.width;
		 self.view.frame = frame;
	 }
	completion:^(BOOL finished)
	 {
		 [self exitWithBackButton:YES];
	 }];
}

- (IBAction)Complete:(id)sender
{
    if ([[User Singleton].password isEqualToString:_passwordTextField.text]) {
        if (_dailySpendLimitSwitch.on) {
            _pAccountSettings->bDailySpendLimit = 1;
            _pAccountSettings->dailySpendLimitSatoshis = [CoreBridge denominationToSatoshi:_dailySpendLimitField.text];
        } else {
            _pAccountSettings->bDailySpendLimit = 0;
        }

        if (_pinSpendLimitSwitch.on) {
            _pAccountSettings->bSpendRequirePin = 1;
            _pAccountSettings->spendRequirePinSatoshis = [CoreBridge denominationToSatoshi:_pinSpendLimitField.text];
        } else {
            _pAccountSettings->bSpendRequirePin = 0;
        }

        tABC_Error Error;
        ABC_UpdateAccountSettings([[User Singleton].name UTF8String],
                                [[User Singleton].password UTF8String],
                                _pAccountSettings,
                                &Error);
        if (ABC_CC_Ok == Error.code) {
            [[User Singleton] loadSettings];
        } else {
            UIAlertView *alert = [[UIAlertView alloc]
                                initWithTitle:NSLocalizedString(@"Unable to update Settings", nil)
                                message:[Util errorMap:&Error]
                                delegate:self
                                cancelButtonTitle:@"Cancel"
                                otherButtonTitles:@"OK", nil];
            [alert show];
            [Util printABC_Error:&Error];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                            initWithTitle:NSLocalizedString(@"Incorrect password", nil)
                            message:NSLocalizedString(@"Incorrect password", nil)
                            delegate:self
                            cancelButtonTitle:@"Cancel"
                            otherButtonTitles:@"OK", nil];
        [alert show];
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
    if (_pAccountSettings)
    {
        ABC_FreeAccountSettings(_pAccountSettings);
    }
	[self.delegate spendingLimitsViewControllerDone:self withBackButton:bBack];
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


#import "SpendingLimitsViewController.h"
#import "MinCharTextField.h"
#import "CommonTypes.h"
#import "CoreBridge.h"
#import "InfoView.h"
#import "User.h"
#import "Util.h"
#import "ABC.h"

@interface SpendingLimitsViewController () <UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, InfoViewDelegate>
{
    tABC_AccountSettings            *_pAccountSettings;
}

@property (nonatomic, weak) IBOutlet MinCharTextField           *passwordTextField;
@property (nonatomic, weak) IBOutlet UIButton                   *buttonComplete;
@property (nonatomic, weak) IBOutlet UISwitch                   *dailySpendLimitSwitch;
@property (nonatomic, weak) IBOutlet UITextField                *dailySpendLimitField;
@property (nonatomic, weak) IBOutlet UILabel                    *dailyDenomination;
@property (nonatomic, weak) IBOutlet UIScrollView               *scrollView;

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

    CGSize size = CGSizeMake(_scrollView.frame.size.width, _scrollView.frame.size.height);
    self.scrollView.contentSize = size;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

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

    _dailySpendLimitSwitch.on = _pAccountSettings->bDailySpendLimit > 0;
    _dailySpendLimitField.text = [CoreBridge formatSatoshi:_pAccountSettings->dailySpendLimitSatoshis withSymbol:false];
    _dailySpendLimitField.keyboardType = UIKeyboardTypeDecimalPad;
    _dailyDenomination.text = [User Singleton].denominationLabelShort;

    _pinSpendLimitSwitch.on = _pAccountSettings->bSpendRequirePin > 0;
    _pinSpendLimitField.text = [CoreBridge formatSatoshi:_pAccountSettings->spendRequirePinSatoshis withSymbol:false];
    _pinSpendLimitField.keyboardType = UIKeyboardTypeDecimalPad;
    _pinDenomination.text = [User Singleton].denominationLabelShort;

    [self switchFlipped:_dailySpendLimitSwitch];
    [self switchFlipped:_pinSpendLimitSwitch];

    _passwordTextField.delegate = self;
    _passwordTextField.returnKeyType = UIReturnKeyDone;
    _dailySpendLimitField.delegate = self;
    _dailySpendLimitField.returnKeyType = UIReturnKeyDone;
    _pinSpendLimitField.delegate = self;
    _pinSpendLimitField.returnKeyType = UIReturnKeyDone;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    CGSize size = CGSizeMake(_scrollView.frame.size.width, _scrollView.frame.size.height);
    size.height += keyboardFrame.size.height;
    self.scrollView.contentSize = size;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    CGSize size = CGSizeMake(_scrollView.frame.size.width, _scrollView.frame.size.height);
    self.scrollView.contentSize = size;
}

#pragma mark - Keyboard Delegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (nil != self.delegate)
    {
        if (NSOrderedSame == [string compare:@"."] && [textField.text rangeOfString:@"."].location != NSNotFound)
        {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Action Methods

-(IBAction)switchFlipped:(UISwitch *)uiSwitch
{
    UITextField *field = nil;
    UILabel *denom = nil;
    UIColor *color = uiSwitch.on ? [UIColor whiteColor] : [UIColor lightGrayColor];
    if (uiSwitch == _pinSpendLimitSwitch) {
        field = _pinSpendLimitField;
        denom = _pinDenomination;
    } else if (uiSwitch == _dailySpendLimitSwitch) {
        field = _dailySpendLimitField;
        denom = _dailyDenomination;
    }
    if (field) {
        field.enabled = uiSwitch.on;
        field.textColor = color;
        denom.textColor = color;
    }
}

-(IBAction)Back:(id)sender
{
    [self exitWithBackButton:YES];
}

- (IBAction)Complete:(id)sender
{
    if ([CoreBridge passwordOk:_passwordTextField.text]) {
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
        [self exitWithBackButton:YES];
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

- (IBAction)info
{
	[self.view endEditing:YES];
    [InfoView CreateWithHTML:@"infoSpendingLimits" forView:self.view];
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

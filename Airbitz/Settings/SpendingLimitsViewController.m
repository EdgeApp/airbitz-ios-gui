
#import "SpendingLimitsViewController.h"
#import "MinCharTextField.h"
#import "CommonTypes.h"
#import "AirbitzCore.h"
#import "InfoView.h"
#import "User.h"
#import "Util.h"
#import "FadingAlertView.h"
#import "MainViewController.h"
#import "Theme.h"

#define IPHONE4_SCROLL_OFFSET 45

@interface SpendingLimitsViewController () <UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, InfoViewDelegate>
{
    UITextField                     *_currentTextField;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *viewContentTop;
@property (nonatomic, weak) IBOutlet MinCharTextField           *passwordTextField;
@property (nonatomic, weak) IBOutlet UIButton                   *buttonComplete;
@property (nonatomic, weak) IBOutlet UISwitch                   *dailySpendLimitSwitch;
@property (nonatomic, weak) IBOutlet UITextField                *dailySpendLimitField;
@property (nonatomic, weak) IBOutlet UILabel                    *dailyDenomination;
//@property (nonatomic, weak) IBOutlet UIScrollView               *scrollView;

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
    self.passwordTextField.minimumCharacters = [AirbitzCore getMinimumPasswordLength];
    if (![abcAccount passwordExists]) {
        self.passwordTextField.hidden = YES;
    }

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    // put the cursor in the user name field
//    [self.passwordTextField becomeFirstResponder];

    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];

    _dailySpendLimitSwitch.on = [User Singleton].bDailySpendLimit;
    _dailySpendLimitField.text = [abcAccount.settings.denomination satoshiToBTCString:[User Singleton].dailySpendLimitSatoshis withSymbol:false];
    _dailySpendLimitField.keyboardType = UIKeyboardTypeDecimalPad;
    _dailyDenomination.text = abcAccount.settings.denomination.symbol;

    _pinSpendLimitSwitch.on = abcAccount.settings.bSpendRequirePin > 0;
    _pinSpendLimitField.text = [abcAccount.settings.denomination satoshiToBTCString:abcAccount.settings.spendRequirePinSatoshis withSymbol:false];
    _pinSpendLimitField.keyboardType = UIKeyboardTypeDecimalPad;
    _pinDenomination.text = abcAccount.settings.denomination.symbol;

    [self switchFlipped:_dailySpendLimitSwitch];
    [self switchFlipped:_pinSpendLimitSwitch];

    _passwordTextField.delegate = self;
    _passwordTextField.returnKeyType = UIReturnKeyDone;
    _dailySpendLimitField.delegate = self;
    _dailySpendLimitField.returnKeyType = UIReturnKeyDone;
    _pinSpendLimitField.delegate = self;
    _pinSpendLimitField.returnKeyType = UIReturnKeyDone;
}

- (void)viewWillAppear:(BOOL)animated
{
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
    [keyboardDoneButtonView sizeToFit];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStylePlain target:self
                                                                  action:@selector(doneClicked:)];
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:leftButton, flex, doneButton, nil]];
    self.pinSpendLimitField.inputAccessoryView = keyboardDoneButtonView;
    self.dailySpendLimitField.inputAccessoryView = keyboardDoneButtonView;
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBarTitle:self title:@"Spending Limits"];

    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Back:) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(info) fromObject:self];

}

- (IBAction)doneClicked:(id)sender
{
    ABCLog(2,@"Done Clicked.");
    [self.view endEditing:YES];
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
    CGFloat offset;

    if(_currentTextField)
    {
        offset = _currentTextField.frame.origin.y + _currentTextField.frame.size.height + 5 - keyboardFrame.origin.y;

        if (offset > 0)
        {
            [UIView animateWithDuration:0.35
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^
                             {
                                 self.viewContentTop.constant -= offset;
                                 [self.view layoutIfNeeded];
                             }
                             completion:^(BOOL finished)
                             {
                             }];

        }
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
                     {
                         self.viewContentTop.constant = 0;
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished)
                     {
                     }];
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

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    _currentTextField = textField;
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
    [Util checkPasswordAsync:_passwordTextField.text withSelector:@selector(doComplete:) controller:self];
}

- (void)doComplete:(NSNumber *)authenticated
{
    BOOL bAuthenticated = [authenticated boolValue];
    if (bAuthenticated) {
        if (_dailySpendLimitSwitch.on) {
            [User Singleton].bDailySpendLimit = YES;
            [User Singleton].dailySpendLimitSatoshis = [abcAccount.settings.denomination btcStringToSatoshi:_dailySpendLimitField.text];
        } else {
            [User Singleton].bDailySpendLimit = NO;
        }

        if (_pinSpendLimitSwitch.on) {
            abcAccount.settings.bSpendRequirePin = true;
            abcAccount.settings.spendRequirePinSatoshis = [abcAccount.settings.denomination btcStringToSatoshi:_pinSpendLimitField.text];
        } else {
            abcAccount.settings.bSpendRequirePin = false;
        }
        [[User Singleton] saveLocalSettings];
        NSError *error = [abcAccount.settings saveSettings];
        if (error)
        {
            UIAlertView *alert =
                    [[UIAlertView alloc]
                            initWithTitle:NSLocalizedString(@"Unable to update Settings", nil)
                                  message:error.userInfo[NSLocalizedDescriptionKey]
                                 delegate:self
                        cancelButtonTitle:cancelButtonText
                        otherButtonTitles:okButtonText, nil];
            [alert show];
        }
        [self exitWithBackButton:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                            initWithTitle:NSLocalizedString(@"Incorrect password", nil)
                            message:NSLocalizedString(@"Incorrect password", nil)
                            delegate:self
                            cancelButtonTitle:cancelButtonText
                            otherButtonTitles:okButtonText, nil];
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

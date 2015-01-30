
#import "TwoFactorShowViewController.h"

@interface TwoFactorShowViewController () <UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, InfoViewDelegate>
{
}

@property (nonatomic, weak) IBOutlet MinCharTextField           *passwordTextField;
@property (nonatomic, weak) IBOutlet UIButton                   *buttonComplete;
@property (nonatomic, weak) IBOutlet UIButton                   *buttonApprove;
@property (nonatomic, weak) IBOutlet UIButton                   *buttonCancel;
@property (nonatomic, weak) IBOutlet UISwitch                   *tfaEnabledSwitch;

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
    self.passwordTextField.delegate = self;
    self.passwordTextField.minimumCharacters = ABC_MIN_PASS_LENGTH;

    _passwordTextField.delegate = self;
    _passwordTextField.returnKeyType = UIReturnKeyDone;
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Action Methods

-(IBAction)switchFlipped:(UISwitch *)uiSwitch
{
}

-(IBAction)Back:(id)sender
{
    [self exitWithBackButton:YES];
}

- (IBAction)Complete:(id)sender
{
    if ([CoreBridge passwordOk:_passwordTextField.text]) {
        if (_tfaEnabledSwitch.on) {
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

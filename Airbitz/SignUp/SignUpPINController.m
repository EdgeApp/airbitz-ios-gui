//
//  SignUpPINController.m
//  AirBitz
//

#import "SignUpPINController.h"
#import "MinCharTextField.h"
#import "Util.h"
#import "User.h"
#import "MainViewController.h"
#import "Theme.h"
#import "LocalSettings.h"
#import "FadingAlertView.h"
#import "Mixpanel.h"

#define KEYBOARD_MARGIN         10.0

@interface SignUpPINController () <UITextFieldDelegate>
{
}

@property (nonatomic, weak) IBOutlet MinCharTextField           *pinTextField;
@property (nonatomic, weak) IBOutlet UIView                     *masterView;
@property (nonatomic, weak) IBOutlet UIView                     *contentView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint         *contentStartConstraint;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView    *activityView;
@property (nonatomic, strong)   UIButton                        *buttonBlocker;
@property (nonatomic)           CGFloat                         contentViewY;
@property (nonatomic, copy)     NSString                        *labelString;
@property (nonatomic, assign)   BOOL                            bSuccess;
@property (nonatomic, copy)     NSString                        *strReason;
@property (weak, nonatomic) IBOutlet UILabel                    *pinTextLabel;
@property (weak, nonatomic) IBOutlet UILabel                    *setPasswordLabel;


@end

@implementation SignUpPINController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pinTextField.delegate = self;
    self.pinTextField.minimumCharacters = [ABCContext getMinimumPINLength];
    self.contentViewY = self.contentView.frame.origin.y;

    self.labelString = signupText;
}

-(void)viewWillAppear:(BOOL)animated
{
    [[Mixpanel sharedInstance] track:@"SUP-PIN-Enter"];
    [self.pinTextField addTarget:self action:@selector(pinTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];

    [self.pinTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // ABCLog(2,@"%s", __FUNCTION__);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action Methods

- (void)next
{

    if ([self fieldsAreValid])
    {
        self.manager.strPIN = self.pinTextField.text;
        [self.pinTextField resignFirstResponder];
        [super next];
    }
    else
    {
        [[Mixpanel sharedInstance] track:@"SUP-PIN-invalid"];
    }
}


// checks the pin field
// returns YES if field is good
// if the field is bad, an appropriate message box is displayed
// note: this function is aware of the 'mode' of the view controller and will check and display appropriately
- (BOOL)fieldsAreValid
{
    BOOL valid = YES;
    {
        // if the pin isn't long enough
        if (self.pinTextField.text.length < [ABCContext getMinimumPINLength])
        {
            valid = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                    initWithTitle:self.labelString
                          message:[NSString stringWithFormat:pinOrPasswordCheckFailedFormatString,
                                                             self.labelString,
                                                             [NSString stringWithFormat:pingMustBeXXXDigitsFormatString, [ABCContext getMinimumPINLength]]]
                         delegate:nil
                cancelButtonTitle:okButtonText
                otherButtonTitles:nil];
            [alert show];
        }
    }

    return valid;
}

#pragma mark - UITextField delegates

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;   // return NO to not change text
{
    if (textField == self.pinTextField)
    {
        NSString *newString = [[string componentsSeparatedByCharactersInSet:
                                [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                               componentsJoinedByString:@""];
        if (![newString isEqualToString:string])
        {
            [MainViewController fadingAlert:PINOnlyNumbersText holdTime:FADING_ALERT_HOLD_TIME_DEFAULT];
            return NO;
        }
    }
    return YES;
}

- (void)pinTextFieldChanged:(UITextField *)textField
{
    if (textField.text.length == 4)
    {
        [textField resignFirstResponder];
    }
}

@end

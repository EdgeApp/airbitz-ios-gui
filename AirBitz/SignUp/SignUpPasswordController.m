//
//  SignUpPasswordController.m
//  AirBitz
//

#import "SignUpPasswordController.h"
#import "MinCharTextField.h"
#import "PasswordVerifyView.h"
#import "ABC.h"
#import "Util.h"

#define KEYBOARD_MARGIN         10.0
#define PASSWORD_VERIFY_FRAME_Y_OFFSET 20

@interface SignUpPasswordController () <UITextFieldDelegate, PasswordVerifyViewDelegate>
{
    UITextField                     *_activeTextField;
    PasswordVerifyView              *_passwordVerifyView;
    FadingAlertView                 *_fadingAlert;
    float                           _keyboardFrameOriginY;

}

@property (nonatomic, weak) IBOutlet MinCharTextField *passwordTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField *reenterPasswordTextField;
@property (nonatomic, weak) IBOutlet MinCharTextField *pinTextField;
@property (nonatomic, weak) IBOutlet UIView                     *masterView;
@property (nonatomic, weak) IBOutlet UIView                     *contentView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView    *activityView;
@property (nonatomic, strong)   UIButton                        *buttonBlocker;
@property (nonatomic)           CGFloat                         contentViewY;



@end

@implementation SignUpPasswordController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.passwordTextField.delegate = self;
    self.passwordTextField.minimumCharacters = ABC_MIN_PASS_LENGTH;
    self.reenterPasswordTextField.delegate = self;
    self.reenterPasswordTextField.minimumCharacters = ABC_MIN_PASS_LENGTH;
    self.pinTextField.delegate = self;
    self.pinTextField.minimumCharacters = ABC_MIN_PIN_LENGTH;
    self.contentViewY = self.contentView.frame.origin.y;

}

-(void)viewWillAppear:(BOOL)animated
{
    //NSLog(@"Adding keyboard notification");
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self.pinTextField addTarget:self action:@selector(pinTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordTextField addTarget:self action:@selector(passwordTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    
    // Only needed for old SignUpViewController which is multipurpose. Used when changing password or PIN
//    [self updateDisplayForMode:_mode];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // NSLog(@"%s", __FUNCTION__);
    
    //NSLog(@"Removing keyboard notification");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)blockUser:(BOOL)bBlock
{
    if (bBlock)
    {
        [self.activityView startAnimating];
        self.buttonBlocker.hidden = NO;
    }
    else
    {
        [self.activityView stopAnimating];
        self.buttonBlocker.hidden = YES;
    }
}

-(void)scrollTextFieldAboveKeyboard:(UITextField *)textField
{
    if(_keyboardFrameOriginY) //set when keyboard is visible
    {
        CGRect textFieldFrame = [self.contentView convertRect:textField.frame toView:self.view.window];

        float overlap = _keyboardFrameOriginY - (textFieldFrame.origin.y + textFieldFrame.size.height + KEYBOARD_MARGIN);

        if(overlap < 0)
        {
            [UIView animateWithDuration:0.35
                                  delay: 0.0
                                options: UIViewAnimationOptionCurveEaseInOut
                             animations:^
             {
                 CGRect frame = self.contentView.frame;
                 frame.origin.y += overlap;
                 self.contentView.frame = frame;
             }
                             completion:^(BOOL finished)
             {
                 
             }];
        }
    }
}


#pragma mark - keyboard callbacks

- (void)keyboardWillShow:(NSNotification *)notification
{
    //Get KeyboardFrame (in Window coordinates)
    if(_activeTextField)
    {
        //NSLog(@"Keyboard will show for SignUpView");
        NSDictionary *userInfo = [notification userInfo];
        CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        
        _keyboardFrameOriginY = keyboardFrame.origin.y;
        
        [self scrollTextFieldAboveKeyboard:_activeTextField];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if(_activeTextField)
    {
        //NSLog(@"Keyboard will hide for SignUpView");
        _activeTextField = nil;
    }
    _keyboardFrameOriginY = 0.0;
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         CGRect frame = self.contentView.frame;
         frame.origin.y = self.contentViewY;
         self.contentView.frame = frame;
     }
                     completion:^(BOOL finished)
     {
     }];
}

#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //called when user taps on either search textField or location textField
    
    //NSLog(@"TextField began editing");
    _activeTextField = textField;
    if(textField == self.passwordTextField)
    {
        if(_passwordVerifyView == nil)
        {
            _passwordVerifyView = [PasswordVerifyView CreateInsideView:self.masterView withDelegate:self];
            CGRect frame = _passwordVerifyView.frame;
            frame.origin.y += PASSWORD_VERIFY_FRAME_Y_OFFSET;
            _passwordVerifyView.frame = frame;
        }
        _passwordVerifyView.password = textField.text;
    }
    else
    {
        if(_passwordVerifyView)
        {
            [_passwordVerifyView dismiss];
        }
    }
    //won't do anything when a textField is tapped for the first time and no keyboard is visible because
    //keyboardFrameOriginY isn't set yet (doestn' get set until KeyboardWillShow notification which occurs after this
    //method is called.  But -scrollTextFieldAboveKeyboard gets called from the KeyboardWillShow notification
    [self scrollTextFieldAboveKeyboard:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
        UIView *view = [self.contentView viewWithTag:textField.tag + 1];
        if (view)
        {
            [view becomeFirstResponder];
        }
        else
        {
            [textField resignFirstResponder];
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

- (void)passwordTextFieldChanged:(UITextField *)textField
{
    if (_passwordVerifyView == nil)
    {
        _passwordVerifyView = [PasswordVerifyView CreateInsideView:self.masterView withDelegate:self];
    }
    _passwordVerifyView.password = textField.text;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(_activeTextField)
    {
        
        if(_activeTextField == self.passwordTextField)
        {
            if(_passwordVerifyView)
            {
                [_passwordVerifyView dismiss];
            }
        }
        [_activeTextField resignFirstResponder];
    }
}

#pragma mark - PasswordVerifyViewDelegates

- (void)PasswordVerifyViewDismissed:(PasswordVerifyView *)pv
{
    [_passwordVerifyView removeFromSuperview];
    _passwordVerifyView = nil;
}


@end

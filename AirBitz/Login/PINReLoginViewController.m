//
//  PINReLoginViewController.m
//  AirBitz
//
//  Created by Allan Wright on 11/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "PINReLoginViewController.h"
#import "ButtonSelectorView.h"
#import "User.h"
#import "Util.h"
#import "CoreBridge.h"
#import "CommonTypes.h"
#import "LocalSettings.h"
#import "APPINView.h"
#import "Theme.h"

@interface PINReLoginViewController () <APPINViewDelegate, ButtonSelectorDelegate, FadingAlertViewDelegate>
{
    CGRect   _originalContentFrame;
    CGRect   _originalLogoFrame;
    CGRect   _originalRightSwipeArrowFrame;
    CGPoint  _firstTouchPoint;
    BOOL     _bTouchesEnabled;
    NSString                        *_account;
    NSUInteger _invalidEntryCount;
    FadingAlertView                 *_fadingAlert;
}
@property (nonatomic, weak) IBOutlet UIView      *contentView;

@property (nonatomic, weak) IBOutlet UIButton    *backButton;
@property (nonatomic, weak) IBOutlet UIImageView *swipeRightArrow;
@property (nonatomic, weak) IBOutlet UILabel     *swipeText;
@property (nonatomic, weak) IBOutlet UIImageView *logoImage;
@property (nonatomic, weak) IBOutlet UIView      *spinnerView;
@property (nonatomic, weak) IBOutlet UIView		 *errorMessageView;
@property (nonatomic, weak) IBOutlet UILabel	 *errorMessageText;
@property (weak, nonatomic) IBOutlet APPINView   *PINCodeView;
@property (nonatomic, weak) IBOutlet ButtonSelectorView     *usernameSelector;

@property (nonatomic, strong) NSArray   *arrayAccounts;
@property (nonatomic, strong) NSArray   *otherAccounts;

@end

@implementation PINReLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _originalContentFrame = self.contentView.frame;
    _originalLogoFrame = self.logoImage.frame;
    _originalRightSwipeArrowFrame = _swipeRightArrow.frame;

    self.spinnerView.hidden = YES;

	self.errorMessageView.alpha = 0.0;
    
    self.PINCodeView.delegate = self;
    self.usernameSelector.delegate = self;
    [self.usernameSelector.button setBackgroundImage:nil forState:UIControlStateNormal];
    [self.usernameSelector.button setBackgroundImage:nil forState:UIControlStateSelected];
    self.usernameSelector.textLabel.text = NSLocalizedString(@"", @"username");
    [self.usernameSelector setButtonWidth:_originalLogoFrame.size.width];
    self.usernameSelector.accessoryImage = [UIImage imageNamed:@"btn_close.png"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self animateSwipeArrowWithRepetitions:3 andDelay:1.0 direction:1 arrow:_swipeRightArrow origFrame:_originalRightSwipeArrowFrame];
    
    [self getAllAccounts];
    [self updateUsernameSelector:[LocalSettings controller].cachedUsername];

    _bTouchesEnabled = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.PINCodeView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self dismissErrorMessage];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.PINCodeView.PINCode = nil;
    [super viewWillDisappear:animated];
}

#pragma mark - APPINViewDelegate Methods

- (void)PINCodeView:(APPINView *)view didEnterPIN:(NSString *)PINCode
{
    [self showSpinner:YES];
    [self signIn:PINCode];
}

#pragma mark - Action Methods

- (IBAction)Back
{
    [self dismissErrorMessage];

    //spring out
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         CGRect frame = self.view.frame;
         if(frame.origin.x < 0)
         {
             frame.origin.x = -frame.size.width;
         }
         else
         {
             frame.origin.x = frame.size.width;
         }
         self.view.frame = frame;
     }
                     completion:^(BOOL finished)
     {
         [self.delegate PINReLoginViewControllerDidAbort];
     }];
}

- (IBAction)buttonSwitchUserTouched:(id)sender
{
    [self dismissErrorMessage];
    [self.delegate PINReLoginViewControllerDidSwitchUserWithMessage:nil];
}

- (IBAction)buttonForgotTouched:(id)sender
{
    [self dismissErrorMessage];
    [self.delegate PINReLoginViewControllerDidSwitchUserWithMessage:nil];
}

#pragma mark - Misc Methods

- (void)getAllAccounts
{
        char * pszUserNames;
        tABC_Error error;
        __block tABC_CC result = ABC_ListAccounts(&pszUserNames, &error);
            switch (result)
            {
                case ABC_CC_Ok:
                {
                    NSString *str = [NSString stringWithCString:pszUserNames encoding:NSUTF8StringEncoding];
                    NSArray *arrayAccounts = [str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                    NSMutableArray *stringArray = [[NSMutableArray alloc] init];
                    for(NSString *str in arrayAccounts)
                    {
                        if(str && str.length!=0)
                        {
                            [stringArray addObject:str];
                        }
                    }
                    self.arrayAccounts = [stringArray copy];
                    break;
                }
                default:
                {
                    tABC_Error temp;
                    temp.code = result;
                    [self showFadingError:[Util errorMap:&temp]];
                    break;
                }
            }
}

- (void)updateUsernameSelector:(NSString *)username
{
    [self setUsernameText:username];
    NSMutableArray *stringArray = [[NSMutableArray alloc] init];
    for(NSString *str in self.arrayAccounts)
    {
        if(![str isEqualToString:username])
        {
            [stringArray addObject:str];
        }
    }
    self.otherAccounts = [stringArray copy];
    self.usernameSelector.arrayItemsToSelect = self.otherAccounts;
}

- (void)setUsernameText:(NSString *)username
{
    NSString *title = [NSString stringWithFormat:@"Enter PIN for (%@)",
                       username];
    // Define general attributes like color and fonts for the entire text
    NSDictionary *attr = @{NSForegroundColorAttributeName:self.usernameSelector.button.titleLabel.textColor,
                           NSFontAttributeName:self.usernameSelector.button.titleLabel.font};
    NSMutableAttributedString *attributedText = [ [NSMutableAttributedString alloc]
                                                 initWithString:title
                                                 attributes:attr];
    // blue and bold text attributes
    UIColor *color = [UIColor colorWithRed:60./255. green:140.5/255. blue:200/255. alpha:1.];
    UIFont *boldFont = [UIFont boldSystemFontOfSize:self.usernameSelector.button.titleLabel.font.pointSize];
    NSRange usernameTextRange = [title rangeOfString:username];
    [attributedText setAttributes:@{NSForegroundColorAttributeName:color,
                                    NSFontAttributeName:boldFont}
                            range:usernameTextRange];
    [self.usernameSelector.button setAttributedTitle:attributedText forState:UIControlStateNormal];
}

- (void)animateSwipeArrowWithRepetitions:(int)repetitions
                                andDelay:(float)delay
                               direction:(int)dir
                                   arrow:(UIView *)swipeArrow
                               origFrame:(CGRect)originalFrame
{
    if (!repetitions)
    {
        return;
    }
    [UIView animateWithDuration:0.35
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         CGRect frame = swipeArrow.frame;
         if (dir > 0)
             frame.origin.x = originalFrame.origin.x + originalFrame.size.width * 0.5;
         else
             frame.origin.x = originalFrame.origin.x - originalFrame.size.width * 0.5;
         swipeArrow.frame = frame;
         
     }
                     completion:^(BOOL finished)
     {
         [UIView animateWithDuration:0.45
                               delay:0.0
                             options:UIViewAnimationOptionCurveEaseInOut
                          animations:^
          {
              CGRect frame = swipeArrow.frame;
              frame.origin.x = originalFrame.origin.x;
              swipeArrow.frame = frame;
              
          }
                          completion:^(BOOL finished)
          {
              [self animateSwipeArrowWithRepetitions:repetitions - 1
                                            andDelay:0
                                           direction:dir
                                               arrow:swipeArrow
                                           origFrame:originalFrame];
          }];
     }];
}

- (CGFloat)StatusBarHeight
{
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    return MIN(statusBarSize.width, statusBarSize.height);
}

- (void)animateToInitialPresentation
{
    [UIView animateWithDuration:0.35
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         self.contentView.frame = _originalContentFrame;
         
         _backButton.alpha = 1.0;
         _swipeRightArrow.alpha = 1.0;
         _swipeText.alpha = 1.0;
         
         self.logoImage.transform = CGAffineTransformMakeScale(1.0, 1.0);
         self.logoImage.frame = _originalLogoFrame;
         self.logoImage.alpha = 1.0;
     }
                     completion:^(BOOL finished)
     {
     }];
}

- (void)showFadingError:(NSString *)message
{
    [self.PINCodeView resignFirstResponder]; // hide keyboard
    [FadingAlertView create:self.view message:message holdTime:FADING_ALERT_HOLD_TIME_DEFAULT];
}

#pragma mark - FadingAlertView delegate

- (void)fadingAlertDismissed:(FadingAlertView *)view
{
    _fadingAlert = nil;
    [self.PINCodeView becomeFirstResponder];
}

- (void)dismissErrorMessage
{
    [self.errorMessageView.layer removeAllAnimations];
}

#pragma mark - touch events (for swiping)

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self dismissErrorMessage];

    if (!_bTouchesEnabled) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    _firstTouchPoint = [touch locationInView:self.view.window];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_bTouchesEnabled) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view.window];
    
    CGRect frame = self.view.frame;
    CGFloat xPos;
    
    xPos = touchPoint.x - _firstTouchPoint.x;
    
    frame.origin.x = xPos;
    self.view.frame = frame;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_bTouchesEnabled) {
        return;
    }
    
    float xOffset = self.view.frame.origin.x;
    if(xOffset < 0) xOffset = -xOffset;
    if(xOffset < self.view.frame.size.width / 2)
    {
        //spring back
        [UIView animateWithDuration:0.35
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             CGRect frame = self.view.frame;
             frame.origin.x = 0.0;
             self.view.frame = frame;
         }
                         completion:^(BOOL finished)
         {
         }];
    }
    else
    {
        //spring out
        [UIView animateWithDuration:0.35
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             CGRect frame = self.view.frame;
             if(frame.origin.x < 0)
             {
                 frame.origin.x = -frame.size.width;
             }
             else
             {
                 frame.origin.x = frame.size.width;
             }
             self.view.frame = frame;
         }
                         completion:^(BOOL finished)
         {
             [self.delegate PINReLoginViewControllerDidAbort];
         }];
    }
}

#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self dismissErrorMessage];
}

#pragma mark - ReLogin Methods

- (void)signIn:(NSString *)PINCode
{
    [self animateToInitialPresentation];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
    {
        tABC_Error error;
        [CoreBridge PINLoginWithPIN:PINCode error:&error];
        dispatch_async(dispatch_get_main_queue(), ^
        {
            switch (error.code)
            {
                case ABC_CC_Ok:
                {
                    [User login:[LocalSettings controller].cachedUsername password:NULL];
                    [[User Singleton] resetPINLoginInvalidEntryCount];
                    [self.delegate PINReLoginViewControllerDidLogin];
                    break;
                }
                case ABC_CC_BadPassword:
                {
                    if ([[User Singleton] haveExceededPINLoginInvalidEntries])
                    {
                        [[User Singleton] resetPINLoginInvalidEntryCount];
                        [self abortPermanently];
                    }
                    else
                    {
                        [self showFadingError:NSLocalizedString(@"Invalid PIN", nil)];
                    }
                    break;
                }
                default:
                {
                    [self showFadingError:[Util errorMap:&error]];
                    break;
                }
            }
            [self showSpinner:NO];
            self.PINCodeView.PINCode = nil;
        });
    });
}

- (void)abortPermanently
{
    NSString *PINExpired = NSLocalizedString(@"Invalid PIN. Please log in.", nil);
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.delegate PINReLoginViewControllerDidSwitchUserWithMessage:PINExpired];
    }];
}

- (void)showSpinner:(BOOL)bShow
{
    _spinnerView.hidden = !bShow;
    
    // disable touches while the spinner is visible
    _bTouchesEnabled = _spinnerView.hidden;
}

- (void)removeAccount:(NSString *)account
{
    // TODO delete the account, update array - current implementation is fake
    tABC_Error error;
    tABC_CC cc = ABC_AccountDelete((const char*)[account UTF8String], &error);
    if(cc == ABC_CC_Ok) {
        // go to login view controller
    }
    else {
        [self showFadingError:[Util errorMap:&error]];
    }
}

#pragma mark - ButtonSelectorView delegates

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
    [LocalSettings controller].cachedUsername = [self.otherAccounts objectAtIndex:itemIndex];
    if([CoreBridge PINLoginExists:[LocalSettings controller].cachedUsername])
    {
        [self updateUsernameSelector:[LocalSettings controller].cachedUsername];
    }
    else
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.delegate PINReLoginViewControllerDidSwitchUserWithMessage:nil];
        }];
    }
}

- (void)ButtonSelectorWillShowTable:(ButtonSelectorView *)view
{
    [self.usernameSelector.textLabel resignFirstResponder];
    [self.PINCodeView resignFirstResponder];

}

- (void)ButtonSelectorWillHideTable:(ButtonSelectorView *)view
{
    [self.PINCodeView becomeFirstResponder];

}

- (void)ButtonSelectorDidTouchAccessory:(ButtonSelectorView *)selector accountString:(NSString *)string
{
    _account = string;
    NSString *message = [NSString stringWithFormat:[Theme Singleton].deleteAccountWarning,
                         string];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Delete Account", nil)
                          message:NSLocalizedString(message, nil)
                          delegate:self
                          cancelButtonTitle:@"No"
                          otherButtonTitles:@"Yes", nil];
    [alert show];
    [self.PINCodeView becomeFirstResponder];

}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // if they said they wanted to delete the account
    if (buttonIndex == 1)
    {
        [self removeAccount:_account];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.delegate PINReLoginViewControllerDidSwitchUserWithMessage:nil];
        }];
    }
}

@end

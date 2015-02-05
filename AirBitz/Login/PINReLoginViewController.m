//
//  PINReLoginViewController.m
//  AirBitz
//
//  Created by Allan Wright on 11/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "PINReLoginViewController.h"
#import "User.h"
#import "Util.h"
#import "CoreBridge.h"
#import "CommonTypes.h"
#import "LocalSettings.h"
#import "APPINView.h"

@interface PINReLoginViewController () <APPINViewDelegate, FadingAlertViewDelegate>
{
    CGRect   _originalContentFrame;
    CGRect   _originalLogoFrame;
    CGRect   _originalRightSwipeArrowFrame;
    CGPoint  _firstTouchPoint;
    BOOL     _bTouchesEnabled;
    NSUInteger _invalidEntryCount;
    FadingAlertView                 *_fadingAlert;
}
@property (nonatomic, weak) IBOutlet UIView      *contentView;
@property (nonatomic, weak) IBOutlet UIButton    *backButton;
@property (nonatomic, weak) IBOutlet UIImageView *swipeRightArrow;
@property (nonatomic, weak) IBOutlet UILabel     *swipeText;
@property (nonatomic, weak) IBOutlet UILabel     *titleText;
@property (nonatomic, weak) IBOutlet UIImageView *logoImage;
@property (nonatomic, weak) IBOutlet UIView      *spinnerView;
@property (nonatomic, weak) IBOutlet UIView		 *errorMessageView;
@property (nonatomic, weak) IBOutlet UILabel	 *errorMessageText;
@property (weak, nonatomic) IBOutlet APPINView   *PINCodeView;

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [self animateSwipeArrowWithRepetitions:3 andDelay:1.0 direction:1 arrow:_swipeRightArrow origFrame:_originalRightSwipeArrowFrame];

    [self setTitleColors];

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

- (void)setTitleColors
{
    NSString *username = [LocalSettings controller].cachedUsername;
    NSString *title = [NSString stringWithFormat:@"Enter PIN for (%@)",
                       username];
    // Define general attributes like color and fonts for the entire text
    NSDictionary *attr = @{NSForegroundColorAttributeName:self.titleText.textColor,
                           NSFontAttributeName:self.titleText.font};
    NSMutableAttributedString *attributedText = [ [NSMutableAttributedString alloc]
                                                 initWithString:title
                                                 attributes:attr];
    // blue and bold text attributes
    UIColor *color = [UIColor colorWithRed:126.5/255. green:202.5/255. blue:255/255. alpha:1.];
    UIFont *boldFont = [UIFont boldSystemFontOfSize:self.titleText.font.pointSize];
    NSRange usernameTextRange = [title rangeOfString:username];
    [attributedText setAttributes:@{NSForegroundColorAttributeName:color,
                                    NSFontAttributeName:boldFont}
                            range:usernameTextRange];
    self.titleText.attributedText = attributedText;
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
         _titleText.alpha = 1.0;
         
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
    _fadingAlert = [FadingAlertView CreateInsideView:self.view withDelegate:self];
    _fadingAlert.message = message;
    _fadingAlert.fadeDuration = 2;
    _fadingAlert.fadeDelay = 5;
    [_fadingAlert blockModal:NO];
    [_fadingAlert showSpinner:NO];
    [_fadingAlert showFading];
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
        __block tABC_CC result = [CoreBridge PINLoginWithPIN:PINCode];
        dispatch_async(dispatch_get_main_queue(), ^
        {
            switch (result)
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
                    [self showFadingError:NSLocalizedString(@"Invalid PIN", nil)];
                    if ([[User Singleton] haveExceededPINLoginInvalidEntries])
                    {
                        [[User Singleton] resetPINLoginInvalidEntryCount];
                        [self abortPermanently];
                    }
                    break;
                }
                case ABC_CC_PinExpired:
                {
                    [[User Singleton] resetPINLoginInvalidEntryCount];
                    [self abortPermanently];
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
            [self showSpinner:NO];
            self.PINCodeView.PINCode = nil;
        });
    });
}

- (void)abortPermanently
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        [CoreBridge deletePINLogin];
    });
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

@end

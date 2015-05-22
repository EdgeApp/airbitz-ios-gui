
#import "FadingAlertView.h"
#import "ABC.h"
#import "Util.h"
#import "LatoLabel.h"
#import "Theme.h"
#import "MainViewController.h"

#define ALERT_MESSAGE_FADE_DELAY 10
#define ALERT_MESSAGE_FADE_DURATION 10

@interface FadingAlertView ()

+ (void)fadeOutView:(UIView *)view completion:(void (^)(BOOL finished))completion;
+ (void)hideAlertByTap:(UITapGestureRecognizer *)sender;


@property (weak, nonatomic) IBOutlet UIView             *parentView;
@property (weak, nonatomic) IBOutlet LatoLabel          *connectedLine1;
@property (weak, nonatomic) IBOutlet LatoLabel          *connectedLine2;
@property (weak, nonatomic) IBOutlet LatoLabel          *connectedLine3;
@property (weak, nonatomic) IBOutlet UIImageView        *connectedPhoto;
@property (nonatomic, weak) IBOutlet UIView             *alertGroupView;
@property (nonatomic, weak) IBOutlet UILabel            *messageText;
@property (nonatomic, weak) IBOutlet UIView             *activityIndicator;
@property (nonatomic)       CGFloat                     holdTime;
@property (nonatomic, weak) NSTimer                     *dismissTimer;


// Old Stuff. Deprecated
@property (nonatomic, weak) IBOutlet UIView *alertGroup;
@property (nonatomic, weak) IBOutlet UIButton *buttonBlocker;
@property (nonatomic, weak) IBOutlet UIImageView *background;


@end

static FadingAlertView *singleton = nil;
static BOOL bInitialized = NO;

// Old Stuff. Deprecated
static FadingAlertView *currentView = nil;
static NSTimer *timer = nil;
static UIView *alert;



@implementation FadingAlertView

///////////// New implementation. Use me ///////////

+ (void)initAll
{
    if (!bInitialized)
    {
        singleton = [[FadingAlertView alloc] init];
        singleton = [[[NSBundle mainBundle] loadNibNamed:@"FadingAlertViewNew" owner:nil options:nil] objectAtIndex:0];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:singleton action:@selector(hideAlertByTap:)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture.numberOfTouchesRequired = 1;
        [singleton addGestureRecognizer:tapGesture];
        [singleton setTranslatesAutoresizingMaskIntoConstraints:YES];
        singleton.dismissTimer = nil;

        bInitialized = YES;
    }

};

+ (void)create:(UIView *)parentView message:(NSString *)message
{
    [FadingAlertView create:parentView message:message image:nil line1:nil line2:nil line3:nil holdTime:FADING_ALERT_HOLD_TIME_DEFAULT withDelegate:nil];
}

+ (void)create:(UIView *)parentView message:(NSString *)message holdTime:(CGFloat)holdTime
{
    [FadingAlertView create:parentView message:message image:nil line1:nil line2:nil line3:nil holdTime:holdTime withDelegate:nil];
}

+ (void)create:(UIView *)parentView message:(NSString *)message image:(UIImage *)image line1:(NSString *)line1 line2:(NSString *)line2 line3:(NSString *)line3 holdTime:(CGFloat)holdTime withDelegate:(id<FadingAlertViewDelegate>)delegate
{
    // Before anything else. Dismiss any previous alerts and kill the timer
    // Do this first so it calls the previous delegate
    if (singleton.dismissTimer)
        [FadingAlertView dismiss:YES];

    singleton.delegate = delegate;

    singleton.frame = parentView.frame;

    singleton.parentView = parentView;
    singleton.alpha = 0.0;
    singleton.clipsToBounds = YES;
    singleton.holdTime          = holdTime;

    singleton.alertGroupView.layer.masksToBounds = NO;
    singleton.alertGroupView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    singleton.alertGroupView.layer.shadowRadius = 10;
    singleton.alertGroupView.layer.shadowColor = [[UIColor blackColor] CGColor];
    singleton.alertGroupView.layer.shadowOpacity = 0.4;

    singleton.connectedPhoto.image = image;
    singleton.connectedLine1.text = line1;
    singleton.connectedLine2.text = line2;
    singleton.connectedLine3.text = line3;
    singleton.messageText.text = message;

    singleton.alertGroupView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    singleton.alertGroupView.layer.shadowRadius = 10;
    singleton.alertGroupView.layer.shadowColor = [[UIColor blackColor] CGColor];
    singleton.alertGroupView.layer.shadowOpacity = 0.4;
    singleton.layer.cornerRadius = 5.0;

    [singleton setTranslatesAutoresizingMaskIntoConstraints:YES];

    if (holdTime == FADING_ALERT_HOLD_TIME_FOREVER_WITH_SPINNER)
    {
        singleton.activityIndicator.hidden = NO;
    }
    else
    {
        singleton.activityIndicator.hidden = YES;
    }

    // message overrides all
    if (message)
    {
        singleton.messageText.hidden = NO;
        singleton.connectedPhoto.hidden = YES;
        singleton.connectedLine1.hidden = YES;
        singleton.connectedLine2.hidden = YES;
        singleton.connectedLine3.hidden = YES;
    }
    else
    {
        singleton.messageText.hidden = YES;
        singleton.connectedPhoto.hidden = NO;
        singleton.connectedLine1.hidden = NO;
        singleton.connectedLine2.hidden = NO;
        singleton.connectedLine3.hidden = NO;
    }

    if (FADING_ALERT_HOLD_TIME_DEFAULT == holdTime)
        holdTime = [Theme Singleton].alertHoldTimeDefault;

    [parentView addSubview:singleton];

    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
                        options:[Theme Singleton].animationCurveDefault
                     animations:^{
                         singleton.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         if (FADING_ALERT_HOLD_TIME_FOREVER < holdTime)
                             singleton.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:holdTime target:singleton selector:@selector(dismiss) userInfo:nil repeats:NO];
                     }];
    return;
}

- (void)dismiss
{
    [FadingAlertView dismiss:NO];
}

+ (void)dismiss:(BOOL)bNow
{
    CGFloat fadeTime;
    if (bNow)
        fadeTime = [Theme Singleton].animationDurationTimeDefault;
    else
        fadeTime = [Theme Singleton].alertFadeoutTimeDefault;

    if (singleton.dismissTimer)
    {
        [singleton.dismissTimer invalidate];
        singleton.dismissTimer = nil;
    }

    [UIView animateWithDuration:fadeTime
                          delay:[Theme Singleton].animationDelayTimeDefault
                        options:[Theme Singleton].animationCurveDefault
                     animations:^{
                         singleton.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         [singleton removeFromSuperview];
                         if (singleton.delegate)
                             [singleton.delegate fadingAlertDismissedNew];
                     }];
}

- (void)hideAlertByTap:(UITapGestureRecognizer *)sender
{
    if (FADING_ALERT_HOLD_TIME_FOREVER < singleton.holdTime)
        [FadingAlertView dismiss:YES];
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}




/////////////////////////// Old stuff. Do not use //////////////////////////

+ (FadingAlertView *)currentView
{
    return currentView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

+ (FadingAlertView *)CreateInsideView:(UIView *)parentView withDelegate:(id<FadingAlertViewDelegate>)delegate
{
//	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		currentView = [[[NSBundle mainBundle] loadNibNamed:@"FadingAlertView" owner:nil options:nil] objectAtIndex:0];
//	} else {
//		currentView = [[[NSBundle mainBundle] loadNibNamed:@"FadingAlertView~ipad" owner:nil options:nil] objectAtIndex:0];
//	}
    alert.alpha = 1.0;

    [currentView setCenter:parentView.center];
    
    currentView.fadeDelay = ALERT_MESSAGE_FADE_DELAY;
    currentView.fadeDuration = ALERT_MESSAGE_FADE_DURATION;
    currentView.buttonBlocker.hidden = NO;
    currentView.activityIndicator.hidden = YES;
    currentView.delegate = delegate;
    
    //create shadow view by adding a black background with custom opacity
    UIView *shadowView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    shadowView.backgroundColor = [UIColor blackColor];
    shadowView.alpha = 0.1;
    [currentView addSubview:shadowView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:[FadingAlertView class] action:@selector(hideAlertByTap:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [shadowView addGestureRecognizer:tapGesture];

	[parentView addSubview:currentView];
    
    return currentView;
}

+ (FadingAlertView *)CreateLoadingView:(UIView *)parentView withDelegate:(id<FadingAlertViewDelegate>)delegate
{
    currentView = [FadingAlertView CreateInsideView:parentView withDelegate:delegate];
    [currentView blockModal:YES];
    [currentView showSpinner:YES center:YES];
    [currentView showBackground:NO];
    return currentView;
}

- (void)blockModal:(BOOL)blocking
{
    _buttonBlocker.hidden = !blocking;
}

- (void)showSpinner:(BOOL)visible
{
    _activityIndicator.hidden = !visible;
}

- (void)showSpinner:(BOOL)visible center:(BOOL)center
{
    _activityIndicator.hidden = !visible;
    if (center) {
        [_activityIndicator setCenter:_alertGroup.center];
    }
}

- (void)showBackground:(BOOL)visible
{
    _background.hidden = !visible;
}

- (void)show
{
    _messageText.text = _message;
    self.alpha = 1.0;
}

- (void)showFading
{
    [self show];
    [self dismiss:YES];
}

+ (void)hideAlertByTap:(UITapGestureRecognizer *)sender {
    if(!currentView.buttonBlocker.hidden)
    {
        return;
    }
    if(timer)
    {
        [timer invalidate];
    }
    if(currentView.delegate) {
        [currentView.delegate fadingAlertDismissed:currentView];
    }
    //fade out and then remove from superview
    [self fadeOutView:currentView
           completion:^(BOOL finished) {
               [currentView removeFromSuperview];
               currentView = nil;
           }];
}

+ (void)fadeOutView:(UIView *)view completion:(void (^)(BOOL finished))completion {
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [view setAlpha:0.0];
                     }
                     completion:completion];
}

- (void)timedOut
{
    [timer invalidate];
    [UIView animateWithDuration:_fadeDuration
             delay:0.0
             options:UIViewAnimationOptionCurveEaseOut
             animations:^{
                self.alpha = 0.0;
             }
             completion:^(BOOL finished)
             {
                [currentView removeFromSuperview];
                currentView = nil;
                if(self.delegate) {
                    [self.delegate fadingAlertDismissed:self];
             }
            }];
}

- (void)dismiss:(BOOL)animated
{
    if (animated) {
        if(self.fadeDelay != 0)
        {
            timer = [NSTimer scheduledTimerWithTimeInterval:_fadeDelay target:self selector:@selector(timedOut) userInfo:nil repeats:NO];
        }
    } else {
        [currentView removeFromSuperview];
        currentView = nil;
    }
}

@end

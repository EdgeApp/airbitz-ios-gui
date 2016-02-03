
#import "FadingAlertView.h"
#import "Util.h"
#import "LatoLabel.h"
#import "Theme.h"
#import "MainViewController.h"
#import "BlurView.h"

#define ALERT_MESSAGE_FADE_DELAY 10
#define ALERT_MESSAGE_FADE_DURATION 10

@interface FadingAlertView ()

@property (weak, nonatomic) IBOutlet UIView             *darkView;
@property (weak, nonatomic) IBOutlet UIView             *parentView;
@property (weak, nonatomic) IBOutlet BlurView           *blurView;
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
    [FadingAlertView create:parentView message:message image:nil line1:nil line2:nil line3:nil holdTime:FADING_ALERT_HOLD_TIME_DEFAULT withDelegate:nil notify:nil];
}

+ (void)create:(UIView *)parentView message:(NSString *)message holdTime:(CGFloat)holdTime
{
    [FadingAlertView create:parentView message:message image:nil line1:nil line2:nil line3:nil holdTime:holdTime withDelegate:nil notify:nil];
}

+ (void)create:(UIView *)parentView message:(NSString *)message holdTime:(CGFloat)holdTime notify:(void(^)(void))cb
{
    [FadingAlertView create:parentView message:message image:nil line1:nil line2:nil line3:nil holdTime:holdTime withDelegate:nil notify:cb];
}

+ (void)create:(UIView *)parentView message:(NSString *)message image:(UIImage *)image line1:(NSString *)line1 line2:(NSString *)line2 line3:(NSString *)line3 holdTime:(CGFloat)holdTime withDelegate:(id<FadingAlertViewDelegate>)delegate notify:(void(^)(void))cb
{
    // Before anything else. Dismiss any previous alerts and kill the timer
    // Do this first so it calls the previous delegate
    if (singleton.dismissTimer)
        [FadingAlertView dismiss:FadingAlertDismissFast];

    singleton.delegate = delegate;

    singleton.frame = parentView.frame;

    singleton.parentView = parentView;
    singleton.alpha = 0.0;
    singleton.blurView.alpha = 0;
    singleton.clipsToBounds = YES;
    singleton.holdTime          = holdTime;

    singleton.connectedPhoto.image = image;
    singleton.connectedLine1.text = line1;
    singleton.connectedLine2.text = line2;
    singleton.connectedLine3.text = line3;
    singleton.messageText.text = message;

    singleton.alertGroupView.layer.masksToBounds = YES;

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

    if (![Theme Singleton].bTranslucencyEnable)
    {
        singleton.darkView.hidden = YES;
    }


    [parentView addSubview:singleton];

    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
                        options:[Theme Singleton].animationCurveDefault
                     animations:^{
                         singleton.alpha = 1.0;
                         singleton.blurView.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         if (FADING_ALERT_HOLD_TIME_FOREVER < holdTime)
                             singleton.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:holdTime target:singleton selector:@selector(dismiss) userInfo:nil repeats:NO];
                         if (cb)
                             cb();
                     }];
    return;
}

+ (void)update:(NSString *)message;
{
    singleton.messageText.text = message;
}

- (void)dismiss
{
    [FadingAlertView dismiss:FadingAlertDismissGradual];
}

+ (void)dismiss:(eFadingAlertDismissType)dismissType;
{
    CGFloat fadeTime;
    if (FadingAlertDismissNow == dismissType)
    {
        singleton.alpha = 0.0;
        [singleton removeFromSuperview];
        if (singleton.delegate)
            [singleton.delegate fadingAlertDismissed];
    }
    else
    {
        if (FadingAlertDismissFast == dismissType)
            fadeTime = [Theme Singleton].animationDurationTimeDefault;
        else if (FadingAlertDismissGradual == dismissType)
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
                                 [singleton.delegate fadingAlertDismissed];
                         }];
    }
}

- (void)hideAlertByTap:(UITapGestureRecognizer *)sender
{
    if (FADING_ALERT_HOLD_TIME_FOREVER < singleton.holdTime)
        [FadingAlertView dismiss:FadingAlertDismissFast];
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

@end

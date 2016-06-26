
#import "MiniDropDownAlertView.h"
#import "Util.h"
#import "LatoLabel.h"
#import "Theme.h"
#import "MainViewController.h"
#import "BlurView.h"
#import "LatoLabel.h"

@interface MiniDropDownAlertView ()
{
}
- (void)hideAlertByTap:(UITapGestureRecognizer *)sender;

@property (weak, nonatomic) IBOutlet UIView *parentView;
@property (weak, nonatomic) IBOutlet UIView *alertGroupView;
@property (nonatomic, weak) IBOutlet UILabel *messageText;

@end


@implementation MiniDropDownAlertView

static MiniDropDownAlertView *singleton = nil;
static BOOL bInitialized = NO;

+ (void)initAll
{
    if (!bInitialized)
    {
        singleton = [[MiniDropDownAlertView alloc] init];
        singleton = [[[NSBundle mainBundle] loadNibNamed:@"MiniDropDownAlertView" owner:nil options:nil] objectAtIndex:0];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:singleton action:@selector(hideAlertByTap:)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture.numberOfTouchesRequired = 1;
        [singleton addGestureRecognizer:tapGesture];
        [singleton setTranslatesAutoresizingMaskIntoConstraints:YES];


        bInitialized = YES;
    }

};

+ (void)create:(UIView *)parentView message:(NSString *)message
{
    [MiniDropDownAlertView create:parentView message:message holdTime:0.0 withDelegate:nil];
}

+ (void)create:(UIView *)parentView message:(NSString *)message holdTime:(CGFloat)holdTime withDelegate:(id<MiniDropDownAlertViewDelegate>)delegate
{
    singleton.delegate = delegate;

    CGRect frame;

    frame = parentView.frame;
    frame.size.height = [Theme Singleton].fadingAlertMiniDropdownHeight;
    frame.origin.y = -[MainViewController getSafeOffscreenOffset:frame.size.height];

    singleton.parentView = parentView;
    singleton.frame = frame;
    singleton.alpha = 0.0;

    singleton.alertGroupView.layer.masksToBounds = NO;
    singleton.alertGroupView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    singleton.alertGroupView.layer.shadowRadius = 10;
    singleton.alertGroupView.layer.shadowColor = [[UIColor blackColor] CGColor];
    singleton.alertGroupView.layer.shadowOpacity = 0.4;

    singleton.messageText.text = message;

    singleton.messageText.hidden = NO;

    if (!holdTime)
        holdTime = [Theme Singleton].alertHoldTimeDefault;

    [parentView addSubview:singleton];

    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
                        options:[Theme Singleton].animationCurveDefault
                     animations:^{
                         singleton.alpha = 1.0;
                         CGRect frame = singleton.frame;
                         frame.origin.y = [MainViewController getHeaderHeight];
                         singleton.frame = frame;
                     }
                     completion:^(BOOL finished) {
                         [NSTimer scheduledTimerWithTimeInterval:holdTime target:singleton selector:@selector(dismiss) userInfo:nil repeats:NO];

                     }];
    return;
}

- (void)dismiss
{
    [MiniDropDownAlertView dismiss:NO];
}

+ (void)update:(NSString *)message;
{
    singleton.messageText.text = message;
}

+ (void)dismiss:(BOOL)bNow
{
    CGFloat fadeTime;
    if (bNow)
        fadeTime = [Theme Singleton].animationDurationTimeDefault;
    else
        fadeTime = [Theme Singleton].alertFadeoutTimeDefault;

    [UIView animateWithDuration:fadeTime
                          delay:[Theme Singleton].animationDelayTimeDefault
                        options:[Theme Singleton].animationCurveDefault
                     animations:^{
                         singleton.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         CGRect frame = singleton.frame;
                         frame.origin.y = -[MainViewController getSafeOffscreenOffset:frame.size.height];
                         singleton.frame = frame;
                         [singleton removeFromSuperview];
                         if (singleton.delegate)
                             [singleton.delegate dropDownAlertDismissed];
                     }];
}

- (void)hideAlertByTap:(UITapGestureRecognizer *)sender
{
    [MiniDropDownAlertView dismiss:YES];
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

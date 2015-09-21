
#import "DropDownAlertView.h"
#import "ABC.h"
#import "Util.h"
#import "LatoLabel.h"
#import "Theme.h"
#import "MainViewController.h"
#import "BlurView.h"
#import "LatoLabel.h"

@interface DropDownAlertView ()
{
}
- (void)hideAlertByTap:(UITapGestureRecognizer *)sender;

@property (weak, nonatomic) IBOutlet UIView *parentView;
@property (weak, nonatomic) IBOutlet UIView *alertGroupView;
@property (weak, nonatomic) IBOutlet LatoLabel *connectedLine1;
@property (weak, nonatomic) IBOutlet LatoLabel *connectedLine2;
@property (weak, nonatomic) IBOutlet LatoLabel *connectedLine3;
@property (weak, nonatomic) IBOutlet UIImageView *connectedPhoto;
@property (nonatomic, weak) IBOutlet UILabel *messageText;

@end


@implementation DropDownAlertView

static DropDownAlertView *singleton = nil;
static BOOL bInitialized = NO;

+ (void)initAll
{
    if (!bInitialized)
    {
        singleton = [[DropDownAlertView alloc] init];
        singleton = [[[NSBundle mainBundle] loadNibNamed:@"DropDownAlertView" owner:nil options:nil] objectAtIndex:0];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:singleton action:@selector(hideAlertByTap:)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture.numberOfTouchesRequired = 1;
        [singleton addGestureRecognizer:tapGesture];
        [singleton setTranslatesAutoresizingMaskIntoConstraints:YES];


        bInitialized = YES;
    }

};

+ (void)create:(UIView *)parentView image:(UIImage *)image line1:(NSString *)line1 line2:(NSString *)line2 line3:(NSString *)line3 holdTime:(CGFloat)holdTime withDelegate:(id<DropDownAlertViewDelegate>)delegate
{
    [DropDownAlertView create:parentView message:nil image:image line1:line1 line2:line2 line3:line3 holdTime:holdTime withDelegate:delegate];
}

+ (void)create:(UIView *)parentView message:(NSString *)message
{
    [DropDownAlertView create:parentView message:message image:nil line1:nil line2:nil line3:nil holdTime:0.0 withDelegate:nil];
}

+ (void)create:(UIView *)parentView message:(NSString *)message holdTime:(CGFloat)holdTime withDelegate:(id<DropDownAlertViewDelegate>)delegate
{
    [DropDownAlertView create:parentView message:message image:nil line1:nil line2:nil line3:nil holdTime:holdTime withDelegate:delegate];
}

+ (void)create:(UIView *)parentView message:(NSString *)message image:(UIImage *)image line1:(NSString *)line1 line2:(NSString *)line2 line3:(NSString *)line3 holdTime:(CGFloat)holdTime withDelegate:(id<DropDownAlertViewDelegate>)delegate
{
    singleton.delegate = delegate;

    CGRect frame;

    frame = parentView.frame;
    frame.size.height = [Theme Singleton].fadingAlertDropdownHeight;
    frame.origin.y = -[MainViewController getSafeOffscreenOffset:frame.size.height];

    singleton.parentView = parentView;
    singleton.frame = frame;
    singleton.alpha = 0.0;

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
    [DropDownAlertView dismiss:NO];
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
    [DropDownAlertView dismiss:YES];
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

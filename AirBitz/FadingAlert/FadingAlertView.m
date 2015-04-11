
#import "FadingAlertView.h"
#import "ABC.h"
#import "Util.h"

#define ALERT_MESSAGE_FADE_DELAY 10
#define ALERT_MESSAGE_FADE_DURATION 10

@interface FadingAlertView ()

+ (void)fadeOutView:(UIView *)view completion:(void (^)(BOOL finished))completion;
+ (void)hideAlertByTap:(UITapGestureRecognizer *)sender;

@property (nonatomic, weak) IBOutlet UILabel *messageText;
@property (nonatomic, weak) IBOutlet UIButton *buttonBlocker;
@property (nonatomic, weak) IBOutlet UIView *activityIndicator;
@property (nonatomic, weak) IBOutlet UIView *alertGroup;
@property (nonatomic, weak) IBOutlet UIImageView *background;

@end

static FadingAlertView *currentView = nil;
static NSTimer *timer = nil;
static UIView *alert;

@implementation FadingAlertView

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

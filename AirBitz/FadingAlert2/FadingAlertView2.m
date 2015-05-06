
#import "FadingAlertView2.h"
#import "ABC.h"
#import "Util.h"

#define ALERT_MESSAGE_FADE_DELAY 10
#define ALERT_MESSAGE_FADE_DURATION 10

@interface FadingAlertView2 ()
{

}
- (void)fadeOutView:(UIView *)view completion:(void (^)(BOOL finished))completion;
- (void)hideAlertByTap:(UITapGestureRecognizer *)sender;

@property (nonatomic, weak) IBOutlet UILabel *messageText;
@property (nonatomic, weak) IBOutlet UIView *activityIndicator;
@property (nonatomic, weak) IBOutlet UIToolbar *toolBarView;
@property (nonatomic, weak) IBOutlet UIView *shadowView;
@property (nonatomic, weak) NSTimer *timer;
@property BOOL bIsBlocking;

@end


@implementation FadingAlertView2

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSLog(@"FadingAlert2 init show: x=%f width=%f\n", self.layer.frame.origin.x, self.layer.frame.size.width);
        self.bIsBlocking = false;
        self.fadeDelay = ALERT_MESSAGE_FADE_DELAY;
        self.fadeDuration = ALERT_MESSAGE_FADE_DURATION;
        self.activityIndicator.hidden = YES;
        self.alpha = 0.0;
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 5.0;
        _toolBarView.clipsToBounds = YES;
        _toolBarView.layer.cornerRadius = 5.0;
        _toolBarView.alpha = 1.0;
        _shadowView.backgroundColor = [UIColor clearColor];
        _shadowView.alpha = 0.0;

    }
    return self;
}

+ (FadingAlertView2 *)CreateInsideView:(UIView *)parentView withDelegate:(id<FadingAlertView2Delegate>)delegate
{
    FadingAlertView2 *currentView = [[FadingAlertView2 alloc] init];
    currentView = [[[NSBundle mainBundle] loadNibNamed:@"FadingAlertView2" owner:nil options:nil] objectAtIndex:0];

    NSLog(@"FadingAlert2 CreateInsideView show: x=%f width=%f\n", parentView.layer.frame.origin.x, parentView.layer.frame.size.width);


    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:currentView action:@selector(hideAlertByTap:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [currentView addGestureRecognizer:tapGesture];

    currentView.delegate = delegate;

	[parentView addSubview:currentView];

    [currentView setTranslatesAutoresizingMaskIntoConstraints:YES];

    CGRect frame;

    frame = parentView.frame;
    currentView.frame = frame;

    return currentView;
}

+ (FadingAlertView2 *)CreateLoadingView:(UIView *)parentView withDelegate:(id<FadingAlertView2Delegate>)delegate
{
    FadingAlertView2 *currentView = [[FadingAlertView2 alloc] init];
    currentView = [[[NSBundle mainBundle] loadNibNamed:@"FadingAlertView2" owner:nil options:nil] objectAtIndex:0];

    NSLog(@"FadingAlert2 CreateLoadingView show: x=%f width=%f\n", parentView.layer.frame.origin.x, parentView.layer.frame.size.width);

    currentView.delegate = delegate;

    currentView.bIsBlocking = true;
    currentView.activityIndicator.hidden = false;
    [currentView showSpinner:YES center:YES];
    [currentView showBackground:NO];
    return currentView;
}

- (void)blockModal:(BOOL)blocking
{
    self.bIsBlocking = blocking;
}

- (void)showSpinner:(BOOL)visible
{
    _activityIndicator.hidden = !visible;
}

- (void)messageTextSet:(NSString *)message
{
    self.messageText.text = message;
}

- (void)show
{
    self.alpha = 1.0;

    NSLog(@"FadingAlert show: x=%f width=%f\n", self.layer.frame.origin.x, self.layer.frame.size.width);

}

- (void)showFading
{
    [self show];
    [self dismiss:YES];
}

- (void)hideAlertByTap:(UITapGestureRecognizer *)sender {
    if(self.bIsBlocking)
    {
        return;
    }
    if(self.timer)
    {
        [self.timer invalidate];
    }
    if(self.delegate) {
        [self.delegate fadingAlertDismissed:self];
    }
    //fade out and then remove from superview
    [self fadeOutView:self
           completion:^(BOOL finished) {
               [self removeFromSuperview];
           }];
}

- (void)fadeOutView:(UIView *)view completion:(void (^)(BOOL finished))completion {
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [view setAlpha:0.0];
                         [self.shadowView setAlpha:0.0];
                         [self.toolBarView setAlpha:0.0];
                         NSLog(@"FadingAlert2 init fadeout: x=%f width=%f\n", self.layer.frame.origin.x, self.layer.frame.size.width);

                     }
                     completion:completion];
}

- (void)timedOut
{
    [self.timer invalidate];
    [UIView animateWithDuration:_fadeDuration
             delay:0.0
             options:UIViewAnimationOptionCurveEaseOut
             animations:^{
                self.alpha = 0.0;
             }
             completion:^(BOOL finished)
             {
                [self removeFromSuperview];
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
            self.timer = [NSTimer scheduledTimerWithTimeInterval:_fadeDelay target:self selector:@selector(timedOut) userInfo:nil repeats:NO];
        }
    } else {
        [self removeFromSuperview];
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

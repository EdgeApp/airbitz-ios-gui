
#import "FadingAlertView2.h"
#import "ABC.h"
#import "Util.h"
#import "LatoLabel.h"
#import "Theme.h"
#import "MainViewController.h"
#import "BlurView.h"

#define ALERT_MESSAGE_FADE_DELAY 10
#define ALERT_MESSAGE_FADE_DURATION 10

@interface FadingAlertView2 ()
{
}
- (void)fadeOutView:(UIView *)view completion:(void (^)(BOOL finished))completion;
- (void)hideAlertByTap:(UITapGestureRecognizer *)sender;

@property (weak, nonatomic) IBOutlet UIView *alertGroupView;
@property (weak, nonatomic) IBOutlet LatoLabel *connectedLine1;
@property (weak, nonatomic) IBOutlet LatoLabel *connectedLine2;
@property (weak, nonatomic) IBOutlet LatoLabel *connectedLine3;
@property (weak, nonatomic) IBOutlet UIImageView *connectedPhoto;
@property (nonatomic, weak) IBOutlet UILabel *messageText;
@property (nonatomic, weak) IBOutlet UIView *activityIndicator;
//@property (nonatomic, weak) IBOutlet BlurView *blurView;

@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic) BOOL bDropDown;
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
//        self.blurView.clipsToBounds = YES;
//        self.blurView.layer.cornerRadius = 5.0;
//        self.blurView.alpha = 1.0;
        self.bDropDown = false;


//        _shadowView.backgroundColor = [UIColor clearColor];
//        _shadowView.alpha = 0.0;

    }
    return self;
}

+ (FadingAlertView2 *)CreateDropView:(UIView *)parentView withDelegate:(id<FadingAlertView2Delegate>)delegate
{
    FadingAlertView2 *currentView = [[FadingAlertView2 alloc] init];
    currentView = [[[NSBundle mainBundle] loadNibNamed:@"FadingAlertDropDownView" owner:nil options:nil] objectAtIndex:0];

    NSLog(@"FadingAlert2 CreateDropView show: x=%f width=%f\n", parentView.layer.frame.origin.x, parentView.layer.frame.size.width);


    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:currentView action:@selector(hideAlertByTap:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [currentView addGestureRecognizer:tapGesture];

    currentView.delegate = delegate;

    [currentView setTranslatesAutoresizingMaskIntoConstraints:YES];

    CGRect frame;

    frame = parentView.frame;
    frame.size.height = [Theme Singleton].fadingAlertDropdownHeight;
    frame.origin.y = - (frame.size.height * 2);

    currentView.frame = frame;
    currentView.bDropDown = true;
    currentView.alpha = 0.0;

    currentView.alertGroupView.layer.masksToBounds = NO;
//        self.walletsView.layer.cornerRadius = 8; // if you like rounded corners
    currentView.alertGroupView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    currentView.alertGroupView.layer.shadowRadius = 10;
    currentView.alertGroupView.layer.shadowColor = [[UIColor blackColor] CGColor];
    currentView.alertGroupView.layer.shadowOpacity = 0.4;

    [parentView addSubview:currentView];

    return currentView;
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
    currentView.alpha = 0.0;
    currentView.alertGroupView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    currentView.alertGroupView.layer.shadowRadius = 10;
    currentView.alertGroupView.layer.shadowColor = [[UIColor blackColor] CGColor];
    currentView.alertGroupView.layer.shadowOpacity = 0.4;

    currentView.delegate = delegate;

    [currentView setTranslatesAutoresizingMaskIntoConstraints:YES];

    CGRect frame;

    frame = parentView.frame;
    currentView.frame = frame;

    [parentView addSubview:currentView];

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
//    [currentView showBackground:NO];

    currentView.alpha = 0.0;
    currentView.alertGroupView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    currentView.alertGroupView.layer.shadowRadius = 10;
    currentView.alertGroupView.layer.shadowColor = [[UIColor blackColor] CGColor];
    currentView.alertGroupView.layer.shadowOpacity = 0.4;

    CGRect frame = parentView.frame;
    currentView.frame = frame;

    [parentView addSubview:currentView];

    return currentView;
}

- (void)photoAlertSet:(UIImage *)image line1:(NSString *)line1 line2:(NSString *)line2 line3:(NSString *)line3;
{
    self.connectedPhoto.image = image;
    self.connectedLine1.text = line1;
    self.connectedLine2.text = line2;
    self.connectedLine3.text = line3;
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
    self.alpha = 0.0;
//    [self.blurView setAlpha:0.0];
    [self layoutIfNeeded];
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.alpha = 1.0;
                         if (self.bDropDown)
                         {
                             CGRect frame = self.frame;
                             frame.origin.y = [MainViewController getHeaderHeight];
                             self.frame = frame;
                         }
//                         [self.blurView setAlpha:1.0];
                         NSLog(@"FadingAlert2 init fadeout: x=%f width=%f\n", self.layer.frame.origin.x, self.layer.frame.size.width);

                     }
                     completion:^(BOOL finished)
                     {}];

    NSLog(@"FadingAlert show: x=%f y=%f width=%f height=%f\n", self.layer.frame.origin.x, self.layer.frame.origin.y, self.layer.frame.size.width, self.layer.frame.size.height);

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
                         if (self.bDropDown)
                         {
                             CGRect frame = self.frame;
                             frame.origin.y = - (frame.size.height * 2);
                             self.frame = frame;
                         }
//                         [self.shadowView setAlpha:0.0];
//                         [self.blurView setAlpha:0.0];
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
                 if (self.bDropDown)
                 {
                     CGRect frame = self.frame;
                     frame.origin.y = - (frame.size.height * 2);
                     self.frame = frame;
                 }

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

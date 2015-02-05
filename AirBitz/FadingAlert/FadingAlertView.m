
#import "FadingAlertView.h"
#import "ABC.h"
#import "Util.h"

#define ALERT_MESSAGE_FADE_DELAY 10
#define ALERT_MESSAGE_FADE_DURATION 10

@interface FadingAlertView ()

@property (nonatomic, weak) IBOutlet UILabel *messageText;
@property (nonatomic, weak) IBOutlet UIView *buttonBlocker;
@property (nonatomic, weak) IBOutlet UIView *activityIndicator;

@end

@implementation FadingAlertView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

+ (FadingAlertView *)CreateInsideView:(UIView *)parentView withDelegate:(id<FadingAlertViewDelegate>)delegate
{
	FadingAlertView *alert;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		alert = [[[NSBundle mainBundle] loadNibNamed:@"FadingAlertView~iphone" owner:nil options:nil] objectAtIndex:0];
	} else {
		alert = [[[NSBundle mainBundle] loadNibNamed:@"FadingAlertView~ipad" owner:nil options:nil] objectAtIndex:0];
	}
    alert.alpha = 1.0;
    alert.fadeDelay = ALERT_MESSAGE_FADE_DELAY;
    alert.fadeDuration = ALERT_MESSAGE_FADE_DURATION;
    alert.buttonBlocker.hidden = YES;
    alert.activityIndicator.hidden = YES;
    alert.delegate = delegate;
	[parentView addSubview:alert];
	return alert;
}

- (void)blockButtons:(BOOL)blocking
{
    _buttonBlocker.hidden = !blocking;
}

- (void)showSpinner:(BOOL)visible
{
    _activityIndicator.hidden = !visible;
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

- (void)dismiss:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:_fadeDuration
                              delay:_fadeDelay
                            options:UIViewAnimationOptionCurveLinear
                        animations:^
        {
            self.alpha = 0.0;
        }
        completion:^(BOOL finished)
        {
            if (self.delegate) {
                [self.delegate fadingAlertDismissed:self];
            }
        }];
    } else {
        self.alpha = 0.0;
        if (self.delegate) {
            [self.delegate fadingAlertDismissed:self];
        }
    }
}

@end

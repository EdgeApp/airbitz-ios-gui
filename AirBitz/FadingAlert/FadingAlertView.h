
#import <UIKit/UIKit.h>

#define FADING_ALERT_HOLD_TIME_DEFAULT                  0  // Forces use of Theme.m hold time settings
#define FADING_ALERT_HOLD_TIME_FOREVER                  -1 // Hold the alert until dismissed
#define FADING_ALERT_HOLD_TIME_FOREVER_WITH_SPINNER     -2 // Hold the alert until dismissed. Include a spinner
#define FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP        9999999 // Hold the alert until dismissed or tapped


@protocol FadingAlertViewDelegate;
@protocol UIGestureRecognizerDelegate;

@interface FadingAlertView : UIView

@property (nonatomic, assign) id<FadingAlertViewDelegate> delegate;
@property (nonatomic, assign) int fadeDelay;
@property (nonatomic, assign) int fadeDuration;
@property (nonatomic, copy) NSString *message;

+ (void)initAll;

+ (void)create:(UIView *)parentView message:(NSString *)message;
+ (void)create:(UIView *)parentView message:(NSString *)message holdTime:(CGFloat)holdTime;
+ (void)create:(UIView *)parentView message:(NSString *)message holdTime:(CGFloat)holdTime notify:(void(^)(void))cb;
+ (void)create:(UIView *)parentView message:(NSString *)message image:(UIImage *)image line1:(NSString *)line1 line2:(NSString *)line2 line3:(NSString *)line3 holdTime:(CGFloat)holdTime withDelegate:(id<FadingAlertViewDelegate>)delegate notify:(void(^)(void))cb;
+ (void)update:(NSString *)message;
+ (void)dismiss:(BOOL)bNow;

@end

@protocol FadingAlertViewDelegate <NSObject>

@required
@optional
-(void)fadingAlertDismissed;

@end

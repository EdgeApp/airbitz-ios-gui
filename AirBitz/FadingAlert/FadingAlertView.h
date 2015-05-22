
#import <UIKit/UIKit.h>

#define FADING_ALERT_HOLD_TIME_DEFAULT                  0  // Forces use of Theme.m hold time settings
#define FADING_ALERT_HOLD_TIME_FOREVER                  -1 // Hold the alert until dismissed
#define FADING_ALERT_HOLD_TIME_FOREVER_WITH_SPINNER     -2 // Hold the alert until dismissed. Include a spinner


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
+ (void)create:(UIView *)parentView message:(NSString *)message image:(UIImage *)image line1:(NSString *)line1 line2:(NSString *)line2 line3:(NSString *)line3 holdTime:(CGFloat)holdTime withDelegate:(id<FadingAlertViewDelegate>)delegate;
+ (void)dismiss:(BOOL)bNow;

// Deprecated. Do not use anything below
+ (FadingAlertView *)CreateInsideView:(UIView *)parentView withDelegate:(id<FadingAlertViewDelegate>)delegate;
+ (FadingAlertView *)CreateLoadingView:(UIView *)parentView withDelegate:(id<FadingAlertViewDelegate>)delegate;

- (void)blockModal:(BOOL)blocking;
- (void)showSpinner:(BOOL)visible;
- (void)showSpinner:(BOOL)visible center:(BOOL)center;
- (void)showBackground:(BOOL)visible;
- (void)show;
- (void)showFading;
- (void)dismiss:(BOOL)animated;

@end

@protocol FadingAlertViewDelegate <NSObject>

@required
@optional
-(void)fadingAlertDismissed:(FadingAlertView *)pv;
-(void)fadingAlertDismissedNew;

@end

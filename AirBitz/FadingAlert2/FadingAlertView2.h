
#import <UIKit/UIKit.h>

@protocol FadingAlertView2Delegate;
@protocol UIGestureRecognizerDelegate;

@interface FadingAlertView2 : UIView

@property (nonatomic, assign) id<FadingAlertView2Delegate> delegate;
@property (nonatomic, assign) int fadeDelay;
@property (nonatomic, assign) int fadeDuration;

+ (FadingAlertView2 *)CreateDropView:(UIView *)parentView withDelegate:(id<FadingAlertView2Delegate>)delegate;
+ (FadingAlertView2 *)CreateInsideView:(UIView *)parentView withDelegate:(id<FadingAlertView2Delegate>)delegate;
+ (FadingAlertView2 *)CreateLoadingView:(UIView *)parentView withDelegate:(id<FadingAlertView2Delegate>)delegate;

- (void)blockModal:(BOOL)blocking;
- (void)showSpinner:(BOOL)visible;
- (void)showSpinner:(BOOL)visible center:(BOOL)center;
- (void)messageTextSet:(NSString *)message;
- (void)photoAlertSet:(UIImage *)image line1:(NSString *)line1 line2:(NSString *)line2 line3:(NSString *)line3;
- (void)show;
- (void)showFading;
- (void)dismiss:(BOOL)animated;

@end

@protocol FadingAlertView2Delegate <NSObject>

@required
-(void)fadingAlertDismissed:(FadingAlertView2 *)pv;

@optional

@end

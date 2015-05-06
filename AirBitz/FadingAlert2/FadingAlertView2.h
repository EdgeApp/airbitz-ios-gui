
#import <UIKit/UIKit.h>

@protocol FadingAlertView2Delegate;
@protocol UIGestureRecognizerDelegate;

@interface FadingAlertView2 : UIView

@property (nonatomic, assign) id<FadingAlertView2Delegate> delegate;
@property (nonatomic, assign) int fadeDelay;
@property (nonatomic, assign) int fadeDuration;

+ (FadingAlertView2 *)CreateInsideView:(UIView *)parentView withDelegate:(id<FadingAlertView2Delegate>)delegate;
+ (FadingAlertView2 *)CreateLoadingView:(UIView *)parentView withDelegate:(id<FadingAlertView2Delegate>)delegate;

- (void)blockModal:(BOOL)blocking;
- (void)showSpinner:(BOOL)visible;
- (void)showSpinner:(BOOL)visible center:(BOOL)center;
- (void)showBackground:(BOOL)visible;
- (void)messageTextSet:(NSString *)message;
- (void)show;
- (void)showFading;
- (void)dismiss:(BOOL)animated;

@end

@protocol FadingAlertView2Delegate <NSObject>

@required
-(void)fadingAlertDismissed:(FadingAlertView2 *)pv;
@optional

@end

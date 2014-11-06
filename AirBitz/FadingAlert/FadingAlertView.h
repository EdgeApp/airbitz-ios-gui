
#import <UIKit/UIKit.h>

@protocol FadingAlertViewDelegate;

@interface FadingAlertView : UIView

@property (nonatomic, assign) id<FadingAlertViewDelegate> delegate;
@property (nonatomic, assign) int fadeDelay;
@property (nonatomic, assign) int fadeDuration;
@property (nonatomic, copy) NSString *message;

+ (FadingAlertView *)CreateInsideView:(UIView *)parentView withDelegate:(id<FadingAlertViewDelegate>)delegate;

- (void)blockButtons:(BOOL)blocking;
- (void)showSpinner:(BOOL)visible;
- (void)show;
- (void)showFading;
- (void)dismiss:(BOOL)animated;

@end

@protocol FadingAlertViewDelegate <NSObject>

@required
-(void)fadingAlertDismissed:(FadingAlertView *)pv;
@optional

@end

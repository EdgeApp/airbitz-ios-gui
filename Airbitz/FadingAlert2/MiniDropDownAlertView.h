
#import <UIKit/UIKit.h>

#define DROP_DOWN_HOLD_TIME_DEFAULT 0  // Forces use of Theme.m hold time settings

@protocol MiniDropDownAlertViewDelegate;
@protocol UIGestureRecognizerDelegate;

@interface MiniDropDownAlertView : UIView

@property (nonatomic, assign) id<MiniDropDownAlertViewDelegate> delegate;

+ (void)initAll;
+ (void)create:(UIView *)parentView message:(NSString *)message;
+ (void)create:(UIView *)parentView message:(NSString *)message holdTime:(CGFloat)holdTime withDelegate:(id<MiniDropDownAlertViewDelegate>)delegate;
+ (void)update:(NSString *)message;
+ (void)dismiss:(BOOL)bNow;

@end

@protocol MiniDropDownAlertViewDelegate <NSObject>

@required

@optional
-(void)dropDownAlertDismissed;

@end

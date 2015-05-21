
#import <UIKit/UIKit.h>

#define HOLD_TIME_DEFAULT 0 // Forces use of Theme.m hold time settings

@protocol DropDownAlertViewDelegate;
@protocol UIGestureRecognizerDelegate;

@interface DropDownAlertView : UIView

@property (nonatomic, assign) id<DropDownAlertViewDelegate> delegate;

+ (void)initAll;
+ (void)create:(UIView *)parentView message:(NSString *)message;
+ (void)create:(UIView *)parentView image:(UIImage *)image line1:(NSString *)line1 line2:(NSString *)line2 line3:(NSString *)line3 holdTime:(CGFloat)holdTime withDelegate:(id<DropDownAlertViewDelegate>)delegate;
+ (void)create:(UIView *)parentView message:(NSString *)message holdTime:(CGFloat)holdTime withDelegate:(id<DropDownAlertViewDelegate>)delegate;
+ (void)create:(UIView *)parentView message:(NSString *)message image:(UIImage *)image line1:(NSString *)line1 line2:(NSString *)line2 line3:(NSString *)line3 holdTime:(CGFloat)holdTime withDelegate:(id<DropDownAlertViewDelegate>)delegate;
+ (void)dismiss:(BOOL)bNow;

//+ (void)CreateDropView:(UIView *)parentView withDelegate:(id<DropDownAlertViewDelegate>)delegate;
//+ (void)CreateInsideView:(UIView *)parentView withDelegate:(id<DropDownAlertViewDelegate>)delegate;
//+ (void)CreateLoadingView:(UIView *)parentView withDelegate:(id<DropDownAlertViewDelegate>)delegate;
//
//- (void)blockModal:(BOOL)blocking;
//- (void)showSpinner:(BOOL)visible;
//- (void)showSpinner:(BOOL)visible center:(BOOL)center;
//- (void)messageTextSet:(NSString *)message;
//- (void)photoAlertSet:(UIImage *)image line1:(NSString *)line1 line2:(NSString *)line2 line3:(NSString *)line3;
//- (void)show;
//- (void)showFading;

@end

@protocol DropDownAlertViewDelegate <NSObject>

@required

@optional
-(void)dropDownAlertDismissed;

@end

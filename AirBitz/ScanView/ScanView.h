
#import <UIKit/UIKit.h>

@interface ScanView : UIView

@property (nonatomic, assign) int fadeDelay;
@property (nonatomic, assign) int fadeDuration;
@property (nonatomic, copy) NSString *message;

+ (ScanView *)CreateInsideView:(UIView *)parentView;

@end

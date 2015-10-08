
#import <UIKit/UIKit.h>

@protocol ScanViewDelegate;

@interface ScanView : UIView

@property (nonatomic, assign) id<ScanViewDelegate> delegate;

+ (ScanView *)CreateView:(UIView *)parentView;

- (void)startQRReader;
- (void)stopQRReader;
- (void)willRotateOrientation:(UIInterfaceOrientation) orientation;

@end

@protocol ScanViewDelegate <NSObject>

@required
- (BOOL)processResultArray:(NSArray *)results;
@optional

@end

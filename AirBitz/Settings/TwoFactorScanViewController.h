
#import <UIKit/UIKit.h>

@protocol TwoFactorScanViewControllerDelegate;

@interface TwoFactorScanViewController : UIViewController

@property (assign) id<TwoFactorScanViewControllerDelegate> delegate;

@end


@protocol TwoFactorScanViewControllerDelegate <NSObject>

-(void)twoFactorScanViewControllerDone:(TwoFactorScanViewController *)controller withBackButton:(BOOL)bBack;

@optional
@end


#import <UIKit/UIKit.h>

@protocol SpendingLimitsViewControllerDelegate;

@interface SpendingLimitsViewController : UIViewController

@property (assign) id<SpendingLimitsViewControllerDelegate> delegate;

@end


@protocol SpendingLimitsViewControllerDelegate <NSObject>

-(void)spendingLimitsViewControllerDone:(SpendingLimitsViewController *)controller withBackButton:(BOOL)bBack;

@optional
@end

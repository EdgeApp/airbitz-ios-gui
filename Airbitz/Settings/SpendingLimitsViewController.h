
#import <UIKit/UIKit.h>
#import "AirbitzViewController.h"

@protocol SpendingLimitsViewControllerDelegate;

@interface SpendingLimitsViewController : AirbitzViewController

@property (assign) id<SpendingLimitsViewControllerDelegate> delegate;

@end


@protocol SpendingLimitsViewControllerDelegate <NSObject>

-(void)spendingLimitsViewControllerDone:(SpendingLimitsViewController *)controller withBackButton:(BOOL)bBack;

@optional
@end

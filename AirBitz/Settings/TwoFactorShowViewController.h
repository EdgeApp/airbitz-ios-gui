
#import <UIKit/UIKit.h>
#import "AirbitzViewController.h"

@protocol TwoFactorShowViewControllerDelegate;

@interface TwoFactorShowViewController : AirbitzViewController

@property (assign) id<TwoFactorShowViewControllerDelegate> delegate;

@end


@protocol TwoFactorShowViewControllerDelegate <NSObject>

-(void)twoFactorShowViewControllerDone:(TwoFactorShowViewController *)controller withBackButton:(BOOL)bBack;

@optional
@end

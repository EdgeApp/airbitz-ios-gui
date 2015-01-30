
#import <UIKit/UIKit.h>

@protocol TwoFactorShowViewControllerDelegate;

@interface TwoFactorShowViewController : UIViewController

@property (assign) id<TwoFactorShowViewControllerDelegate> delegate;

@end


@protocol TwoFactorShowViewControllerDelegate <NSObject>

-(void)twoFactorShowViewControllerDone:(TwoFactorShowViewController *)controller withBackButton:(BOOL)bBack;

@optional
@end

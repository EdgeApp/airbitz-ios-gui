
#import <UIKit/UIKit.h>

@protocol TwoFactorMenuViewControllerDelegate;

@interface TwoFactorMenuViewController : UIViewController

@property (assign) id<TwoFactorMenuViewControllerDelegate> delegate;
@property (assign) NSString *secret;
@property (assign) BOOL bSuccess;
@property (assign) BOOL bStoreSecret;
@property (assign) BOOL bTestSecret;

@end


@protocol TwoFactorMenuViewControllerDelegate <NSObject>

-(void)twoFactorMenuViewControllerDone:(TwoFactorMenuViewController *)controller withBackButton:(BOOL)bBack;

@optional
@end

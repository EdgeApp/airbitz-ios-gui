
#import <UIKit/UIKit.h>

@protocol TwoFactorMenuViewControllerDelegate;

@interface TwoFactorMenuViewController : UIViewController

@property (assign) id<TwoFactorMenuViewControllerDelegate> delegate;
@property (copy) NSString *secret;
@property (copy) NSString *username;
@property (assign) BOOL bSuccess;
@property (assign) BOOL bStoreSecret;
@property (assign) BOOL bTestSecret;

@end


@protocol TwoFactorMenuViewControllerDelegate <NSObject>

-(void)twoFactorMenuViewControllerDone:(TwoFactorMenuViewController *)controller withBackButton:(BOOL)bBack;

@optional
@end

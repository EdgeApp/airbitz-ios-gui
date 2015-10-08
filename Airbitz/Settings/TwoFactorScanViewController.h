
#import <UIKit/UIKit.h>
#import "AirbitzViewController.h"

@protocol TwoFactorScanViewControllerDelegate;

@interface TwoFactorScanViewController : AirbitzViewController

@property (assign) id<TwoFactorScanViewControllerDelegate> delegate;
@property (assign) NSString *secret;
@property (assign) BOOL bSuccess;
@property (assign) BOOL bStoreSecret;
@property (assign) BOOL bTestSecret;

@end


@protocol TwoFactorScanViewControllerDelegate <NSObject>

-(void)twoFactorScanViewControllerDone:(TwoFactorScanViewController *)controller withBackButton:(BOOL)bBack;

@optional
@end

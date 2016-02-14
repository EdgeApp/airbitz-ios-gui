
#import <UIKit/UIKit.h>
#import "AirbitzViewController.h"

@protocol TwoFactorMenuViewControllerDelegate;

@interface TwoFactorMenuViewController : AirbitzViewController

@property (assign) id<TwoFactorMenuViewControllerDelegate> delegate;
@property (copy) NSString *secret;
@property (copy) NSString *username;
@property (copy) NSDate *resetDate;
@property (assign) BOOL bSuccess;
@property (assign) BOOL bStoreSecret;
@property (assign) BOOL bTestSecret;

@end


@protocol TwoFactorMenuViewControllerDelegate <NSObject>

-(void)twoFactorMenuViewControllerDone:(TwoFactorMenuViewController *)controller withBackButton:(BOOL)bBack;

@optional
@end

//
//  BuySellViewController.h
//  AirBitz
//

#import <UIKit/UIKit.h>
#import "AirbitzViewController.h"

@protocol BuySellViewControllerDelegate;

@interface BuySellViewController : AirbitzViewController

@property (assign) id<BuySellViewControllerDelegate> delegate;
- (BOOL)launchPluginByCountry:(NSString *)country provider:(NSString *)provider uri:(NSURL *)uri;

@end


@protocol BuySellViewControllerDelegate <NSObject>

@required
@end

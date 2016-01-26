//
//  BuySellViewController.h
//  AirBitz
//

#import <UIKit/UIKit.h>
#import "AirbitzViewController.h"

@protocol GiftCardViewControllerDelegate;

@interface GiftCardViewController : AirbitzViewController

@property (assign) id<GiftCardViewControllerDelegate> delegate;
- (void)resetViews;

@end


@protocol GiftCardViewControllerDelegate <NSObject>

@required
@end

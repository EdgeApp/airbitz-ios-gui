//
//  BuySellViewController.h
//  AirBitz
//

#import <UIKit/UIKit.h>
#import "AirbitzViewController.h"

@protocol PluginListViewControllerDelegate;

@interface PluginListViewController : AirbitzViewController

@property (assign) id<PluginListViewControllerDelegate> delegate;
- (void)resetViews;

@end


@protocol PluginListViewControllerDelegate <NSObject>

@required
@end

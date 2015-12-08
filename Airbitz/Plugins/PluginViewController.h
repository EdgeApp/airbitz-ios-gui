//
//  PluginViewController.h
//  AirBitz
//

#import <UIKit/UIKit.h>
#import "Plugin.h"

@protocol PluginViewControllerDelegate;

@interface PluginViewController : UIViewController

@property (assign) id<PluginViewControllerDelegate> delegate;
@property (assign) Plugin *plugin;
@property (assign) NSURL *uri;

@end


@protocol PluginViewControllerDelegate <NSObject>

@required
- (void)PluginViewControllerDone:(PluginViewController *)vc;
@end

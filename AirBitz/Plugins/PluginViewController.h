//
//  PluginViewController.h
//  AirBitz
//

#import <UIKit/UIKit.h>

@protocol PluginViewControllerDelegate;

@interface PluginViewController : UIViewController

@property (assign) id<PluginViewControllerDelegate> delegate;

@end


@protocol PluginViewControllerDelegate <NSObject>

@required
- (void)PluginViewControllerDone:(PluginViewController *)vc;
@end

//
//  DebugViewController.h
//  AirBitz
//
//  See LICENSE for copy, modification, and use permissions
//
//  See AUTHORS for contributing developers
//

#import <UIKit/UIKit.h>

@protocol DebugViewControllerDelegate;

@interface DebugViewController : UIViewController

@property (assign)          id<DebugViewControllerDelegate>  delegate;

@end

@protocol DebugViewControllerDelegate <NSObject>

@required
-(void) sendDebugViewControllerDidFinish:(DebugViewController *)controller;
@end

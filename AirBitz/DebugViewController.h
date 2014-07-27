//
//  DebugViewController.h
//  AirBitz
//
//  Created by Timbo on 6/16/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
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

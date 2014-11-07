//
//  PINReLoginViewController.h
//  AirBitz
//
//  Created by Allan on 11/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

@protocol PINReLoginViewControllerDelegate;

@interface PINReLoginViewController : UIViewController

@property (assign) id<PINReLoginViewControllerDelegate> delegate;

@end

@protocol PINReLoginViewControllerDelegate <NSObject>

@required
-(void)PINReLoginViewControllerDidSwitchUserWithMessage:(NSString *)message;
-(void)PINReLoginViewControllerDidAbort;
-(void)PINReLoginViewControllerDidLogin;
@end

//
//  LoginViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoginViewControllerDelegate;

@interface LoginViewController : UIViewController

@property (assign) id<LoginViewControllerDelegate> delegate;

@end




@protocol LoginViewControllerDelegate <NSObject>

@required
-(void)loginViewControllerDidAbort;
-(void)loginViewControllerDidLogin:(BOOL)bNewAccount;
-(void)loginViewControllerDidSwitchAccount;
@end

//
//  PasswordRecoveryViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/20/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PasswordRecoveryViewControllerDelegate;

@interface PasswordRecoveryViewController : UIViewController

@property (assign) id<PasswordRecoveryViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *userName;

@end

@protocol PasswordRecoveryViewControllerDelegate <NSObject>

@required
-(void)passwordRecoveryViewControllerDidFinish:(PasswordRecoveryViewController *)controller;
@end
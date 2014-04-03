//
//  SignUpViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SignUpViewControllerDelegate;

@interface SignUpViewController : UIViewController

@property (assign) id<SignUpViewControllerDelegate> delegate;

@end


@protocol SignUpViewControllerDelegate <NSObject>

@required
-(void)signupViewControllerDidFinish:(SignUpViewController *)controller;
@end
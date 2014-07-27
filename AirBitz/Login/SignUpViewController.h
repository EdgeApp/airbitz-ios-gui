//
//  SignUpViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum eSignUpMode
{
    SignUpMode_SignUp,
    SignUpMode_ChangePassword,
    SignUpMode_ChangePIN,
    SignUpMode_ChangePasswordUsingAnswers
} tSignUpMode;

@protocol SignUpViewControllerDelegate;

@interface SignUpViewController : UIViewController

@property (assign)            id<SignUpViewControllerDelegate> delegate;
@property (nonatomic, assign) tSignUpMode                      mode;
@property (nonatomic, copy)   NSString                         *strUserName; // only used for SignUpMode_ChangePasswordUsingAnswers
@property (nonatomic, copy)   NSString                         *strAnswers; // only used for SignUpMode_ChangePasswordUsingAnswers

@end


@protocol SignUpViewControllerDelegate <NSObject>

@required

-(void)signupViewControllerDidFinish:(SignUpViewController *)controller withBackButton:(BOOL)bBack;

@end
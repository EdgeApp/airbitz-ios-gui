//
//  PasswordVerifyView.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/21/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PasswordVerifyViewDelegate;

@interface PasswordVerifyView : UIView

@property (nonatomic, assign) id<PasswordVerifyViewDelegate> delegate;
@property (nonatomic, copy) NSString *password;

+ (PasswordVerifyView *)CreateInsideView:(UIView *)parentView withDelegate:(id<PasswordVerifyViewDelegate>)delegate;

-(void)dismiss;
@end



@protocol PasswordVerifyViewDelegate <NSObject>

@required
-(void)PasswordVerifyViewDismissed:(PasswordVerifyView *)pv;
@optional

@end
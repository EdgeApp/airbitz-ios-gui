//
//  SendConfirmationViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SendConfirmationViewControllerDelegate;

@interface SendConfirmationViewController : UIViewController


@property (assign) id<SendConfirmationViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *sendToAddress;
@property (nonatomic, assign) int64_t amountToSendSatoshi;
@property (nonatomic, assign) int selectedWalletIndex;
@end


@protocol SendConfirmationViewControllerDelegate <NSObject>

@required
-(void)sendConfirmationViewController:(SendConfirmationViewController *)controller didConfirm:(BOOL)didConfirm;
@end
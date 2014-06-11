//
//  SendConfirmationViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Wallet.h"

@protocol SendConfirmationViewControllerDelegate;

@interface SendConfirmationViewController : UIViewController


@property (assign)              id<SendConfirmationViewControllerDelegate>  delegate;
@property (nonatomic, copy)     NSString                                    *sendToAddress;
@property (nonatomic, copy)     NSString                                    *nameLabel;
@property (nonatomic, assign)   int64_t                                     amountToSendSatoshi;
@property (nonatomic, assign)   int                                         selectedWalletIndex;
@property (nonatomic, strong)   Wallet                                      *wallet;
@property (nonatomic, assign)   BOOL                                        bAddressIsWalletUUID;

@end


@protocol SendConfirmationViewControllerDelegate <NSObject>

@required
-(void)sendConfirmationViewControllerDidFinish:(SendConfirmationViewController *)controller;
@end

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
@property (nonatomic, copy)     NSString                                    *category;
@property (nonatomic, copy)     NSString                                    *notes;
@property (nonatomic, copy)     NSString                                    *returnUrl;
@property (nonatomic, assign)   int64_t                                     amountToSendSatoshi;
@property (nonatomic, assign)   double                                      overrideCurrency;
@property (nonatomic, strong)   Wallet                                      *wallet;
@property (nonatomic, strong)   Wallet                                      *destWallet;
@property (nonatomic, assign)   BOOL                                        bAddressIsWalletUUID;
@property (nonatomic, assign)   BOOL                                        bAdvanceToTx;

@end


@protocol SendConfirmationViewControllerDelegate <NSObject>

@required
-(void)sendConfirmationViewControllerDidFinish:(SendConfirmationViewController *)controller;

@optional
-(void)sendConfirmationViewControllerDidFinish:(SendConfirmationViewController *)controller
                                      withBack:(BOOL)bBack
                                     withError:(BOOL)bError
                                      withTxId:(NSString *)txid;

@end

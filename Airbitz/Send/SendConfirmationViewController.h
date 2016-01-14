//
//  SendConfirmationViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Wallet.h"
#import "ABC.h"
#import "SpendTarget.h"
#import "AirbitzViewController.h"

@protocol SendConfirmationViewControllerDelegate;

@interface SendConfirmationViewController : AirbitzViewController


@property (assign)              id<SendConfirmationViewControllerDelegate>  delegate;
@property (nonatomic, assign)   double                                      overrideCurrency;
@property (nonatomic, strong)   SpendTarget                                 *spendTarget;
//@property (nonatomic, strong)   Wallet                                      *wallet;
@property (nonatomic, assign)   BOOL                                        bAdvanceToTx;
@property (nonatomic, assign)   BOOL                                        bSignOnly;

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

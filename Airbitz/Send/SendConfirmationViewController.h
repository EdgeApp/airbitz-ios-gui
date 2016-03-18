//
//  SendConfirmationViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ABCWallet.h"
#import "ABCSpend.h"
#import "AirbitzViewController.h"

@protocol SendConfirmationViewControllerDelegate;

@interface SendConfirmationViewController : AirbitzViewController


@property (assign)              id<SendConfirmationViewControllerDelegate>  delegate;
@property (nonatomic, strong)   ABCParsedURI                                *parsedURI;
@property (nonatomic, strong)   ABCWallet                                   *destWallet;
@property (nonatomic, strong)   ABCPaymentRequest                           *paymentRequest;
@property (nonatomic, strong)   NSString                                    *address2;
@property (nonatomic)           uint64_t                                    amountSatoshi2;

@property (nonatomic, assign)   BOOL                                        bAdvanceToTx;
@property (nonatomic, assign)   BOOL                                        bSignOnly;
@property (nonatomic, assign)   BOOL                                        bAmountImmutable;

@end


@protocol SendConfirmationViewControllerDelegate <NSObject>

@required
-(void)sendConfirmationViewControllerDidFinish:(SendConfirmationViewController *)controller;

@optional
-(void)sendConfirmationViewControllerDidFinish:(SendConfirmationViewController *)controller
                                      withBack:(BOOL)bBack
                                     withError:(BOOL)bError
                                   transaction:(ABCTransaction *)transaction
                                  withUnsentTx:(ABCUnsentTx *)unsentTx;

@end

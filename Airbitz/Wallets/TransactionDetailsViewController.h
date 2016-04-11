//
//  TransactionDetailsViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ABCTransaction.h"
#import "ABCWallet.h"
#import "AirbitzViewController.h"

typedef enum eTDMode
{
	TD_MODE_RECEIVED,
	TD_MODE_SENT
} tTDMode;

@protocol TransactionDetailsViewControllerDelegate;

@interface TransactionDetailsViewController : AirbitzViewController

@property (assign)            id<TransactionDetailsViewControllerDelegate>  delegate;
@property (nonatomic, strong) ABCTransaction *transaction;
@property (nonatomic, strong) ABCWallet *wallet;
@property (nonatomic, assign) tTDMode                                       transactionDetailsMode;
@property (nonatomic, assign) BOOL                                          bOldTransaction;
@property (nonatomic, strong) UIImage                                       *photo;
@property (nonatomic, strong) NSString                                      *returnUrl;
@property (nonatomic, strong) NSString                                      *photoUrl;

@end

@protocol TransactionDetailsViewControllerDelegate <NSObject>

@required
- (void)TransactionDetailsViewControllerDone:(TransactionDetailsViewController *)controller;
@optional

@end

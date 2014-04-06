//
//  TransactionDetailsViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Transaction.h"

typedef enum eTDMode
{
	TD_MODE_RECEIVED,
	TD_MODE_SENT
} tTDMode;

@protocol TransactionDetailsViewControllerDelegate;

@interface TransactionDetailsViewController : UIViewController

@property (assign) id<TransactionDetailsViewControllerDelegate> delegate;
@property (nonatomic, weak) Transaction *transaction;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, assign) tTDMode transactionDetailsMode;

@end

@protocol TransactionDetailsViewControllerDelegate <NSObject>

@required
-(void)TransactionDetailsViewControllerDone:(TransactionDetailsViewController *)controller;
@optional
@end
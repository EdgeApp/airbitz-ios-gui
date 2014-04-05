//
//  TransactionDetailsViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Transaction.h"

@protocol TransactionDetailsViewControllerDelegate;

@interface TransactionDetailsViewController : UIViewController

@property (assign) id<TransactionDetailsViewControllerDelegate> delegate;
@property (nonatomic, weak) Transaction *transaction;

@end

@protocol TransactionDetailsViewControllerDelegate <NSObject>

@required
-(void)TransactionDetailsViewControllerDone:(TransactionDetailsViewController *)controller;
@optional
@end
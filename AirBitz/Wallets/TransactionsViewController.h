//
//  TransactionsViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Wallet.h"
#import "AirbitzViewController.h"

@protocol TransactionsViewControllerDelegate;

@interface TransactionsViewController : AirbitzViewController

@property (assign) id<TransactionsViewControllerDelegate> delegate;
//@property (nonatomic, strong) Wallet *wallet;

@end


@protocol TransactionsViewControllerDelegate <NSObject>

@required
//-(void)TransactionsViewControllerDone:(TransactionsViewController *)controller;
@optional
@end

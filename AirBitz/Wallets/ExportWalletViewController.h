//
//  ExportWalletViewController.h
//  AirBitz
//
//  Created by Adam Harris on 5/26/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Wallet.h"

@protocol ExportWalletViewControllerDelegate;

@interface ExportWalletViewController : UIViewController

@property (assign)            id<ExportWalletViewControllerDelegate> delegate;
@property (nonatomic, strong) Wallet                                 *wallet;

@end

@protocol ExportWalletViewControllerDelegate <NSObject>

@required

- (void)exportWalletViewControllerDidFinish:(ExportWalletViewController *)controller;

@end


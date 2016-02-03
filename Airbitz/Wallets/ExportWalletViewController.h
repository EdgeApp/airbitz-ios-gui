//
//  ExportWalletViewController.h
//  AirBitz
//
//  Created by Adam Harris on 5/26/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ABCWallet.h"
#import "AirbitzViewController.h"

@protocol ExportWalletViewControllerDelegate;

@interface ExportWalletViewController : AirbitzViewController

@property (assign)            id<ExportWalletViewControllerDelegate> delegate;

@end

@protocol ExportWalletViewControllerDelegate <NSObject>

@required

- (void)exportWalletViewControllerDidFinish:(ExportWalletViewController *)controller;

@end


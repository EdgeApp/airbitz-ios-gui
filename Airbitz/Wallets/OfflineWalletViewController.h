//
//  OfflineWalletViewController.h
//  AirBitz
//
//  Created by Adam Harris on 5/13/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OfflineWalletViewControllerDelegate;

@interface OfflineWalletViewController : UIViewController

@property (assign)            id<OfflineWalletViewControllerDelegate> delegate;

@end

@protocol OfflineWalletViewControllerDelegate <NSObject>

@required

- (void)offlineWalletViewControllerDidFinish:(OfflineWalletViewController *)controller;

@end
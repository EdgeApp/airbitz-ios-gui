//
//  ImportWalletViewController.h
//  AirBitz
//
//  Created by Adam Harris on 5/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ImportWalletViewControllerDelegate;

@interface ImportWalletViewController : UIViewController

@property (assign)            id<ImportWalletViewControllerDelegate> delegate;

@end

@protocol ImportWalletViewControllerDelegate <NSObject>

@required

- (void)importWalletViewControllerDidFinish:(ImportWalletViewController *)controller;

@end
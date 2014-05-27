//
//  ExportWalletOptionsOptionsViewController.h
//  AirBitz
//
//  Created by Adam Harris on 5/26/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ExportWalletOptionsViewControllerDelegate;

@interface ExportWalletOptionsViewController : UIViewController

@property (assign)            id<ExportWalletOptionsViewControllerDelegate> delegate;

@end

@protocol ExportWalletOptionsViewControllerDelegate <NSObject>

@required

- (void)exportWalletOptionsViewControllerDidFinish:(ExportWalletOptionsViewController *)controller;

@end
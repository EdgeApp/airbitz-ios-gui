//
//  ExportWalletOptionsOptionsViewController.h
//  AirBitz
//
//  Created by Adam Harris on 5/26/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Wallet.h"
#import "DateTime.h"
#import "AirbitzViewController.h"

typedef enum eWalletExportType
{
    WalletExportType_CSV = 0,
    WalletExportType_Quicken,
    WalletExportType_Quickbooks,
    WalletExportType_PDF,
    WalletExportType_PrivateSeed
} tWalletExportType;

@protocol ExportWalletOptionsViewControllerDelegate;

@interface ExportWalletOptionsViewController : AirbitzViewController

@property (assign)            id<ExportWalletOptionsViewControllerDelegate> delegate;
@property (assign)            tWalletExportType                             type;
@property (nonatomic, strong) DateTime                                      *fromDateTime;
@property (nonatomic, strong) DateTime                                      *toDateTime;

@end

@protocol ExportWalletOptionsViewControllerDelegate <NSObject>

@required

- (void)exportWalletOptionsViewControllerDidFinish:(ExportWalletOptionsViewController *)controller;

@end
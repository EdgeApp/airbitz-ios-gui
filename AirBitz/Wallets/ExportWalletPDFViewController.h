//
//  ExportWalletOptionsOptionsViewController.h
//  AirBitz
//
//  Created by Adam Harris on 6/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>



@protocol ExportWalletPDFViewControllerDelegate;

@interface ExportWalletPDFViewController : UIViewController

@property (assign)            id<ExportWalletPDFViewControllerDelegate> delegate;
@property (nonatomic, strong) NSData                                    *dataPDF;


@end

@protocol ExportWalletPDFViewControllerDelegate <NSObject>

@required

- (void)exportWalletPDFViewControllerDidFinish:(ExportWalletPDFViewController *)controller;

@end
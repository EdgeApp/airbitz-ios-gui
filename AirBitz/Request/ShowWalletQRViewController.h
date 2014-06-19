//
//  ShowWalletQRViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ShowWalletQRViewControllerDelegate;

@interface ShowWalletQRViewController : UIViewController

@property (assign) id<ShowWalletQRViewControllerDelegate> delegate;
@property (nonatomic, strong) UIImage *qrCodeImage;
@property (nonatomic, strong) NSString *statusString;
@property (nonatomic, strong) NSString *addressString;
@property (nonatomic, assign) int64_t amountSatoshi;

- (IBAction)Back;

@end




@protocol ShowWalletQRViewControllerDelegate <NSObject>

@required

-(void)ShowWalletQRViewControllerDone:(ShowWalletQRViewController *)controller;
@end

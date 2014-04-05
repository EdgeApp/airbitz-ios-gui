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
@property (nonatomic, strong) IBOutlet UIImage *qrCodeImage;

@end




@protocol ShowWalletQRViewControllerDelegate <NSObject>

@required

-(void)ShowWalletQRViewControllerDone:(ShowWalletQRViewController *)controller;
@end
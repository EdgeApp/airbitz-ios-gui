//
//  RequestViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RequestViewControllerDelegate;

@interface RequestViewController : UIViewController

@property (assign) id<RequestViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString  *walletUUID;
@property (nonatomic, readwrite) SInt64 originalAmountSatoshi;

- (BOOL)showingQRCode:(NSString *)walletUUID withTx:(NSString *)txId;
- (SInt64)transactionDifference:(NSString *)walletUUID withTx:(NSString *)txId;
- (void)LaunchQRCodeScreen: (SInt64)amountSatoshi;
- (void)resetViews;

@end


@protocol RequestViewControllerDelegate <NSObject>

@required
-(void)RequestViewControllerDone:(RequestViewController *)vc;
@end

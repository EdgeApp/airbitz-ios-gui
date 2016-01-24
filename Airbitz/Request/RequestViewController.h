//
//  RequestViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonTypes.h"
#import "AirbitzViewController.h"

@protocol RequestViewControllerDelegate;

@interface RequestViewController : AirbitzViewController

@property (assign) id<RequestViewControllerDelegate> delegate;
@property (nonatomic, readwrite) SInt64 originalAmountSatoshi;
@property (nonatomic, strong) NSString                    *requestID;


- (BOOL)showingQRCode:(NSString *)walletUUID withTx:(NSString *)txId;
- (RequestState)updateQRCode:(SInt64)incomingSatoshi;
- (void)resetViews;
- (IBAction)segmentedControlBTCUSDAction:(id)sender;


@end


@protocol RequestViewControllerDelegate <NSObject>

@required

@end


//
//  WalletMakerView.h
//  AirBitz
//
//  Created by Carson Whitsett on 4/4/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ButtonSelectorView.h"

@protocol WalletMakerViewDelegate;

@interface WalletMakerView : UIView

@property (nonatomic, assign) id<WalletMakerViewDelegate>   delegate;


- (void)reset;
- (void)exit;

@end

@protocol WalletMakerViewDelegate <NSObject>

@required


@optional

- (void)walletMakerViewExit:(WalletMakerView *)walletMakerView;
- (void)walletMakerViewExitOffline:(WalletMakerView *)walletMakerView;


@end

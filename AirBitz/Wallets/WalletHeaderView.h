//
//  WalletHeaderView.h
//  AirBitz
//
//  Created by Carson Whitsett on 6/2/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//
//  Used as the section headerView for the wallets table in WalletsViewController.
//  Initialize with CreateWithTitle:
//  Set the delegate if you want to receive notifications when the expand/collapse button was tapped
//  (button will just rotate and nothing else will happen if you don't)
//  If the expand/collapse button is not needed, just set btn_expandCollapse.hidden = YES

#import <UIKit/UIKit.h>

@protocol WalletHeaderViewDelegate;

@interface WalletHeaderView : UIView

@property(nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *btn_expandCollapse;
@property (nonatomic, weak) IBOutlet UIButton *btn_addWallet;
@property (nonatomic, weak) IBOutlet UIButton *btn_header;
@property (nonatomic, assign) id<WalletHeaderViewDelegate>   delegate;
+(WalletHeaderView *)CreateWithTitle:(NSString *)title collapse:(BOOL)bCollapsed;

@end


@protocol WalletHeaderViewDelegate <NSObject>

@required
- (void)walletHeaderView:(WalletHeaderView *)walletHeaderView Expanded:(BOOL)expanded;
- (void)addWallet;

@optional
- (void)headerButton;

@end

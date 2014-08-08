//
//  WalletsViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WalletsViewController : UIViewController

- (void)reloadWallets;
- (void)selectWalletWithUUID:(NSString *)strUUID;
- (void)resetViews;

@end

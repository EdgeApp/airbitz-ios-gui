//
//  SyncView.h
//  AirBitz
//
//  Created by Tim Horton on 3/21/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SyncViewDelegate;

@interface SyncView : UIView

@property (nonatomic, assign) id<SyncViewDelegate> delegate;

+ (SyncView *)createView:(UIView *)parentView forWallet:(NSString *)walletUUID;
- (void)dismiss;

@end

@protocol SyncViewDelegate <NSObject>

@required
- (void)SyncViewDismissed:(SyncView *)sv;
@optional

@end

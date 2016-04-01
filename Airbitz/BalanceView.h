//
//  BalanceView.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BalanceViewDelegate;

@interface BalanceView : UIView

@property (assign) id<BalanceViewDelegate> delegate;
+ (BalanceView *)CreateWithDelegate:(id)del;
- (void)showBalance:(BOOL)show;
@property (nonatomic, strong) IBOutlet UILabel *topAmount;
@property (nonatomic, strong) IBOutlet UILabel *botAmount;
@property (nonatomic, strong) IBOutlet UILabel *botDenomination;

@end

@protocol BalanceViewDelegate <NSObject>

@required

@optional
-(void)BalanceViewChanged:(BalanceView *)view show:(BOOL)show;
@end

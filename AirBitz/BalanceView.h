//
//  BalanceView.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BalanceViewDelegate;

typedef enum eBalanceViewState
{
    BALANCE_VIEW_UP,
    BALANCE_VIEW_DOWN
}tBalanceViewState;

@interface BalanceView : UIView

@property (assign) id<BalanceViewDelegate> delegate;
@property BOOL barIsUp;

+ (BalanceView *)CreateWithDelegate:(id)del;

- (void)refresh;
@property (nonatomic, weak) IBOutlet UIImageView *topIcon;
@property (nonatomic, weak) IBOutlet UILabel *topAmount;
@property (nonatomic, weak) IBOutlet UILabel *topDenomination;
@property (nonatomic, weak) IBOutlet UIImageView *botIcon;
@property (nonatomic, weak) IBOutlet UILabel *botAmount;
@property (nonatomic, weak) IBOutlet UILabel *botDenomination;

@end



@protocol BalanceViewDelegate <NSObject>

@required

@optional
-(void)BalanceView:(BalanceView *)view changedStateTo:(tBalanceViewState)state;
@end

//
//  BalanceView.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "BalanceView.h"
#import "Theme.h"

@interface BalanceView ()
{
    BOOL            _showingBalance;
}
@property (weak, nonatomic) IBOutlet UIView *balanceView;
@property (weak, nonatomic) IBOutlet UILabel *showBalanceLabel;

@end

@implementation BalanceView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        [self initMyVariables];
    }
    return self;
}

-(void)awakeFromNib
{
    [self initMyVariables];
}

- (void)finishedLoading;
{
    [self.showBalanceLabel setText:showBalanceText];
}

- (void)showBalance:(BOOL)show;
{
    float balanceViewAlpha, showBalanceLabelAlpha;
    if (show && !_showingBalance)
    {
        balanceViewAlpha = 1.0;
        showBalanceLabelAlpha = 0.0;
        _showingBalance = YES;
    }
    else if (!show && _showingBalance)
    {
        balanceViewAlpha = 0.0;
        showBalanceLabelAlpha = 1.0;
        _showingBalance = NO;
    }
    else
    {
        return;
    }

    if (self.delegate)
        if([self.delegate respondsToSelector:@selector(BalanceViewChanged:show:)])
            [self.delegate BalanceViewChanged:self show:show];
    
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
                        options:[Theme Singleton].animationCurveDefault
                     animations:^{
                         [self.balanceView setAlpha:balanceViewAlpha];
                         [self.showBalanceLabel setAlpha:showBalanceLabelAlpha];
                     } completion:nil];
}

- (IBAction)ShowBalanceTouched:(id)sender
{
    [self showBalance:!_showingBalance];
}

-(void)initMyVariables
{
    [self showBalance:NO];
}

+ (BalanceView *)CreateWithDelegate:(id)del
{
    BalanceView *bv;
    
    bv = [[[NSBundle mainBundle] loadNibNamed:@"BalanceView~iphone" owner:self options:nil] objectAtIndex:0];

    bv.delegate = del;
    [bv.showBalanceLabel setText:loadingText];
    [bv.balanceView setAlpha:0.0];
    [bv.showBalanceLabel setAlpha:1.0];
    
    return bv;
}

@end

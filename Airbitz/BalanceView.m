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

- (void)showBalance:(BOOL)show;
{
    float balanceViewAlpha, showBalanceLabelAlpha;
    
    if (show)
    {
        balanceViewAlpha = 1.0;
        showBalanceLabelAlpha = 0.0;
        _showingBalance = YES;
    }
    else
    {
        balanceViewAlpha = 0.0;
        showBalanceLabelAlpha = 1.0;
        _showingBalance = NO;
    }
    
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
                        options:[Theme Singleton].animationCurveDefault
                     animations:^
     {
         [self.balanceView setAlpha:balanceViewAlpha];
         [self.showBalanceLabel setAlpha:showBalanceLabelAlpha];
     }
                     completion:^(BOOL finished){
                         [self.delegate BalanceViewChanged:self show:show];
                     }];
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
    
    return bv;
}

@end

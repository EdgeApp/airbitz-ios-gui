//
//  BalanceView.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "BalanceView.h"

#define BAR_UP @"Balance_View_Bar_Up"

@interface BalanceView ()
{
    CGPoint originalBarPosition;
}
@property (nonatomic, weak) IBOutlet UIView *bar;
@property (nonatomic, weak) IBOutlet UIImageView *barIcon;
@property (nonatomic, weak) IBOutlet UILabel *barAmount;
@property (nonatomic, weak) IBOutlet UILabel *barDenomination;

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

-(void)initMyVariables
{
    [self refresh];

    originalBarPosition = self.frame.origin;
    self.barAmount.text = self.topAmount.text;
    self.barDenomination.text = self.topDenomination.text;
    self.barIcon.image = [UIImage imageNamed:@"icon_bitcoin_light"];
    
//    [self.layer setBackgroundColor:[[[UIColor blackColor] colorWithAlphaComponent:0.1] CGColor]];
//    [self.layer setBorderColor:[[[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0] colorWithAlphaComponent:1.0] CGColor]];
//    [self.layer setBorderWidth:1.0];
    
    //The rounded corner part, where you specify your view's corner radius:
//    self.layer.cornerRadius = 5;
//    self.clipsToBounds = YES;

    
}

-(void)refresh
{
    _barIsUp = [[NSUserDefaults standardUserDefaults] boolForKey:BAR_UP];
    
    NSString *fiatAmount = [NSString stringWithFormat:@"%@ %@", self.botDenomination.text, self.botAmount.text];
    
    self.botAmount.text = fiatAmount;
    
    if(_barIsUp)
    {
        self.barAmount.text = self.topAmount.text;
        self.barDenomination.text = self.topDenomination.text;
        [self moveBarUp];
    }
    else
    {
        self.barAmount.text = self.botAmount.text;
        self.barDenomination.text = self.botDenomination.text;
        [self moveBarDown];
    }
}

+ (BalanceView *)CreateWithDelegate:(id)del
{

    BalanceView *bv;
    
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
//    {
        bv = [[[NSBundle mainBundle] loadNibNamed:@"BalanceView~iphone" owner:self options:nil] objectAtIndex:0];
//    }
//    else
//    {
//        bv = [[[NSBundle mainBundle] loadNibNamed:@"BalanceView~ipad" owner:self options:nil] objectAtIndex:0];
//    }
    

    bv.delegate = del;
    [bv addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:bv action:@selector(BalanceViewTapped:)]];
    
    return bv;
}

- (void)balanceViewSetBTC
{
    _barIsUp = YES;
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^
                     {
                         [self moveBarUp];
                     }
                     completion:^(BOOL finished)
                     {
                         if([self.delegate respondsToSelector:@selector(BalanceView:changedStateTo:)])
                         {
                             [self.delegate BalanceView:self changedStateTo:BALANCE_VIEW_UP];
                         }
                     }];

    // Store bar position
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [[NSUserDefaults standardUserDefaults] setBool:_barIsUp forKey:BAR_UP];
    [userDefaults synchronize];
}


- (void)balanceViewSetFiat
{
    //move bar down
    _barIsUp = NO;
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^
                     {
                         [self moveBarDown];
                     }
                     completion:^(BOOL finished)
                     {
                         if([self.delegate respondsToSelector:@selector(BalanceView:changedStateTo:)])
                         {
                             [self.delegate BalanceView:self changedStateTo:BALANCE_VIEW_DOWN];
                         }
                     }];

    // Store bar position
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [[NSUserDefaults standardUserDefaults] setBool:_barIsUp forKey:BAR_UP];
    [userDefaults synchronize];
}


- (void)BalanceViewTapped:(UITapGestureRecognizer *)recognizer
{
    if(_barIsUp)
    {
        [self balanceViewSetFiat];
    }
    else
    {
        [self balanceViewSetBTC];
    }
}

- (void)moveBarUp
{
    CGRect frame = self.bar.frame;
    frame.origin.y = originalBarPosition.y;
    self.bar.frame = frame;
    self.barAmount.text = self.topAmount.text;
    self.barDenomination.text = self.topDenomination.text;
    self.barIcon.image = [UIImage imageNamed:@"icon_bitcoin_light"];
}

- (void)moveBarDown
{
    CGRect frame = self.bar.frame;
    frame.origin.y = frame.size.height;
    self.bar.frame = frame;
    self.barAmount.text = self.botAmount.text;
    self.barDenomination.text = self.botDenomination.text;
    self.barIcon.image = [UIImage imageNamed:@""];
}

@end

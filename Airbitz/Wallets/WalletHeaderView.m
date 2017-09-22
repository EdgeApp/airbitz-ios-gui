//
//  WalletHeaderView.m
//  AirBitz
//
//  Created by Carson Whitsett on 6/2/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "WalletHeaderView.h"
#import "Theme.h"

@interface WalletHeaderView ()
{
    BOOL headerCollapsed;
}

@end

@implementation WalletHeaderView
@synthesize segmentedControlBTCUSD;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setThemeValues];
    }
    return self;
}

- (void)setThemeValues {
    self.backgroundColor = [Theme Singleton].colorDarkPrimary;
    self.titleLabel.textColor = [Theme Singleton].colorWhite;
}

+(WalletHeaderView *)CreateWithTitle:(NSString *)title collapse:(BOOL)bCollapsed
{
    WalletHeaderView *whv = nil;
    
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        whv = [[[NSBundle mainBundle] loadNibNamed:@"WalletHeaderView~iphone" owner:nil options:nil] objectAtIndex:0];
    }
//    else
//    {
//     av = [[[NSBundle mainBundle] loadNibNamed:@"HowToPlayView~ipad" owner:nil options:nil] objectAtIndex:0];
//     
//    }
    whv.layer.cornerRadius = 0.0;
    whv.titleLabel.text = title;
    whv->headerCollapsed = bCollapsed;
    if (whv->headerCollapsed)
    {
        whv.btn_expandCollapse.transform = CGAffineTransformRotate(whv.btn_expandCollapse.transform, M_PI);
    }
    return whv;
}

- (IBAction)ExpandCollapse
{
    if(headerCollapsed)
    {
        headerCollapsed = NO;
        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                              delay:[Theme Singleton].animationDelayTimeDefault
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             self.btn_expandCollapse.transform = CGAffineTransformRotate(self.btn_expandCollapse.transform, M_PI);
         }
                         completion:^(BOOL finished)
         {
             
             [self.delegate walletHeaderView:self Expanded:YES];
         }];
    }
    else
    {
        headerCollapsed = YES;
        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                              delay:[Theme Singleton].animationDelayTimeDefault
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             self.btn_expandCollapse.transform = CGAffineTransformRotate(self.btn_expandCollapse.transform, -M_PI);
         }
                         completion:^(BOOL finished)
         {
             [self.delegate walletHeaderView:self Expanded:NO];
         }];
    }
}

- (void)createCloseButton
{
    self.btn_addWallet.transform = CGAffineTransformRotate(self.btn_addWallet.transform, M_PI/4);
}

- (IBAction)headerButton
{
    if ([self.delegate respondsToSelector:@selector(headerButton)]) {
        [self.delegate headerButton];
    }
}

- (IBAction)exportButton
{
    if ([self.delegate respondsToSelector:@selector(exportWallet)]) {
        [self.delegate exportWallet];
    }
}

- (IBAction)addWallet
{
    if ([self.delegate respondsToSelector:@selector(addWallet)]) {
        [self.delegate addWallet];
    }
}

- (IBAction)segmentedControlAction:(id)sender {
    
    [self.delegate segmentedControlHeader];
}

@end

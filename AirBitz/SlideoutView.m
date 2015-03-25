//
//  SlideoutView.m
//  AirBitz
//
//  Created by Tom on 3/25/15.
//  Copyright (c) 2015 AirBitz. All rights reserved.
//

#import "SlideoutView.h"


@implementation SlideoutView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        if (self.subviews.count == 0) {
            UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
            UIView *subview = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
            subview.frame = self.bounds;
            [self addSubview:subview];
        }
    }
    return self;
}


- (IBAction)buysellTouched:(id)sender
{
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(slideoutBuySell)])
        {
            [self.delegate slideoutBuySell];
        }
    }
}

- (IBAction)accountTouched:(id)sender
{
    NSLog(@"account touched");
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(slideoutAccount)])
        {
            [self.delegate slideoutAccount];
        }
    }
}

- (IBAction)settingTouched:(id)sender
{
    NSLog(@"setting touched");
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(slideoutSettings)])
        {
            [self.delegate slideoutSettings];
        }
    }
}

- (IBAction)logoutTouched:(id)sender
{
    NSLog(@"logout touched");
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(slideoutLogout)])
        {
            [self.delegate slideoutLogout];
        }
    }
}

@end

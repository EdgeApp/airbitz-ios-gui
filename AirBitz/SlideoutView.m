//
//  SlideoutView.m
//  AirBitz
//
//  Created by Tom on 3/25/15.
//  Copyright (c) 2015 AirBitz. All rights reserved.
//

#import "SlideoutView.h"

@interface SlideoutView ()
{
    CGRect   _originalSlideoutFrame;
    BOOL     _open;
}

@end

@implementation SlideoutView

+ (SlideoutView *)CreateWithDelegate:(id)del parentView:(UIView *)parentView withTab:(UIView *)tabBar;
{
    SlideoutView *v = [[[NSBundle mainBundle] loadNibNamed:@"SlideoutView~iphone" owner:self options:nil] objectAtIndex:0];
    v.delegate = del;

    CGRect f = parentView.frame;
    int topOffset = 64;
    int sliderWidth = 250;
    f.size.width = sliderWidth;
    f.origin.y = topOffset;
    f.origin.x = parentView.frame.size.width - f.size.width;
    f.size.height = parentView.frame.size.height - tabBar.frame.size.height - topOffset;
    v.frame = f;

    v->_originalSlideoutFrame = v.frame;

    f = v.frame;
    f.origin.x = f.origin.x + f.size.width;
    v.frame = f;
    v->_open = NO;

    return v;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)showSlideout:(BOOL)show
{
    [self showSlideout:show withAnimation:YES];
}

- (void)showSlideout:(BOOL)show withAnimation:(BOOL)bAnimation
{
    if (!show)
    {
        CGRect frame = self.frame;
        frame.origin.x = frame.origin.x + frame.size.width;
        if (self.delegate && [self.delegate respondsToSelector:@selector(slideoutWillClose:)]) {
            [self.delegate slideoutWillClose:self];
        }
        if (bAnimation) {
            [UIView animateWithDuration:0.35
                                delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                            animations:^
            {
                self.frame = frame;
            }
                            completion:^(BOOL finished)
            {
                self.hidden = YES;
            }];
        } else {
            self.frame = frame;
            self.hidden = YES;
        }
    } else {
        self.hidden = NO;
        if (self.delegate && [self.delegate respondsToSelector:@selector(slideoutWillOpen:)]) {
            [self.delegate slideoutWillOpen:self];
        }
        if (bAnimation) {
            [UIView animateWithDuration:0.35
                                delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                            animations:^
            {
                self.frame = _originalSlideoutFrame;
            }
                            completion:^(BOOL finished)
            {
                
            }];
        } else {
            self.frame = _originalSlideoutFrame;
        }
    }
    _open = show;
}

- (IBAction)buysellTouched
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(slideoutBuySell)]) {
        [self.delegate slideoutBuySell];
    }
}

- (IBAction)accountTouched
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(slideoutAccount)]) {
        [self.delegate slideoutAccount];
    }
}

- (IBAction)settingTouched
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(slideoutSettings)]) {
        [self.delegate slideoutSettings];
    }
}

- (IBAction)logoutTouched
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(slideoutLogout)]) {
        [self.delegate slideoutLogout];
    }
}

- (BOOL)isOpen
{
    return _open;
}

@end

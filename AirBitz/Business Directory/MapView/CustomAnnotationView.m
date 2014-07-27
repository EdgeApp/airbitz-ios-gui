//
//  CustomAnnotationView.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/25/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "CustomAnnotationView.h"

@implementation CustomAnnotationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

// See this for more information: https://github.com/nfarina/calloutview/pull/9
- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *calloutMaybe = [self.calloutView hitTest:[self.calloutView convertPoint:point fromView:self] withEvent:event];
    return calloutMaybe ?: [super hitTest:point withEvent:event];
}

@end

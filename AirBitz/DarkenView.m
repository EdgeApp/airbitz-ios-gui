//
//  DarkenView.m
//
//  Created by Carson Whitsett on 1/30/14.
//  Copyright (c) 2014 AirBitz, Inc. All rights reserved.
//

#import "DarkenView.h"

@implementation DarkenView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([self.delegate respondsToSelector:@selector(DarkenViewTapped:)])
	{
		[self.delegate DarkenViewTapped:self];
	}
}

@end



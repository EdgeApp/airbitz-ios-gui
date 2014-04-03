//
//  MontserratLabel.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/6/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "MontserratLabel.h"

@implementation MontserratLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	if((self.tag % 100) == 0)
	{
		self.font = [UIFont fontWithName:@"Montserrat-Regular" size:self.font.pointSize];
	}
	else
	{
		self.font = [UIFont fontWithName:@"Montserrat-Bold" size:self.font.pointSize];
	}
}

@end

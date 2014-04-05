//
//  StylizedTextField.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/5/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//
//	Using this textField, you automatically get a white text color and light gray placeholder text.

#import "StylizedTextField.h"

@implementation StylizedTextField

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
	[self setTintColor:[UIColor whiteColor]];
	
	UIColor *color = [UIColor lightTextColor];
	if(self.placeholder)
	{
		self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder attributes:@{NSForegroundColorAttributeName: color}];
	}
}


@end

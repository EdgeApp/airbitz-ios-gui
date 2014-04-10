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
	[super awakeFromNib];
	
	//UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 15.0, 15.0)];
	[button setImage:[UIImage imageNamed:@"clearButton.png"] forState:UIControlStateNormal];
	[button setFrame:CGRectMake(0.0f, 0.0f, 15.0f, 15.0f)]; // Required for iOS7
	[button addTarget:self action:@selector(doClear) forControlEvents:UIControlEventTouchUpInside];
	 self.rightView = button;
	 self.rightViewMode = self.clearButtonMode;
}

-(void)doClear
{
	self.text = @"";
}

@end

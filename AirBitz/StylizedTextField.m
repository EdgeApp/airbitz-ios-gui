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
	[super awakeFromNib];
	[self setTintColor:[UIColor whiteColor]];
	[self setPlaceholderTextColor];
	
	
	//UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 15.0, 15.0)];
	[button setImage:[UIImage imageNamed:@"clearButton.png"] forState:UIControlStateNormal];
	[button setFrame:CGRectMake(0.0f, 0.0f, 15.0f, 15.0f)]; // Required for iOS7
	[button addTarget:self action:@selector(doClear) forControlEvents:UIControlEventTouchUpInside];
	 self.rightView = button;
	 self.rightViewMode = self.clearButtonMode;
	 
	//UIColor *color = [UIColor lightTextColor];
	//YOURTEXTFIELD.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"PlaceHolder Text" attributes:@{NSForegroundColorAttributeName: color}];
}

-(void)setPlaceholderTextColor
{
	if(self.placeholder)
	{
		UIColor *color = [UIColor lightTextColor];
		{
			self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder attributes:@{NSForegroundColorAttributeName: color}];
		}
	}
}


-(void)setPlaceholder:(NSString *)placeholder
{
	[super setPlaceholder:placeholder];
	[self setPlaceholderTextColor];
}

-(void)doClear
{
	self.text = @"";
}

@end

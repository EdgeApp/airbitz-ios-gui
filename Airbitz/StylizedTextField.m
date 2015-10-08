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

-(void)initMyVariables
{
	[self setTintColor:[UIColor whiteColor]];
	[self setPlaceholderTextColor];
	
	
	//UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    /*
	UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 15.0, 15.0)];
	[button setImage:[UIImage imageNamed:@"clearButton.png"] forState:UIControlStateNormal];
	[button setFrame:CGRectMake(0.0f, 0.0f, 15.0f, 15.0f)]; // Required for iOS7
	[button addTarget:self action:@selector(doClear) forControlEvents:UIControlEventTouchUpInside];
	self.rightView = button;
	self.rightViewMode = self.clearButtonMode;
*/
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    self.leftView = paddingView;
    self.leftViewMode = UITextFieldViewModeAlways;
    self.rightView = paddingView;
    self.rightViewMode = UITextFieldViewModeAlways;
    self.tintColor = [UIColor whiteColor];
    
    [self resetBorder];
    
    //The rounded corner part, where you specify your view's corner radius:
    self.layer.cornerRadius = 5;
    self.clipsToBounds = YES;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        [self initMyVariables];
    }
    return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	[self initMyVariables];
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

- (void)resetBorder
{
    [self.layer setBackgroundColor:[[[UIColor blackColor] colorWithAlphaComponent:0.3] CGColor]];
    [self.layer setBorderColor:[[[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.5] colorWithAlphaComponent:1.0] CGColor]];
    [self.layer setBorderWidth:1.0];
}

@end

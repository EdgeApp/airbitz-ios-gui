//
//  StylizedTextField.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/5/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//
//	Using this textField, you automatically get a white text color and light gray placeholder text.

#import "StylizedTextField3.h"
#import "Util.h"
#import "Theme.h"

@implementation StylizedTextField3

-(void)initMyVariables
{
	[self setTintColor:[UIColor whiteColor]];
	[self setPlaceholderTextColor];
	
    self.font = [UIFont fontWithName:[Theme Singleton].appFont size:self.font.pointSize];
	
	//UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
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
		UIColor *color = [UIColor lightGrayColor];
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
    [self.layer setBackgroundColor:[[[UIColor whiteColor] colorWithAlphaComponent:1.0] CGColor]];
    [self.layer setBorderColor:[[[UIColor whiteColor] colorWithAlphaComponent:1.0] CGColor]];
    [self.layer setBorderWidth:1.0];
}

@end

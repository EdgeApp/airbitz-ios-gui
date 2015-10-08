//
//  MinCharTextField.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/25/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "MinCharTextField.h"

@implementation MinCharTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
        self.leftView = paddingView;
        self.leftViewMode = UITextFieldViewModeAlways;
        self.rightView = paddingView;
        self.rightViewMode = UITextFieldViewModeAlways;
        self.tintColor = [UIColor whiteColor];

    }
    return self;
}

-(void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(myTextDidChange)
												 name:UITextFieldTextDidChangeNotification
											   object:self];
	self.layer.cornerRadius = 6.0;
	[super awakeFromNib];
}

- (void)myTextDidChange
{
    // draw a red highlight if number of characters is less than the minimum required
	if(self.text.length < self.minimumCharacters)
	{
		self.layer.borderColor = [[UIColor redColor] CGColor];
		self.layer.borderWidth = 1.0;
		_satisfiesMinimumCharacters = NO;
	}
	else
	{
        [self resetBorder];
		_satisfiesMinimumCharacters = YES;
	}
}

- (void)dealloc
{
    // Stop listening when deallocating your class:
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

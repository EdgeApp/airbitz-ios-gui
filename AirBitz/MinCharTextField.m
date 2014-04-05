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
		self.layer.borderColor = [[UIColor clearColor] CGColor];
		self.layer.borderWidth = 0.0;
		_satisfiesMinimumCharacters = YES;
	}
}

- (void)dealloc
{
    // Stop listening when deallocating your class:
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

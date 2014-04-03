//
//  CalculatorView.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/2/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "CalculatorView.h"

#define OPERATION_CLEAR		0
#define OPERATION_BACK		1
#define OPERATION_DONE		2
#define OPERATION_DIVIDE	3
#define OPERATION_EQUAL		4
#define OPERATION_MINUS		5
#define OPERATION_MULTIPLY	6
#define OPERATION_PLUS		7
#define OPERATION_PERCENT	8

@implementation CalculatorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
	{
		
        [self addSubview:[[[NSBundle mainBundle] loadNibNamed:@"CalculatorView~iphone" owner:self options:nil] objectAtIndex:0]];
    }
    return self;
}


-(IBAction)digit:(UIButton *)sender
{
	if(sender.tag < 10)
	{
		if(sender.tag == 0)
		{
			//allow 0 only if current value is non-zero OR there's a decimal point
			if(([self.textField.text intValue] != 0) || ([self.textField.text rangeOfString:@"."].location != NSNotFound))
			{
				self.textField.text = [self.textField.text stringByAppendingFormat:@"%li", (long)sender.tag];
			}
		}
		else
		{
			self.textField.text = [self.textField.text stringByAppendingFormat:@"%li", (long)sender.tag];
		}
	}
	else
	{
		if ([self.textField.text rangeOfString:@"."].location == NSNotFound)
		{
			self.textField.text = [self.textField.text stringByAppendingString:@"."];
		}
	}
	//[self updateTextFieldContents];
	[self.delegate CalculatorValueChanged:self];
}

-(IBAction)operation:(UIButton *)sender
{
	switch (sender.tag)
	{
		case OPERATION_CLEAR:
			self.textField.text = @"";
			break;
		case OPERATION_BACK:
			self.textField.text = [self.textField.text substringToIndex:self.textField.text.length - (self.textField.text.length > 0)];
			break;
		case OPERATION_DONE:
			[self.delegate CalculatorDone:self];
			break;
		case OPERATION_DIVIDE:
		case OPERATION_EQUAL:
		case OPERATION_MINUS:
		case OPERATION_MULTIPLY:
		case OPERATION_PLUS:
		case OPERATION_PERCENT:
			break;
			
	}
	//[self updateTextFieldContents];
	[self.delegate CalculatorValueChanged:self];
}

@end

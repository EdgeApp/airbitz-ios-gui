//
//  CalculatorView.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/2/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "CalculatorView.h"
#import "ABCContext.h"
#import "Util.h"
#import "AB.h"

#define DIGIT_BACK			11

#define OPERATION_CLEAR		0
#define OPERATION_DONE		2
#define OPERATION_DIVIDE	3
#define OPERATION_EQUAL		4
#define OPERATION_MINUS		5
#define OPERATION_MULTIPLY	6
#define OPERATION_PLUS		7
#define OPERATION_PERCENT	8

@interface CalculatorView ()
{
	float accumulator;
	int operation;
	BOOL lastKeyWasOperation;
    NSString *_decimalSymbol;
    NSNumberFormatter *formatter;
    NSLocale *locale;
}

@property (weak, nonatomic) IBOutlet UIButton *buttonDone;
@property (weak, nonatomic) IBOutlet UIButton *decimalButton;

@end

@implementation CalculatorView

- (void) initAll;
{
    formatter = [[NSNumberFormatter alloc] init];
    locale = [NSLocale autoupdatingCurrentLocale];
    [formatter setLocale:locale];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];

    _decimalSymbol = [formatter decimalSeparator];
    
    [self.decimalButton setTitle:_decimalSymbol forState:UIControlStateNormal];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code
        _calcMode = CALC_MODE_COIN;
//        self.backgroundColor = [UIColor colorWithWhite:0.8
//                                                 alpha:0.4];
        [self initAll];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
	{

        UIView *view = [[[NSBundle mainBundle] loadNibNamed:@"CalculatorView~iphone" owner:self options:nil] objectAtIndex:0];
        _calcMode = CALC_MODE_COIN;
        [Util addSubviewWithConstraints:self child:view];
        [self initAll];
        
    }
    return self;
}

#pragma mark - Action Methods

- (IBAction)digit:(UIButton *)sender
{
	//ABCLog(2,@"Digit: %i", (int)sender.tag);
	if(operation == OPERATION_EQUAL)
	{
		//also clear the accumulator
		//ABCLog(2,@"Clearing accumulator");
		accumulator = 0.0;
		operation = OPERATION_CLEAR;
	}
	if(lastKeyWasOperation)
	{
		//ABCLog(2,@"Clearing textfield");
		self.textField.text = @"";
	}
	if(sender.tag < 10)
	{
		if(sender.tag == 0)
		{
			//allow 0 only if current value is non-zero OR there's a decimal point
			if(([self.textField.text intValue] != 0) || ([self.textField.text rangeOfString:_decimalSymbol].location != NSNotFound))
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
		if(sender.tag == DIGIT_BACK)
		{
			self.textField.text = [self.textField.text substringToIndex:self.textField.text.length - (self.textField.text.length > 0)];
		}
		else
		{
			if ([self.textField.text rangeOfString:_decimalSymbol].location == NSNotFound)
			{
				self.textField.text = [self.textField.text stringByAppendingString:_decimalSymbol];
			}
		}
	}
	lastKeyWasOperation = NO;
	[self.delegate CalculatorValueChanged:self];
}

- (IBAction)operation:(UIButton *)sender
{
	//ABCLog(2,@"Operation %i", (int)sender.tag);
	switch (sender.tag)
	{
		case OPERATION_CLEAR:
			self.textField.text = @"";
			accumulator = 0.0;
			lastKeyWasOperation = NO;
			break;
            //case OPERATION_BACK:
			//self.textField.text = [self.textField.text substringToIndex:self.textField.text.length - (self.textField.text.length > 0)];
			//lastKeyWasOperation = NO;
			//break;
		case OPERATION_DONE:
			[self.delegate CalculatorDone:self];
			lastKeyWasOperation = NO;
			break;
		case OPERATION_DIVIDE:
			[self performLastOperation];
			lastKeyWasOperation = YES;
			break;
		case OPERATION_EQUAL:
			[self performLastOperation];
			lastKeyWasOperation = YES;
			break;
		case OPERATION_MINUS:
			[self performLastOperation];
			lastKeyWasOperation = YES;
			break;
		case OPERATION_MULTIPLY:
			[self performLastOperation];
			lastKeyWasOperation = YES;
			break;
		case OPERATION_PLUS:
			[self performLastOperation];
			lastKeyWasOperation = YES;
			break;
		case OPERATION_PERCENT:
			//[self performLastOperation];
			if(accumulator)
			{
                self.textField.text = [self formattedAcc:(accumulator * ([self textFieldFloatValue] / 100.0))];
			}
			else
			{
                self.textField.text = [self formattedAcc:[self textFieldFloatValue] / 100.0];
			}
			lastKeyWasOperation = YES;
			break;

	}
	if(sender.tag != OPERATION_PERCENT)
	{
		operation = (int)sender.tag;
	}


	[self.delegate CalculatorValueChanged:self];
}

#pragma mark - Public Methods

- (void)hideDoneButton
{
//    self.buttonDone.hidden = YES;
    // Never hide the Done button
//    [self.buttonDone setTitle:@"Next" forState:UIControlStateNormal];
//    UIImage *buttonImage = [UIImage imageNamed:@"btn_calc_next.png"];
//    [self.buttonDone setBackgroundImage:buttonImage forState:UIControlStateNormal];
}

#pragma mark - Misc Methods

- (void)loadAccumulator
{
	accumulator = [self textFieldFloatValue];
}

- (NSString *)formattedAcc: (float) acc
{
    if (_calcMode == CALC_MODE_COIN)
    {
        NSNumber *num = [NSNumber numberWithDouble:acc];
        NSString *string = [formatter stringFromNumber:num];
        int64_t satoshi = [abcAccount.settings.denomination btcStringToSatoshi:string];
        if (satoshi == 0 || acc == 0.0)
            return @"";
        else
            return [abcAccount.settings.denomination satoshiToBTCString:satoshi withSymbol:false];
    }
    else
    {
        if (acc == 0.0)
            return @"";
        else
            return [self.currency doubleToPrettyCurrencyString:acc
                                                    withSymbol:false];
    }
}

- (void)performLastOperation
{
	switch(operation)
	{
		case OPERATION_CLEAR:
		case OPERATION_DONE:
			//ABCLog(2,@"Performing loadAccumulator");
			[self loadAccumulator];
			break;
		case OPERATION_DIVIDE:
			//ABCLog(2,@"Performing Divide");
			accumulator /= [self textFieldFloatValue];
            self.textField.text = [self formattedAcc:accumulator];
			break;
		case OPERATION_EQUAL:
			//ABCLog(2,@"Performing Equal");
			break;
		case OPERATION_MINUS:
			//ABCLog(2,@"Performing Minus");
			accumulator -= [self textFieldFloatValue];
            if (accumulator < 0) accumulator = 0;
            self.textField.text = [self formattedAcc:accumulator];
			break;
		case OPERATION_MULTIPLY:
			//ABCLog(2,@"Performing Multiply");
			accumulator *= [self textFieldFloatValue];
            self.textField.text = [self formattedAcc:accumulator];
			break;
		case OPERATION_PLUS:
			//ABCLog(2,@"Performing Plus");
			accumulator += [self textFieldFloatValue];
            self.textField.text = [self formattedAcc:accumulator];
			break;
		case OPERATION_PERCENT:
			//self.textField.text = [NSString stringWithFormat:@"%.2f", [self textFieldFloatValue] / 100.0];
			break;
	}
}

- (double)textFieldFloatValue;
{
    NSNumber *num = [formatter numberFromString:self.textField.text];
    return [num doubleValue];
}

@end

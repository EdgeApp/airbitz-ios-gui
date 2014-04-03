//
//  RequestViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "RequestViewController.h"
#import "Notifications.h"
#import "Transaction.h"
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

@interface RequestViewController () <UITextFieldDelegate, CalculatorViewDelegate>
{
	UITextField *selectedTextField;
}
@property (nonatomic, weak) IBOutlet CalculatorView *keypadView;
@property (nonatomic, weak) IBOutlet UITextField *BTC_TextField;
@property (nonatomic, weak) IBOutlet UITextField *USD_TextField;

@end

@implementation RequestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	self.keypadView.delegate = self;
	
}

-(void)awakeFromNib
{
	
}

-(void)viewWillAppear:(BOOL)animated
{
	self.BTC_TextField.inputView = self.keypadView;
	self.USD_TextField.inputView = self.keypadView;
	self.BTC_TextField.delegate = self;
	self.USD_TextField.delegate = self;
	
	//set initial textField contents
	self.BTC_TextField.text = @"1.0000";
	self.USD_TextField.text = [NSString stringWithFormat:@"%.2f", 1.0 * EXCHANGE_RATE];
	
	CGRect frame = self.keypadView.frame;
	frame.origin.y = frame.origin.y + frame.size.height;
	self.keypadView.frame = frame;
}


-(void)viewDidAppear:(BOOL)animated
{
	//[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:NO]];
	[super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*-(IBAction)Back
{
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:YES]];
	[self.delegate RequestViewControllerDone:self];
}*/

#pragma mark textfield delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	selectedTextField = textField;
	self.keypadView.textField = textField;
	self.BTC_TextField.text = @"";
	self.USD_TextField.text = @"";
}

#pragma mark calculator delegates

-(void)CalculatorDone:(CalculatorView *)calculator
{
	[self.BTC_TextField resignFirstResponder];
	[self.USD_TextField resignFirstResponder];
}

-(void)CalculatorValueChanged:(CalculatorView *)calculator
{
	[self updateTextFieldContents];
}

/*
-(IBAction)digit:(UIButton *)sender
{
	if(sender.tag < 10)
	{
		if(sender.tag == 0)
		{
			//allow 0 only if current value is non-zero OR there's a decimal point
			if(([selectedTextField.text intValue] != 0) || ([selectedTextField.text rangeOfString:@"."].location != NSNotFound))
			{
				selectedTextField.text = [selectedTextField.text stringByAppendingFormat:@"%li", (long)sender.tag];
			}
		}
		else
		{
			selectedTextField.text = [selectedTextField.text stringByAppendingFormat:@"%li", (long)sender.tag];
		}
	}
	else
	{
		if ([selectedTextField.text rangeOfString:@"."].location == NSNotFound)
		{
			selectedTextField.text = [selectedTextField.text stringByAppendingString:@"."];
		}
	}
	[self updateTextFieldContents];
}

-(IBAction)operation:(UIButton *)sender
{
	switch (sender.tag)
	{
			case OPERATION_CLEAR:
				selectedTextField.text = @"";
				break;
			case OPERATION_BACK:
				selectedTextField.text = [selectedTextField.text substringToIndex:selectedTextField.text.length-(selectedTextField.text.length > 0)];
				break;
			case OPERATION_DONE:
				[self.BTC_TextField resignFirstResponder];
				[self.USD_TextField resignFirstResponder];
				break;
			case OPERATION_DIVIDE:
			case OPERATION_EQUAL:
			case OPERATION_MINUS:
			case OPERATION_MULTIPLY:
			case OPERATION_PLUS:
			case OPERATION_PERCENT:
				break;
				
	}
	[self updateTextFieldContents];
}
*/
-(void)updateTextFieldContents
{
	if(selectedTextField == self.BTC_TextField)
	{
		double value = [self.BTC_TextField.text doubleValue];
		
		self.USD_TextField.text = [NSString stringWithFormat:@"%.2f", value * EXCHANGE_RATE];
	}
	else
	{
		double value = [self.USD_TextField.text doubleValue];
		//NSLog(@"Value: %@", [NSString stringWithFormat:@"%.6f", value * EXCHANGE_RATE]);
		self.BTC_TextField.text = [NSString stringWithFormat:@"%.4f", value / EXCHANGE_RATE];
	}
}


@end

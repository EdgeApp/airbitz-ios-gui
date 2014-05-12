//
//  TransactionDetailsViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "TransactionDetailsViewController.h"
#import "User.h"
#import "NSDate+Helper.h"
#import "ABC.h"
#import "InfoView.h"
#import "AutoCompleteTextField.h"
#import "CalculatorView.h"

#define DOLLAR_CURRENCY_NUM	840

@interface TransactionDetailsViewController () <UITextFieldDelegate, InfoViewDelegate, AutoCompleteTextFieldDelegate, CalculatorViewDelegate>
{
	UITextField *activeTextField;
	CGRect originalFrame;
	UIButton *blockingButton;
}
@property (nonatomic, weak) IBOutlet UIView *headerView;
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet UIView *scrollableContentView;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *walletLabel;
@property (nonatomic, weak) IBOutlet UILabel *bitCoinLabel;
@property (nonatomic, weak) IBOutlet UIButton *advancedDetailsButton;
@property (nonatomic, weak) IBOutlet UIButton *doneButton;
@property (nonatomic, weak) IBOutlet UITextField *fiatTextField;
@property (nonatomic, weak) IBOutlet UITextField *notesTextField;
@property (nonatomic, weak) IBOutlet AutoCompleteTextField *categoryTextField;
@property (nonatomic, weak) IBOutlet AutoCompleteTextField *nameTextField;
@property (nonatomic, weak) IBOutlet CalculatorView *keypadView;
@end

@implementation TransactionDetailsViewController

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
	UIImage *blue_button_image = [self stretchableImage:@"btn_blue.png"];
	[self.advancedDetailsButton setBackgroundImage:blue_button_image forState:UIControlStateNormal];
	[self.advancedDetailsButton setBackgroundImage:blue_button_image forState:UIControlStateSelected];
	
	self.keypadView.delegate = self;
	
	self.fiatTextField.delegate = self;
	self.fiatTextField.inputView = self.keypadView;
	self.notesTextField.delegate = self;
	self.nameTextField.delegate = self;
	self.categoryTextField.delegate = self;
	self.nameTextField.autoTextFieldDelegate = self;
	self.categoryTextField.autoTextFieldDelegate = self;
	
	/*
	 @property (nonatomic, copy)     NSString        *strID;
	 @property (nonatomic, copy)     NSString        *strWalletUUID;
	 @property (nonatomic, copy)     NSString        *strWalletName;
	 @property (nonatomic, copy)     NSString        *strName;
	 @property (nonatomic, copy)     NSString        *strAddress;
	 @property (nonatomic, strong)   NSDate          *date;
	 @property (nonatomic, assign)   BOOL            bConfirmed;
	 @property (nonatomic, assign)   unsigned int    confirmations;
	 @property (nonatomic, assign)   double          amount;
	 @property (nonatomic, assign)   double          balance;
	 @property (nonatomic, copy)     NSString        *strCategory;
	 @property (nonatomic, copy)     NSString        *strNotes;
	 */
	 
	// self.dateLabel.text = [NSDate stringForDisplayFromDate:self.transaction.date prefixed:NO alwaysDisplayTime:YES];
	
	self.dateLabel.text = [NSDate stringFromDate:self.transaction.date withFormat:[NSDate timestampFormatString]];
	self.nameTextField.text = self.transaction.strName;
	self.categoryTextField.arrayAutoCompleteStrings = [NSArray arrayWithObjects:@"Income:Salary", @"Income:Rent", @"Transfer:Bank Account", @"Transfer:Cash", @"Transfer:Wallet", @"Expense:Dining", @"Expense:Clothing", @"Expense:Computers", @"Expense:Electronics", @"Expense:Education", @"Expense:Entertainment", @"Expense:Rent", @"Expense:Insurance", @"Expense:Medical", @"Expense:Pets", @"Expense:Recreation", @"Expense:Tax", @"Expense:Vacation", @"Expense:Utilities",nil];
	self.categoryTextField.tableAbove = YES;
	//[self.addressButton setTitle:self.transaction.strAddress forState:UIControlStateNormal];
	
	
	self.bitCoinLabel.text = [NSString stringWithFormat:@"B %.5f", ABC_SatoshiToBitcoin(self.transaction.amountSatoshi)];
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	self.nameTextField.placeholder = NSLocalizedString(@"Payee or Business Name", nil);
	[self.nameTextField becomeFirstResponder];
}

-(void)viewWillAppear:(BOOL)animated
{
	if(originalFrame.size.height == 0)
	{
		CGRect frame = self.view.frame;
		frame.origin.x = 0;
		frame.origin.y = 0;
		originalFrame = frame;
		
		if(_transactionDetailsMode == TD_MODE_SENT)
		{
			self.walletLabel.text = [NSString stringWithFormat:@"From: %@", self.transaction.strWalletName];
		}
		else
		{
			self.walletLabel.text = [NSString stringWithFormat:@"To: %@", self.transaction.strWalletName];
		}
		
		double currency;
		tABC_CC result;
		tABC_Error error;
#warning TODO: hard coded for dollar currency right now
		result = ABC_SatoshiToCurrency(self.transaction.amountSatoshi, &currency, DOLLAR_CURRENCY_NUM, &error);
		if(result == ABC_CC_Ok)
		{
			self.fiatTextField.text = [NSString stringWithFormat:@"$%.2f", currency ];
		}
		
		frame = self.keypadView.frame;
		frame.origin.y = frame.origin.y + frame.size.height;
		self.keypadView.frame = frame;
	}
}

-(void)viewDidDisappear:(BOOL)animated
{
	NSLog(@"View Did Disappear!");
	[self.delegate TransactionDetailsViewControllerDone:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark blocking button

-(void)createBlockingButtonUnderView:(UIView *)view
{
	[[view superview] bringSubviewToFront:view];
	
	blockingButton = [UIButton buttonWithType:UIButtonTypeCustom];
	CGRect frame = self.view.bounds;
	//frame.origin.y = self.headerView.frame.origin.y + self.headerView.frame.size.height;
	//frame.size.height = self.view.bounds.size.height - frame.origin.y;
	blockingButton.frame = frame;
	blockingButton.backgroundColor = [UIColor clearColor]; //[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
	[self.view insertSubview:blockingButton belowSubview:view];
	blockingButton.alpha = 0.0;
	
	[blockingButton addTarget:self
					   action:@selector(blockingButtonHit:)
			 forControlEvents:UIControlEventTouchDown];
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^
	 {
		 blockingButton.alpha = 1.0;
	 }
					 completion:^(BOOL finished)
	 {
		 
	 }];
	
}

-(void)removeBlockingButton
{
	//[self.walletMakerView.textField resignFirstResponder];
	if(blockingButton)
	{
		[UIView animateWithDuration:0.35
							  delay:0.0
							options:UIViewAnimationOptionCurveLinear
						 animations:^
		 {
			 blockingButton.alpha = 0.0;
		 }
						 completion:^(BOOL finished)
		 {
			 [blockingButton removeFromSuperview];
			 blockingButton = nil;
		 }];
	}
}

-(void)blockingButtonHit:(UIButton *)button
{
	//[self hideWalletMaker];
	[self.view endEditing:YES];
	[self removeBlockingButton];
}

#pragma mark actions

-(IBAction)Done
{
	[self.delegate TransactionDetailsViewControllerDone:self];
}

-(IBAction)AdvancedDetails
{
	//spawn infoView
	InfoView *iv = [InfoView CreateWithDelegate:self];
	iv.frame = self.view.bounds;
	
	NSString* path = [[NSBundle mainBundle] pathForResource:@"transactionDetails" ofType:@"html"];
	NSString* content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	
	//transaction ID
	content = [content stringByReplacingOccurrencesOfString:@"*1" withString:self.transaction.strID];
	//Total sent
	content = [content stringByReplacingOccurrencesOfString:@"*2" withString:[NSString stringWithFormat:@"BTC %.5f", ABC_SatoshiToBitcoin(self.transaction.amountSatoshi)]];
	//source
	#warning TODO: source and destination addresses are faked for now, so's miner's fee.
	content = [content stringByReplacingOccurrencesOfString:@"*3" withString:@"1.002<BR>1K7iGspRyQsposdKCSbsoXZntsJ7DPNssN<BR>0.0345<BR>1z8fkj4igkh498thgkjERGG23fhD4gGaNSHa<BR>0.2342<BR>1Wfh8d9csf987gT7H6fjkhd0fkj4tkjhf8S4er3"];
	//Destination
	content = [content stringByReplacingOccurrencesOfString:@"*4" withString:@"1M6TCZJTdVX1xGC8iAcQLTDtRKF2zM6M38<BR>1.27059<BR>12HUD1dsrc9dhQgGtWxqy8dAM2XDgvKdzq<BR>0.00001"];
	//Miner Fee
	content = [content stringByReplacingOccurrencesOfString:@"*5" withString:@"0.0001"];
	iv.htmlInfoToDisplay = content;
	[self.view addSubview:iv];
}

-(UIImage *)stretchableImage:(NSString *)imageName
{
	UIImage *img = [UIImage imageNamed:imageName];
	UIImage *stretchable = [img resizableImageWithCapInsets:UIEdgeInsetsMake(28, 28, 28, 28)]; //top, left, bottom, right
	return stretchable;
}

#pragma mark Keyboard callbacks

- (void)keyboardWillShow:(NSNotification *)notification
{
	//Get KeyboardFrame (in Window coordinates)
	NSDictionary *userInfo = [notification userInfo];
	CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	CGRect ownFrame = [self.view.window convertRect:keyboardFrame toView:self.view];
	
	//get textfield frame in window coordinates
	CGRect textFieldFrame = [activeTextField.superview convertRect:activeTextField.frame toView:self.view];
	
	//calculate offset
	float distanceToMove = (textFieldFrame.origin.y + textFieldFrame.size.height + 20.0) - ownFrame.origin.y;
	
	if(distanceToMove > 0)
	{
		//need to scroll

		[UIView animateWithDuration:0.35
							  delay: 0.0
							options: UIViewAnimationOptionCurveEaseOut
						 animations:^
		 {
			 CGRect frame = originalFrame;
			 frame.origin.y -= distanceToMove;
			 self.view.frame = frame;
		 }
		 completion:^(BOOL finished)
		 {
		 }];
	}
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	if(activeTextField)
	{
		if([activeTextField isKindOfClass:[AutoCompleteTextField class]])
		{
			//hide autocomplete tableView if visible
			[(AutoCompleteTextField *)activeTextField autoCompleteTextFieldShouldReturn];
		}
		activeTextField = nil;
		[UIView animateWithDuration:0.35
							  delay: 0.0
							options: UIViewAnimationOptionCurveEaseOut
						 animations:^
		 {
			 self.view.frame = originalFrame;
		 }
		 completion:^(BOOL finished)
		 {
		 }];
		 
		 [self removeBlockingButton];
	}
}

#pragma mark calculator delegates

-(void)CalculatorDone:(CalculatorView *)calculator
{
	[self.fiatTextField resignFirstResponder];
}

-(void)CalculatorValueChanged:(CalculatorView *)calculator
{
}


#pragma mark AutoCompleteTextField delegates

-(void)autoCompleteTextFieldDidSelectFromTable:(AutoCompleteTextField *)textField
{
	if(textField == self.nameTextField)
	{
		[self.categoryTextField becomeFirstResponder];
	}
}

#pragma mark UITextField delegates

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if([textField isKindOfClass:[AutoCompleteTextField class]])
	{
		[(AutoCompleteTextField *)textField autoCompleteTextFieldShouldChangeCharactersInRange:range replacementString:string];
	}
	return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	activeTextField = textField;
	self.keypadView.textField = textField;
	[self createBlockingButtonUnderView:textField];
	if([textField isKindOfClass:[AutoCompleteTextField class]])
	{
		[(AutoCompleteTextField *)textField autoCompleteTextFieldDidBeginEditing];
	}
	
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if([textField isKindOfClass:[AutoCompleteTextField class]])
	{
		[(AutoCompleteTextField *)textField autoCompleteTextFieldShouldReturn];
	}
	[textField resignFirstResponder];
	if(textField == self.nameTextField)
	{
		[self.categoryTextField becomeFirstResponder];
	}
	return YES;
}

#pragma mark infoView delegates

-(void)InfoViewFinished:(InfoView *)infoView
{
	[infoView removeFromSuperview];
}

@end

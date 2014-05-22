//
//  SendConfirmationViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "SendConfirmationViewController.h"
#import "ABC.h"
#import "ConfirmationSliderView.h"
#import "User.h"
#import "CalculatorView.h"
#import "ButtonSelectorView.h"
#import "SendStatusViewController.h"
#import "TransactionDetailsViewController.h"
#import "CoreBridge.h"
#import "Util.h"

#define DOLLAR_CURRENCY_NUM 840

@interface SendConfirmationViewController () <UITextFieldDelegate, ConfirmationSliderViewDelegate, CalculatorViewDelegate, ButtonSelectorDelegate, TransactionDetailsViewControllerDelegate>
{
	ConfirmationSliderView              *_confirmationSlider;
	UITextField                         *_selectedTextField;
	SendStatusViewController            *_sendStatusController;
	TransactionDetailsViewController    *_transactionDetailsController;
	BOOL                                _callbackSuccess;
	NSString                            *_strReason;
	Transaction                         *_completedTransaction;	// nil until sendTransaction is successfully completed
}

@property (nonatomic, weak) IBOutlet UIButton               *buttonBlocker;

@property (weak, nonatomic) IBOutlet UIView                 *viewDisplayArea;
@property (nonatomic, weak) IBOutlet UILabel                *addressLabel;
@property (nonatomic, weak) IBOutlet UILabel                *conversionLabel;

@property (nonatomic, weak) IBOutlet UITextField            *withdrawlPIN;
@property (nonatomic, weak) IBOutlet UITextField            *amountUSDTextField;
@property (nonatomic, weak) IBOutlet UILabel                *amountUSDLabel;
@property (nonatomic, weak) IBOutlet UITextField            *amountBTCTextField;
@property (nonatomic, weak) IBOutlet UILabel                *amountBTCLabel;
@property (nonatomic, weak) IBOutlet UIButton               *btn_alwaysConfirm;
@property (nonatomic, weak) IBOutlet UIView                 *confirmSliderContainer;
@property (nonatomic, weak) IBOutlet CalculatorView         *keypadView;
@property (nonatomic, weak) IBOutlet ButtonSelectorView     *buttonSelector;

@end

@implementation SendConfirmationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	self.withdrawlPIN.delegate = self;
	self.amountBTCTextField.delegate = self;
	self.amountUSDTextField.delegate = self;
	self.buttonSelector.delegate = self;
	self.keypadView.delegate = self;
	self.amountBTCTextField.inputView = self.keypadView;
	self.amountUSDTextField.inputView = self.keypadView;

    // set up our user blocking button
    self.buttonBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonBlocker.backgroundColor = [UIColor clearColor];
    [self.buttonBlocker addTarget:self action:@selector(buttonBlockerTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonBlocker.frame = self.view.bounds;
    self.buttonBlocker.hidden = YES;
    [self.viewDisplayArea addSubview:self.buttonBlocker];

    // make sure the edit fields are in front of the blocker
    [self.viewDisplayArea bringSubviewToFront:self.amountBTCTextField];
    [self.viewDisplayArea bringSubviewToFront:self.amountUSDTextField];
    [self.viewDisplayArea bringSubviewToFront:self.withdrawlPIN];

	self.buttonSelector.textLabel.text = NSLocalizedString(@"Send From:", @"Label text on Send Bitcoin screen");
	
	[self setWalletButtonTitle];
	
	CGRect frame = self.keypadView.frame;
	frame.origin.y = self.view.frame.size.height;
	self.keypadView.frame = frame;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(myTextDidChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:self.withdrawlPIN];
				
	_confirmationSlider = [ConfirmationSliderView CreateInsideView:self.confirmSliderContainer withDelegate:self];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)myTextDidChange:(NSNotification *)notification
{
	if(notification.object == self.withdrawlPIN)
	{
		if(self.withdrawlPIN.text.length == 4)
		{
			[self.withdrawlPIN resignFirstResponder];
		}
	}
	else
	{
		NSLog(@"Text changed for some field");
	}
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	self.amountBTCLabel.text = [User Singleton].denominationLabel; 
    self.amountBTCTextField.text = [CoreBridge formatSatoshi:self.amountToSendSatoshi];
    self.conversionLabel.text = [CoreBridge conversionString:DOLLAR_CURRENCY_NUM];
	self.addressLabel.text = self.sendToAddress;
	
	tABC_CC result;
	double currency;
	tABC_Error error;
	
#warning TODO: eventually pull currency number from the wallet.  Wallet specifies what currency it's in
	result = ABC_SatoshiToCurrency(self.amountToSendSatoshi, &currency, DOLLAR_CURRENCY_NUM, &error);
				
	if(result == ABC_CC_Ok)
	{
		self.amountUSDTextField.text = [NSString stringWithFormat:@"%.2f", currency];
	}
	
	if (self.amountToSendSatoshi)
	{
		[self.withdrawlPIN becomeFirstResponder];
	}
	else
	{
		self.amountUSDTextField.text = nil;
		self.amountBTCTextField.text = nil;
		[self.amountUSDTextField becomeFirstResponder];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Actions Methods

- (IBAction)Back:(id)sender
{
	[self.withdrawlPIN resignFirstResponder];
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = self.view.frame;
		 frame.origin.x = frame.size.width;
		 self.view.frame = frame;
	 }
	 completion:^(BOOL finished)
	 {
		 [self.delegate sendConfirmationViewControllerDidFinish:self];
	 }];
}

- (IBAction)buttonBlockerTouched:(id)sender
{
	[self.withdrawlPIN resignFirstResponder];
	[self.amountUSDTextField resignFirstResponder];
	[self.amountBTCTextField resignFirstResponder];
}

- (IBAction)alwaysConfirm:(UIButton *)sender
{
	if(sender.selected)
	{
		sender.selected = NO;
	}
	else
	{
		sender.selected = YES;
	}
}

#pragma mark - Misc Methods

- (void)blockUser:(BOOL)bBlock
{
    if (bBlock)
    {
        self.buttonBlocker.hidden = NO;
    }
    else
    {
        self.buttonBlocker.hidden = YES;
    }
}

- (void)showSendStatus
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_sendStatusController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendStatusViewController"];



	CGRect frame = self.view.bounds;
	//frame.origin.x = frame.size.width;
	_sendStatusController.view.frame = frame;
	[self.view addSubview:_sendStatusController.view];
	_sendStatusController.view.alpha = 0.0;

	_sendStatusController.messageLabel.text = NSLocalizedString(@"Sending...", @"status message");

	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 _sendStatusController.view.alpha = 1.0;
	 }
					 completion:^(BOOL finished)
	 {
	 }];
}

- (void)initiateSendRequest
{
	//[self showSendStatus];
	tABC_Error Error;
	tABC_CC result;
	tABC_WalletInfo **aWalletInfo = NULL;
    unsigned int nCount;
	double currency;
	
	result = ABC_SatoshiToCurrency([self.amountBTCTextField.text doubleValue], &currency, DOLLAR_CURRENCY_NUM, &Error);
	if(result == ABC_CC_Ok)
	{
		ABC_GetWallets([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &aWalletInfo, &nCount, &Error);
		
		if(nCount)
		{
			tABC_TxDetails Details;
			Details.amountSatoshi = self.amountToSendSatoshi;
			Details.amountCurrency = currency;
			Details.amountFeesAirbitzSatoshi = 0;
			Details.amountFeesMinersSatoshi = 0;
			Details.szName = "Anonymous";
			Details.szCategory = "";
			Details.szNotes = "";
			Details.attributes = 0x2;
			
			tABC_WalletInfo *info = aWalletInfo[self.selectedWalletIndex];
			
			result = ABC_InitiateSendRequest([[User Singleton].name UTF8String],
										[[User Singleton].password UTF8String],
										info->szUUID,
										[self.sendToAddress UTF8String],
										&Details,
										ABC_SendConfirmation_Callback,
										(__bridge void *)self,
										&Error);
			if(result == ABC_CC_Ok)
			{
				[self showSendStatus];
			}
			else
			{
				[Util printABC_Error:&Error];
			}
			
			ABC_FreeWalletInfoArray(aWalletInfo, nCount);
		}
	}
}

- (void)setWalletButtonTitle
{
	tABC_WalletInfo **aWalletInfo = NULL;
    unsigned int nCount;
	tABC_Error Error;
    ABC_GetWallets([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &aWalletInfo, &nCount, &Error);
    [Util printABC_Error:&Error];
	
    printf("Wallets:\n");
	
	if(nCount)
	{
		tABC_WalletInfo *info = aWalletInfo[self.selectedWalletIndex];
		
		[self.buttonSelector.button setTitle:[NSString stringWithUTF8String:info->szName] forState:UIControlStateNormal];
		self.buttonSelector.selectedItemIndex = self.selectedWalletIndex;
	}
	
    // assign list of wallets to buttonSelector
	NSMutableArray *walletsArray = [[NSMutableArray alloc] init];
	
    for (int i = 0; i < nCount; i++)
    {
        tABC_WalletInfo *pInfo = aWalletInfo[i];
		[walletsArray addObject:[NSString stringWithUTF8String:pInfo->szName]];
    }
	
	self.buttonSelector.arrayItemsToSelect = [walletsArray copy];
    ABC_FreeWalletInfoArray(aWalletInfo, nCount);
}

- (void)launchTransactionDetailsWithTransaction:(Transaction *)transaction
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_transactionDetailsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionDetailsViewController"];
	
	_transactionDetailsController.delegate = self;
	_transactionDetailsController.transaction = transaction;
	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
	_transactionDetailsController.view.frame = frame;
	
	//transactionDetailsController.nameLabel.text = self.nameLabel;
	_transactionDetailsController.transactionDetailsMode = TD_MODE_SENT;
	
	[self.view addSubview:_transactionDetailsController.view];
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 _transactionDetailsController.view.frame = self.view.bounds;
	 }
					 completion:^(BOOL finished)
	 {
	 }];
	
}

- (void)sendBitcoinComplete:(NSString *)transactionID
{
	[self performSelector:@selector(showTransactionDetails:) withObject:transactionID afterDelay:3.0]; //show sending screen for 3 seconds
}

- (void)showTransactionDetails:(NSString *)transactionID
{
	if(_callbackSuccess)
	{
		tABC_WalletInfo **aWalletInfo = NULL;
		tABC_Error error;
		tABC_TxInfo *txInfo;
		//tABC_TxDetails *details;
		unsigned int nCount;

		ABC_GetWallets([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &aWalletInfo, &nCount, &error);

		if(nCount)
		{
			tABC_WalletInfo *walletInfo = aWalletInfo[self.selectedWalletIndex];

			NSLog(@"Transaction complete with Transaction ID: %@", transactionID);


			tABC_CC result = ABC_GetTransaction([[User Singleton].name UTF8String],
                                                [[User Singleton].password UTF8String],
                                                walletInfo->szUUID,
                                                [transactionID UTF8String],
                                                &txInfo,
                                                &error);

			if(result == ABC_CC_Ok)
			{
				_completedTransaction = [[Transaction alloc] init];
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

				NSString *address;
				if(txInfo->countAddresses)
				{
					address = [NSString stringWithUTF8String:txInfo->aAddresses[0]];
				}
				else
				{
					address = @"NO ADDRESS";
				}

				_completedTransaction.strID = transactionID;
				_completedTransaction.strWalletUUID = [NSString stringWithUTF8String:walletInfo->szUUID];
				_completedTransaction.strWalletName = [NSString stringWithUTF8String:walletInfo->szName];
				_completedTransaction.strAddress = address;
				_completedTransaction.date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)txInfo->timeCreation];
#warning TODO: what do I do with bConfirmed and comfirmations?
				_completedTransaction.bConfirmed = NO;
				_completedTransaction.confirmations = 0;

				_completedTransaction.amountSatoshi = txInfo->pDetails->amountSatoshi;
#warning TODO: what do I do with balance?
				_completedTransaction.balance = 0;

				_completedTransaction.strCategory = [NSString stringWithUTF8String:txInfo->pDetails->szCategory];
				_completedTransaction.strNotes = [NSString stringWithUTF8String:txInfo->pDetails->szNotes];

				ABC_FreeWalletInfoArray(aWalletInfo, nCount);
				ABC_FreeTransaction(txInfo);
				
				[self launchTransactionDetailsWithTransaction:_completedTransaction];
			}
		}
	}
	else
	{
		NSLog(@"Error: %@", _strReason);
	}
	
}

#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	_selectedTextField = textField;
	self.keypadView.textField = textField;
    [self blockUser:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self blockUser:NO];
}

#pragma mark - ConfirmationSlider delegates

- (void)ConfirmationSliderDidConfirm:(ConfirmationSliderView *)controller
{
	//make sure PIN is good
	
	if(self.withdrawlPIN.text.length)
	{
		//make sure the entered PIN matches the PIN stored in the Core
		tABC_Error error;
		char *szPIN = NULL;
		
		ABC_GetPIN([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &szPIN, &error);
		[Util printABC_Error:&error];
		NSLog(@"current PIN: %s", szPIN);
		if(szPIN)
		{
			NSString *storedPIN = [NSString stringWithUTF8String:szPIN];
			if([self.withdrawlPIN.text isEqualToString:storedPIN])
			{
				NSLog(@"SUCCESS!");
				[self initiateSendRequest];
			}
			else
			{
				UIAlertView *alert = [[UIAlertView alloc]
									  initWithTitle:NSLocalizedString(@"Incorrect PIN", nil)
									  message:NSLocalizedString(@"You must enter the correct withdrawl PIN in order to proceed", nil)
									  delegate:self
									  cancelButtonTitle:@"OK"
									  otherButtonTitles:nil];
				[alert show];
			}
			free(szPIN);
		}
		
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Incorrect PIN", nil)
							  message:NSLocalizedString(@"You must enter your withdrawl PIN in order to proceed", nil)
							  delegate:self
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
		
	}
	[_confirmationSlider resetIn:1.0];
}

#pragma mark - Calculator delegates

- (void)CalculatorDone:(CalculatorView *)calculator
{
	[self.amountUSDTextField resignFirstResponder];
	[self.amountBTCTextField resignFirstResponder];
	[self.withdrawlPIN becomeFirstResponder];
}

- (void)CalculatorValueChanged:(CalculatorView *)calculator
{
	[self updateTextFieldContents];
}

- (void)updateTextFieldContents
{
	tABC_CC result;
	double currency;
	tABC_Error error;
	
	if(_selectedTextField == self.amountBTCTextField)
	{
		double value = [self.amountBTCTextField.text doubleValue];
        self.amountToSendSatoshi = [CoreBridge denominationToSatoshi: value];
		result = ABC_SatoshiToCurrency(self.amountToSendSatoshi, &currency, DOLLAR_CURRENCY_NUM, &error);
		if(result == ABC_CC_Ok)
		{
			self.amountUSDTextField.text = [NSString stringWithFormat:@"%.2f", currency];
		}
	}
	else
	{
		int64_t satoshi;
		result = ABC_CurrencyToSatoshi([self.amountUSDTextField.text doubleValue], DOLLAR_CURRENCY_NUM, &satoshi, &error);
		if(result == ABC_CC_Ok)
		{
			self.amountToSendSatoshi = satoshi;
            self.amountBTCTextField.text = [CoreBridge formatSatoshi: satoshi withSymbol:false];
		}
	}
}

#pragma mark - ButtonSelectorView delegates

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
	NSLog(@"Selected item %i", itemIndex);
}

#pragma mark - TransactionDetailsViewController delegates

- (void)TransactionDetailsViewControllerDone:(TransactionDetailsViewController *)controller
{
	[controller.view removeFromSuperview];
	_transactionDetailsController = nil;

	[_sendStatusController.view removeFromSuperview];
	_sendStatusController = nil;

	[self.delegate sendConfirmationViewControllerDidFinish:self];
}

#pragma mark - ABC Callbacks

void ABC_SendConfirmation_Callback(const tABC_RequestResults *pResults)
{
	// NSLog(@"Request callback");
    
    if (pResults)
    {
        SendConfirmationViewController *controller = (__bridge id)pResults->pData;
        controller->_callbackSuccess = (BOOL)pResults->bSuccess;
        controller->_strReason = [NSString stringWithFormat:@"%s", pResults->errorInfo.szDescription];
		
        if (pResults->requestType == ABC_RequestType_SendBitcoin)
        {
			
            //NSLog(@"Sign-in completed with cc: %ld (%s)", (unsigned long) pResults->errorInfo.code, pResults->errorInfo.szDescription);
            [controller performSelectorOnMainThread:@selector(sendBitcoinComplete:) withObject:[NSString stringWithUTF8String:pResults->pRetData] waitUntilDone:FALSE];
			free(pResults->pRetData);
        }
    }
}

@end

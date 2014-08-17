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
#import "SendStatusViewController.h"
#import "TransactionDetailsViewController.h"
#import "CoreBridge.h"
#import "Util.h"
#import "CommonTypes.h"

@interface SendConfirmationViewController () <UITextFieldDelegate, ConfirmationSliderViewDelegate, CalculatorViewDelegate, TransactionDetailsViewControllerDelegate, UIGestureRecognizerDelegate>
{
	ConfirmationSliderView              *_confirmationSlider;
	UITextField                         *_selectedTextField;
	BOOL                                _callbackSuccess;
    int64_t                             _maxAmount;
    BOOL                                _maxLocked;
	NSString                            *_strReason;
	Transaction                         *_completedTransaction;	// nil until sendTransaction is successfully completed
    UITapGestureRecognizer              *tap;
}

@property (weak, nonatomic) IBOutlet UIView                 *viewDisplayArea;

@property (weak, nonatomic) IBOutlet UIImageView            *imageTopEmboss;
@property (weak, nonatomic) IBOutlet UILabel                *labelSendFromTitle;
@property (weak, nonatomic) IBOutlet UILabel                *labelSendFrom;
@property (weak, nonatomic) IBOutlet UILabel                *labelSendToTitle;
@property (nonatomic, weak) IBOutlet UILabel                *addressLabel;
@property (weak, nonatomic) IBOutlet UIView                 *viewBTC;
@property (nonatomic, weak) IBOutlet UILabel                *amountBTCSymbol;
@property (nonatomic, weak) IBOutlet UILabel                *amountBTCLabel;
@property (nonatomic, weak) IBOutlet UITextField            *amountBTCTextField;
@property (weak, nonatomic) IBOutlet UIView                 *viewUSD;
@property (nonatomic, weak) IBOutlet UILabel                *amountUSDSymbol;
@property (nonatomic, weak) IBOutlet UILabel                *amountUSDLabel;
@property (nonatomic, weak) IBOutlet UITextField            *amountUSDTextField;
@property (nonatomic, weak) IBOutlet UIButton               *maxAmountButton;
@property (nonatomic, weak) IBOutlet UILabel                *conversionLabel;
@property (weak, nonatomic) IBOutlet UILabel                *labelPINTitle;
@property (weak, nonatomic) IBOutlet UILabel                *txFeesLabel;
@property (weak, nonatomic) IBOutlet UIImageView            *imagePINEmboss;
@property (nonatomic, weak) IBOutlet UITextField            *withdrawlPIN;
@property (nonatomic, weak) IBOutlet UIView                 *confirmSliderContainer;
@property (nonatomic, weak) IBOutlet UIButton               *btn_alwaysConfirm;
@property (weak, nonatomic) IBOutlet UILabel                *labelAlwaysConfirm;
@property (nonatomic, weak) IBOutlet CalculatorView         *keypadView;

@property (nonatomic, strong) SendStatusViewController          *sendStatusController;
@property (nonatomic, strong) TransactionDetailsViewController  *transactionDetailsController;

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
    // Added gesture recognizer to control keyboard
    tap = [[UITapGestureRecognizer alloc] 
        initWithTarget:self
                action:@selector(dismissKeyboard)];

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:self.viewDisplayArea];

    self.keypadView.currencyNum = self.wallet.currencyNum;
	self.withdrawlPIN.delegate = self;
	self.amountBTCTextField.delegate = self;
	self.amountUSDTextField.delegate = self;
	self.keypadView.delegate = self;
	self.amountBTCTextField.inputView = self.keypadView;
	self.amountUSDTextField.inputView = self.keypadView;

    // make sure the edit fields are in front of the blocker
    [self.viewDisplayArea bringSubviewToFront:self.amountBTCTextField];
    [self.viewDisplayArea bringSubviewToFront:self.amountUSDTextField];
    [self.viewDisplayArea bringSubviewToFront:self.withdrawlPIN];

	[self setWalletLabel];
	
	CGRect frame = self.keypadView.frame;
	frame.origin.y = self.view.frame.size.height;
	self.keypadView.frame = frame;
	
	_confirmationSlider = [ConfirmationSliderView CreateInsideView:self.confirmSliderContainer withDelegate:self];
    _maxLocked = NO;

    [self updateDisplayLayout];

    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view removeGestureRecognizer:tap];
    [self dismissKeyboard];
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
    [self.view addGestureRecognizer:tap];
	self.amountBTCLabel.text = [User Singleton].denominationLabel; 
    self.amountBTCTextField.text = [CoreBridge formatSatoshi:self.amountToSendSatoshi withSymbol:false];
    self.conversionLabel.text = [CoreBridge conversionString:self.wallet];
    
    NSString *prefix;
    NSString *suffix;
    
    if ([self.sendToAddress length] > 10 && !self.bAddressIsWalletUUID)
    {
        prefix = [self.sendToAddress substringToIndex:5];
        suffix = [self.sendToAddress substringFromIndex: [self.sendToAddress length] - 5];
        self.addressLabel.text = [NSString stringWithFormat:@"%@...%@", prefix, suffix];
    }
    else
    {
        self.addressLabel.text = self.sendToAddress;
    }
    
    
    
	
	tABC_CC result;
	double currency;
	tABC_Error error;
	
	result = ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                   self.amountToSendSatoshi, &currency, self.wallet.currencyNum, &error);
				
	if(result == ABC_CC_Ok)
	{
		self.amountUSDTextField.text = [NSString stringWithFormat:@"%.2f", currency];
	}
    [self startCalcFees];
	
    if (self.amountToSendSatoshi)
    {
        // If the PIN is empty, then focus
        if ([self.withdrawlPIN.text length] <= 0)
        {
            [self.withdrawlPIN becomeFirstResponder];
        }
    }
    else
    {
        self.amountUSDTextField.text = nil;
        self.amountBTCTextField.text = nil;
        [self.amountUSDTextField becomeFirstResponder];
    }
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(myTextDidChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:self.withdrawlPIN];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(exchangeRateUpdate:)
                                                 name:NOTIFICATION_EXCHANGE_RATE_CHANGE
                                               object:nil];
    [self exchangeRateUpdate:nil]; 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Notification Handlers

- (void)exchangeRateUpdate: (NSNotification *)notification
{
	[self updateTextFieldContents];
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

- (IBAction)selectMaxAmount
{
    UITextField *_holder = _selectedTextField;
    if (self.wallet != nil && _maxLocked == NO)
    {
        _maxLocked = YES;
        _selectedTextField = self.amountBTCTextField;
        // We use a serial queue for this calculation
        [CoreBridge postToSyncQueue:^{
            int64_t maxAmount = [CoreBridge maxSpendable:self.wallet.strUUID
                                               toAddress:[self getDestAddress]
                                              isTransfer:self.bAddressIsWalletUUID];
            dispatch_async(dispatch_get_main_queue(), ^{
                _maxLocked = NO;
                _maxAmount = maxAmount;
                self.amountToSendSatoshi = maxAmount;
                self.amountBTCTextField.text = [CoreBridge formatSatoshi:self.amountToSendSatoshi withSymbol:false];

                [self updateTextFieldContents];
                _selectedTextField = _holder;
            });
        }];
    }
}

#pragma mark - Misc Methods

- (void)dismissKeyboard
{
	[self.withdrawlPIN resignFirstResponder];
	[self.amountUSDTextField resignFirstResponder];
	[self.amountBTCTextField resignFirstResponder];
}

- (void)updateDisplayLayout
{
    // if we are on a smaller screen
    if (!IS_IPHONE5)
    {
        // be prepared! lots and lots of magic numbers here to jam the controls to fit on a small screen

        int topShift = 22;
        int valueShift = 47;
        int pinShift = 67;
        CGRect frame;

        self.imageTopEmboss.hidden = YES;
        
        frame = self.labelSendFromTitle.frame;
        frame.origin.y -= topShift;
        self.labelSendFromTitle.frame = frame;
        
        frame = self.labelSendFrom.frame;
        frame.origin.y -= topShift;
        self.labelSendFrom.frame = frame;
        
        frame = self.labelSendToTitle.frame;
        frame.origin.y -= topShift + 10;
        self.labelSendToTitle.frame = frame;
        
        frame = self.addressLabel.frame;
        frame.origin.y -= topShift + 10;
        self.addressLabel.frame = frame;
        
        frame = self.conversionLabel.frame;
        frame.origin.y -= (topShift + 22);
        self.conversionLabel.frame = frame;

        frame = self.maxAmountButton.frame;
        frame.origin.y -= (topShift + 22);
        self.maxAmountButton.frame = frame;
        
        frame = self.viewBTC.frame;
        frame.origin.y -= valueShift;
        self.viewBTC.frame = frame;

        frame = self.viewUSD.frame;
        frame.origin.y -= (valueShift + 2);
        self.viewUSD.frame = frame;

        frame = self.imagePINEmboss.frame;
        frame.origin.y -= pinShift;
        self.imagePINEmboss.frame = frame;
        
        frame = self.labelPINTitle.frame;
        frame.origin.y -= pinShift;
        self.labelPINTitle.frame = frame;
        
        frame = self.withdrawlPIN.frame;
        frame.origin.y -= pinShift;
        self.withdrawlPIN.frame = frame;
        
        frame = self.confirmSliderContainer.frame;
        frame.origin.y -= pinShift;
        self.confirmSliderContainer.frame = frame;

        /*
        frame = self.amountBTCTextField.frame;
        frame.origin.y -= 5;
        self.amountBTCTextField.frame = frame;
        frame = self.amountUSDTextField.frame;
        frame.origin.y = self.viewUSD.frame.origin.y + 7;
        self.amountUSDTextField.frame = frame;


        frame = self.btn_alwaysConfirm.frame;
        frame.origin.y = self.confirmSliderContainer.frame.origin.y + self.confirmSliderContainer.frame.size.height + 25;
        self.btn_alwaysConfirm.frame = frame;

        frame = self.labelAlwaysConfirm.frame;
        frame.origin.y = self.btn_alwaysConfirm.frame.origin.y + self.btn_alwaysConfirm.frame.size.height + 0;
        self.labelAlwaysConfirm.frame = frame;
         */
    }
}

- (void)showSendStatus
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	self.sendStatusController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendStatusViewController"];



	CGRect frame = self.view.bounds;
	//frame.origin.x = frame.size.width;
	self.sendStatusController.view.frame = frame;
	[self.view addSubview:self.sendStatusController.view];
	self.sendStatusController.view.alpha = 0.0;

	self.sendStatusController.messageLabel.text = NSLocalizedString(@"Sending...", @"status message");

	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 self.sendStatusController.view.alpha = 1.0;
	 }
     completion:^(BOOL finished)
	 {
	 }];
}

- (void)hideSendStatus
{
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
    {
        self.sendStatusController.view.alpha = 0.0;
    }
    completion:^(BOOL finished)
    {
        [self.sendStatusController.view removeFromSuperview];
        self.sendStatusController = nil;
    }];
}

- (void)initiateSendRequest
{
	tABC_Error Error;
	tABC_CC result;
	tABC_WalletInfo **aWalletInfo = NULL;
    unsigned int nCount;
	double currency;
	
	result = ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                   self.amountToSendSatoshi, &currency, self.wallet.currencyNum, &Error);
	if (result == ABC_CC_Ok)
	{
		ABC_GetWallets([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &aWalletInfo, &nCount, &Error);
		
		if (nCount)
		{
			tABC_TxDetails Details;
			Details.amountSatoshi = self.amountToSendSatoshi;
			Details.amountCurrency = currency;
            // These will be calculated for us
			Details.amountFeesAirbitzSatoshi = 0;
			Details.amountFeesMinersSatoshi = 0;
            // If this is a transfer, populate the comments
            if (self.nameLabel) {
                Details.szName = (char *)[self.nameLabel UTF8String];
            } else {
                Details.szName = "";
            }
            Details.szCategory = "";
            Details.szNotes = "";
			Details.attributes = 0x2;
			
			tABC_WalletInfo *info = aWalletInfo[self.selectedWalletIndex];
			
            if (self.bAddressIsWalletUUID)
            {
                NSString *categoryText = NSLocalizedString(@"Transfer:Wallet:", nil);
                tABC_TransferDetails Transfer;
                Transfer.szSrcWalletUUID = strdup(info->szUUID);
                Transfer.szSrcName = strdup([self.destWallet.strName UTF8String]);
                Transfer.szSrcCategory = strdup([[NSString stringWithFormat:@"%@%@", categoryText, self.destWallet.strName] UTF8String]);

                Transfer.szDestWalletUUID = strdup([self.destWallet.strUUID UTF8String]);
                Transfer.szDestName = strdup([self.wallet.strName UTF8String]);
                Transfer.szDestCategory = strdup([[NSString stringWithFormat:@"%@%@", categoryText, self.wallet.strName] UTF8String]);

                result = ABC_InitiateTransfer([[User Singleton].name UTF8String],
                                            [[User Singleton].password UTF8String],
                                            &Transfer, &Details,
                                            ABC_SendConfirmation_Callback,
                                            (__bridge void *)self,
                                            &Error);

                free(Transfer.szSrcWalletUUID);
                free(Transfer.szSrcName);
                free(Transfer.szSrcCategory);
                free(Transfer.szDestWalletUUID);
                free(Transfer.szDestName);
                free(Transfer.szDestCategory);
            } else {
                result = ABC_InitiateSendRequest([[User Singleton].name UTF8String],
                                            [[User Singleton].password UTF8String],
                                            info->szUUID,
                                            [self.sendToAddress UTF8String],
                                            &Details,
                                            ABC_SendConfirmation_Callback,
                                            (__bridge void *)self,
                                            &Error);
            }
			if (result == ABC_CC_Ok)
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

- (void)setWalletLabel
{
	tABC_WalletInfo **aWalletInfo = NULL;
    unsigned int nCount;
	tABC_Error Error;

    ABC_GetWallets([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &aWalletInfo, &nCount, &Error);
    [Util printABC_Error:&Error];

	if (nCount > self.selectedWalletIndex)
	{
		tABC_WalletInfo *pInfo = aWalletInfo[self.selectedWalletIndex];
        
        NSMutableString *coinFormatted = [[NSMutableString alloc] init];
        [coinFormatted appendFormat:@"%@ (%@)",
         [NSString stringWithUTF8String:pInfo->szName],
         [CoreBridge formatSatoshi:pInfo->balanceSatoshi]];

        self.labelSendFrom.text = coinFormatted;
	}

    ABC_FreeWalletInfoArray(aWalletInfo, nCount);
}

- (void)launchTransactionDetailsWithTransaction:(Wallet *)wallet withTx:(Transaction *)transaction
{
    [self.view removeGestureRecognizer:tap];

	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	self.transactionDetailsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionDetailsViewController"];
	
	self.transactionDetailsController.delegate = self;
	self.transactionDetailsController.transaction = transaction;
	self.transactionDetailsController.wallet = self.wallet;
    self.transactionDetailsController.bOldTransaction = NO;
    self.transactionDetailsController.transactionDetailsMode = TD_MODE_SENT;
	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
	self.transactionDetailsController.view.frame = frame;
	
	[self.view addSubview:self.transactionDetailsController.view];
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 self.transactionDetailsController.view.frame = self.view.bounds;
	 }
					 completion:^(BOOL finished)
	 {
	 }];
	
}

- (void)failedToSend:(NSArray *)params
{
    NSString *title = params[0];
    NSString *message = params[1];
    UIAlertView *alert = [[UIAlertView alloc]
                            initWithTitle:title
                            message:message
                            delegate:nil
                            cancelButtonTitle:@"OK"
                            otherButtonTitles:nil];
    [alert show];
    [self hideSendStatus];
}

- (void)sendBitcoinComplete:(NSArray *)params
{
	[self performSelector:@selector(showTransactionDetails:) withObject:params afterDelay:3.0]; //show sending screen for 3 seconds
}

- (void)showTransactionDetails:(NSArray *)params
{
    if ([params count] < 2) {
        NSLog(@"Not enought args\n");
        return;
    }
    NSString *walletUUID = params[0];
    NSString *txId = params[1];
    Wallet *wallet = [CoreBridge getWallet:walletUUID];
    Transaction *transaction = [CoreBridge getTransaction:walletUUID withTx:txId];
	if (_callbackSuccess)
	{
        [self launchTransactionDetailsWithTransaction:wallet withTx:transaction];
	}
	else
	{
		NSLog(@"Error: %@", _strReason);
	}
	
}

- (void)updateTextFieldContents
{
	double currency;
    int64_t satoshi;
	tABC_Error error;

	if (_selectedTextField == self.amountBTCTextField)
	{
        self.amountToSendSatoshi = [CoreBridge denominationToSatoshi: self.amountBTCTextField.text];
		if (ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                  self.amountToSendSatoshi, &currency, self.wallet.currencyNum, &error) == ABC_CC_Ok)
        {
			self.amountUSDTextField.text = [NSString stringWithFormat:@"%.2f", currency];
        }
	}
	else if (_selectedTextField == self.amountUSDTextField)
	{
        currency = [self.amountUSDTextField.text doubleValue];
		if (ABC_CurrencyToSatoshi([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                  currency, self.wallet.currencyNum, &satoshi, &error) == ABC_CC_Ok)
		{
			self.amountToSendSatoshi = satoshi;
            self.amountBTCTextField.text = [CoreBridge formatSatoshi:satoshi
                                                          withSymbol:false
                                                    overrideDecimals:[CoreBridge currencyDecimalPlaces]];
		}
	}
    [self startCalcFees];
}

- (void)startCalcFees
{
    // Don't caculate fees until there is a value
    if (self.amountToSendSatoshi == 0)
    {
        self.conversionLabel.text = [CoreBridge conversionString:self.wallet];
        self.conversionLabel.textColor = [UIColor whiteColor];
        self.amountBTCTextField.textColor = [UIColor whiteColor];
        self.amountUSDTextField.textColor = [UIColor whiteColor];
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self calcFees];
    });
}

- (void)calcFees
{
    int64_t fees = 0;
    NSString *dest = [self getDestAddress];
    BOOL sufficent =
        [CoreBridge calcSendFees:self.wallet.strUUID
                          sendTo:dest
                    amountToSend:self.amountToSendSatoshi
                  storeResultsIn:&fees
                  walletTransfer:self.bAddressIsWalletUUID];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateFeeFieldContents:fees hasEnough:sufficent];
    });
}

- (void)updateFeeFieldContents:(int64_t)txFees hasEnough:(BOOL)sufficientFunds
{
    UIColor *color;
    _maxAmountButton.selected = NO;
    if (_maxAmount > 0 && _maxAmount == self.amountToSendSatoshi)
    {
        color = [UIColor colorWithRed:255/255.0f green:166/255.0f blue:52/255.0f alpha:1.0f];
        [_maxAmountButton setBackgroundImage:[UIImage imageNamed:@"btn_use_max.png"]
                                    forState:UIControlStateNormal];

    }
    else
    {
        color = [UIColor whiteColor];
        [_maxAmountButton setBackgroundImage:[UIImage imageNamed:@"btn_max.png"]
                                    forState:UIControlStateNormal];
    }
    if (sufficientFunds)
    {
        tABC_Error error;
        double currencyFees = 0.0;
        self.conversionLabel.textColor = color;
        self.amountBTCTextField.textColor = color;
        self.amountUSDTextField.textColor = color;

        NSMutableString *coinFeeString = [[NSMutableString alloc] init];
        NSMutableString *fiatFeeString = [[NSMutableString alloc] init];
        [coinFeeString appendString:@"+ "];
        [coinFeeString appendString:[CoreBridge formatSatoshi:txFees withSymbol:false]];
        [coinFeeString appendString:@" "];
        [coinFeeString appendString:[User Singleton].denominationLabel];

        if (ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], 
                                  txFees, &currencyFees, self.wallet.currencyNum, &error) == ABC_CC_Ok)
        {
            [fiatFeeString appendString:@"+ "];
            [fiatFeeString appendString:[CoreBridge formatCurrency:currencyFees
                                                   withCurrencyNum:self.wallet.currencyNum
                                                        withSymbol:false]];
            [fiatFeeString appendString:@" "];
            [fiatFeeString appendString:self.wallet.currencyAbbrev];
        }
        self.amountBTCLabel.text = coinFeeString; 
        self.amountUSDLabel.text = fiatFeeString;
        self.conversionLabel.text = [CoreBridge conversionString:self.wallet];
    }
    else
    {
        NSString *message = NSLocalizedString(@"Insufficient funds", nil);
        self.conversionLabel.text = message;
        self.conversionLabel.textColor = [UIColor redColor];
        self.amountBTCTextField.textColor = [UIColor redColor];
        self.amountUSDTextField.textColor = [UIColor redColor];
    }
    [self alineTextFields:self.amountBTCLabel alignWith:self.amountBTCTextField];
    [self alineTextFields:self.amountUSDLabel alignWith:self.amountUSDTextField];
}

- (void)alineTextFields:(UILabel *)child alignWith:(UITextField *)parent
{
    NSDictionary *attributes = @{NSFontAttributeName: parent.font};
    CGSize parentText = [parent.text sizeWithAttributes:attributes];

    CGRect parentField = parent.frame;
    CGRect childField = child.frame;
    int origX = childField.origin.x;
    int newX = parentField.origin.x + parentText.width;
    int newWidth = childField.size.width + (origX - newX);
    childField.origin.x = newX;
    childField.size.width = newWidth;
    child.frame = childField;
}

- (void)installLeftToRightSwipeDetection
{
	UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeftToRight:)];
	gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:gesture];
}

// used by the guesture recognizer to ignore exit
- (BOOL)haveSubViewsShowing
{
    return (self.sendStatusController != nil || self.transactionDetailsController != nil);
}


#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	_selectedTextField = textField;
    if (_selectedTextField == self.amountBTCTextField)
        self.keypadView.calcMode = CALC_MODE_COIN;
    else if (_selectedTextField == self.amountUSDTextField)
        self.keypadView.calcMode = CALC_MODE_FIAT;
	self.keypadView.textField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
}

#pragma mark - ConfirmationSlider delegates

- (void)ConfirmationSliderDidConfirm:(ConfirmationSliderView *)controller
{
	//make sure PIN is good
    if (self.withdrawlPIN.text.length)
	{
		//make sure the entered PIN matches the PIN stored in the Core
		tABC_Error error;
		char *szPIN = NULL;
		
		ABC_GetPIN([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &szPIN, &error);
		[Util printABC_Error:&error];
		NSLog(@"current PIN: %s", szPIN);
		if (szPIN)
		{
			NSString *storedPIN = [NSString stringWithUTF8String:szPIN];
			if ([self.withdrawlPIN.text isEqualToString:storedPIN])
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

#pragma mark - TransactionDetailsViewController delegates

- (void)TransactionDetailsViewControllerDone:(TransactionDetailsViewController *)controller
{
	[controller.view removeFromSuperview];
	self.transactionDetailsController = nil;

	[self.sendStatusController.view removeFromSuperview];
	self.sendStatusController = nil;

	[self.delegate sendConfirmationViewControllerDidFinish:self];
}

#pragma mark - ABC Callbacks

void ABC_SendConfirmation_Callback(const tABC_RequestResults *pResults)
{
    if (pResults)
    {
        SendConfirmationViewController *controller = (__bridge id)pResults->pData;
        controller->_callbackSuccess = (BOOL)pResults->bSuccess;
        controller->_strReason = [Util errorMap:&(pResults->errorInfo)];
        if (pResults->requestType == ABC_RequestType_SendBitcoin)
        {
            if (pResults->bSuccess)
            {
                NSString *walletUUID = [NSString stringWithUTF8String:pResults->szWalletUUID];
                NSString *txId = [NSString stringWithUTF8String:pResults->pRetData];
                NSArray *params = [NSArray arrayWithObjects: walletUUID, txId, nil];

                [controller performSelectorOnMainThread:@selector(sendBitcoinComplete:)
                                             withObject:params
                                          waitUntilDone:FALSE];
                free(pResults->pRetData);
            } else {
                free(pResults->pRetData);
                NSString *title = NSLocalizedString(@"Error during send", nil);
                NSString *message;
                if (pResults->errorInfo.code == ABC_CC_InsufficientFunds) {
                    message =
                        NSLocalizedString(@"You do not have enough funds to send this transaction.", nil);
                } else if (pResults->errorInfo.code == ABC_CC_ServerError) {
                    message = [Util errorMap:&(pResults->errorInfo)];
                } else {
                    message =
                        NSLocalizedString(@"There was an error when we were trying to send the funds. Please try again later.", nil);
                }
                NSArray *params = [NSArray arrayWithObjects: title, message, nil];
                [controller performSelectorOnMainThread:@selector(failedToSend:) 
                                             withObject:params
                                          waitUntilDone:FALSE];
            }
        }
    }
}

- (NSString *)getDestAddress
{
    if (self.bAddressIsWalletUUID) {
        return self.destWallet.strUUID;
    } else {
        return self.sendToAddress;
    }
}


#pragma mark - GestureReconizer methods

- (void)didSwipeLeftToRight:(UIGestureRecognizer *)gestureRecognizer
{
    if (![self haveSubViewsShowing])
    {
        [self Back:nil];
    }
}

#pragma mark - Custom Notification Handlers

// called when a tab bar button that is already selected, is reselected again
- (void)tabBarButtonReselect:(NSNotification *)notification
{
    if (![self haveSubViewsShowing])
    {
        [self Back:nil];
    }
}

@end

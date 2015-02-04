//
//  RequestViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "DDData.h"
#import "RequestViewController.h"
#import "Notifications.h"
#import "Transaction.h"
#import "TxOutput.h"
#import "CalculatorView.h"
#import "ButtonSelectorView.h"
#import "ABC.h"
#import "User.h"
#import "ShowWalletQRViewController.h"
#import "CoreBridge.h"
#import "Util.h"
#import "ImportWalletViewController.h"
#import "InfoView.h"
#import "LocalSettings.h"

#define QR_CODE_TEMP_FILENAME @"qr_request.png"
#define QR_CODE_SIZE          200.0

#define WALLET_BUTTON_WIDTH         200

#define OPERATION_CLEAR		0
#define OPERATION_BACK		1
#define OPERATION_DONE		2
#define OPERATION_DIVIDE	3
#define OPERATION_EQUAL		4
#define OPERATION_MINUS		5
#define OPERATION_MULTIPLY	6
#define OPERATION_PLUS		7
#define OPERATION_PERCENT	8

@interface RequestViewController () <UITextFieldDelegate, CalculatorViewDelegate, ButtonSelectorDelegate, 
                                     ShowWalletQRViewControllerDelegate, ImportWalletViewControllerDelegate>
{
	UITextField                 *_selectedTextField;
	int                         _selectedWalletIndex;
	ShowWalletQRViewController  *_qrViewController;
    ImportWalletViewController  *_importWalletViewController;
    tABC_TxDetails              _details;
    NSString                    *requestID;
}

@property (nonatomic, weak) IBOutlet CalculatorView     *keypadView;
@property (nonatomic, weak) IBOutlet UILabel            *BTCLabel_TextField;
@property (nonatomic, weak) IBOutlet UITextField        *BTC_TextField;
@property (nonatomic, weak) IBOutlet UILabel            *USDLabel_TextField;
@property (nonatomic, weak) IBOutlet UITextField        *USD_TextField;
@property (nonatomic, weak) IBOutlet ButtonSelectorView *buttonSelector;
@property (nonatomic, weak) IBOutlet UILabel            *exchangeRateLabel;
@property (nonatomic, weak) IBOutlet UIButton           *nextButton;

@property (nonatomic, copy)   NSString *strFullName;
@property (nonatomic, copy)   NSString *strPhoneNumber;
@property (nonatomic, copy)   NSString *strEMail;
@property (nonatomic, strong) NSArray  *arrayWallets;

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

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:nil];

	self.keypadView.delegate = self;
	self.buttonSelector.delegate = self;
	self.buttonSelector.textLabel.text = NSLocalizedString(@"Wallet:", @"Label text on Request Bitcoin screen");
    [self.buttonSelector setButtonWidth:WALLET_BUTTON_WIDTH];
    
    self.nextButton.titleLabel.text = NSLocalizedString(@"Next", @"Button label to go to Show Wallet QR view");
}

-(void)awakeFromNib
{
	
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // create a dummy view to replace the keyboard if we are on a 4.5" screen
    UIView *dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];

	[self loadWalletInfo];

	self.BTCLabel_TextField.text = [User Singleton].denominationLabel; 
    if (IS_IPHONE4) {
#ifdef __IPHONE_8_0
        [self.keypadView removeFromSuperview];
#endif
    }
	self.BTC_TextField.inputView = !IS_IPHONE4 ? dummyView : self.keypadView;
	self.USD_TextField.inputView = !IS_IPHONE4 ? dummyView : self.keypadView;
	self.BTC_TextField.delegate = self;
	self.USD_TextField.delegate = self;

    // if they are on a 4" screen then move the calculator below the bottom of the screen
    if (IS_IPHONE4 )
    {
        CGRect frame = self.keypadView.frame;
        frame.origin.y = frame.origin.y + frame.size.height;
        self.keypadView.frame = frame;
    }
    else
    {
        // no need for the done button since the calculator is always up
        [self.keypadView hideDoneButton];
    }

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exchangeRateUpdate:) name:NOTIFICATION_EXCHANGE_RATE_CHANGE object:nil];
    [self exchangeRateUpdate:nil]; 
}


-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

    [self setFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)showingQRCode:(NSString *)walletUUID withTx:(NSString *)txId
{
    if (_qrViewController == nil || _qrViewController.addressString == nil)
    {
        return NO;
    }
    Transaction *transaction = [CoreBridge getTransaction:walletUUID withTx:txId];
    for (TxOutput *output in transaction.outputs)
    {
        if (!output.bInput 
            && [_qrViewController.addressString isEqualToString:output.strAddress])
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)transactionWasDonation
{
    // a transaction can only be treated as a donation if the QR view is showing
    if (_qrViewController)
    {
        return [self isDonation:_qrViewController.amountSatoshi];
    }
    else
    {
        return NO;
    }
}


- (BOOL)isDonation:(SInt64)requestedSatoshis
{
    return YES == [LocalSettings controller].bMerchantMode && 0 == requestedSatoshis;
}

- (SInt64)transactionDifference:(NSString *)walletUUID withTx:(NSString *) txId
{
    // If the request was 0, then this was a donation and it's up to payer to
    // determine amount to send
    if (_details.amountSatoshi > 0)
    {
        Transaction *transaction = [CoreBridge getTransaction:walletUUID withTx:txId];
        return transaction.amountSatoshi - _details.amountSatoshi;
    }
    else
    {
        return 0;
    }
}

- (void)resetViews
{
    if (_importWalletViewController)
    {
        [_importWalletViewController.view removeFromSuperview];
        _importWalletViewController = nil;
    }
    if (_qrViewController)
    {
        [_qrViewController.view removeFromSuperview];
        _qrViewController = nil;
    }
    self.BTC_TextField.text = @"";
	self.USD_TextField.text = @"";

}


#pragma mark - Action Methods

- (IBAction)info
{
	[self.view endEditing:YES];
    [InfoView CreateWithHTML:@"infoRequest" forView:self.view];
}

- (IBAction)ImportWallet
{
	[self.view endEditing:YES];
    [self bringUpImportWalletView];
}

- (IBAction)QRCodeButton
{
    [self.view endEditing:YES];
    SInt64 amountSatoshi = [CoreBridge denominationToSatoshi:self.BTC_TextField.text];
    RequestState state = [self isDonation:amountSatoshi] ? kDonation : kRequest;
    [self LaunchQRCodeScreen:amountSatoshi withRequestState:state];
}

- (void)LaunchQRCodeScreen:(SInt64)amountSatoshi withRequestState:(RequestState)state
{
    [self.view endEditing:YES];
    
    SInt64 requestAmount = amountSatoshi;
    SInt64 donation = 0;
    if (kDonation == state)
    {
        // parameter represents the received donation amount
        requestAmount = 0;
        donation = amountSatoshi;
    }

    // get the QR Code image
    NSMutableString *strRequestID = [[NSMutableString alloc] init];
    NSMutableString *strRequestAddress = [[NSMutableString alloc] init];
    NSMutableString *strRequestURI = [[NSMutableString alloc] init];
    UIImage *qrImage = [self createRequestQRImageFor:@"" withNotes:@"" storeRequestIDIn:strRequestID storeRequestURI:strRequestURI storeRequestAddressIn:strRequestAddress scaleAndSave:NO withAmount:requestAmount withRequestState:state];

    ShowWalletQRViewController *tempQRViewController = NULL;
    if (_qrViewController)
    {
        tempQRViewController = _qrViewController;
    }
    // bring up the qr code view controller
    [self showQRCodeViewControllerWithQRImage:qrImage address:strRequestAddress requestURI:strRequestURI withAmount:requestAmount withDonation:donation withRequestState:state];

    if (tempQRViewController)
    {
        [tempQRViewController.view removeFromSuperview];
    }

}

#pragma mark - Notification Handlers

- (void)exchangeRateUpdate: (NSNotification *)notification
{
    NSLog(@"Updating exchangeRateUpdate");
	[self updateTextFieldContents];
}

#pragma mark - Misc Methods

- (void)setFirstResponder
{
    // if this is a 4.5" screen then the calculator is up so we need to always have one of the edit boxes selected
    if (!IS_IPHONE4)
    {
        // if the BTC is not the first responder
        if (![self.BTC_TextField isFirstResponder])
        {
            // make the USD the first responder
            [self.USD_TextField becomeFirstResponder];
        }
    }
}

- (const char *)createReceiveRequestFor:(NSString *)strName withNotes:(NSString *)strNotes withAmount:(SInt64)amountSatoshi withRequestState:(RequestState)state
{
	//creates a receive request.  Returns a requestID.  Caller must free this ID when done with it
	tABC_CC result;
	double currency;
	tABC_Error error;

    Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];

	//first need to create a transaction details struct
    memset(&_details, 0, sizeof(tABC_TxDetails));

    _details.amountSatoshi = amountSatoshi;
    if (kPartial != state)
    {
        self.originalAmountSatoshi = _details.amountSatoshi;
    }
	
	//the true fee values will be set by the core
	_details.amountFeesAirbitzSatoshi = 0;
	_details.amountFeesMinersSatoshi = 0;
	
	result = ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                   _details.amountSatoshi, &currency, wallet.currencyNum, &error);
	if (result == ABC_CC_Ok)
	{
		_details.amountCurrency = currency;
	}

    _details.szName = (char *) [strName UTF8String];
    _details.szNotes = (char *) [strNotes UTF8String];
	_details.szCategory = "";
	_details.attributes = 0x0; //for our own use (not used by the core)
    _details.bizId = 0;

	char *pRequestID;

    // create the request
	result = ABC_CreateReceiveRequest([[User Singleton].name UTF8String],
                                      [[User Singleton].password UTF8String],
                                      [wallet.strUUID UTF8String],
                                      &_details,
                                      &pRequestID,
                                      &error);

	if (result == ABC_CC_Ok)
	{
		return pRequestID;
	}
	else
	{
		return 0;
	}
}

-(void)showQRCodeViewControllerWithQRImage:(UIImage *)image address:(NSString *)address requestURI:(NSString *)strRequestURI withAmount:(SInt64)amountSatoshi  withDonation:(SInt64)donation withRequestState:(RequestState)state
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];

    _qrViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ShowWalletQRViewController"];

    Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
	_qrViewController.delegate = self;
	_qrViewController.qrCodeImage = image;
	_qrViewController.addressString = address;
	_qrViewController.uriString = strRequestURI;
    _qrViewController.amountSatoshi = amountSatoshi;
    _qrViewController.donation = donation;
    _qrViewController.state = state;

    if (kPartial == state)
    {
        NSMutableString *strBody = [[NSMutableString alloc] init];
        
        [strBody appendString:NSLocalizedString(@"Partial Payment from ",nil)];
        [strBody appendFormat:@"%@ ", [CoreBridge formatSatoshi:self.originalAmountSatoshi withSymbol:true]];
        [strBody appendString:NSLocalizedString(@"Request ",nil)];

        _qrViewController.statusString = [NSString stringWithFormat:@"%@", strBody];
    }
    else
    {
        _qrViewController.statusString = NSLocalizedString(@"Waiting for Payment...", @"Message on receive request screen");
    }
    _qrViewController.requestID = requestID;
    _qrViewController.walletUUID = wallet.strUUID;
    _qrViewController.txDetails = _details;
    _qrViewController.currencyNum = wallet.currencyNum;
	//CGRect frame = self.view.bounds;
	//_qrViewController.view.frame = frame;
	[self.view addSubview:_qrViewController.view];
	_qrViewController.view.alpha = 0.0;
	
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		_qrViewController.view.alpha = 1.0;
	 }
    completion:^(BOOL finished)
    {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }];
}

// generates and returns a request qr image, stores request id in the given mutable string
- (UIImage *)createRequestQRImageFor:(NSString *)strName withNotes:(NSString *)strNotes storeRequestIDIn:(NSMutableString *)strRequestID storeRequestURI:(NSMutableString *)strRequestURI storeRequestAddressIn:(NSMutableString *)strRequestAddress scaleAndSave:(BOOL)bScaleAndSave withAmount:(SInt64)amountSatoshi withRequestState:(RequestState)state
{
    UIImage *qrImage = nil;
    [strRequestID setString:@""];
    [strRequestAddress setString:@""];
    [strRequestURI setString:@""];

    unsigned int width = 0;
    unsigned char *pData = NULL;
    char *pszURI = NULL;
    tABC_Error error;

    const char *szRequestID = [self createReceiveRequestFor:strName withNotes:strNotes withAmount:amountSatoshi withRequestState:state];
    requestID = [NSString stringWithUTF8String:szRequestID];

    if (szRequestID)
    {
        Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
        tABC_CC result = ABC_GenerateRequestQRCode([[User Singleton].name UTF8String],
                                           [[User Singleton].password UTF8String],
                                           [wallet.strUUID UTF8String],
                                                   szRequestID,
                                                   &pszURI,
                                                   &pData,
                                                   &width,
                                                   &error);

        if (result == ABC_CC_Ok)
        {
                qrImage = [Util dataToImage:pData withWidth:width andHeight:width];

            if (pszURI && strRequestURI)
            {
                [strRequestURI appendFormat:@"%s", pszURI];
                free(pszURI);
            }
            
        }
        else
        {
                [Util printABC_Error:&error];
        }
    }

    if (szRequestID)
    {
        if (strRequestID)
        {
            [strRequestID appendFormat:@"%s", szRequestID];
        }
        char *szRequestAddress = NULL;

        Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
        tABC_CC result = ABC_GetRequestAddress([[User Singleton].name UTF8String],
                                               [[User Singleton].password UTF8String],
                                               [wallet.strUUID UTF8String],
                                               szRequestID,
                                               &szRequestAddress,
                                               &error);

        if (result == ABC_CC_Ok)
        {
            if (szRequestAddress && strRequestAddress)
            {
                [strRequestAddress appendFormat:@"%s", szRequestAddress];
                free(szRequestAddress);
            }
        }
        else
        {
            [Util printABC_Error:&error];
        }

        free((void*)szRequestID);
    }

    if (pData)
    {
        free(pData);
    }
    
    UIImage *qrImageFinal = qrImage;

    if (bScaleAndSave)
    {
        // scale qr image up
        UIGraphicsBeginImageContext(CGSizeMake(QR_CODE_SIZE, QR_CODE_SIZE));
        CGContextRef c = UIGraphicsGetCurrentContext();
        CGContextSetInterpolationQuality(c, kCGInterpolationNone);
        [qrImage drawInRect:CGRectMake(0, 0, QR_CODE_SIZE, QR_CODE_SIZE)];
        qrImageFinal = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        // save it to a file
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:QR_CODE_TEMP_FILENAME];
        [UIImagePNGRepresentation(qrImageFinal) writeToFile:filePath atomically:YES];
    }

    return qrImageFinal;
}

- (void)updateTextFieldContents
{
    tABC_Error error;
    Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
    self.exchangeRateLabel.text = [CoreBridge conversionString:wallet];
    self.USDLabel_TextField.text = wallet.currencyAbbrev;
	if (_selectedTextField == self.BTC_TextField)
	{
		double currency;
        int64_t satoshi = [CoreBridge denominationToSatoshi: self.BTC_TextField.text];
		if (ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                  satoshi, &currency, wallet.currencyNum, &error) == ABC_CC_Ok)
            self.USD_TextField.text = [CoreBridge formatCurrency:currency
                                                 withCurrencyNum:wallet.currencyNum
                                                      withSymbol:false];
	}
	else if (_selectedTextField == self.USD_TextField)
	{
		int64_t satoshi;
		double currency = [self.USD_TextField.text doubleValue];
		if (ABC_CurrencyToSatoshi([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                  currency, wallet.currencyNum, &satoshi, &error) == ABC_CC_Ok)
            self.BTC_TextField.text = [CoreBridge formatSatoshi:satoshi
                                                     withSymbol:false
                                               cropDecimals:[CoreBridge currencyDecimalPlaces]];
	}
}

- (void)loadWalletInfo
{
    // load all the non-archive wallets
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWallets:arrayWallets archived:nil withTxs:NO];

    // create the array of wallet names
    _selectedWalletIndex = 0;
    NSMutableArray *arrayWalletNames = [[NSMutableArray alloc] initWithCapacity:[arrayWallets count]];
    for (int i = 0; i < [arrayWallets count]; i++)
    {
        Wallet *wallet = [arrayWallets objectAtIndex:i];
 
        [arrayWalletNames addObject:[NSString stringWithFormat:@"%@ (%@)", wallet.strName, [CoreBridge formatSatoshi:wallet.balance]]];
 
        if ([_walletUUID isEqualToString: wallet.strUUID])
            _selectedWalletIndex = i;
    }
    
    if (_selectedWalletIndex < [arrayWallets count])
    {
        Wallet *wallet = [arrayWallets objectAtIndex:_selectedWalletIndex];
        self.keypadView.currencyNum = wallet.currencyNum;

        self.buttonSelector.arrayItemsToSelect = [arrayWalletNames copy];
        [self.buttonSelector.button setTitle:wallet.strName forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = (int) _selectedWalletIndex;
    }
    self.arrayWallets = arrayWallets;
}

- (void)bringUpImportWalletView
{
    if (nil == _importWalletViewController)
    {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
        _importWalletViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ImportWalletViewController"];

        _importWalletViewController.delegate = self;

        CGRect frame = self.view.bounds;
        frame.origin.x = frame.size.width;
        _importWalletViewController.view.frame = frame;
        [self.view addSubview:_importWalletViewController.view];

        [UIView animateWithDuration:0.35
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             _importWalletViewController.view.frame = self.view.bounds;
         }
                         completion:^(BOOL finished)
         {

         }];
    }
}

#pragma mark - Calculator delegates

- (void)CalculatorDone:(CalculatorView *)calculator
{
	[self.BTC_TextField resignFirstResponder];
	[self.USD_TextField resignFirstResponder];
}

- (void)CalculatorValueChanged:(CalculatorView *)calculator
{
	[self updateTextFieldContents];
}


#pragma mark - ButtonSelectorView delegates

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
    _selectedWalletIndex = itemIndex;

    // Update wallet UUID
    Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
    [self.buttonSelector.button setTitle:wallet.strName forState:UIControlStateNormal];
    self.buttonSelector.selectedItemIndex = _selectedWalletIndex;
    
    _walletUUID = wallet.strUUID;

    self.keypadView.currencyNum = wallet.currencyNum;
    [self updateTextFieldContents];
}

#pragma mark - ShowWalletQRViewController delegates

- (void)ShowWalletQRViewControllerDone:(ShowWalletQRViewController *)controller
{
	[controller.view removeFromSuperview];
	_qrViewController = nil;

    [self setFirstResponder];
}

#pragma mark - Textfield delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	_selectedTextField = textField;
    if (_selectedTextField == self.BTC_TextField)
        self.keypadView.calcMode = CALC_MODE_COIN;
    else if (_selectedTextField == self.USD_TextField)
        self.keypadView.calcMode = CALC_MODE_FIAT;

	self.keypadView.textField = textField;
	self.BTC_TextField.text = @"";
	self.USD_TextField.text = @"";
}

#pragma mark - Import Wallet Delegates

- (void)importWalletViewControllerDidFinish:(ImportWalletViewController *)controller
{
	[controller.view removeFromSuperview];
	_importWalletViewController = nil;

    [self setFirstResponder];
}


@end

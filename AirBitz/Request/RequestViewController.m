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
#import "ButtonSelectorView.h"
#import "ABC.h"
#import "User.h"
#import "ShowWalletQRViewController.h"

#define OPERATION_CLEAR		0
#define OPERATION_BACK		1
#define OPERATION_DONE		2
#define OPERATION_DIVIDE	3
#define OPERATION_EQUAL		4
#define OPERATION_MINUS		5
#define OPERATION_MULTIPLY	6
#define OPERATION_PLUS		7
#define OPERATION_PERCENT	8

#define DOLLAR_CURRENCY_NUM	840

@interface RequestViewController () <UITextFieldDelegate, CalculatorViewDelegate, ButtonSelectorDelegate, ShowWalletQRViewControllerDelegate>
{
	UITextField *selectedTextField;
	int selectedWalletIndex;
	NSString *selectedWalletUUID;
	ShowWalletQRViewController *qrViewController;
}

@property (nonatomic, weak) IBOutlet CalculatorView *keypadView;
@property (nonatomic, weak) IBOutlet UITextField *BTC_TextField;
@property (nonatomic, weak) IBOutlet UITextField *USD_TextField;
@property (nonatomic, weak) IBOutlet ButtonSelectorView *buttonSelector;

//@property (nonatomic, weak) IBOutlet UIImageView *testImageView;

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
	self.buttonSelector.delegate = self;
	self.buttonSelector.textLabel.text = NSLocalizedString(@"Wallet:", @"Label text on Request Bitcoin screen");
	[self setWalletButtonTitle];
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

#pragma mark Actions

/*
 typedef struct sABC_TxDetails
 {
 
	int64_t amountSatoshi;				// amount of bitcoins in satoshi (including fees if any)
	int64_t amountFeesAirbitzSatoshi;	// airbitz fees in satoshi
	int64_t amountFeesMinersSatoshi;	// miners fees in satoshi
	double amountCurrency;				// amount in currency
	char *szName;						// payer or payee
	char *szCategory;					// category for the transaction
	char *szNotes;						// notes for the transaction
	unsigned int attributes;			// attributes for the transaction
} tABC_TxDetails;

 createReceiveREquest will now give me addresses
*/

-(const char *)createReceiveRequest
{
	//creates a receive request.  Returns a requestID.  Caller must free this ID when done with it
	
	tABC_TxDetails details;
	tABC_CC result;
	double currency;
	tABC_Error error;
	
	//first need to create a transaction details struct
	details.amountSatoshi = ABC_BitcoinToSatoshi([self.BTC_TextField.text doubleValue]);
	#warning TODO: need to set up fees
	details.amountFeesAirbitzSatoshi = details.amountSatoshi / 100;
	details.amountFeesMinersSatoshi = 0;
	
	#warning TODO:  hard coded to DOLLAR right now
	result = ABC_SatoshiToCurrency(details.amountSatoshi, &currency, DOLLAR_CURRENCY_NUM, &error);
	if(result == ABC_CC_Ok)
	{
		details.amountCurrency = currency;
	}
	
	tABC_AccountSettings *pAccountSettings = NULL;
    ABC_LoadAccountSettings([[User Singleton].name UTF8String],
                            [[User Singleton].password UTF8String],
                            &pAccountSettings,
                            &error);
	
	if(pAccountSettings->bNameOnPayments)
	{
		details.szName = pAccountSettings->szNickname;
	}
	else
	{
		//cw should we change details.szName to a const char * (to fix warning)?
		details.szName = [NSLocalizedString(@"Anonymous", @"Name on payment") UTF8String];
	}
	
	#warning TODO: Need to set up category for this transaction
	details.szCategory = "None";
	
	#warning TODO: Need to set up notes for this transaction
	details.szNotes = "";
	
	#warning TODO: Need to set up attributes for this transaction
	details.attributes = 0x2;
	
	if(pAccountSettings)
	{
		ABC_FreeAccountSettings(pAccountSettings);
	}
	
	char *pRequestID;
	
	result = ABC_CreateReceiveRequest([[User Singleton].name UTF8String],
											  [[User Singleton].password UTF8String],
                                     [selectedWalletUUID UTF8String],
                                     &details,
                                     &pRequestID,
                                     &error);
				
	if(result == ABC_CC_Ok)
	{
		return pRequestID;
	}
	else
	{
		return 0;
	}
}

-(UIImage *)dataToImage:(const unsigned char *)data withWidth:(int)width andHeight:(int)height
{
	//converts raw monochrome bitmap data (each byte is a 1 or a 0 representing a pixel) into a UIImage
	char *pixels = malloc(4 * width * width);
	char *buf = pixels;
		
	for (int y = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++)
		{
			if (data[(y * width) + x] & 0x1)
			{
				printf("%c", '*');
				*buf++ = 0;
				*buf++ = 0;
				*buf++ = 0;
				*buf++ = 255;
			}
			else
			{
				printf(" ");
				*buf++ = 255;
				*buf++ = 255;
				*buf++ = 255;
				*buf++ = 255;
			}
		}
		printf("\n");
	}
	
	CGContextRef ctx;
	CGImageRef imageRef;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	ctx = CGBitmapContextCreate(pixels,
								(float)width,
								(float)height,
								8,
								width * 4,
								colorSpace,
								kCGImageAlphaPremultipliedLast );
	CGColorSpaceRelease(colorSpace);
	imageRef = CGBitmapContextCreateImage (ctx);
	UIImage* rawImage = [UIImage imageWithCGImage:imageRef];
	
	CGContextRelease(ctx);
	CGImageRelease(imageRef);
	free(pixels);
	return rawImage;
}

-(void)showQRCodeViewControllerWithQRImage:(UIImage *)image
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	qrViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ShowWalletQRViewController"];
	
	qrViewController.delegate = self;
	qrViewController.qrCodeImage = image;
	
	CGRect frame = self.view.bounds;
	qrViewController.view.frame = frame;
	[self.view addSubview:qrViewController.view];
	qrViewController.view.alpha = 0.0;
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		qrViewController.view.alpha = 1.0;
	 }
					 completion:^(BOOL finished)
	 {
	 }];
}

-(IBAction)QRCodeButton
{
	unsigned int width = 0;
    unsigned char *pData = NULL;
	tABC_Error error;
	
	const char *requestID = [self createReceiveRequest];
	
	if(requestID)
	{
		tABC_CC result = ABC_GenerateRequestQRCode([[User Singleton].name UTF8String],
                                      [[User Singleton].password UTF8String],
                                      [selectedWalletUUID UTF8String],
                                      requestID,
                                      &pData,
                                      &width,
                                      &error);
	
		if(result == ABC_CC_Ok)
		{
			printf("QRCode width: %d\n", width);
			//UtilHexDump("QRCode data", pData, width * width);
			
			UIImage *qrImage = [self dataToImage:pData withWidth:width andHeight:width];
			
			
			
			//self.testImageView.image = qrImage;
			//self.testImageView.layer.magnificationFilter = kCAFilterNearest;
			[self showQRCodeViewControllerWithQRImage:qrImage];
			
		}
		else
		{
			[self printABC_Error:&error];
		}
		if(requestID) free((void*)requestID);
	}
	
    if(pData) free(pData);
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

- (void)printABC_Error:(const tABC_Error *)pError
{
    if (pError)
    {
        if (pError->code != ABC_CC_Ok)
        {
            printf("Code: %d, Desc: %s, Func: %s, File: %s, Line: %d\n",
                   pError->code,
                   pError->szDescription,
                   pError->szSourceFunc,
                   pError->szSourceFile,
                   pError->nSourceLine
                   );
        }
    }
}

-(void)setWalletButtonTitle
{
	tABC_WalletInfo **aWalletInfo = NULL;
    unsigned int nCount;
	tABC_Error Error;
    ABC_GetWallets([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &aWalletInfo, &nCount, &Error);
    [self printABC_Error:&Error];
	
    printf("Wallets:\n");
	
	if(nCount)
	{
		tABC_WalletInfo *info = aWalletInfo[selectedWalletIndex];
		
		selectedWalletUUID = [NSString stringWithUTF8String:info->szUUID];
		[self.buttonSelector.button setTitle:[NSString stringWithUTF8String:info->szName] forState:UIControlStateNormal];
		self.buttonSelector.selectedItemIndex = selectedWalletIndex;
	}
	
    // assign list of wallets to buttonSelector
	NSMutableArray *walletsArray = [[NSMutableArray alloc] init];
	
    for (int i = 0; i < nCount; i++)
    {
        tABC_WalletInfo *pInfo = aWalletInfo[i];
		/*
		 printf("Account: %s, UUID: %s, Name: %s, currency: %d, attributes: %u, balance: %lld\n",
		 pInfo->szUserName,
		 pInfo->szUUID,
		 pInfo->szName,
		 pInfo->currencyNum,
		 pInfo->attributes,
		 pInfo->balanceSatoshi);
		 */
		[walletsArray addObject:[NSString stringWithUTF8String:pInfo->szName]];
    }
	
	self.buttonSelector.arrayItemsToSelect = [walletsArray copy];
    ABC_FreeWalletInfoArray(aWalletInfo, nCount);
}


#pragma mark ButtonSelectorView delegates
-(void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
	NSLog(@"Selected item %i", itemIndex);
}

#pragma mark ShowWalletQRViewController delegates

-(void)ShowWalletQRViewControllerDone:(ShowWalletQRViewController *)controller
{
	[controller.view removeFromSuperview];
	qrViewController = nil;
}
@end

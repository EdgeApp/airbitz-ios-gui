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
#import "RequestViewController.h"
#import "Notifications.h"
#import "Transaction.h"
#import "CalculatorView.h"
#import "ButtonSelectorView.h"
#import "ABC.h"
#import "User.h"
#import "ShowWalletQRViewController.h"
#import "CommonTypes.h"
#import "CoreBridge.h"

#define QR_CODE_TEMP_FILENAME @"qr_request.png"
#define QR_CODE_SIZE          200.0


typedef enum eAddressPickerType
{
    AddressPickerType_SMS,
    AddressPickerType_EMail
} tAddressPickerType;

#define OPERATION_CLEAR		0
#define OPERATION_BACK		1
#define OPERATION_DONE		2
#define OPERATION_DIVIDE	3
#define OPERATION_EQUAL		4
#define OPERATION_MINUS		5
#define OPERATION_MULTIPLY	6
#define OPERATION_PLUS		7
#define OPERATION_PERCENT	8

@interface RequestViewController () <UITextFieldDelegate, CalculatorViewDelegate, ButtonSelectorDelegate, ShowWalletQRViewControllerDelegate, ABPeoplePickerNavigationControllerDelegate, MFMessageComposeViewControllerDelegate>
{
	UITextField                 *_selectedTextField;
	int                         _selectedWalletIndex;
	NSString                    *_selectedWalletUUID;
	ShowWalletQRViewController  *_qrViewController;
    tAddressPickerType          _addressPickerType;
}

@property (nonatomic, weak) IBOutlet CalculatorView     *keypadView;
@property (nonatomic, weak) IBOutlet UILabel            *BTCLabel_TextField;
@property (nonatomic, weak) IBOutlet UITextField        *BTC_TextField;
@property (nonatomic, weak) IBOutlet UILabel            *USDLabel_TextField;
@property (nonatomic, weak) IBOutlet UITextField        *USD_TextField;
@property (nonatomic, weak) IBOutlet ButtonSelectorView *buttonSelector;
@property (nonatomic, weak) IBOutlet UILabel            *exchangeRateLabel;

@property (nonatomic, copy) NSString *strFullName;
@property (nonatomic, copy) NSString *strPhoneNumber;

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
    [super viewWillAppear:animated];
	self.BTCLabel_TextField.text = [User Singleton].denominationLabel; 
	self.BTC_TextField.inputView = self.keypadView;
	self.USDLabel_TextField.text = @"USD";
	self.USD_TextField.inputView = self.keypadView;
	self.BTC_TextField.delegate = self;
	self.USD_TextField.delegate = self;
    self.exchangeRateLabel.text = [CoreBridge conversionString: DOLLAR_CURRENCY_NUM];
	
	CGRect frame = self.keypadView.frame;
	frame.origin.y = frame.origin.y + frame.size.height;
	self.keypadView.frame = frame;
}


-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action Methods

- (IBAction)info
{
	[self.view endEditing:YES];
}

- (IBAction)ImportWallet
{
	[self.view endEditing:YES];
}

- (IBAction)email
{
    [self showAddressPickerFor:AddressPickerType_EMail];
}

- (IBAction)SMS
{
    [self showAddressPickerFor:AddressPickerType_SMS];
}

- (IBAction)QRCodeButton
{
	unsigned int width = 0;
    unsigned char *pData = NULL;
	tABC_Error error;

	[self.view endEditing:YES];

	const char *requestID = [self createReceiveRequest];

	if (requestID)
	{
		tABC_CC result = ABC_GenerateRequestQRCode([[User Singleton].name UTF8String],
                                                   [[User Singleton].password UTF8String],
                                                   [_selectedWalletUUID UTF8String],
                                                   requestID,
                                                   &pData,
                                                   &width,
                                                   &error);

		if (result == ABC_CC_Ok)
		{
			//printf("QRCode width: %d\n", width);

			UIImage *qrImage = [self dataToImage:pData withWidth:width andHeight:width];
			char *requestAddress;

			result = ABC_GetRequestAddress([[User Singleton].name UTF8String],
										   [[User Singleton].password UTF8String],
										   [_selectedWalletUUID UTF8String],
                                           requestID,
                                           &requestAddress,
                                           &error);
			if (result == ABC_CC_Ok)
			{
				[self showQRCodeViewControllerWithQRImage:qrImage address:[NSString stringWithUTF8String:requestAddress]];
				free(requestAddress);
			}
		}
		else
		{
			[self printABC_Error:&error];
		}
		if (requestID) free((void*)requestID);
	}
    if (pData) free(pData);
}

#pragma mark - Misc Methods

- (const char *)createReceiveRequest
{
	//creates a receive request.  Returns a requestID.  Caller must free this ID when done with it
	
	tABC_TxDetails details;
	tABC_CC result;
	double currency;
	tABC_Error error;
	
	//first need to create a transaction details struct
    details.amountSatoshi = [CoreBridge denominationToSatoshi:[self.BTC_TextField.text doubleValue]];
	
	//the true fee values will be set by the core
	details.amountFeesAirbitzSatoshi = 0;
	details.amountFeesMinersSatoshi = 0;
	
	#warning TODO:  hard coded to DOLLAR right now
	result = ABC_SatoshiToCurrency(details.amountSatoshi, &currency, DOLLAR_CURRENCY_NUM, &error);
	if (result == ABC_CC_Ok)
	{
		details.amountCurrency = currency;
	}
	
	tABC_AccountSettings *pAccountSettings = NULL;
    ABC_LoadAccountSettings([[User Singleton].name UTF8String],
                            [[User Singleton].password UTF8String],
                            &pAccountSettings,
                            &error);
	
	if (pAccountSettings->bNameOnPayments)
	{
        if (pAccountSettings->szNickname)
        {
            details.szName = pAccountSettings->szNickname;
        }
        else
        {
            details.szName = "";
        }
	}
	else
	{
		//cw should we change details.szName to a const char * (to fix warning)?
		details.szName = (char *)[NSLocalizedString(@"Anonymous", @"Name on payment") UTF8String];
	}
	
	#warning TODO: Need to set up category for this transaction
	details.szCategory = "";
	
	#warning TODO: Need to set up notes for this transaction
	details.szNotes = "";
	
	details.attributes = 0x0; //for our own use (not used by the core)

	char *pRequestID;

    // create the request
	result = ABC_CreateReceiveRequest([[User Singleton].name UTF8String],
                                      [[User Singleton].password UTF8String],
                                      [_selectedWalletUUID UTF8String],
                                      &details,
                                      &pRequestID,
                                      &error);

    // free the account setting structure we obtained
	if (pAccountSettings)
	{
		ABC_FreeAccountSettings(pAccountSettings);
	}

	if (result == ABC_CC_Ok)
	{
		return pRequestID;
	}
	else
	{
		return 0;
	}
}

- (UIImage *)dataToImage:(const unsigned char *)data withWidth:(int)width andHeight:(int)height
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
				//printf("%c", '*');
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
		//printf("\n");
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

-(void)showQRCodeViewControllerWithQRImage:(UIImage *)image address:(NSString *)address
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_qrViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ShowWalletQRViewController"];
	
	_qrViewController.delegate = self;
	_qrViewController.qrCodeImage = image;
	_qrViewController.addressString = address;
	_qrViewController.statusString = NSLocalizedString(@"Waiting for Payment...", @"Message on receive request screen");
	_qrViewController.amountSatoshi = ABC_BitcoinToSatoshi([self.BTC_TextField.text doubleValue]);
	CGRect frame = self.view.bounds;
	_qrViewController.view.frame = frame;
	[self.view addSubview:_qrViewController.view];
	_qrViewController.view.alpha = 0.0;
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		_qrViewController.view.alpha = 1.0;
	 }
					 completion:^(BOOL finished)
	 {
	 }];
}

- (void)showAddressPickerFor:(tAddressPickerType)type
{
	[self.view endEditing:YES];

    _addressPickerType = type;

    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];

    picker.peoplePickerDelegate = self;

    if (type == AddressPickerType_SMS)
    {
        picker.displayedProperties = @[[NSNumber numberWithInt:kABPersonPhoneProperty]];
    }
    else
    {
        picker.displayedProperties = @[[NSNumber numberWithInt:kABPersonEmailProperty]];
    }

    [self presentViewController:picker animated:YES completion:nil];
    //[self.view.window.rootViewController presentViewController:picker animated:YES completion:nil];
}

// generates and returns a request qr image, stores request id in the given mutable string
- (UIImage *)createRequestQRImage:(NSMutableString *)strRequestID
{

    UIImage *qrImage = nil;

	unsigned int width = 0;
    unsigned char *pData = NULL;
	tABC_Error error;

	[self.view endEditing:YES];

	const char *requestID = [self createReceiveRequest];

	if (requestID)
	{
		tABC_CC result = ABC_GenerateRequestQRCode([[User Singleton].name UTF8String],
                                                   [[User Singleton].password UTF8String],
                                                   [_selectedWalletUUID UTF8String],
                                                   requestID,
                                                   &pData,
                                                   &width,
                                                   &error);

		if (result == ABC_CC_Ok)
		{
			qrImage = [self dataToImage:pData withWidth:width andHeight:width];
		}
		else
		{
			[self printABC_Error:&error];
		}
	}

    if (requestID)
    {
        if (strRequestID)
        {
            [strRequestID appendFormat:@"%s", requestID];
        }
        free((void*)requestID);
    }

    if (pData)
    {
        free(pData);
    }

    return qrImage;
}

- (void)updateTextFieldContents
{
	if (_selectedTextField == self.BTC_TextField)
	{
		double value = [self.BTC_TextField.text doubleValue];
        double satoshi = [CoreBridge denominationToSatoshi: value];
		
		double currency;
		tABC_Error error;
		
		ABC_SatoshiToCurrency(satoshi, &currency, DOLLAR_CURRENCY_NUM, &error);
		
		self.USD_TextField.text = [NSString stringWithFormat:@"%.2f", currency];
	}
	else
	{
		double value = [self.USD_TextField.text doubleValue];

		int64_t satoshi;
		tABC_Error	error;
		tABC_CC result;
		
		result = ABC_CurrencyToSatoshi(value, DOLLAR_CURRENCY_NUM, &satoshi, &error);
		if(result == ABC_CC_Ok)
		{
            self.BTC_TextField.text = [CoreBridge formatSatoshi: satoshi];
		}
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

- (void)setWalletButtonTitle
{
	tABC_WalletInfo **aWalletInfo = NULL;
    unsigned int nCount;
	tABC_Error Error;
    ABC_GetWallets([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &aWalletInfo, &nCount, &Error);
    [self printABC_Error:&Error];
	
    NSLog(@"Wallets:\n");
	
	if (_selectedWalletIndex <= nCount)
	{
		tABC_WalletInfo *info = aWalletInfo[_selectedWalletIndex];
		
		_selectedWalletUUID = [NSString stringWithUTF8String:info->szUUID];
		[self.buttonSelector.button setTitle:[NSString stringWithUTF8String:info->szName] forState:UIControlStateNormal];
		self.buttonSelector.selectedItemIndex = _selectedWalletIndex;
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

- (void)sendSMS
{
    //NSLog(@"sendSMS to: %@ / %@", self.strFullName, self.strPhoneNumber);

    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
	if ([MFMessageComposeViewController canSendText] && [MFMessageComposeViewController canSendAttachments])
	{
        NSMutableString *strBody = [[NSMutableString alloc] init];
        [strBody appendString:@"Bitcoin Request"];

        // get the QR Code image
        NSMutableString *strRequestID = [[NSMutableString alloc] init];
        UIImage *image = [self createRequestQRImage:strRequestID];

        // scale it up
        UIGraphicsBeginImageContext(CGSizeMake(QR_CODE_SIZE, QR_CODE_SIZE));
        CGContextRef c = UIGraphicsGetCurrentContext();
        CGContextSetInterpolationQuality(c, kCGInterpolationNone);
        [image drawInRect:CGRectMake(0, 0, QR_CODE_SIZE, QR_CODE_SIZE)];
        UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        // save it to a file so we can add it as an attachment
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:QR_CODE_TEMP_FILENAME];
        [UIImagePNGRepresentation(scaledImage) writeToFile:filePath atomically:YES];

        char *requestAddress = NULL;
        ABC_GetRequestAddress([[User Singleton].name UTF8String],
                              [[User Singleton].password UTF8String],
                              [_selectedWalletUUID UTF8String],
                              [strRequestID UTF8String],
                              &requestAddress,
                              NULL);
        if (requestAddress)
        {
            [strBody appendFormat:@":\n%s", requestAddress];
            free(requestAddress);
        }

        BOOL attached = [controller addAttachmentData:UIImagePNGRepresentation(scaledImage) typeIdentifier:(NSString*)kUTTypePNG filename:filePath];
        if (attached)
        {
            NSLog(@"Attached qr code");
        }
        else
        {
            NSLog(@"Not attached qr code");
        }

		controller.body = strBody;

        if (self.strPhoneNumber)
        {
            if ([self.strPhoneNumber length] != 0)
            {
                controller.recipients = @[self.strPhoneNumber];
            }
        }

		controller.messageComposeDelegate = self;

        [self presentViewController:controller animated:YES completion:nil];
        //[self.view.window.rootViewController presentViewController:controller animated:YES completion:nil];
	}

}

- (NSString *)getNameFromAddressRecord:(ABRecordRef)person
{
    NSString *strFirstName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *strMiddleName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
    NSString *strLastName  = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);

    NSMutableString *strFullName = [[NSMutableString alloc] init];
    if (strFirstName)
    {
        [strFullName appendString:strFirstName];
    }
    if (strMiddleName)
    {
        if ([strFullName length])
        {
            [strFullName appendString:@" "];
        }
        [strFullName appendString:strMiddleName];
    }
    if (strLastName)
    {
        if ([strFullName length])
        {
            [strFullName appendString:@" "];
        }
        [strFullName appendString:strLastName];
    }

    // if we don't have a name yet, try the company
    if ([strFullName length] == 0)
    {
        NSString *strCompanyName  = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonOrganizationProperty);
        if (strCompanyName)
        {
            [strFullName appendString:strCompanyName];
        }
    }

    return strFullName;
}

#pragma mark - calculator delegates

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
	NSLog(@"Selected item %i", itemIndex);
    _selectedWalletIndex = itemIndex;
    [self setWalletButtonTitle];
}

#pragma mark - ShowWalletQRViewController delegates

- (void)ShowWalletQRViewControllerDone:(ShowWalletQRViewController *)controller
{
	[controller.view removeFromSuperview];
	_qrViewController = nil;
}

#pragma mark - Address Book delegates

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [[peoplePicker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{

    self.strFullName = [self getNameFromAddressRecord:person];

    if (_addressPickerType == AddressPickerType_SMS)
    {
        if (property == kABPersonPhoneProperty)
        {
            ABMultiValueRef multiPhones = ABRecordCopyValue(person, kABPersonPhoneProperty);
            for (CFIndex i = 0; i < ABMultiValueGetCount(multiPhones); i++)
            {
                if (identifier == ABMultiValueGetIdentifierAtIndex(multiPhones, i))
                {
                    NSString *strPhoneNumber = (__bridge_transfer NSString *) ABMultiValueCopyValueAtIndex(multiPhones, i);
                    self.strPhoneNumber = strPhoneNumber;
                    break;
                }
            }
            CFRelease(multiPhones);
        }

        [[peoplePicker presentingViewController] dismissViewControllerAnimated:YES completion:^{
            [self sendSMS];
        }];
    }


    return NO;
}

#pragma mark - MFMessageComposeViewController delegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
	switch (result)
    {
		case MessageComposeResultCancelled:
			NSLog(@"Cancelled");
			break;
		case MessageComposeResultFailed:
        {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AirBitz"
                                                            message:@"Error sending SMS"
														   delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
			[alert show];
        }
			break;

		case MessageComposeResultSent:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AirBitz"
                                                            message:@"Request sent"
														   delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
			[alert show];
        }
			break;

		default:
			break;
	}

    [[controller presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Textfield delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	_selectedTextField = textField;
	self.keypadView.textField = textField;
	self.BTC_TextField.text = @"";
	self.USD_TextField.text = @"";
}


@end

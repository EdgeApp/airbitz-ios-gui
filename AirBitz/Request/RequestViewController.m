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
#import "CalculatorView.h"
#import "ButtonSelectorView.h"
#import "ABC.h"
#import "User.h"
#import "ShowWalletQRViewController.h"
#import "CommonTypes.h"
#import "CoreBridge.h"
#import "Util.h"
#import "ImportWalletViewController.h"

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

@interface RequestViewController () <UITextFieldDelegate, CalculatorViewDelegate, ButtonSelectorDelegate, ShowWalletQRViewControllerDelegate, ABPeoplePickerNavigationControllerDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, ImportWalletViewControllerDelegate>
{
	UITextField                 *_selectedTextField;
	int                         _selectedWalletIndex;
	NSString                    *_selectedWalletUUID;
	ShowWalletQRViewController  *_qrViewController;
    tAddressPickerType          _addressPickerType;
    ImportWalletViewController  *_importWalletViewController;
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
@property (nonatomic, copy) NSString *strEMail;

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
    [self bringUpImportWalletView];
}

- (IBAction)email
{
    [self.view endEditing:YES];
    self.strFullName = @"";
    self.strEMail = @"";
    _addressPickerType = AddressPickerType_EMail;

    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Send Email", nil)
                          message:NSLocalizedString(@"Select from contacts?", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"Yes, Contacts", nil)
                          otherButtonTitles:NSLocalizedString(@"No, Skip", nil), nil];
    [alert show];
}

- (IBAction)SMS
{
    [self.view endEditing:YES];
    self.strPhoneNumber = @"";
    self.strFullName = @"";
    _addressPickerType = AddressPickerType_SMS;

    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Send SMS", nil)
                          message:NSLocalizedString(@"Select from contacts?", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"Yes, Contacts", nil)
                          otherButtonTitles:NSLocalizedString(@"No, Skip", nil), nil];
    [alert show];
}

- (IBAction)QRCodeButton
{
	[self.view endEditing:YES];

    // get the QR Code image
    NSMutableString *strRequestID = [[NSMutableString alloc] init];
    NSMutableString *strRequestAddress = [[NSMutableString alloc] init];
    UIImage *qrImage = [self createRequestQRImageFor:@"" withNotes:@"" storeRequestIDIn:strRequestID storeRequestAddressIn:strRequestAddress scaleAndSave:NO];

    // bring up the qr code view controller
    [self showQRCodeViewControllerWithQRImage:qrImage address:strRequestAddress];
}

#pragma mark - Misc Methods

- (const char *)createReceiveRequestFor:(NSString *)strName withNotes:(NSString *)strNotes
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

    details.szName = (char *) [strName UTF8String];
    details.szNotes = (char *) [strNotes UTF8String];

	#warning TODO: Need to set up category for this transaction
	details.szCategory = "";

	details.attributes = 0x0; //for our own use (not used by the core)

	char *pRequestID;

    // create the request
	result = ABC_CreateReceiveRequest([[User Singleton].name UTF8String],
                                      [[User Singleton].password UTF8String],
                                      [_selectedWalletUUID UTF8String],
                                      &details,
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
    double satoshi = [CoreBridge denominationToSatoshi:[self.BTC_TextField.text doubleValue]];
    _qrViewController.amountSatoshi = [CoreBridge formatSatoshi: satoshi];
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

- (void)showAddressPicker
{
	[self.view endEditing:YES];

    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];

    picker.peoplePickerDelegate = self;

    if (_addressPickerType == AddressPickerType_SMS)
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
- (UIImage *)createRequestQRImageFor:(NSString *)strName withNotes:(NSString *)strNotes storeRequestIDIn:(NSMutableString *)strRequestID storeRequestAddressIn:(NSMutableString *)strRequestAddress scaleAndSave:(BOOL)bScaleAndSave
{
    UIImage *qrImage = nil;
    [strRequestID setString:@""];
    [strRequestAddress setString:@""];

	unsigned int width = 0;
    unsigned char *pData = NULL;
	tABC_Error error;

	const char *szRequestID = [self createReceiveRequestFor:strName withNotes:strNotes];

	if (szRequestID)
	{
		tABC_CC result = ABC_GenerateRequestQRCode([[User Singleton].name UTF8String],
                                                   [[User Singleton].password UTF8String],
                                                   [_selectedWalletUUID UTF8String],
                                                   szRequestID,
                                                   &pData,
                                                   &width,
                                                   &error);

		if (result == ABC_CC_Ok)
		{
			qrImage = [self dataToImage:pData withWidth:width andHeight:width];
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

        tABC_CC result = ABC_GetRequestAddress([[User Singleton].name UTF8String],
                                               [[User Singleton].password UTF8String],
                                               [_selectedWalletUUID UTF8String],
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

- (void)setWalletButtonTitle
{
	tABC_WalletInfo **aWalletInfo = NULL;
    unsigned int nCount;
	tABC_Error Error;
    ABC_GetWallets([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &aWalletInfo, &nCount, &Error);
    [Util printABC_Error:&Error];
	
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

- (void)sendEMail
{
    //NSLog(@"sendEMail to: %@ / %@", self.strFullName, self.strEMail);

    // if mail is available
    if ([MFMailComposeViewController canSendMail])
    {
        NSMutableString *strBody = [[NSMutableString alloc] init];

        [strBody appendString:@"<html><body>\n"];

        [strBody appendString:NSLocalizedString(@"Bitcoin Request", nil)];
        [strBody appendString:@"<br><br>\n"];

        // create the request and get the QR Code image
        NSMutableString *strRequestID = [[NSMutableString alloc] init];
        NSMutableString *strRequestAddress = [[NSMutableString alloc] init];
        UIImage *image = [self createRequestQRImageFor:self.strFullName withNotes:self.strEMail storeRequestIDIn:strRequestID storeRequestAddressIn:strRequestAddress scaleAndSave:YES];

        // if we have a request address
        if ([strRequestAddress length])
        {
            [strBody appendFormat:@"%@", strRequestAddress];
            [strBody appendString:@"<br><br>\n"];
        }

        NSData *imageData = [NSData dataWithData:UIImageJPEGRepresentation(image, 1.0)];
        NSString *base64String = [imageData base64Encoded];
        [strBody appendString:[NSString stringWithFormat:@"<p><b><img src='data:image/jpeg;base64,%@'></b></p>", base64String]];

        [strBody appendString:@"</body></html>\n"];




        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];

        if ([self.strEMail length])
        {
            [mailComposer setToRecipients:[NSArray arrayWithObject:self.strEMail]];
        }

        [mailComposer setSubject:NSLocalizedString(@"Bitcoin Request", nil)];

        [mailComposer setMessageBody:strBody isHTML:YES];

        mailComposer.mailComposeDelegate = self;

        [self presentViewController:mailComposer animated:YES completion:nil];
        //[self presentModalViewController:mailComposer animated:NO];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Can't send e-mail"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)sendSMS
{
    //NSLog(@"sendSMS to: %@ / %@", self.strFullName, self.strPhoneNumber);

    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
	if ([MFMessageComposeViewController canSendText] && [MFMessageComposeViewController canSendAttachments])
	{
        NSMutableString *strBody = [[NSMutableString alloc] init];
        [strBody appendString:NSLocalizedString(@"Bitcoin Request", nil)];

        // create the request and get the QR Code image
        NSMutableString *strRequestID = [[NSMutableString alloc] init];
        NSMutableString *strRequestAddress = [[NSMutableString alloc] init];
        UIImage *image = [self createRequestQRImageFor:self.strFullName withNotes:self.strPhoneNumber storeRequestIDIn:strRequestID storeRequestAddressIn:strRequestAddress scaleAndSave:YES];

        // if we have a request address
        if ([strRequestAddress length])
        {
            [strBody appendFormat:@":\n%@", strRequestAddress];
        }

        // create the attachment
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:QR_CODE_TEMP_FILENAME];
        BOOL bAttached = [controller addAttachmentData:UIImagePNGRepresentation(image) typeIdentifier:(NSString*)kUTTypePNG filename:filePath];
        if (!bAttached)
        {
            NSLog(@"Could not attach qr code");
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

// creates the full name from an address book record
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

- (void)bringUpImportWalletView
{
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
    else if (_addressPickerType == AddressPickerType_EMail)
    {
        if (property == kABPersonEmailProperty)
        {
            ABMultiValueRef multiEMails = ABRecordCopyValue(person, kABPersonEmailProperty);
            for (CFIndex i = 0; i < ABMultiValueGetCount(multiEMails); i++)
            {
                if (identifier == ABMultiValueGetIdentifierAtIndex(multiEMails, i))
                {
                    NSString *strEMail = (__bridge_transfer NSString *) ABMultiValueCopyValueAtIndex(multiEMails, i);
                    self.strEMail = strEMail;
                    break;
                }
            }
            CFRelease(multiEMails);
        }

        [[peoplePicker presentingViewController] dismissViewControllerAnimated:YES completion:^{
            [self sendEMail];
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

#pragma mark - Mail Compose Delegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    NSString *strTitle = nil;
    NSString *strMsg = nil;

	switch (result)
    {
		case MFMailComposeResultCancelled:
            strMsg = NSLocalizedString(@"Email cancelled.", nil);
			break;

		case MFMailComposeResultSaved:
            strMsg = NSLocalizedString(@"Email saved to send later.", nil);
			break;

		case MFMailComposeResultSent:
            strMsg = NSLocalizedString(@"Email sent.", nil);
			break;

		case MFMailComposeResultFailed:
		{
            strTitle = NSLocalizedString(@"Error sending Email.", nil);
            strMsg = [error localizedDescription];
			break;
		}
		default:
			break;
	}

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle
                                                    message:strMsg
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];

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

#pragma mark UIAlertView delegates

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	// we only use the alert for selecting from contacts or not

    // if they wanted to select from contacts
    if (buttonIndex == 0)
    {
        [self performSelector:@selector(showAddressPicker) withObject:nil afterDelay:0.0];
    }
    else if (_addressPickerType == AddressPickerType_SMS)
    {
        [self performSelector:@selector(sendSMS) withObject:nil afterDelay:0.0];
    }
    else if (_addressPickerType == AddressPickerType_EMail)
    {
        [self performSelector:@selector(sendEMail) withObject:nil afterDelay:0.0];
    }
}

#pragma mark - Import Wallet Delegates

- (void)importWalletViewControllerDidFinish:(ImportWalletViewController *)controller
{
	[controller.view removeFromSuperview];
	_importWalletViewController = nil;
}


@end

//
//  ShowWalletQRViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

/* BLE flow:
 Request Bitcoin (this file): Peripheral
 Build table of services and characteristics.
 Start advertising
 Once connected:
 receive first and last name from Central
 show “connected” popup
 when read request comes in:
 Write entire bit coin address and amount to characteristic
 
 
 Send Bitcoin: Central
 Once connected:
 write first and last name to characteristic
 wait for -peripheral:didWriteValueForCharacteristic callback
 Request a read of the characteristic
 wait to receive bit coin address and amount from peripheral
 When it comes in, disconnect and transition to send confirmation screen
 */

#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "DDData.h"
#import "ShowWalletQRViewController.h"
#import "Notifications.h"
#import "ABC.h"
#import "Util.h"
#import "User.h"
#import "CoreBridge.h"
#import "InfoView.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "TransferService.h"
#import "RecipientViewController.h"
#import "Contact.h"
#import "LocalSettings.h"

//This allows you to test the case when the advertisied bitcoin address (first 10 digits) doesn't match the actual bitcoin address.  This is to catch the rare condition where someone could try to spoof someone else's bitcoin request.
#define TEST_SEND_BOGUS_BITCOIN_ADDRESS	0 /* should be 0 for deployment */
#define BOGUS_BITCOIN_ADDRESS_STRING	@"bitcoin:cwHpX8DTZ2dSf12bntRHNarGoJJTri8ZG5?label=Carson%20Whitsett%20-%20Hello"

#define QR_CODE_TEMP_FILENAME @"qr_request.png"

#define QR_ATTACHMENT_WIDTH 100

#define NOTIFY_MTU      20

typedef enum eAddressPickerType
{
    AddressPickerType_SMS,
    AddressPickerType_EMail
} tAddressPickerType;

static NSTimeInterval		lastPeripheralBLEPowerOffNotificationTime = 0;

@interface ShowWalletQRViewController () <ABPeoplePickerNavigationControllerDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, CBPeripheralManagerDelegate, RecipientViewControllerDelegate, UIGestureRecognizerDelegate>
{
    tAddressPickerType          _addressPickerType;
}

@property (nonatomic, weak) IBOutlet UIImageView    *qrCodeImageView;
@property (nonatomic, weak) IBOutlet UILabel        *statusLabel;
@property (nonatomic, weak) IBOutlet UILabel        *amountLabel;
@property (nonatomic, weak) IBOutlet UILabel        *addressLabel1;
@property (nonatomic, weak) IBOutlet UILabel        *addressLabel2;
@property (weak, nonatomic) IBOutlet UIView         *viewQRCodeFrame;
@property (weak, nonatomic) IBOutlet UIImageView    *imageBottomFrame;
@property (weak, nonatomic) IBOutlet UIButton       *buttonCancel;
@property (weak, nonatomic) IBOutlet UIButton       *buttonCopyAddress;
@property (nonatomic, weak) IBOutlet UIImageView	*BLE_LogoImageView;

@property (nonatomic, copy)   NSString *strFullName;
@property (nonatomic, copy)   NSString *strPhoneNumber;
@property (nonatomic, copy)   NSString *strEMail;

@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic   *bitcoinURICharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic   *userNameCharacteristic;
@property (strong, nonatomic) NSData                    *dataToSend;
//@property (nonatomic, readwrite) NSInteger              sendDataIndex;

@property (nonatomic, weak) IBOutlet UIView				*connectedView;
@property (nonatomic, weak) IBOutlet UIImageView		*connectedPhoto;
@property (nonatomic, weak) IBOutlet UILabel			*connectedName;
@property (nonatomic, weak) IBOutlet UILabel			*connectedLine2;
@property (nonatomic, weak) IBOutlet UILabel			*connectedLine3;

@property (nonatomic, weak) IBOutlet UIButton                *refreshButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *refreshSpinner;

@property (nonatomic, strong) RecipientViewController   *recipientViewController;
@property (nonatomic, strong) NSArray                   *arrayContacts;

@end

@implementation ShowWalletQRViewController

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

    [self updateDisplayLayout];

	self.qrCodeImageView.layer.magnificationFilter = kCAFilterNearest;
	self.qrCodeImageView.image = self.qrCodeImage;
	self.statusLabel.text = self.statusString;
	//show first eight characters of address larger than rest
	if(self.addressString.length >= 8)
	{
		self.addressLabel1.text = [self.addressString substringToIndex:8];
		[self.addressLabel1 sizeToFit];
		if(self.addressString.length > 8)
		{
			self.addressLabel2.text = [self.addressString substringFromIndex:8];
			
			CGRect frame = self.addressLabel2.frame;
			float endX = frame.origin.x + frame.size.width;
			frame.origin.x = self.addressLabel1.frame.origin.x + self.addressLabel1.frame.size.width;
			frame.size.width = endX - frame.origin.x;
			self.addressLabel2.frame = frame;
		}
	}
	else
	{
		self.addressLabel1.text = self.addressString;
	}

    switch (self.state) {
        case kPartial:
        {
            self.amountLabel.text = [NSString stringWithFormat:@"%@ %@",[CoreBridge formatSatoshi: self.amountSatoshi],@"Remaining..."];
            break;
        }
        default:
        {
            self.amountLabel.text = [CoreBridge formatSatoshi: self.amountSatoshi];
            break;
        }
    }
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:NO]];
	
	if([LocalSettings controller].bDisableBLE)
	{
		self.BLE_LogoImageView.hidden = YES;
	}
	else
	{
		// Start up the CBPeripheralManager.  Warn if settings BLE is on but device BLE is off (but only once every 24 hours)
		NSTimeInterval curTime = CACurrentMediaTime();
		if((curTime - lastPeripheralBLEPowerOffNotificationTime) > 86400.0) //24 hours
		{
			_peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:@{CBPeripheralManagerOptionShowPowerAlertKey: @(YES)}];
		}
		else
		{
			_peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:@{CBPeripheralManagerOptionShowPowerAlertKey: @(NO)}];
		}
		lastPeripheralBLEPowerOffNotificationTime = curTime;
	}
	
	self.connectedView.alpha = 0.0;
	self.connectedPhoto.layer.cornerRadius = 8.0;
	self.connectedPhoto.layer.masksToBounds = YES;

	 self.arrayContacts = @[];
	// load all the names from the address book
    [self generateListOfContactNames];

    if (kPartial == self.state || (kDonation == self.state && 0 < _donation))
    {
        [self showPaymentPopup];
    }
    
    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [CoreBridge prioritizeAddress:_addressString inWallet:_walletUUID];
}

-(void)viewWillDisappear:(BOOL)animated
{
	if([LocalSettings controller].bDisableBLE == NO)
	{
		// Don't keep it going while we're not showing.
		[self.peripheralManager stopAdvertising];
	}
    [CoreBridge prioritizeAddress:nil inWallet:_walletUUID];
}

-(void)showConnectedPopup
{
	self.connectedView.alpha = 1.0;
	self.qrCodeImageView.alpha = 0.0;
    self.connectedLine2.text = @"Connected";
    self.connectedLine3.text = @"";
	
	//see if there is a match between advertised name and name in contacts.  If so, use the photo from contacts
	BOOL imageIsFromContacts = NO;
	
	NSArray *arrayComponents = [self.connectedName.text componentsSeparatedByString:@" "];
	if(arrayComponents.count >= 2)
	{
		//filter off the nickname.  We just want first name and last name
		NSString *firstName = [arrayComponents objectAtIndex:0];
		NSString *lastName = [arrayComponents objectAtIndex:1];
		NSString *name = [NSString stringWithFormat:@"%@ %@", firstName, lastName ];
		for (Contact *contact in self.arrayContacts)
		{
			if([[name uppercaseString] isEqualToString:[contact.strName uppercaseString]])
			{
				self.connectedPhoto.image = contact.imagePhoto;
				imageIsFromContacts = YES;
				break;
			}
		}
	}
		
	
	if(imageIsFromContacts == NO)
	{
		self.connectedPhoto.image = [UIImage imageNamed:@"BLE_photo.png"];
	}
	
	[UIView animateWithDuration:3.0
						  delay:2.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^
	 {
		 self.connectedView.alpha = 0.0;
		 self.qrCodeImageView.alpha = 1.0;
	 }
	 completion:^(BOOL finished)
	 {
		 
	 }];
}

-(void)showPaymentPopup
{
    NSTimeInterval delay;
    NSTimeInterval duration;
    switch (self.state) {
        case kPartial:
        {
            delay = 2.0;
            duration = 4.0;
            self.connectedName.text = @"** Warning **";
            self.connectedLine2.text = @"Partial Payment";
            self.connectedLine3.text = @"";
            self.connectedPhoto.image = [UIImage imageNamed:@"Warning_icon.png"];
            break;
        }
        case kDonation:
        {
            delay = 7.0;
            duration = 2.0;
            self.connectedName.text = @"Payment received";
            tABC_Error error;
            double currency;
            if (ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                      _donation, &currency, _currencyNum, &error) == ABC_CC_Ok)
            {
                NSString *fiatAmount = [CoreBridge currencySymbolLookup:_currencyNum];
                NSString *fiatSymbol = [NSString stringWithFormat:@"%.2f", currency];
                NSString *fiat = [fiatAmount stringByAppendingString:fiatSymbol];
                self.connectedLine2.text = [CoreBridge formatSatoshi:_donation];
                self.connectedLine3.text = fiat;
            }
            else
            {
                // failed to look up the wallet's fiat currency
                self.connectedLine2.text = [CoreBridge formatSatoshi:self.amountSatoshi];
                self.connectedLine3.text = @"";
            }
            break;
        }
        default:
        {
            return;
        }
    }
    
    self.connectedView.alpha = 1.0;
    self.qrCodeImageView.alpha = 0.0;
    [UIView animateWithDuration:duration
                          delay:delay
                        options:UIViewAnimationOptionCurveLinear
                     animations:^
     {
         self.connectedView.alpha = 0.0;
         self.qrCodeImageView.alpha = 1.0;
     }
                     completion:^(BOOL finished)
     {
     }];
}

#pragma mark address book

- (void)generateListOfContactNames
{
    NSMutableArray *arrayContacts = [[NSMutableArray alloc] init];
	
    CFErrorRef error;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
	
    __block BOOL accessGranted = NO;
	
    if (ABAddressBookRequestAccessWithCompletion != NULL)
    {
        // we're on iOS 6
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
		
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     accessGranted = granted;
                                                     dispatch_semaphore_signal(sema);
                                                 });
		
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        //dispatch_release(sema);
    }
    else
    {
        // we're on iOS 5 or older
        accessGranted = YES;
    }
	
    if (accessGranted)
    {
        CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
        for (CFIndex i = 0; i < CFArrayGetCount(people); i++)
        {
            ABRecordRef person = CFArrayGetValueAtIndex(people, i);
			
            NSString *strFullName = [Util getNameFromAddressRecord:person];
            if ([strFullName length])
            {
                // add this contact
                [self addContactInfo:person withName:strFullName toArray:arrayContacts];
            }
        }
        CFRelease(people);
    }
	
    // assign final
    self.arrayContacts = [arrayContacts sortedArrayUsingSelector:@selector(compare:)];
    //NSLog(@"contacts: %@", self.arrayContacts);
}

- (void)addContactInfo:(ABRecordRef)person withName:(NSString *)strName toArray:(NSMutableArray *)arrayContacts
{
    UIImage *imagePhoto = nil;
	
    // does this contact has an image
    if (ABPersonHasImageData(person))
    {
        NSData *data = (__bridge_transfer NSData*)ABPersonCopyImageData(person);
        imagePhoto = [UIImage imageWithData:data];
    }

	Contact *contact = [[Contact alloc] init];
	contact.strName = strName;
	//contact.strData = strData;
	//contact.strDataLabel = strDataLabel;
	contact.imagePhoto = imagePhoto;
	
	[arrayContacts addObject:contact];
}

#pragma mark - CBPeripheral methods

/** Required protocol method.  A full app should take care of all the possible states,
 *  but we're just waiting for  to know when the CBPeripheralManager is ready
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
	if(peripheral.state == CBPeripheralManagerStatePoweredOn)
	{

		// We're in CBPeripheralManagerStatePoweredOn state...
		//NSLog(@"self.peripheralManager powered on.");
		
		// ... so build our service.
		
		// Start with the CBMutableCharacteristic
		self.bitcoinURICharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
																		 properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite
																			  value:nil
																		permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
											
											
		// Then the service
		CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]
																		   primary:YES];
		
		// Add the characteristic to the service
		transferService.characteristics = @[self.bitcoinURICharacteristic];
		
		// And add it to the peripheral manager
		[self.peripheralManager addService:transferService];
		
		//now start advertising (UUID and username)
		
		//make 10-character address
		NSString *address;
		if(self.addressString.length >= 10)
		{
			address = [self.addressString substringToIndex:10];
		}
		else
		{
			address = self.addressString;
		}
		
		tABC_AccountSettings            *pAccountSettings;
		tABC_Error Error;
		Error.code = ABC_CC_Ok;
		
		// load the current account settings
		pAccountSettings = NULL;
		ABC_LoadAccountSettings([[User Singleton].name UTF8String],
								[[User Singleton].password UTF8String],
								&pAccountSettings,
								&Error);
		[Util printABC_Error:&Error];
		
		BOOL sendName = NO;
		if (pAccountSettings)
		{
			if(pAccountSettings->bNameOnPayments)
			{
				sendName = YES;
			}
			ABC_FreeAccountSettings(pAccountSettings);
		}
		
		NSString *name;
		if(sendName)
		{
			name = [User Singleton].fullName ;
		}
		else
		{
			name = @" ";
		}
		//broadcast first 10 digits of bitcoin address followed by full name (up to 28 bytes total)
		[self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]], CBAdvertisementDataLocalNameKey : [NSString stringWithFormat:@"%@%@", address, name]}];
		self.BLE_LogoImageView.hidden = NO;
	}
	else
	{
		self.BLE_LogoImageView.hidden = YES;
	}

}


/** Catch when someone subscribes to our characteristic, then start sending them data
 */
 /*
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
    
	//[self showConnectedPopup];
	
    // Send the bitcoin address and the amount in Satoshi
	NSString *stringToSend = [NSString stringWithFormat:@"%@", self.uriString];
    self.dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
    
    // Reset the index
    self.sendDataIndex = 0;
    
    // Start sending
    [self sendData];
}*/


/** Recognise when the central unsubscribes
 */
 /*
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central unsubscribed from characteristic");
	[self.navigationController popViewControllerAnimated:YES];
}
*/

/** Sends the next amount of data to the connected central
 */
 /*
- (void)sendData
{
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    
    if (sendingEOM)
	{
        // send it
		
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.bitcoinURICharacteristic onSubscribedCentrals:nil];
        
        // Did it send?
        if (didSend)
		{
            // It did, so mark it as sent
            sendingEOM = NO;
            
            NSLog(@"Sent: EOM");
        }
        
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    
    // Is there any left to send?
    
    if (self.sendDataIndex >= self.dataToSend.length)
	{
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    
    BOOL didSend = YES;
    
    while (didSend)
	{
        // Make the next chunk
        
        // Work out how big it should be
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
        
        // Send it
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.bitcoinURICharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend)
		{
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.sendDataIndex >= self.dataToSend.length)
		{
            // It was - send an EOM
            
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            
            // Send it
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.bitcoinURICharacteristic onSubscribedCentrals:nil];
            
            if (eomSent)
			{
                // It sent, we're all done
                sendingEOM = NO;
                NSLog(@"Sent: EOM");
            }
            return;
        }
    }
}
*/

/** This callback comes in when the PeripheralManager is ready to send the next chunk of data.
 *  This is to ensure that packets will arrive in the order they are sent
 */
 /*
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    // Start sending again
    [self sendData];
}*/

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
	//NSLog(@"didReceiveWriteRequests");
	for(CBATTRequest *request in requests)
	{
		if([request.characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
		{
			NSString *userName = [[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding];
			//NSLog(@"Received new string: %@", userName);
			
			self.connectedName.text = userName;
		}
	}
	[self showConnectedPopup];
	[self.peripheralManager respondToRequest:[requests objectAtIndex:0] withResult:CBATTErrorSuccess];
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
	//NSLog(@"didReceiveReadRequests");

	if([request.characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
	{
		// Send the bitcoin address and the amount in Satoshi
#if TEST_SEND_BOGUS_BITCOIN_ADDRESS
		NSString *stringToSend = BOGUS_BITCOIN_ADDRESS_STRING;
#else
		NSString *stringToSend = [NSString stringWithFormat:@"%@", self.uriString];
#endif
		self.dataToSend = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];
		request.value = self.dataToSend;
		[peripheral respondToRequest:request withResult:CBATTErrorSuccess];
	}
}

#pragma mark - Action Methods

- (IBAction)Refresh
{
    _refreshButton.hidden = YES;
    _refreshSpinner.hidden = NO;
    [CoreBridge refreshWallet:_walletUUID refreshData:NO notify:^{
        _refreshSpinner.hidden = YES;
        _refreshButton.hidden = NO;
    }];
}

- (IBAction)CopyAddress
{
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	[pb setString:self.addressString];
}

- (IBAction)Cancel
{
	[self Back];
}

- (IBAction)Back
{
	self.view.alpha = 1.0;
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		self.view.alpha = 0.0;
	 }
                    completion:^(BOOL finished)
    {
        [self.delegate ShowWalletQRViewControllerDone:self];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:YES]];
}

- (IBAction)Info
{
	[self.view endEditing:YES];
    [InfoView CreateWithHTML:@"infoRequestQR" forView:self.view];
}

- (IBAction)email
{
    self.strFullName = @"";
    self.strEMail = @"";

    [self launchRecipientWithMode:RecipientMode_Email];

#if 0 // old method
    _addressPickerType = AddressPickerType_EMail;

    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Send Email", nil)
                          message:NSLocalizedString(@"Select Email from Contact List?", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"Yes", nil)
                          otherButtonTitles:NSLocalizedString(@"No, I'll type it manually", nil), nil];
    [alert show];
#endif
}

- (IBAction)SMS
{
    self.strPhoneNumber = @"";
    self.strFullName = @"";

    [self launchRecipientWithMode:RecipientMode_SMS];

#if 0 // old method
    _addressPickerType = AddressPickerType_SMS;

    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Send SMS", nil)
                          message:NSLocalizedString(@"Select from Contact List?", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"Yes, Contacts", nil)
                          otherButtonTitles:NSLocalizedString(@"No, I'll type in manually", nil), nil];
    [alert show];
#endif
}


#pragma mark - Misc Methods

- (void)updateDisplayLayout
{
    // if we are on a smaller screen
    if (IS_IPHONE4 )
    {
        // be prepared! lots and lots of magic numbers here to jam the controls to fit on a small screen

        CGRect frame;

        frame = self.imageBottomFrame.frame;
        frame.size.height = 135.0;
        self.imageBottomFrame.frame = frame;

        self.buttonCancel.hidden = YES;
        /*
         
        frame = self.viewQRCodeFrame.frame;
        frame.origin.y = 67.0;
        self.viewQRCodeFrame.frame = frame;

        frame = self.qrCodeImageView.frame;
        frame.origin.y = self.viewQRCodeFrame.frame.origin.y + 8.0;
        self.qrCodeImageView.frame = frame;

        frame = self.imageBottomFrame.frame;
        frame.origin.y = self.viewQRCodeFrame.frame.origin.y + self.viewQRCodeFrame.frame.size.height + 2.0;
        frame.size.height = 165.0;
        self.imageBottomFrame.frame = frame;

        frame = self.statusLabel.frame;
        frame.origin.y = self.imageBottomFrame.frame.origin.y + 2.0;
        self.statusLabel.frame = frame;

        frame = self.amountLabel.frame;
        frame.origin.y = self.statusLabel.frame.origin.y + self.statusLabel.frame.size.height + 3.0;
        self.amountLabel.frame = frame;

        frame = self.addressLabel.frame;
        frame.origin.y = self.amountLabel.frame.origin.y + self.amountLabel.frame.size.height + 3.0;
        self.addressLabel.frame = frame;

        frame = self.buttonCancel.frame;
        frame.origin.y = self.addressLabel.frame.origin.y + self.addressLabel.frame.size.height + 3.0;
        self.buttonCancel.frame = frame;

        frame = self.buttonCopyAddress.frame;
        frame.origin.y = self.buttonCancel.frame.origin.y + self.buttonCancel.frame.size.height + 3.0;
        self.buttonCopyAddress.frame = frame;
*/
    }
}

- (void)replaceRequestTags:(NSString **) strContent
{
    NSString *amountBTC = [CoreBridge formatSatoshi:self.amountSatoshi
                                         withSymbol:false
                                      forceDecimals:8];
    NSString *amountMBTC = [CoreBridge formatSatoshi:self.amountSatoshi
                                          withSymbol:false
                                       forceDecimals:5];
    // For sending requests, use 8 decimal places which is a BTC (not mBTC or uBTC amount)
    
    NSString *iosURL;
    NSString *redirectURL = [NSString stringWithString: self.uriString];
    NSString *paramsURI;
    NSString *paramsURIEnc;
    
    NSRange tempRange = [self.uriString rangeOfString:@"bitcoin:"];
    
    if (*strContent == NULL)
    {
        return;
    }
    
    if (tempRange.location != NSNotFound)
    {
        iosURL = [self.uriString stringByReplacingCharactersInRange:tempRange withString:@"bitcoin://"];
        paramsURI = [self.uriString stringByReplacingCharactersInRange:tempRange withString:@""];
        paramsURIEnc = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                             NULL,
                                                                                             (CFStringRef)paramsURI,
                                                                                             NULL,
                                                                                             (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                             kCFStringEncodingUTF8 ));
        redirectURL = [NSString stringWithFormat:@"%@%@",@"https://airbitz.co/blf/?address=", paramsURIEnc ];
        
    }
    NSString *name;
    
    if ([User Singleton].bNameOnPayments && [User Singleton].fullName)
    {
        name = [NSString stringWithString:[User Singleton].fullName];
    }
    else
    {
        name = nil;
    }
        
    NSMutableArray* searchList  = [[NSMutableArray alloc] initWithObjects:
                                   @"[[abtag FROM]]",
                                   @"[[abtag BITCOIN_URL]]",
                                   @"[[abtag REDIRECT_URL]]",
                                   @"[[abtag BITCOIN_URI]]",
                                   @"[[abtag ADDRESS]]",
                                   @"[[abtag AMOUNT_BTC]]",
                                   @"[[abtag AMOUNT_MBTC]]",
                                   @"[[abtag QRCODE]]",
                                   nil];
    
    NSMutableArray* replaceList = [[NSMutableArray alloc] initWithObjects:
                                   name ? name : @"Unknown User",
                                   iosURL,
                                   redirectURL,
                                   self.uriString,
                                   self.addressString,
                                   amountBTC,
                                   amountMBTC,
                                   @"cid:qrcode.jpg",
                                   nil];
    
    for (int i=0; i<[searchList count];i++)
    {
        *strContent = [*strContent stringByReplacingOccurrencesOfString:[searchList objectAtIndex:i]
                                                           withString:[replaceList objectAtIndex:i]];
    }

}

- (void)sendEMail
{

    // if mail is available
    if ([MFMailComposeViewController canSendMail])
    {
        
        NSError* error = nil;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"emailTemplate" ofType:@"html"];
        NSString* content = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
        [self replaceRequestTags:&content];
        
        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
        
        if ([self.strEMail length])
        {
            [mailComposer setToRecipients:[NSArray arrayWithObject:self.strEMail]];
        }

        NSString *subject;
        
        if ([User Singleton].bNameOnPayments && [User Singleton].fullName)
        {
            subject = [NSString stringWithFormat:@"Airbitz Bitcoin Request from %@", [User Singleton].fullName];
        }
        else
        {
            subject = [NSString stringWithFormat:@"Airbitz Bitcoin Request"];
        }
        
        [mailComposer setSubject:NSLocalizedString(subject, nil)];
        
        [mailComposer setMessageBody:content isHTML:YES];

        NSData *imgData;

        UIImage *imageAttachment = [self imageWithImage:self.qrCodeImage scaledToSize:CGSizeMake(QR_ATTACHMENT_WIDTH, QR_ATTACHMENT_WIDTH)];
        imgData = [NSData dataWithData:UIImageJPEGRepresentation(imageAttachment, 1.0)];
        [mailComposer addAttachmentData:imgData mimeType:@"image/jpeg" fileName:@"qrcode.jpg"];

        mailComposer.mailComposeDelegate = self;

        [self presentViewController:mailComposer animated:YES completion:nil];
        [self finalizeRequest:@"Email"];
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
        
        NSError* error = nil;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"SMSTemplate" ofType:@"txt"];
        NSString* content = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
        [self replaceRequestTags:&content];

        // create the attachment
        UIImage *imageAttachment = [self imageWithImage:self.qrCodeImage scaledToSize:CGSizeMake(QR_ATTACHMENT_WIDTH, QR_ATTACHMENT_WIDTH)];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:QR_CODE_TEMP_FILENAME];
        BOOL bAttached = [controller addAttachmentData:UIImagePNGRepresentation(imageAttachment) typeIdentifier:(NSString*)kUTTypePNG filename:filePath];
        if (!bAttached)
        {
            NSLog(@"Could not attach qr code");
        }

		controller.body = content;

        if (self.strPhoneNumber)
        {
            if ([self.strPhoneNumber length] != 0)
            {
                controller.recipients = @[self.strPhoneNumber];
            }
        }

		controller.messageComposeDelegate = self;

        [self presentViewController:controller animated:YES completion:nil];
        [self finalizeRequest:@"SMS"];
	}
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationNone);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)launchRecipientWithMode:(tRecipientMode)mode
{
    if (self.recipientViewController)
    {
        return;
    }
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    self.recipientViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"RecipientViewController"];

    self.recipientViewController.delegate = self;
    self.recipientViewController.mode = mode;

    CGRect frame = self.view.bounds;
    frame.origin.x = frame.size.width;
    self.recipientViewController.view.frame = frame;
    [self.view addSubview:self.recipientViewController.view];

    [UIView animateWithDuration:ENTER_ANIM_TIME_SECS
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         self.recipientViewController.view.frame = self.view.bounds;
     }
                     completion:^(BOOL finished)
     {
     }];
}

- (void)dismissRecipient
{
    [self.recipientViewController.view removeFromSuperview];
    self.recipientViewController = nil;
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
    return (self.recipientViewController != nil);
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

    self.strFullName = [Util getNameFromAddressRecord:person];

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

- (void)finalizeRequest:(NSString *)type
{
    if (_strFullName) {
        _txDetails.szName = (char *)[_strFullName UTF8String];
    } else if (_strEMail) {
        _txDetails.szName = (char *)[_strEMail UTF8String];
    } else if (_strPhoneNumber) {
        _txDetails.szName = (char *)[_strPhoneNumber UTF8String];
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSDate *now = [NSDate date];

    NSMutableString *notes = [[NSMutableString alloc] init];
    [notes appendFormat:NSLocalizedString(@"%@ / %@ requested via %@ on %@.", nil),
                        [CoreBridge formatSatoshi:_txDetails.amountSatoshi],
                        [CoreBridge formatCurrency:_txDetails.amountCurrency withCurrencyNum:_currencyNum],
                        type,
                        [dateFormatter stringFromDate:now]];
    _txDetails.szNotes = (char *)[notes UTF8String];
    tABC_Error Error;
    // Update the Details
    if (ABC_CC_Ok != ABC_ModifyReceiveRequest([[User Singleton].name UTF8String],
                                              [[User Singleton].password UTF8String],
                                              [_walletUUID UTF8String],
                                              [_requestID UTF8String],
                                              &_txDetails,
                                              &Error))
    {
        [Util printABC_Error:&Error];
    }
    // Finalize this request so it isn't used elsewhere
    if (ABC_CC_Ok != ABC_FinalizeReceiveRequest([[User Singleton].name UTF8String],
                                                [[User Singleton].password UTF8String],
                                                [_walletUUID UTF8String],
                                                [_requestID UTF8String],
                                                &Error))
    {
        [Util printABC_Error:&Error];
    }
}

#pragma mark - MFMessageComposeViewController delegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
	switch (result)
    {
		case MessageComposeResultCancelled:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AirBitz"
                                                            message:@"SMS cancelled"
														   delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
			[alert show];
        }
			break;

		case MessageComposeResultFailed:
        {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AirBitz"
                                                            message:@"Error sending SMS"
														   delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
			[alert show];
        }
			break;

		case MessageComposeResultSent:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AirBitz"
                                                            message:@"SMS sent"
														   delegate:nil
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
    NSString *strTitle = NSLocalizedString(@"AirBitz", nil);
    NSString *strMsg = nil;

	switch (result)
    {
		case MFMailComposeResultCancelled:
            strMsg = NSLocalizedString(@"Email cancelled", nil);
			break;

		case MFMailComposeResultSaved:
            strMsg = NSLocalizedString(@"Email saved to send later", nil);
			break;

		case MFMailComposeResultSent:
            strMsg = NSLocalizedString(@"Email sent", nil);
			break;

		case MFMailComposeResultFailed:
		{
            strTitle = NSLocalizedString(@"Error sending Email", nil);
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

#pragma mark - UIAlertView delegates

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

#pragma mark - RecipientViewControllerDelegates

- (void)RecipientViewControllerDone:(RecipientViewController *)controller withFullName:(NSString *)strFullName andTarget:(NSString *)strTarget
{
    // if they selected a target
    if ([strTarget length])
    {
        self.strFullName = strFullName;
        self.strEMail = strTarget;
        self.strPhoneNumber = strTarget;

        //NSLog(@"name: %@, target: %@", strFullName, strTarget);

        if (controller.mode == RecipientMode_SMS)
        {
            [self performSelector:@selector(sendSMS) withObject:nil afterDelay:0.0];
        }
        else if (controller.mode == RecipientMode_Email)
        {
            [self performSelector:@selector(sendEMail) withObject:nil afterDelay:0.0];
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AirBitz"
                                                        message:(controller.mode == RecipientMode_SMS ? @"SMS cancelled" : @"Email cancelled")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }

    [self dismissRecipient];
}

#pragma mark - GestureReconizer methods

- (void)didSwipeLeftToRight:(UIGestureRecognizer *)gestureRecognizer
{
    if (![self haveSubViewsShowing])
    {
        [self Back];
    }
}

#pragma mark - Custom Notification Handlers

// called when a tab bar button that is already selected, is reselected again
- (void)tabBarButtonReselect:(NSNotification *)notification
{
    if (![self haveSubViewsShowing])
    {
        [self Back];
    }
}

@end

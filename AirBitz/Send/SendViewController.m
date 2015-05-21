//
//  SendViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//
/* BLE flow:
 Request Bitcoin: Peripheral
 Build table of services and characteristics.
 Start advertising
 Once connected:
 receive first and last name from Central
 show “connected” popup
 when read request comes in:
 Write entire bit coin address and amount to characteristic
 
 
 Send Bitcoin (this file): Central
 Once connected:
 write first and last name to characteristic
 wait for -peripheral:didWriteValueForCharacteristic callback
 Request a read of the characteristic
 wait to receive bit coin address and amount from peripheral
 When it comes in, disconnect and transition to send confirmation screen
 */

#import "SendViewController.h"
#import "SpendTarget.h"

#import <AVFoundation/AVFoundation.h>
#import <Social/Social.h>
#import "SendViewController.h"
#import "Notifications.h"
#import "ABC.h"
#import "SendConfirmationViewController.h"
#import "FlashSelectView.h"
#import "User.h"
#import "ButtonSelectorView.h"
#import "CommonTypes.h"
#import "Util.h"
#import "InfoView.h"
#import "ZBarSDK.h"
#import "CoreBridge.h"
#import "SyncView.h"
#import "TransferService.h"
#import "BLEScanCell.h"
#import "Contact.h"
#import "LocalSettings.h"
#import "FadingAlertView.h"
#import "ButtonSelectorView2.h"
#import "FadingAlertView2.h"
#import "MainViewController.h"
#import "Theme.h"
#import "SpendTarget.h"
#import "DL_URLServer.h"
#import "Server.h"

#define BLE_TIMEOUT                 1.0

#define POPUP_PICKER_LOWEST_POINT   360
#define POPUP_PICKER_TABLE_HEIGHT   (!IS_IPHONE4 ? 180 : 90)

typedef enum eScanMode
{
	SCAN_MODE_UNINITIALIZED,
    SCAN_MODE_BLE_QR,
//	SCAN_MODE_BLE,
//	SCAN_MODE_QR,
	SCAN_MODE_QR_ENABLE_ONCE_IN_FOREGROUND
}tScanMode;

typedef enum eImportState
{
    ImportState_PrivateKey,
    ImportState_EnterPassword,
    ImportState_RetryPassword,
    ImportState_Importing
} tImportState;


static NSTimeInterval lastCentralBLEPowerOffNotificationTime = 0;

@interface SendViewController () <SendConfirmationViewControllerDelegate, UIAlertViewDelegate, PickerTextViewDelegate,FlashSelectViewDelegate, UITextFieldDelegate, PopupPickerViewDelegate,ButtonSelector2Delegate, SyncViewDelegate, CBCentralManagerDelegate, CBPeripheralDelegate
 ,ZBarReaderDelegate, ZBarReaderViewDelegate
>
{
	ZBarReaderView                  *_readerView;
    ZBarReaderController            *_readerPicker;
//	NSTimer                         *_startScannerTimer;
//	int                             _selectedWalletIndex;
	SendConfirmationViewController  *_sendConfirmationViewController;
    BOOL                            _bUsingImagePicker;
	SyncView                        *_syncingView;
	NSTimeInterval					lastUpdateTime;	//used to remove BLE devices from table when they're no longer around
	NSTimer							*peripheralCleanupTimer; //used to remove BLE devices from table when they're no longer around
	tScanMode						scanMode;
	float							originalFrameHeight;
    FadingAlertView2                 *_fadingAlert;
    BOOL                            bWalletListDropped;
    BOOL                            bFlashOn;
    UIAlertView                     *typeAddressAlertView;
    ImportDataModel                 _dataModel;
    NSString                        *_sweptAddress;
    tImportState                    _state;
    NSString                        *_sweptTXID;
    uint64_t                        _sweptAmount;
    UIAlertView                     *_sweptAlert;
    UIAlertView                     *_tweetAlert;
    UIAlertView                     *_receivedAlert;
    NSTimer                         *_callbackTimer;
    NSString                        *_tweet;


}
@property (nonatomic, strong)   NSString                        *privateKey;
@property (weak, nonatomic)     IBOutlet UIImageView            *scanFrame;
//@property (weak, nonatomic)   IBOutlet FlashSelectView        *flashSelector;
@property (nonatomic, strong)   IBOutlet ButtonSelectorView2    *buttonSelector;
//@property (weak, nonatomic)   IBOutlet UIImageView            *imageTopFrame;
//@property (weak, nonatomic)   IBOutlet UILabel                *labelSendTo;
//@property (weak, nonatomic)   IBOutlet UIImageView            *imageSendTo;
//@property (weak, nonatomic)   IBOutlet UIImageView            *imageFlashFrame;
//@property (weak, nonatomic)   IBOutlet UIView					*bleView;
//@property (weak, nonatomic)   IBOutlet UIView					*qrView;
@property (nonatomic, strong)	IBOutlet UITableView			*tableView;
//@property (nonatomic, weak)   IBOutlet UIButton				*ble_button;

//@property (nonatomic, strong) NSArray   *arrayWallets;
//@property (nonatomic, strong) NSArray   *arrayWalletNames;
@property (nonatomic, strong) NSArray   *arrayChoicesIndexes;
@property (nonatomic, strong) PopupPickerView               *popupPickerSendTo;
//@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *scanningSpinner;
//@property (nonatomic, weak) IBOutlet UILabel				*scanningLabel;
@property (nonatomic, strong) IBOutlet UILabel				*scanningErrorLabel;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bleViewHeight;
@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;
@property (strong, nonatomic) NSMutableData         *data;
@property (strong, nonatomic)  NSMutableArray		*peripheralContainers;
@property (nonatomic, strong) NSArray                   *arrayContacts;
@property (nonatomic, copy)	NSString				*advertisedPartialBitcoinAddress;
@end

@implementation PeripheralContainer
@end

@implementation SendViewController
@synthesize segmentedControl;


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

    _bUsingImagePicker = NO;
    bWalletListDropped = false;

//    self.flashSelector.delegate = self;
	self.buttonSelector.delegate = self;
    [self.buttonSelector disableButton];

    self.addressTextField.delegate = self;
	self.arrayContacts = @[];
	// load all the names from the address book
    [self generateListOfContactNames];


    [self updateDisplay];

    _dataModel = kWIF;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)scanBLEstartCamera
{
    scanMode = SCAN_MODE_UNINITIALIZED;
    [self startQRReader];

    if([LocalSettings controller].bDisableBLE == NO && !self.bImportMode)
    {
        // Start up the CBCentralManager.  Warn if settings BLE is on but device BLE is off (but only once every 24 hours)
        NSTimeInterval curTime = CACurrentMediaTime();
        if((curTime - lastCentralBLEPowerOffNotificationTime) > 86400.0) //24 hours
        {
            _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey: @(YES)}];
        }
        else
        {
            _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey: @(NO)}];
        }
        lastCentralBLEPowerOffNotificationTime = curTime;
        [self startBLE];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self scanBLEstartCamera];

    // Disable [Transfer] button if we're in Import Private Key mode
    if (_bImportMode)
        [segmentedControl setEnabled:NO forSegmentAtIndex:0];
    _dataModel = kWIF;

	//reset our frame's height in case it got changed by the image picker view controller
//	CGRect frame = self.view.frame;
//	frame.size.height = originalFrameHeight;
//	self.view.frame = frame;

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(willResignActive)
               name:UIApplicationWillResignActiveNotification
             object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(applicationDidBecomeActiveNotification:)
               name:UIApplicationDidBecomeActiveNotification
             object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews:) name:NOTIFICATION_WALLETS_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sweepDoneCallback:) name:NOTIFICATION_SWEEP object:nil];


    //
    // This might be a loopback from pleaseRestartSendViewBecauseAppleSucksWithPresentController
    // Check params and go
    //

    if (self.loopbackState == LoopbackState_Go && self.zBarSymbolSet != nil)
    {
        [self processZBarResults:self.zBarSymbolSet];
    }
    else if (self.loopbackState == LoopbackState_Scan_Failed)
    {

        UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:NSLocalizedString(@"QR Code Scan Failure", nil)
                      message:NSLocalizedString(@"Unable to scan QR code", nil)
                     delegate:nil
            cancelButtonTitle:@"OK"
            otherButtonTitles:nil];
        [alert show];
    }
    else if (self.loopbackState == LoopbackState_Invalid_Address)
    {
        UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:[Theme Singleton].invalidAddressPopupText
                      message:NSLocalizedString(@"", nil)
                     delegate:self
            cancelButtonTitle:@"OK"
            otherButtonTitles:nil];
        [alert show];

    }
    self.zBarSymbolSet = nil;
    self.loopbackState = LoopbackState_None;

    [self setupNavBar];
    [self updateViews:nil];

}

- (void)setupNavBar
{
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].backButtonText side:NAV_BAR_LEFT button:true enable:false action:@selector(info:) fromObject:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(info:) fromObject:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self willResignActive];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didTapTitle: (UIButton *)sender
{
    if (bWalletListDropped)
    {
        [self.buttonSelector close];
        bWalletListDropped = false;
    }
    else
    {
        [self.buttonSelector open];
        bWalletListDropped = true;
    }

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification
{
//    [self.flashSelector selectItem:FLASH_ITEM_OFF];
    if (SCAN_MODE_UNINITIALIZED == scanMode) {
        [self scanBLEstartCamera];
    }
}

- (void)willResignActive
{
//	[_startScannerTimer invalidate];
//	_startScannerTimer = nil;
#if !TARGET_IPHONE_SIMULATOR
	[self stopQRReader];

	// Don't keep it going while we're not showing.
	if([LocalSettings controller].bDisableBLE == NO)
	{
		[self stopBLE];
		_centralManager = nil;
	}
#endif
	scanMode = SCAN_MODE_UNINITIALIZED;
}

- (void)resetViews
{
    if (_sendConfirmationViewController)
    {
        [_sendConfirmationViewController.view removeFromSuperview];
        _sendConfirmationViewController = nil;
    }
}

-(void)cleanupPeripherals:(NSTimer *)timer
{
	//gets called periodically by a timer to check when we last heard from each peripheral.  If it's been too long, we remove it from the list.
	NSTimeInterval currentTime = CACurrentMediaTime();
	NSInteger numPeripherals = [self.peripheralContainers count];
	
	if(numPeripherals)
	{
		for (NSInteger i = numPeripherals - 1; i>= 0; i--)
		{
			PeripheralContainer *pc = [self.peripheralContainers objectAtIndex:i];
			//NSLog(@"Last: %f Current: %f", [pc.lastAdvertisingTime floatValue], currentTime);
			if(currentTime - [pc.lastAdvertisingTime doubleValue] > 1.0)
			{
				//haven't heard from this peripheral in a while.  Kill it.
				//NSLog(@"Removing peripheral");
				[self.peripheralContainers removeObjectAtIndex:i];
				[self updateTable];
			}
		}
	}
}

-(void)enableAll
{
    [self startBLE];
    if ([[User Singleton] offerSendHelp]) {
        [self showFadingAlert:NSLocalizedString(@"Scan the QR code of payee to send payment or tap on a bluetooth request from the list below", nil)
                    withDelay:FADING_HELP_DURATION];
    }

}

//-(void)enableBLEMode
//{
//	if(scanMode != SCAN_MODE_BLE)
//	{
//		scanMode = SCAN_MODE_BLE;
//		self.bleView.hidden = NO;
//		self.qrView.hidden = YES;
//		[self startBLE];
//	}
//}
//
//-(void)enableQRMode
//{
//	if(scanMode != SCAN_MODE_QR)
//	{
//		scanMode = SCAN_MODE_QR;
//		self.bleView.hidden = YES;
//		self.qrView.hidden = NO;
//		//turns on QR code scanner.  Disables BLE
//		[self stopBLE];
//
//        if ([[User Singleton] offerSendHelp]) {
//            [self showFadingAlert:NSLocalizedString(@"Scan the QR code of payee to send payment", nil)
//                        withDelay:FADING_HELP_DURATION];
//        }
//
//#if !TARGET_IPHONE_SIMULATOR
//		if([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
//		{
//			//NSLog(@" ^^^^^^^^^^^^^^^^ SPECIAL SCAN MODE.  WAIT UNTIL IN FOREGROUND ^^^^^^^^^^^^^^^^");
//			scanMode = SCAN_MODE_QR_ENABLE_ONCE_IN_FOREGROUND;
//		}
//		else
//		{
//			//NSLog(@" ^^^^^^^^^^^^^^^^ NORMAL SCAN MODE.  START QR NOW ^^^^^^^^^^^^^^^^");
//		}
//#endif
//
//
//	}
//}

#if TARGET_IPHONE_SIMULATOR

-(void)startQRReader
{
}

- (void)stopQRReader
{
}

#else

-(void)startQRReader
{
    // on iOS 8, we must request permission to access the camera
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                // Permission has been granted. Use dispatch_async for any UI updating
                // code because this block may be executed in a thread.
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self attemptToStartQRReader];
                });
            } else {
                [self attemptToStartQRReader];
            }
        }];
    } else {
        [self attemptToStartQRReader];
    }
}

-(void)attemptToStartQRReader
{
    if (_readerView) {
        [_readerView start];
        return;
    }
    // check camera state before proceeding
	_readerView = [ZBarReaderView new];
    if ([_readerView isDeviceAvailable])
    {
        [self.scanningErrorLabel setHidden:YES];
//        [self.flashSelector setHidden:NO];
    }
    else
    {
        self.scanningErrorLabel.text = NSLocalizedString(@"Camera unavailable. Please enable camera access on your phone's Privacy Settings", @"");
        [self.scanningErrorLabel setHidden:NO];
//        [self.flashSelector setHidden:YES];
    }

	[self.view insertSubview:_readerView belowSubview:self.scanFrame];
	_readerView.frame = self.scanFrame.frame;
//    [Util addSubviewWithConstraints:self.scanFrame child:_readerView];
	_readerView.readerDelegate = self;
	_readerView.tracksSymbols = NO;
	
	_readerView.tag = READER_VIEW_TAG;
//	if ([self.pickerTextSendTo.textField.text length])
//	{
//		_readerView.alpha = 0.0;
//	}
	[_readerView start];
	[self flashItemSelected:FLASH_ITEM_OFF];
}

- (void)stopQRReader
{
    if (_readerView)
    {
        [_readerView stop];
//        [_readerView removeFromSuperview];
//        _readerView = nil;
    }
}

#endif

#pragma mark - Action Methods

- (IBAction)info:(id)sender
{
	[self.view endEditing:YES];
    [self resignAllResponders];
    [InfoView CreateWithHTML:@"infoSend" forView:self.view];
}

- (IBAction)buttonCameraTouched:(id)sender
{
    [self resignAllResponders];
    [self showImagePicker];
}
#pragma mark UISegmentedControl


- (IBAction)segmentedControlAction:(id)sender
{
    NSMutableArray *arrayChoices = [[NSMutableArray alloc] init];
    UITextField *textField;
    NSString *title;
    NSString *placeholderText;


    switch (segmentedControl.selectedSegmentIndex)
    {
        case 0:
            arrayChoices = [self createNewSendToChoices:@""];


            self.popupPickerSendTo = [PopupPickerView CreateForView:self.view
                                                     relativeToView:self.segmentedControl
                                                   relativePosition:PopupPickerPosition_Above
                                                        withStrings:arrayChoices
                                                     fromCategories:nil
                                                        selectedRow:-1
                                                          withWidth:-1
                                                      withAccessory:nil
                                                      andCellHeight:[Theme Singleton].heightPopupPicker
                                              roundedEdgesAndShadow:NO];
            self.popupPickerSendTo.delegate = self;
            // Do Transfer
            break;
        case 1:
            if (_bImportMode)
            {
                title = [Theme Singleton].enterPrivateKeyPopupText;
                placeholderText = [Theme Singleton].enterPrivateKeyPlaceholder;
            }
            else
            {
                title = [Theme Singleton].enterBitcoinAddressPopupText;
                placeholderText = [Theme Singleton].enterBitcoinAddressPlaceholder;
            }
            typeAddressAlertView =[[UIAlertView alloc ] initWithTitle:title
                                                              message:nil
                                                             delegate:self
                                                    cancelButtonTitle:[Theme Singleton].cancelButtonText
                                                    otherButtonTitles:[Theme Singleton].doneButtonText, nil];
            typeAddressAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            textField = [typeAddressAlertView textFieldAtIndex:0];
            textField.placeholder = placeholderText;
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.spellCheckingType = UITextSpellCheckingTypeNo;
            textField.returnKeyType = UIReturnKeyDone;

            [typeAddressAlertView show];
            break;

        case 2:
            // Do Photo
            [self resignAllResponders];
            [self showImagePicker];

            break;
        case 3:
            // Do Flash
            [self toggleFlash];
            break;
    }
}

#pragma mark - UIAlertView delegates

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView == typeAddressAlertView)
    {
        _addressTextField.text = [alertView textFieldAtIndex:0].text;
        [self processURI];
    }
    else if (_tweetAlert == alertView)
    {
        _tweetAlert = nil;
        if (1 == buttonIndex)
        {
            [self performSelector:@selector(sendTweet)
                       withObject:nil
                       afterDelay:0.0];
        }
        else
        {
            [self tweetCancelled];
            [self updateState];
        }
    }
    else if (_sweptAlert == alertView)
    {
        _sweptAlert = nil;
        [self updateState];
    }
    else if (_receivedAlert == alertView)
    {
        if (1 == buttonIndex)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_VIEW_SWEEP_TX
                                                                object:nil
                                                              userInfo:@{KEY_TX_DETAILS_EXITED_WALLET_UUID: [CoreBridge Singleton].currentWallet.strUUID,
                                                                      KEY_TX_DETAILS_EXITED_TX_ID:_sweptTXID}];
        }

        _receivedAlert = nil;
        [self updateState];
    }
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
   // NSLog(@"contacts: %@", self.arrayContacts);
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

#pragma mark - BLE Central Methods

-(void)startBLE
{
    if (!self.bImportMode)
    {
        //NSLog(@"################## STARTED BLE ######################");
        [self scan];
        //kick off peripheral cleanup timer (removes peripherals from table when they're no longer in range)
        peripheralCleanupTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(cleanupPeripherals:) userInfo:nil repeats:YES];
    }
}

-(void)stopBLE
{
    if (!self.bImportMode)
    {
        //NSLog(@"################## STOPPED BLE ######################");
        [self.centralManager stopScan];
        //NSLog(@"Getting rid of timer");
        [peripheralCleanupTimer invalidate];
    }
}

/** centralManagerDidUpdateState is a required protocol method.
 *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
 *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
 *  the Central is ready to be used.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
//	NSLog(@"DID UPDATE STATE");

    if (central.state != CBCentralManagerStatePoweredOn)
	{
//		self.ble_button.hidden = YES;
//		[self enableQRMode];
    }
	else
	{
		NSLog(@"POWERED ON");
        [self startBLE];
//		[self enableBLEMode];
//		self.ble_button.hidden = NO;
    }
}


/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
- (void)scan
{
	//NSLog(@"################## BLE SCAN STARTED ######################");
    _data = [[NSMutableData alloc] init];
	self.peripheralContainers = nil;
	[self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
    
    //NSLog(@"Scanning started");
}

/*
 *  @method UUIDSAreEqual:
 *
 *  @param u1 CFUUIDRef 1 to compare
 *  @param u2 CFUUIDRef 2 to compare
 *
 *  @returns 1 (equal) 0 (not equal)
 *
 *  @discussion compares two CFUUIDRef's
 *
 */

- (int) UUIDSAreEqual:(CFUUIDRef)u1 u2:(CFUUIDRef)u2
{
    CFUUIDBytes b1 = CFUUIDGetUUIDBytes(u1);
    CFUUIDBytes b2 = CFUUIDGetUUIDBytes(u2);
    if (memcmp(&b1, &b2, 16) == 0)
	{
        return 1;
    }
    else return 0;
}

/** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    //only interested in peripherals advertising TRANSFER_SERVICE_UUID
	NSArray *array = [advertisementData objectForKey:CBAdvertisementDataServiceUUIDsKey];
	CBUUID *uuid = [array objectAtIndex:0];
	//if([[uuid UUIDString] isEqualToString:TRANSFER_SERVICE_UUID])
	if ([uuid isEqual:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]])
	{
		PeripheralContainer *pc = [[PeripheralContainer alloc] init];
		pc.peripheral = peripheral;
		pc.advertisingData = advertisementData;
		pc.rssi = [RSSI copy];
		pc.lastAdvertisingTime = [NSNumber numberWithDouble:CACurrentMediaTime()];
		
		if (!self.peripheralContainers)
		{
			self.peripheralContainers = [[NSMutableArray alloc] initWithObjects:pc, nil];
		}
		else
		{
			BOOL replacedExistingObject = NO;
			
			for(int i = 0; i < self.peripheralContainers.count; i++)
			{
				PeripheralContainer *container = [self.peripheralContainers objectAtIndex:i];
				if ([self UUIDSAreEqual:container.peripheral.UUID u2:peripheral.UUID])
				{
					[self.peripheralContainers replaceObjectAtIndex:i withObject:pc];
					// printf("Duplicate UUID found updating ...\r\n");
					replacedExistingObject = YES;
					break;
				}
			}
			if(!replacedExistingObject)
			{
				[self.peripheralContainers addObject:pc];
			}
			// printf("New UUID, adding\r\n");
		}
		
		NSTimeInterval newUpdateTime = CACurrentMediaTime();
		if((newUpdateTime - lastUpdateTime) > 0.5)
		{
            dispatch_async(dispatch_get_main_queue(),^{
                [UIView animateWithDuration:0.35
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseInOut
                                 animations:^
                                 {
                                     // Update the table height

                                     CGFloat height, maxheight;

                                     height = ([Theme Singleton].heightBLETableCells * [self.peripheralContainers count]);

                                     maxheight = [MainViewController getHeight] -
                                             [MainViewController getFooterHeight] - [MainViewController getHeaderHeight] - [Theme Singleton].heightMinimumForQRScanFrame;

                                     _bleViewHeight.constant = height > maxheight ? maxheight : height;
                                     [self.view layoutIfNeeded];
                                 }
                                 completion:^(BOOL finished)
                                 {
                                 }];

            });

            lastUpdateTime = newUpdateTime;
			[self updateTable];
		}
    }
//    NSLog(@"Discovered %@ at %@ with adv data: %@", peripheral.name, RSSI, advertisementData);
}


/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}


/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
//    NSLog(@"Peripheral Connected");
    
    // Stop scanning
    [self.centralManager stopScan];
//    NSLog(@"Scanning stopped");
    
    // Clear the data that we may already have
    [self.data setLength:0];
	
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}


/** The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
	{
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Discover the characteristic we want...
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services)
	{
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
    }
}


/*
 *  On Airbitz service discovery, send our name
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics)
	{
        
		if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
		{
			
            // Write username to this characteristic
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
			
			
			NSString *fullName = @" ";
			if(sendName)
			{
				if([User Singleton].fullName)
				{
					if([User Singleton].fullName.length)
					{
						fullName = [User Singleton].fullName;
					}
				}
			}
            else
            {
                // Send device name
                fullName = [[UIDevice currentDevice] name];

            }
			
			[peripheral writeValue:[fullName dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
			
//			NSLog(@"Writing: %@ to peripheral", fullName);
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in.
}

/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
	{
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
	
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    if ([stringFromData rangeOfString:self.advertisedPartialBitcoinAddress].location == NSNotFound)
    {
        //start at index 9 to skip over "bitcoin:".  Partial address is 10 characters long
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Bitcoin address mismatch", nil)
                              message:[NSString stringWithFormat:@"The bitcoin address of the device you connected with:%@ does not match the address that was initially advertised:%@", [stringFromData substringWithRange:NSMakeRange(8, 10) ], self.advertisedPartialBitcoinAddress]
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        self.addressTextField.text = stringFromData;
        [self processURI];
    }

    // subscription a.k.a. notify mode isn't necessary unless your data is larger than >512 bytes
#ifdef LARGE_BLE_DATA
    // determine if this was the last chunk of data
    if ([stringFromData isEqualToString:@"EOM"])
    {
        NSString *receivedData = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
        // make sure partial bitcoin address that was advertized is contained within the actual full bitcoin address
        if ([receivedData rangeOfString:self.advertisedPartialBitcoinAddress].location == NSNotFound)
        {
            // start at index 9 to skip over "bitcoin:".  Partial address is 10 characters long
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Bitcoin address mismatch", nil)
                                  message:[NSString stringWithFormat:@"The bitcoin address of the device you connected with:%@ does not match the address that was initially advertised:%@", [stringFromData substringWithRange:NSMakeRange(8, 10) ], self.advertisedPartialBitcoinAddress]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            self.pickerTextSendTo.textField.text = receivedData;
            [self processURI];
        }

        // and disconnect from the peripehral
        [self.centralManager cancelPeripheralConnection:peripheral];
        [self cleanup];
    }
    else
    {
        [_data appendData:characteristic.value];
    }
#endif
}


/** The peripheral letting us know whether our subscribe/unsubscribe happened or not
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
	{
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
	{
        return;
    }
    
    if (!characteristic.isNotifying)
	{
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}


-(void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices
{
	NSLog(@"Did Modify Services: %@", invalidatedServices);
}


/** Once the disconnection happens, we need to clean up our local copy of the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    //NSLog(@"Did disconnect because: %@", error.description);
	self.peripheralContainers = nil;
    self.discoveredPeripheral = nil;
    
    // We're disconnected, so start scanning again
    [self scan];
	
	//allow tableView selection after some time has gone by because we typically disconnect before the sendConfirmation view has fully slid onscreen
	[self performSelector:@selector(enableTableSelection) withObject:nil afterDelay:1.0];
}

-(void)enableTableSelection
{
	self.tableView.allowsSelection = YES;
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error writing value for characteristic: %@", error.localizedDescription);
        return;
    }

#ifdef LARGE_BLE_DATA
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
#endif
    [peripheral readValueForCharacteristic:characteristic];
}


/** Call this when things either go wrong, or you're done with the connection.
 *  This cancels any subscriptions if there are any, or straight disconnects if not.
 *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
 */
- (void)cleanup
{
    // Don't do anything if we're not connected
    if (self.discoveredPeripheral.state != CBPeripheralStateConnected)
	{
		self.discoveredPeripheral = nil;
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.discoveredPeripheral.services != nil)
	{
        for (CBService *service in self.discoveredPeripheral.services)
		{
            if (service.characteristics != nil)
			{
                for (CBCharacteristic *characteristic in service.characteristics)
				{
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
					{
                        if (characteristic.isNotifying)
						{
                            // It is notifying, so unsubscribe
                            [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            
                            // And we're done.
                            return;
                        }
                    }
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}

/*!
 *  @method printKnownPeripherals:
 *
 *  @discussion printKnownPeripherals prints all curenntly known peripherals stored in the peripherals array of ForeheadSensor class
 *
 */
- (void) printKnownPeripherals
{
    int i;
    printf("List of currently known peripherals : \r\n");
    for (i=0; i < self.peripheralContainers.count; i++)
    {
        PeripheralContainer *p = [self.peripheralContainers objectAtIndex:i];
		
        CFStringRef s = CFUUIDCreateString(NULL, p.peripheral.UUID);
        printf("%d  |  %s\r\n",i,CFStringGetCStringPtr(s, 0));
        CFRelease(s);
        [self printPeripheralInfo:p];
    }
}

/*
 *  @method printPeripheralInfo:
 *
 *  @param peripheral Peripheral to print info of
 *
 *  @discussion printPeripheralInfo prints detailed info about peripheral
 *
 */
- (void) printPeripheralInfo:(PeripheralContainer*)peripheralContainer
{
    CFStringRef s = CFUUIDCreateString(NULL, peripheralContainer.peripheral.UUID);
    printf("------------------------------------\r\n");
    printf("Peripheral Info :\r\n");
    printf("UUID : %s\r\n",CFStringGetCStringPtr(s, 0));
    CFRelease(s);
    printf("RSSI : %d\r\n",[peripheralContainer.peripheral.RSSI intValue]);
    NSLog(@"Name : %@\r\n",peripheralContainer.peripheral.name);
	BOOL connected = NO;
	if(peripheralContainer.peripheral.state == CBPeripheralStateConnected)
	{
		connected = YES;
	}
    printf("isConnected : %d\r\n", connected);
	//UInt32 serialNum
	//printf("serial number:
    printf("-------------------------------------\r\n");
    
}

#pragma mark TableView

-(void)updateTable
{
//	if(self.peripheralContainers.count == 0)
//	{
//		self.scanningLabel.hidden = NO;
//		[self.scanningSpinner startAnimating];
//	}
//	else
//	{
//        if ([[User Singleton] offerBleHelp]) {
//            [self showFadingAlert:NSLocalizedString(@"Bluetooth payment requests are listed here. Tap on a user to send them a payment", nil)
//                        withDelay:FADING_HELP_DURATION];
//        }
//		self.scanningLabel.hidden = YES;
//		[self.scanningSpinner stopAnimating];
//	}
	[self.tableView reloadData];
}

-(BLEScanCell *)getScanCellForTableView:(UITableView *)tableView
{
	BLEScanCell *cell;
	static NSString *cellIdentifier = @"ScanCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[BLEScanCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.peripheralContainers count];
}

-(BOOL)nameIsDuplicate:(NSString *)name
{
	//looks at all peripheral containers and sees if there are two that have the name contained in this one.
	BOOL hasDuplicate = NO;
	int nameCount = 0;
	
	for(PeripheralContainer *pci in self.peripheralContainers)
	{
		NSString *advData = [pci.advertisingData objectForKey:CBAdvertisementDataLocalNameKey];
		if(advData.length > 10)
		{
			NSString *fullName = [advData substringFromIndex:10];
			NSArray *arrayComponents = [fullName componentsSeparatedByString:@" "];
			NSString *firstName = @"";
			if([arrayComponents count])
			{
				firstName = [arrayComponents objectAtIndex:0];
			}
			NSString *lastName = @"";
			if([arrayComponents count] > 1)
			{
				lastName = [arrayComponents objectAtIndex:1];
			}
			NSString *otherName;
			
			if(lastName.length)
			{
				otherName = [NSString stringWithFormat:@"%@ %@", firstName, lastName ];
			}
			else
			{
				otherName = firstName;
			}
			
			if([otherName isEqualToString:name])
			{
				nameCount++;
			}
		}
	}
	if(nameCount > 1)
	{
		hasDuplicate = YES;
	}
	return hasDuplicate;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	BLEScanCell *scanCell = [self getScanCellForTableView:tableView];
	PeripheralContainer *pc = [self.peripheralContainers objectAtIndex:indexPath.row];
	
	int rssi = [pc.rssi intValue];
	
	if(rssi >= -41)
	{
		scanCell.signalImage.image = [UIImage imageNamed:@"5-bars.png"];
	}
	else if(rssi >= -53)
	{
		scanCell.signalImage.image = [UIImage imageNamed:@"4-bars.png"];
	}
	else if(rssi >= -65)
	{
		scanCell.signalImage.image = [UIImage imageNamed:@"3-bars.png"];
	}
	else if(rssi >= -77)
	{
		scanCell.signalImage.image = [UIImage imageNamed:@"2-bars.png"];
	}
	else if(rssi >= -89)
	{
		scanCell.signalImage.image = [UIImage imageNamed:@"1-bar.png"];
	}
	else
	{
		scanCell.signalImage.image = [UIImage imageNamed:@"0-bars.png"];
	}
	
	//see if there is a match between advertised name and name in contacts.  If so, use the photo from contacts
	BOOL imageIsFromContacts = NO;
	NSString *advData = [pc.advertisingData objectForKey:CBAdvertisementDataLocalNameKey];
	if(advData.length >= 10)
	{
		scanCell.contactBitcoinAddress.text = [advData substringToIndex:10];
		if(advData.length > 10)
		{
			scanCell.contactName.text = [advData substringFromIndex:10];
			NSArray *arrayComponents = [scanCell.contactName.text componentsSeparatedByString:@" "];
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
						scanCell.contactImage.image = contact.imagePhoto;
						imageIsFromContacts = YES;
						break;
					}
				}
				if([self nameIsDuplicate:name])
				{
					scanCell.duplicateNamesLabel.hidden = NO;
					scanCell.contactName.textColor = scanCell.duplicateNamesLabel.textColor;
					scanCell.contactBitcoinAddress.textColor = scanCell.duplicateNamesLabel.textColor;
				}
				else
				{
					scanCell.duplicateNamesLabel.hidden = YES;
					scanCell.contactName.textColor = [UIColor whiteColor];
					scanCell.contactBitcoinAddress.textColor = [UIColor whiteColor];
				}
			}
		}
	}
	if(imageIsFromContacts == NO)
	{
		scanCell.contactImage.image = [UIImage imageNamed:@"BLE_photo.png"];
	}
    [scanCell layoutSubviews];
    return scanCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [Theme Singleton].heightBLETableCells;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

	//NSLog(@"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^Selecting row: %li", (long)indexPath.row);
	
	tableView.allowsSelection = NO;
	//attempt to connect to this peripheral
	PeripheralContainer *pc = [self.peripheralContainers objectAtIndex:indexPath.row];
	
	NSString *advData = [pc.advertisingData objectForKey:CBAdvertisementDataLocalNameKey];
	if(advData.length >= 10)
	{
		self.advertisedPartialBitcoinAddress = [advData substringToIndex:10];
	}
	// Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
	self.discoveredPeripheral = pc.peripheral;
	
	// And connect
	//NSLog(@"Connecting to peripheral %@", pc.peripheral);
	[self.centralManager connectPeripheral:pc.peripheral options:nil];
}

#pragma mark - Misc Methods

- (void)resignAllResponders
{
    [self.addressTextField resignFirstResponder];
}

- (void)updateViews:(NSNotification *)notification
{
    if ([CoreBridge Singleton].arrayWallets && [CoreBridge Singleton].currentWallet)
    {
        self.buttonSelector.arrayItemsToSelect = [CoreBridge Singleton].arrayWalletNames;
        [self.buttonSelector.button setTitle:[CoreBridge Singleton].currentWallet.strName forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = [CoreBridge Singleton].currentWalletID;

        NSString *walletName;
        if (self.bImportMode)
            walletName = [NSString stringWithFormat:@"Import To: %@ ↓", [CoreBridge Singleton].currentWallet.strName];
        else
            walletName = [NSString stringWithFormat:@"From: %@ ↓", [CoreBridge Singleton].currentWallet.strName];

        [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle:) fromObject:self];
        if (!([[CoreBridge Singleton].arrayWallets containsObject:[CoreBridge Singleton].currentWallet]))
        {
            if (_fadingAlert)
            {
                [_fadingAlert dismiss:NO];
                _fadingAlert = nil;
            }
            _fadingAlert = [FadingAlertView2 CreateInsideView:self.view withDelegate:self];
            _fadingAlert.fadeDelay = 9999;
            _fadingAlert.fadeDuration = FADING_HELP_DURATION;
            [_fadingAlert messageTextSet:[Theme Singleton].walletHasBeenArchivedText];
            [_fadingAlert blockModal:YES];
            [_fadingAlert showFading];

        }
        else
        {
            if (_fadingAlert)
            {
                [_fadingAlert dismiss:NO];
                _fadingAlert = nil;
            }
        }


        [self.tableView reloadData];

    }
}

// if bToIsUUID NO, then it is assumed the strTo is an address
- (void)showSendConfirmationTo:(SpendTarget *)spendTarget
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_sendConfirmationViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendConfirmationViewController"];

	_sendConfirmationViewController.delegate = self;
    _sendConfirmationViewController.spendTarget = spendTarget;
//    _sendConfirmationViewController.wallet = [CoreBridge Singleton].currentWallet;

    //NSLog(@"Sending to: %@, isUUID: %@, wallet: %@", _sendConfirmationViewController.sendToAddress, (_sendConfirmationViewController.bAddressIsWalletUUID ? @"YES" : @"NO"), _sendConfirmationViewController.wallet.strName);
	
//	CGRect frame = self.view.bounds;
//	frame.origin.x = frame.size.width;
//	_sendConfirmationViewController.view.frame = frame;
//	[self.view addSubview:_sendConfirmationViewController.view];

    [_readerView stop];

    [Util addSubviewWithConstraints:self.view child:_sendConfirmationViewController.view];
	
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 _sendConfirmationViewController.view.frame = self.view.bounds;
	 }
	 completion:^(BOOL finished)
	 {
         [[UIApplication sharedApplication] endIgnoringInteractionEvents];
	 }];
}


- (void)importWallet
{
    bool bSuccess = NO;

    if (self.privateKey)
    {
        self.privateKey = [self.privateKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([self.privateKey length])
        {
            NSRange schemeMarkerRange = [self.privateKey rangeOfString:@"://"];
            if (NSNotFound != schemeMarkerRange.location)
            {
                NSString *scheme = [self.privateKey substringWithRange:NSMakeRange(0, schemeMarkerRange.location)];
                if (nil != scheme && 0 != [scheme length])
                {
                    if (NSNotFound != [scheme rangeOfString:HIDDEN_BITZ_URI_SCHEME].location)
                    {
                        _dataModel = kHBURI;

                        self.privateKey = [self.privateKey substringFromIndex:schemeMarkerRange.location + schemeMarkerRange.length];

                        bSuccess = YES;
                    }
                }
            }
            else
            {
                _dataModel = kWIF;

                bSuccess = YES;
            }

            if (bSuccess)
            {
                if ([CoreBridge Singleton].arrayWallets && [CoreBridge Singleton].currentWallet)
                {
                    // private key is a valid format
                    // attempt to sweep it
                    _sweptAddress = [CoreBridge sweepKey:self.privateKey
                                              intoWallet:[CoreBridge Singleton].currentWallet.strUUID
                                            withCallback:ABC_Sweep_Complete_Callback];

                    if (nil != _sweptAddress && _sweptAddress.length)
                    {
                        _state = ImportState_Importing;
                        [self updateDisplay]; //XXX Will be needed for encrypted private keys

                        // handle the case that the sweep callback is not triggered in a timely manner
                        _callbackTimer = [NSTimer scheduledTimerWithTimeInterval:30
                                                                          target:self
                                                                        selector:@selector(expireImport)
                                                                        userInfo:nil
                                                                         repeats:NO];
                    }
                    else
                    {
                        // no address associated with the private key, must be invalid
                        bSuccess = NO;
                    }

                }
            }
        }
    }

    if (NO == bSuccess)
    {
        _sweptAddress = nil;
        [self showFadingAlert:NSLocalizedString(@"Invalid private key", nil)];
        [self updateState];
    }
}


- (BOOL)processZBarResults:(ZBarSymbolSet *)syms
{
    BOOL bSuccess = YES;
#if !TARGET_IPHONE_SIMULATOR

	for (ZBarSymbol *sym in syms)
	{
        tABC_Error error;
		NSString *text = (NSString *)sym.data;

        if (_bImportMode)
        {
            if (nil != text && [text length])
            {
                self.privateKey = text;
                [self performSelector:@selector(importWallet)
                           withObject:nil
                           afterDelay:0.0];

                bSuccess = YES;
            }

            if (!bSuccess)
            {
                [self showFadingAlert:NSLocalizedString(@"Invalid private key", nil)];
            }
        }
        else
        {
            SpendTarget *spendTarget = [[SpendTarget alloc] init];
            if ([spendTarget newSpend:text error:&error]) {
                bSuccess = YES;
                [self showSendConfirmationTo:spendTarget];
                break;

            } else {
                bSuccess = NO;
            }
        }
	}

//    if (bSuccess == NO)
//    {
//        UIAlertView *alert = [[UIAlertView alloc]
//                initWithTitle:[Theme Singleton].invalidAddressPopupText
//                      message:NSLocalizedString(@"", nil)
//                     delegate:self
//            cancelButtonTitle:@"OK"
//            otherButtonTitles:nil];
//        [alert show];
//    }
#endif
    return bSuccess;
}

- (void)showImagePicker
{
#if !TARGET_IPHONE_SIMULATOR
    [self stopQRReader];
    [self stopBLE];

    _bUsingImagePicker = YES;

    _readerPicker = [ZBarReaderController new];
    _readerPicker.readerDelegate = self;
    if ([ZBarReaderController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        _readerPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    [_readerPicker.scanner setSymbology:ZBAR_I25 config:ZBAR_CFG_ENABLE to:0];
    _readerPicker.showsHelpOnFail = NO;

    [self presentViewController:_readerPicker animated:YES completion:nil];
    [MainViewController animateFadeOut:self.view];

#endif
}

//- (void)startCameraScanner:(NSTimer *)timer
//{
//	//will only switch to QR mode if there are no found BLE devices
//	//NSLog(@"################## SCAN TIMER FIRED ######################");
//	if(self.peripheralContainers.count == 0)
//	{
//		[self enableQRMode];
//	}
//}
//
- (NSArray *)createNewSendToChoices:(NSString *)strCur
{
    BOOL bUseAll = YES;

    if (strCur)
    {
        if ([strCur length])
        {
            bUseAll = NO;
        }
    }

    NSMutableArray *arrayChoices = [[NSMutableArray alloc] init];
    NSMutableArray *arrayChoicesIndexes = [[NSMutableArray alloc] init];

    [arrayChoices addObject:[Theme Singleton].selectWalletTransferPopupHeaderText];
    [arrayChoicesIndexes addObject:[NSNumber numberWithInt:-1]];

    for (int i = 0; i < [[CoreBridge Singleton].arrayWallets count]; i++)
    {
        // if this is not our currently selected wallet in the wallet selector
        // in other words, we can move funds from and to the same wallet
        if ([CoreBridge Singleton].currentWalletID != i)
        {
            Wallet *wallet = [[CoreBridge Singleton].arrayWallets objectAtIndex:i];

            BOOL bAddIt = bUseAll;
            if (!bAddIt)
            {
                // if we can find our current string within this wallet name
                if ([wallet.strName rangeOfString:strCur options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
                    bAddIt = YES;
                }
            }

            if (bAddIt)
            {
                [arrayChoices addObject:[NSString stringWithFormat:@"%@ (%@)", wallet.strName, [CoreBridge formatSatoshi:wallet.balance]]];
                [arrayChoicesIndexes addObject:[NSNumber numberWithInt:i]];
            }
        }

    }
    [arrayChoices addObject:[Theme Singleton].cancelButtonText];
    [arrayChoicesIndexes addObject:[NSNumber numberWithInt:-1]];

    self.arrayChoicesIndexes = arrayChoicesIndexes;

    return arrayChoices;
}

#pragma mark - Flash Select Delegates

- (void)toggleFlash
{

    //NSLog(@"Flash Item Selected: %i", flashType);
    if (bFlashOn)
    {
        [self flashItemSelected:FLASH_ITEM_OFF];
    }
    else
    {
        [self flashItemSelected:FLASH_ITEM_ON];
    }
}
- (void)flashItemSelected:(tFlashItem)flashType
{
#if !TARGET_IPHONE_SIMULATOR
    AVCaptureDevice *device = _readerView.device;

    switch(flashType)
    {
            case FLASH_ITEM_OFF:
                if ([device isTorchModeSupported:AVCaptureTorchModeOff])
                {
                    NSError *error = nil;
                    if ([device lockForConfiguration:&error])
                    {
                        device.torchMode = AVCaptureTorchModeOff;
                        [device unlockForConfiguration];
                        bFlashOn = NO;
                    }
                }
                break;
            case FLASH_ITEM_ON:
                if ([device isTorchModeSupported:AVCaptureTorchModeOn])
                {
                    NSError *error = nil;
                    if ([device lockForConfiguration:&error])
                    {
                        device.torchMode = AVCaptureTorchModeOn;
                        [device unlockForConfiguration];
                        bFlashOn = YES;
                    }
                }
                break;
    }
#endif
}

#pragma mark - SendConfirmationViewController Delegates

- (void)sendConfirmationViewControllerDidFinish:(SendConfirmationViewController *)controller
{
//    [self loadWalletInfo];
//    self.qrView.hidden = YES;
    [_readerView start];
    [self startQRReader];

    self.addressTextField.text = @"";
    //[self startCameraScanner:nil];
	[_sendConfirmationViewController.view removeFromSuperview];
	_sendConfirmationViewController = nil;
	
    scanMode = SCAN_MODE_UNINITIALIZED;
    if ([LocalSettings controller].bDisableBLE == NO) {
        [self enableAll];
//        [self startBleTimeout:BLE_TIMEOUT];
//    } else {
//        [self startBleTimeout:0.0];
    }

    [self enableTableSelection];
    [self setupNavBar];
    [self updateViews:nil];
}

#pragma mark - ButtonSelectorView2 delegates

- (void)ButtonSelector2:(ButtonSelectorView2 *)view selectedItem:(int)itemIndex
{
//    _selectedWalletIndex = itemIndex;
//    Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
//    [self.buttonSelector.button setTitle:wallet.strName forState:UIControlStateNormal];
//    self.buttonSelector.selectedItemIndex = _selectedWalletIndex;
//    bWalletListDropped = false;
//    _walletUUID = wallet.strUUID;
//
//    NSString *walletName = [NSString stringWithFormat:@"To: %@ ↓", wallet.strName];
//    [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle:) fromObject:self];
    NSIndexPath *indexPath = [[NSIndexPath alloc]init];
    indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [CoreBridge makeCurrentWalletWithIndex:indexPath];
    bWalletListDropped = false;

}

- (void)ButtonSelector2WillShowTable:(ButtonSelectorView2 *)view
{
    [self resignAllResponders];
}

- (void)ButtonSelector2WillHideTable:(ButtonSelectorView2 *)view
{

}

#pragma mark - ZBar's Delegate methods

#if !TARGET_IPHONE_SIMULATOR
- (void)readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{

    [self processZBarResults:syms];

}
#endif

#if !TARGET_IPHONE_SIMULATOR

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)reader
{
    [reader dismissViewControllerAnimated:YES completion:nil];
    _bUsingImagePicker = NO;

    self.loopbackState = LoopbackState_Cancelled;
    [self.delegate pleaseRestartSendViewBecauseAppleSucksWithPresentController];
	
	//cw viewWillAppear will get called which will switch us back into BLE mode
}

- (void)imagePickerController:(UIImagePickerController *)reader didFinishPickingMediaWithInfo:(NSDictionary*) info
{
    id<NSFastEnumeration> results = [info objectForKey:ZBarReaderControllerResults];
    //UIImage *image = [info objectForKey: UIImagePickerControllerOriginalImage];

    self.zBarSymbolSet = (ZBarSymbolSet *) results;
    self.loopbackState = LoopbackState_Go;
    [self.delegate pleaseRestartSendViewBecauseAppleSucksWithPresentController];

//    BOOL bSuccess = [self processZBarResults:(ZBarSymbolSet *) results andExit:YES];
//
    [reader dismissViewControllerAnimated:YES completion:nil];
    //[[controller presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    //[reader dismissModalViewControllerAnimated: YES];

//    _bUsingImagePicker = NO;
//
//    if (!bSuccess)
//    {
//        //_startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];
//		[self startQRReader];
//    }
}

- (void)readerControllerDidFailToRead:(ZBarReaderController*)reader
                            withRetry:(BOOL)retry
{
    [reader dismissViewControllerAnimated:YES completion:nil];
    self.loopbackState = LoopbackState_Scan_Failed;
    [self.delegate pleaseRestartSendViewBecauseAppleSucksWithPresentController];
//
//    UIAlertView *alert = [[UIAlertView alloc]
//                          initWithTitle:NSLocalizedString(@"QR Code Scan Failure", nil)
//                          message:NSLocalizedString(@"Unable to scan QR code", nil)
//                          delegate:nil
//                          cancelButtonTitle:@"OK"
//                          otherButtonTitles:nil];
//    [alert show];
//
//    _bUsingImagePicker = NO;
//   // _startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];
//   [self startQRReader];
}

#endif

#pragma mark - PickerTextView Delegates

//- (void)pickerTextViewFieldDidChange:(PickerTextView *)pickerTextView
//{
//    NSArray *arrayChoices = [self createNewSendToChoices:pickerTextView.textField.text];
//
//    [pickerTextView updateChoices:arrayChoices];
//}
//
//- (void)pickerTextViewFieldDidBeginEditing:(PickerTextView *)pickerTextView
//{
//    NSArray *arrayChoices = [self createNewSendToChoices:pickerTextView.textField.text];
//
//    [pickerTextView updateChoices:arrayChoices];
//}
//
//- (BOOL)pickerTextViewShouldEndEditing:(PickerTextView *)pickerTextView
//{
//    // unhighlight text
//    // note: for some reason, if we don't do this, the text won't select next time the user selects it
//    [pickerTextView.textField setSelectedTextRange:[pickerTextView.textField textRangeFromPosition:pickerTextView.textField.beginningOfDocument toPosition:pickerTextView.textField.beginningOfDocument]];
//
//    return YES;
//}
//
//- (void)pickerTextViewFieldDidEndEditing:(PickerTextView *)pickerTextView
//{
//    //[self forceCategoryFieldValue:pickerTextView.textField forPickerView:pickerTextView];
//}
//
- (BOOL)pickerTextViewFieldShouldReturn:(PickerTextView *)pickerTextView
{
	[pickerTextView.textField resignFirstResponder];
    [self processURI];
    return YES;
}

- (void)processURI
{
//    if ([[CoreBridge Singleton].arrayWalletNames count] == 0 || [[CoreBridge Singleton].arrayWallets count] == 0) {
//        [self loadWalletInfo];
//    }
    // Added to wallet queue since wallets are loaded asynchronously
    [CoreBridge postToWalletsQueue:^(void) {
        dispatch_async(dispatch_get_main_queue(),^{
            [self doProcessURI];
        });
    }];
}

- (void)doProcessURI
{
    tABC_Error error;
    BOOL bSuccess = YES;
    SpendTarget *spendTarget = [[SpendTarget alloc] init];
    NSString *text = _addressTextField.text;

    if (text.length)
	{
        // see if the text corresponds to one of the wallets
        NSInteger index = [[CoreBridge Singleton].arrayWalletNames indexOfObject:text];
        if (index != NSNotFound)
        {
            Wallet *wallet = [[CoreBridge Singleton].arrayWallets objectAtIndex:index];
            [spendTarget newTransfer:wallet.strUUID error:&error];
            [self stopQRReader];
            [self showSendConfirmationTo:spendTarget];

        }
        else
        {
            bSuccess = [spendTarget newSpend:text error:&error];
        }

        if (!bSuccess)
        {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Invalid Bitcoin Address", nil)
                                  message:NSLocalizedString(@"", nil)
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            [self stopQRReader];
            [self showSendConfirmationTo:spendTarget];
        }
	}
}

//- (void)pickerTextViewPopupSelected:(PickerTextView *)pickerTextView onRow:(NSInteger)row
- (void)PopupPickerViewSelected:(PopupPickerView *)view onRow:(NSInteger)row userData:(id)data
{
    tABC_Error error;
    // set the text field to the choice
    NSInteger index = [[self.arrayChoicesIndexes objectAtIndex:row] integerValue];
    if (index >= 0)
    {
        Wallet *wallet = [[CoreBridge Singleton].arrayWallets objectAtIndex:index];

        SpendTarget *spendTarget = [[SpendTarget alloc] init];
        [spendTarget newTransfer:wallet.strUUID error:&error];
        [self stopQRReader];
        [self showSendConfirmationTo:spendTarget];
    }
    [view dismiss];

//    [MainViewController animateFadeOut:view remove:YES];

}

- (void)updateDisplay
{
    BOOL bHideEnter = YES;

//    if ((![self.textPrivateKey isFirstResponder]) && ([self.textPrivateKey.text length] == 0))
//    {
//        bHideEnter = NO;
//    }
//
    if (_state == ImportState_PrivateKey)
    {
//        self.viewDisplay.hidden = NO;
//        self.viewPassword.hidden = YES;
    }
    else
    {
//        self.viewDisplay.hidden = YES;
//        self.viewPassword.hidden = NO;
//
//        self.imageApproved.hidden = YES;
//        self.imageNotApproved.hidden = YES;
//        self.textPassword.hidden = YES;
//        self.imagePasswordEmboss.hidden = YES;
//        self.textPassword.enabled = NO;
//
//        if (_bPasswordRequired)
//        {
//            self.textPassword.hidden = NO;
//            self.imagePasswordEmboss.hidden = NO;
//        }
//
        if (_state == ImportState_EnterPassword)
        {
//            self.textPassword.enabled = YES;
//            self.labelPasswordStatus.text = NSLocalizedString(@"Enter password to decode wallet", nil);
//            self.textPassword.hidden = NO;
//            self.imagePasswordEmboss.hidden = NO;
        }
        else if (_state == ImportState_RetryPassword)
        {
//            self.textPassword.enabled = YES;
//            self.labelPasswordStatus.text = NSLocalizedString(@"Incorrect password.\nTry again", nil);
//            self.textPassword.hidden = NO;
//            self.imagePasswordEmboss.hidden = NO;
//            self.imageNotApproved.hidden = NO;
        }
        else if (_state == ImportState_Importing)
        {
            NSMutableString *statusMessage = [NSMutableString string];
//            if (_bPasswordRequired)
//            {
//                [statusMessage appendString:NSLocalizedString(@"Password Correct.\n", nil)];
//                self.imageApproved.hidden = NO;
//            }
            [statusMessage appendString:[[NSString alloc] initWithFormat:NSLocalizedString(@"Importing funds from %@ into wallet...", nil), _sweptAddress]];
//            self.labelPasswordStatus.text = [NSString stringWithString:statusMessage];
        }
    }
}


- (void)updateState
{
    if (nil == _tweetAlert && nil == _sweptAlert && nil == _receivedAlert)
    {
        _state = ImportState_PrivateKey;
        [self updateDisplay];
        [self startQRReader];
    }
}

- (void)sendTweet
{
    // invoke Twitter to send tweet
    SLComposeViewController *slComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [slComposerSheet setInitialText:_tweet];
    [slComposerSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
        switch (result) {
            case SLComposeViewControllerResultCancelled:
                [self tweetCancelled];
            default:
                [self updateState];
                break;
        }
    }];
    [self presentViewController:slComposerSheet animated:YES completion:nil];
}



- (void)tweetCancelled
{
    [self showFadingAlert:NSLocalizedString(@"Import the private key again to retry Twitter", nil)];
}

- (void)showSweepResults
{
    if (_sweptAlert)
    {
        [_sweptAlert show];
    }
    if (_receivedAlert)
    {
        [_receivedAlert show];
    }

    if (kHBURI == _dataModel)
    {
        // make a query with the last bytes of the address
        const int hBitzIDLength = 4;
        if (nil != _sweptAddress && hBitzIDLength <= _sweptAddress.length)
        {
            NSString *hiddenBitzID = [_sweptAddress substringFromIndex:[_sweptAddress length]-hBitzIDLength];
            NSString *hiddenBitzURI = [NSString stringWithFormat:@"%@%@%@", SERVER_API, @"/hiddenbits/", hiddenBitzID];
            [[DL_URLServer controller] issueRequestURL:hiddenBitzURI
                                            withParams:nil
                                            withObject:self
                                          withDelegate:self
                                    acceptableCacheAge:CACHE_24_HOURS
                                           cacheResult:YES];

            _callbackTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                              target:self
                                                            selector:@selector(expireImport)
                                                            userInfo:nil
                                                             repeats:NO];
        }
    }
}


- (void)expireImport
{
    [self showFadingAlert:NSLocalizedString(@"Import failed", nil)];
    [self updateState];
    _callbackTimer = nil;
}

- (void)cancelImportExpirationTimer
{
    if (_callbackTimer)
    {
        [_callbackTimer invalidate];
        _callbackTimer = nil;
    }
}

- (void)sweepDoneCallback:(NSNotification *)notification
{
    [self cancelImportExpirationTimer];

    NSDictionary *userInfo = [notification userInfo];
    tABC_CC result = [[userInfo objectForKey:KEY_SWEEP_CORE_CONDITION_CODE] intValue];
    uint64_t amount = [[userInfo objectForKey:KEY_SWEEP_TX_AMOUNT] unsignedLongLongValue];
    if (nil == _sweptAlert && nil == _receivedAlert)
    {
        _sweptAmount = amount;

        if (ABC_CC_Ok == result)
        {
            if (0 < amount)
            {
                // handle received bitcoin
                _sweptTXID = [userInfo objectForKey:KEY_SWEEP_TX_ID];
                if (_sweptTXID && [_sweptTXID length])
                {
                    _receivedAlert = [[UIAlertView alloc]
                            initWithTitle:NSLocalizedString(@"Received Funds", nil)
                                  message:NSLocalizedString(@"Bitcoin received. Tap for details.", nil)
                                 delegate:self
                        cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                        otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                }
                else
                {
                    _sweptTXID = nil;
                }
            }
            else if (kHBURI != _dataModel)
            {
                NSString *message = NSLocalizedString(@"Failed to import because there is 0 bitcoin remaining at this address", nil);
                _sweptAlert = [[UIAlertView alloc]
                        initWithTitle:NSLocalizedString(@"Error", nil)
                              message:message
                             delegate:self
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil, nil];
            }
        }
        else
        {
            tABC_Error temp;
            temp.code = result;
            NSString *message = [Util errorMap:&temp];
            _sweptAlert = [[UIAlertView alloc]
                    initWithTitle:NSLocalizedString(@"Error", nil)
                          message:message
                         delegate:self
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil, nil];
        }

        [self performSelectorOnMainThread:@selector(showSweepResults)
                               withObject:nil
                            waitUntilDone:NO];
    }
}

#pragma mark - AlertView delegate



#pragma - Fading Alert Methods

- (void)showFadingAlert:(NSString *)message
{
    [self showFadingAlert:message withDelay:ERROR_MESSAGE_FADE_DELAY];
}

- (void)showFadingAlert:(NSString *)message withDelay:(int)fadeDelay
{
    _fadingAlert = [FadingAlertView2 CreateInsideView:self.view withDelegate:nil];
    [_fadingAlert messageTextSet:message];
    _fadingAlert.fadeDelay = fadeDelay;
    _fadingAlert.fadeDuration = ERROR_MESSAGE_FADE_DURATION;
    [_fadingAlert blockModal:NO];
    [_fadingAlert showSpinner:NO];
    [_fadingAlert showFading];
}

- (void)dismissErrorMessage
{
    [_fadingAlert dismiss:NO];
    _fadingAlert = nil;
}

@end

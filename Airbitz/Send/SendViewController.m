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
#import "ABCSpend.h"

#import <AVFoundation/AVFoundation.h>
#import <Social/Social.h>
#import "Notifications.h"
#import "SendConfirmationViewController.h"
#import "FlashSelectView.h"
#import "User.h"
#import "CommonTypes.h"
#import "Util.h"
#import "InfoView.h"
#import "ZBarSDK.h"
#import "ABCContext.h"
#import "TransferService.h"
#import "BLEScanCell.h"
#import "Contact.h"
#import "LocalSettings.h"
#import "FadingAlertView.h"
#import "ButtonSelectorView2.h"
#import "MainViewController.h"
#import "Theme.h"
#import "ABCSpend.h"
#import "Server.h"
#import "PopupPickerView2.h"
#import "CJSONDeserializer.h"
#import "AddressRequestController.h"
#import "SSOViewController.h"
#import "Mixpanel.h"

typedef enum eScanMode
{
	SCAN_MODE_UNINITIALIZED,
}tScanMode;

static NSTimeInterval lastCentralBLEPowerOffNotificationTime = 0;

@interface SendViewController () <SendConfirmationViewControllerDelegate, UIAlertViewDelegate,FlashSelectViewDelegate, UITextFieldDelegate, PopupPickerView2Delegate,ButtonSelector2Delegate, CBCentralManagerDelegate, CBPeripheralDelegate
 ,ZBarReaderDelegate, ZBarReaderViewDelegate, AddressRequestControllerDelegate, SSOViewControllerDelegate
>
{
	ZBarReaderView                  *_readerView;
    ZBarReaderController            *_readerPicker;
    SendConfirmationViewController  *_sendConfirmationViewController;
    SSOViewController               *_ssoViewController;
    AddressRequestController        *_addressRequestController;

	NSTimeInterval					lastUpdateTime;	//used to remove BLE devices from table when they're no longer around
	NSTimer							*peripheralCleanupTimer; //used to remove BLE devices from table when they're no longer around
	tScanMode						scanMode;
    BOOL                            bWalletListDropped;
    BOOL                            bFlashOn;
    UIAlertView                     *typeAddressAlertView;
    UIAlertView                     *_sweptAlert;
    UIAlertView                     *_tweetAlert;
//    UIAlertView                     *_bitidAlert;
    UIAlertView                     *_privateKeyAlert;
    ABCParsedURI                    *_parsedURI;
    NSString                        *_privateKeyURI;
    NSString                        *_tweet;
//    NSMutableArray                  *_kycTokenKeys;
//    BOOL                            _bitidSParam;
//    BOOL                            _bitidProvidingKYCToken;
}
@property (weak, nonatomic)     IBOutlet UIImageView            *scanFrame;
@property (nonatomic, strong)   IBOutlet ButtonSelectorView2    *buttonSelector;
@property (nonatomic, strong)	IBOutlet UITableView			*tableView;
@property (nonatomic, strong)   NSArray                         *arrayChoicesIndexes;
@property (nonatomic, strong)   PopupPickerView2                *popupPickerSendTo;
@property (nonatomic, strong)   IBOutlet UILabel				*scanningErrorLabel;
@property (weak, nonatomic)     IBOutlet UILabel                *topTextLabel;
@property (weak, nonatomic)     IBOutlet UILabel                *textUnderQRScanner;

@property (weak, nonatomic)     IBOutlet UISegmentedControl     *segmentedControl;
@property (weak, nonatomic)     IBOutlet NSLayoutConstraint     *bleViewHeight;
@property (strong, nonatomic)   CBCentralManager                *centralManager;
@property (strong, nonatomic)   CBPeripheral                    *discoveredPeripheral;
@property (strong, nonatomic)   NSMutableData                   *data;
@property (strong, nonatomic)   NSMutableArray		            *peripheralContainers;
@property (nonatomic, copy)	    NSString				        *advertisedPartialBitcoinAddress;
@property (strong, nonatomic)   AFHTTPRequestOperationManager   *afmanager;

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
    
    bWalletListDropped = false;

    self.buttonSelector.delegate = self;
    [self.buttonSelector disableButton];

    self.textUnderQRScanner.hidden = YES;
    [self.scanningErrorLabel setHidden:YES];

    // load all the names from the address book
    [MainViewController generateListOfContactNames];

    self.afmanager = [MainViewController createAFManager];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)scanBLEstartCamera
{
    scanMode = SCAN_MODE_UNINITIALIZED;
    [self startQRReader];

    if([LocalSettings controller].bDisableBLE == NO)
    {
        {
            // Start up the CBCentralManager.  Warn if settings BLE is on but device BLE is off (but only once every 24 hours)
            NSTimeInterval curTime = CACurrentMediaTime();
//            if((curTime - lastCentralBLEPowerOffNotificationTime) > 86400.0) //24 hours
//            {
//                _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey: @(YES)}];
//            }
//            else
            {
                _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey: @(NO)}];
            }
            lastCentralBLEPowerOffNotificationTime = curTime;
            [self startBLE];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [[Mixpanel sharedInstance] track:@"SCN-Enter"];
    [self scanBLEstartCamera];
    [MainViewController changeNavBarOwner:self];

    [segmentedControl setEnabled:YES forSegmentAtIndex:0];

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willRotate:) name:NOTIFICATION_ROTATION_CHANGED object:nil];


    //
    // This might be a loopback from presentViewController
    // Check params and go
    //

    if (self.loopbackState == LoopbackState_Go && self.zBarSymbolSet != nil)
    {
        [self processZBarResults:self.zBarSymbolSet];
    }
    else if (self.loopbackState == LoopbackState_Scan_Failed)
    {

        UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:qrCodeScanFailure
                      message:unableToScanQR
                     delegate:nil
            cancelButtonTitle:okButtonText
            otherButtonTitles:nil];
        [alert show];
    }
    else if (self.loopbackState == LoopbackState_Invalid_Address)
    {
        UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:invalidAddressPopupText
                      message:@""
                     delegate:self
            cancelButtonTitle:okButtonText
            otherButtonTitles:nil];
        [alert show];

    }
    self.zBarSymbolSet = nil;
    self.loopbackState = LoopbackState_None;

    [self setupNavBar];

    self.topTextLabel.text = scanQrToSendFundsText;
    if ([[LocalSettings controller] offerSendHelp])
    {
        [MainViewController fadingAlertHelpPopup:sendScreenHelpText];
    }

    [self updateViews:nil];
    [self flashItemSelected:FLASH_ITEM_OFF];

}

- (void)willRotate:(NSNotification *)notification
{
    NSDictionary *dictData = [notification userInfo];
    NSNumber *orientation = [dictData objectForKey:KEY_ROTATION_ORIENTATION];

    [self rotateZbar:[orientation intValue]];
}

- (void)rotateZbar:(UIInterfaceOrientation) orientation
{
    [_readerView willRotateToInterfaceOrientation:orientation duration:0.35];
}

- (void)setupNavBar
{
    [MainViewController changeNavBar:self title:closeButtonText side:NAV_BAR_LEFT button:true enable:bWalletListDropped action:@selector(didTapTitle:) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(info:) fromObject:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self willResignActive];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // XXX Yikes, is this still needed. ABC will callback our handlers in importWallet
    // but will that still happen if the viewcontroller is destroyed? -paulvp
//    [self cancelImportExpirationTimer];
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
        [[Mixpanel sharedInstance] track:@"SCN-DropWallets"];
        [self.buttonSelector open];
        bWalletListDropped = true;
    }
    [MainViewController changeNavBar:self title:closeButtonText side:NAV_BAR_LEFT button:true enable:bWalletListDropped action:@selector(didTapTitle:) fromObject:self];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification
{
    [self flashItemSelected:FLASH_ITEM_OFF];
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
        [_sendConfirmationViewController removeFromParentViewController];
        _sendConfirmationViewController.delegate = nil;
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
			//ABCLog(2,@"Last: %f Current: %f", [pc.lastAdvertisingTime floatValue], currentTime);
			if(currentTime - [pc.lastAdvertisingTime doubleValue] > 1.0)
			{
				//haven't heard from this peripheral in a while.  Kill it.
				//ABCLog(2,@"Removing peripheral");
				[self.peripheralContainers removeObjectAtIndex:i];
				[self updateTable];
			}
		}
	}
}

-(void)enableAll
{
    [self startBLE];
}

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
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if(authStatus == AVAuthorizationStatusAuthorized)
        {
            [self.scanningErrorLabel setHidden:YES];
        }
        else
        {
            self.scanningErrorLabel.text = cameraUnavailablePleaseEnable;
            [self.scanningErrorLabel setHidden:NO];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self attemptToStartQRReader];
        });
    }];
}

-(void)attemptToStartQRReader
{
    if (_readerView) {
        [_readerView start];
        return;
    }
    // check camera state before proceeding
	_readerView = [ZBarReaderView new];
    _readerView.torchMode = AVCaptureTorchModeOff;
    [self rotateZbar:[[UIApplication sharedApplication] statusBarOrientation]];

	[self.view insertSubview:_readerView belowSubview:self.scanFrame];
	_readerView.frame = self.scanFrame.frame;
	_readerView.readerDelegate = self;
	_readerView.tracksSymbols = NO;
	
	_readerView.tag = READER_VIEW_TAG;
	[_readerView start];
	[self flashItemSelected:FLASH_ITEM_OFF];
}

- (void)stopQRReader
{
    if (_readerView)
    {
        [_readerView stop];
    }
}

#endif

#pragma mark - Action Methods

- (IBAction)info:(id)sender
{
	[self.view endEditing:YES];
    [[Mixpanel sharedInstance] track:@"SCN-Help"];
    [self resignAllResponders];
    [InfoView CreateWithHTML:@"info_send" forView:self.view];
}

- (IBAction)buttonCameraTouched:(id)sender
{
    [self resignAllResponders];
    [self showImagePicker];
}
#pragma mark UISegmentedControl


- (IBAction)segmentedControlAction:(id)sender
{
    NSArray *arrayChoices = [[NSArray alloc] init];
    UITextField *textField;
    NSString *title;
    NSString *placeholderText;
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    NSString *clipboard = [pb string];
    NSString *pasteString;
    ABCParsedURI *parsedURI;
    switch (segmentedControl.selectedSegmentIndex)
    {
        case 0:
            [[Mixpanel sharedInstance] track:@"SCN-Transfer"];
            arrayChoices = [self createNewSendToChoices:@""];
            self.popupPickerSendTo = [PopupPickerView2 CreateForView:self.view
                                                   relativePosition:PopupPicker2Position_Full_Rising
                                                        withStrings:arrayChoices
                                                      withAccessory:nil
                                                         headerText:selectWalletTransferPopupHeaderText
            ];
            self.popupPickerSendTo.delegate = self;
            // Do Transfer
            break;
        case 1:
            [[Mixpanel sharedInstance] track:@"SCN-Address"];
            title = enterBitcoinAddressPopupText;
            placeholderText = enterBitcoinAddressPlaceholder;
            parsedURI = [ABCUtil parseURI:clipboard error:nil];
            if (parsedURI)
            {
                if (parsedURI.privateKey || parsedURI.address)
                {
                    pasteString = [NSString stringWithFormat:@"%@ \"%@...\"", @"Paste", [clipboard substringToIndex:10]];
                }
            }
            else
            {
                pasteString = nil;
            }

            typeAddressAlertView =[[UIAlertView alloc ] initWithTitle:title
                                                              message:nil
                                                             delegate:self
                                                    cancelButtonTitle:cancelButtonText
                                                    otherButtonTitles:doneButtonText, pasteString, nil];
            typeAddressAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            textField = [typeAddressAlertView textFieldAtIndex:0];
            textField.placeholder = placeholderText;
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.spellCheckingType = UITextSpellCheckingTypeNo;
            textField.returnKeyType = UIReturnKeyDone;

            [typeAddressAlertView show];
            [self stopQRReader];
            break;

        case 2:
            // Do Photo
            [[Mixpanel sharedInstance] track:@"SCN-Photo"];
            [self resignAllResponders];
            [self showImagePicker];

            break;
        case 3:
            // Do Flash
            [[Mixpanel sharedInstance] track:@"SCN-Flash"];
            [self toggleFlash];
            break;
    }
}

#pragma mark - UIAlertView delegates

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView == typeAddressAlertView)
    {
        [self startQRReader];
        NSString *uriString = nil;
        if (1 == buttonIndex)
        {
            uriString = [alertView textFieldAtIndex:0].text;
        }
        else if (2 == buttonIndex)
        {
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            uriString = [pb string];
        }
        if (buttonIndex > 0) // 0 == CANCEL
        {
            if (uriString && [uriString length] > 0)
                [self processURI:uriString];
        }
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
    else if (_privateKeyAlert == alertView)
    {
        if (buttonIndex == 1)
        {
            // Import
            [self importWallet:_privateKeyURI];
        }
        else if (buttonIndex == 2)
        {
            // Send
            [self doProcessParsedURI:_parsedURI];
        }
        else
        {
            // Cancel
            [self startQRReader];
        }
    }
//    else if (_bitidAlert == alertView)
//    {
//        if (buttonIndex > 0)
//        {
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
//                ABCError *error = nil;
//                if (!_bitidSParam)
//                    error = [abcAccount bitidLogin:_parsedURI.bitIDURI];
//                else
//                {
//                    if (_kycTokenKeys)
//                    {
//                        NSMutableString *callbackURL = [[NSMutableString alloc] init];
//
//                        [abcAccount.dataStore dataRead:@"Identities" withKey:_kycTokenKeys[buttonIndex-1] data:callbackURL];
//                        error = [abcAccount bitidLoginMeta:_parsedURI.bitIDURI kycURI:[NSString stringWithString:callbackURL]];
//                    }
//                    else
//                    {
//                        error = [abcAccount bitidLoginMeta:_parsedURI.bitIDURI kycURI:@""];
//                    }
//                }
//
//                dispatch_async(dispatch_get_main_queue(),^{
//                    if (!error)
//                    {
//                        if (_bitidProvidingKYCToken)
//                        {
//                            NSString *message = [NSString stringWithFormat:provideIdentityTokenText, _parsedURI.bitIDDomain];
//
//                            [MainViewController fadingAlert:message holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
//                        }
//                        else if(_kycTokenKeys)
//                        {
//                            NSString *message = [NSString stringWithFormat:@"%@ %@", successfully_verified_identity, _kycTokenKeys[buttonIndex-1]];
//                            [MainViewController fadingAlert:message holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
//                        }
//                        else
//                        {
//                            [MainViewController fadingAlert:successfullyLoggedIn holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
//                        }
//                    }
//                    else
//                    {
//                        [MainViewController fadingAlert:errorLoggingIn holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
//                    }
//                    [self startQRReader];
//
//                });
//            });
//        }
//        else
//        {
//            [self startQRReader];
//        }
//    }
}


#pragma mark - BLE Central Methods

-(void)startBLE
{
    //ABCLog(2,@"################## STARTED BLE ######################");
    [self scan];
    //kick off peripheral cleanup timer (removes peripherals from table when they're no longer in range)
    peripheralCleanupTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(cleanupPeripherals:) userInfo:nil repeats:YES];
}

-(void)stopBLE
{
    //ABCLog(2,@"################## STOPPED BLE ######################");
    [self.centralManager stopScan];
    //ABCLog(2,@"Getting rid of timer");
    [peripheralCleanupTimer invalidate];
}

/** centralManagerDidUpdateState is a required protocol method.
 *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
 *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
 *  the Central is ready to be used.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
//	ABCLog(2,@"DID UPDATE STATE");

    if (central.state != CBCentralManagerStatePoweredOn)
	{
//		self.ble_button.hidden = YES;
//		[self enableQRMode];
    }
	else
	{
		ABCLog(2,@"POWERED ON");
        [self startBLE];
//		[self enableBLEMode];
//		self.ble_button.hidden = NO;
    }
}


/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
- (void)scan
{
	//ABCLog(2,@"################## BLE SCAN STARTED ######################");
    _data = [[NSMutableData alloc] init];
	self.peripheralContainers = nil;
	[self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
    
    //ABCLog(2,@"Scanning started");
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
				if ([container.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString])
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
                [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                                      delay:[Theme Singleton].animationDelayTimeDefault
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
//    ABCLog(2,@"Discovered %@ at %@ with adv data: %@", peripheral.name, RSSI, advertisementData);
}


/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    ABCLog(2,@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}


/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
//    ABCLog(2,@"Peripheral Connected");
    
    // Stop scanning
    [self.centralManager stopScan];
//    ABCLog(2,@"Scanning stopped");
    
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
        ABCLog(2,@"Error discovering services: %@", [error localizedDescription]);
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
        ABCLog(2,@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics)
	{
        
		if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
		{
			
            // Write username to this characteristic
			BOOL sendName = abcAccount.settings.bNameOnPayments;

			NSString *fullName = @" ";
			if(sendName)
			{
				if(abcAccount.settings.fullName)
				{
					if(abcAccount.settings.fullName.length)
					{
						fullName = abcAccount.settings.fullName;
					}
				}
			}
            else
            {
                // Send device name
                fullName = [[UIDevice currentDevice] name];

            }
			
			[peripheral writeValue:[fullName dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
			
//			ABCLog(2,@"Writing: %@ to peripheral", fullName);
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
        ABCLog(2,@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
	
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    if ((self.advertisedPartialBitcoinAddress == nil) ||
            (stringFromData == nil) ||
            [stringFromData rangeOfString:self.advertisedPartialBitcoinAddress].location == NSNotFound)
    {
        //start at index 9 to skip over "bitcoin:".  Partial address is 10 characters long
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:bitcoinAddressMismatch
                              message:[NSString stringWithFormat:bitcoinAddressMismatchFormatText, [stringFromData substringWithRange:NSMakeRange(8, 10) ], self.advertisedPartialBitcoinAddress]
                              delegate:nil
                              cancelButtonTitle:okButtonText
                              otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        [[Mixpanel sharedInstance] track:@"SCN-BLE"];
        [self processURI:stringFromData];
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
                                  initWithTitle:bitcoinAddressMismatch, nil)
                                  message:[NSString stringWithFormat:bitcoinAddressMismatchFormatText, [stringFromData substringWithRange:NSMakeRange(8, 10) ], self.advertisedPartialBitcoinAddress]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            [[Mixpanel sharedInstance] track:@"SCN-BLE"];
            [self processURI:receivedData];
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
        ABCLog(2,@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
	{
        return;
    }
    
    if (!characteristic.isNotifying)
	{
        // so disconnect from the peripheral
        ABCLog(2,@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}


-(void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices
{
	ABCLog(2,@"Did Modify Services: %@", invalidatedServices);
}


/** Once the disconnection happens, we need to clean up our local copy of the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    //ABCLog(2,@"Did disconnect because: %@", error.description);
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
        ABCLog(2,@"Error writing value for characteristic: %@", error.localizedDescription);
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
		
//        CFStringRef s = p.peripheral.identifier.UUIDString;
//        CFStringRef s = CFUUIDCreateString(NULL, p.peripheral.identifier.UUIDString);
//        printf("%d  |  %s\r\n",i,CFStringGetCStringPtr(s, 0));
//        CFRelease(s);
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
//    CFStringRef s = CFUUIDCreateString(NULL, peripheralContainer.peripheral.UUID);
//    printf("------------------------------------\r\n");
//    printf("Peripheral Info :\r\n");
//    printf("UUID : %s\r\n",CFStringGetCStringPtr(s, 0));
//    CFRelease(s);
//    printf("RSSI : %d\r\n",[peripheralContainer.peripheral.RSSI intValue]);
//    ABCLog(2,@"Name : %@\r\n",peripheralContainer.peripheral.name);
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
                scanCell.contactImage.image = [[MainViewController Singleton].dictImages objectForKey:[name lowercaseString]];
                if (scanCell.contactImage.image)
                    imageIsFromContacts = YES;

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
        if(imageIsFromContacts == NO)
        {
            scanCell.contactImage.image = [UIImage imageNamed:@"BLE_photo.png"];
        }
    }
    else
    {
        // Invalid BLE request. Assign some warning text and image
        scanCell.contactName.text = invalidBluetoothRequest;
        scanCell.contactName.textColor = scanCell.duplicateNamesLabel.textColor;
        scanCell.contactBitcoinAddress.text = pleaseHaveRequestorContactSupport;
        scanCell.contactBitcoinAddress.textColor = scanCell.duplicateNamesLabel.textColor;
        scanCell.contactImage.image = [UIImage imageNamed:@"Warning_icon.png"];
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

	//ABCLog(2,@"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^Selecting row: %li", (long)indexPath.row);
	
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
	//ABCLog(2,@"Connecting to peripheral %@", pc.peripheral);
	[self.centralManager connectPeripheral:pc.peripheral options:nil];
}

#pragma mark - Misc Methods

- (void)resignAllResponders
{
}

- (void)updateViews:(NSNotification *)notification
{
    if (abcAccount.arrayWallets && abcAccount.currentWallet)
    {
        self.buttonSelector.arrayItemsToSelect = abcAccount.arrayWalletNames;
        [self.buttonSelector.button setTitle:abcAccount.currentWallet.name forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = abcAccount.currentWalletIndex;

        NSString *walletName;
        walletName = [NSString stringWithFormat:@"%@ ▼", abcAccount.currentWallet.name];

        [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle:) fromObject:self];
        if (!([abcAccount.arrayWallets containsObject:abcAccount.currentWallet]))
        {
            self.textUnderQRScanner.text = walletHasBeenArchivedText;
            self.textUnderQRScanner.hidden = NO;
            self.scanFrame.hidden = YES;
            self.segmentedControl.hidden = YES;
        }
        else
        {
            self.textUnderQRScanner.hidden = YES;
            self.scanFrame.hidden = NO;
            self.segmentedControl.hidden = NO;
        }

        [self.tableView reloadData];

    }
}

// if bToIsUUID NO, then it is assumed the strTo is an address
- (void)showSSOViewController:(ABCParsedURI *)parsedURI edgeLoginRequest:(ABCEdgeLoginInfo *)edgeLoginInfo;
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    _ssoViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SSOViewController"];

    _ssoViewController.delegate             = self;
    _ssoViewController.parsedURI            = parsedURI;
    _ssoViewController.edgeLoginInfo        = edgeLoginInfo;

    [_readerView stop];

    [Util addSubviewControllerWithConstraints:self child:_ssoViewController];

    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
                     {
                         _ssoViewController.view.frame = self.view.bounds;
                     }
                     completion:^(BOOL finished)
                     {
                         [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                     }];
}

// if bToIsUUID NO, then it is assumed the strTo is an address
- (void)showSendConfirmationTo:(ABCParsedURI *)parsedURI
                    destWallet:(ABCWallet *)destWallet
                paymentRequest:(ABCPaymentRequest *)paymentRequest
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_sendConfirmationViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendConfirmationViewController"];

	_sendConfirmationViewController.delegate            = self;
    _sendConfirmationViewController.paymentRequest      = paymentRequest;
    _sendConfirmationViewController.parsedURI           = parsedURI;
    _sendConfirmationViewController.destWallet          = destWallet;
    
    _sendConfirmationViewController.bSignOnly           = NO;
    _sendConfirmationViewController.bAdvanceToTx        = YES;
    _sendConfirmationViewController.bAmountImmutable    = NO;

    [_readerView stop];

    [Util addSubviewControllerWithConstraints:self child:_sendConfirmationViewController];
	
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
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


- (void)importWallet:(NSString *)privateKey
{
    [[Mixpanel sharedInstance] track:@"SCN-Import"];

    [abcAccount.currentWallet importPrivateKey:privateKey importing:^(NSString *address) {
        NSMutableString *statusMessage = [NSMutableString string];
        [statusMessage appendString:[[NSString alloc]
                initWithFormat:importingFundsIntoWallet, address]];
        [MainViewController fadingAlert:statusMessage holdTime:FADING_ALERT_HOLD_TIME_FOREVER_WITH_SPINNER];
    } complete:^(ABCImportDataModel dataModel, NSString *address, ABCTransaction *transaction, uint64_t amount) {
        if (ABCImportHBitsURI == dataModel)
        {
            [MainViewController fadingAlertDismiss];
            [self showHbitsResults:address amount:amount];
            NSString *txid = transaction.txid;
            if (txid && [txid length] && amount > 0)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_VIEW_SWEEP_TX
                                                                    object:nil
                                                                  userInfo:@{KEY_TX_DETAILS_EXITED_WALLET_UUID:abcAccount.currentWallet.uuid,
                                                                             KEY_TX_DETAILS_EXITED_TX_ID:txid}];
            }
        }
        else if (0 < amount)
        {
            [MainViewController fadingAlertDismiss];
            NSString *txid = transaction.txid;
            if (txid && [txid length]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_VIEW_SWEEP_TX
                                                                    object:nil
                                                                  userInfo:@{KEY_TX_DETAILS_EXITED_WALLET_UUID:abcAccount.currentWallet.uuid,
                                                                             KEY_TX_DETAILS_EXITED_TX_ID:txid}];
            }
        }
        else
        {
            [MainViewController fadingAlert:importFailedPrivateKeyEmpty];
        }
        [self startQRReader];
        
    } error:^(ABCError *error) {
        NSString *errorMessage = [NSString stringWithFormat:@"%@\n\n%@: %d\n\n%@: %@", importFailedText, errorCodeText, (int) error.code, errorDescriptionText, error.userInfo[NSLocalizedDescriptionKey]];
        [MainViewController fadingAlert:errorMessage];

        [self updateState];
    }];
}


- (void)processZBarResults:(ZBarSymbolSet *)syms
{
#if !TARGET_IPHONE_SIMULATOR
	for (ZBarSymbol *sym in syms)
	{
		NSString *text = (NSString *)sym.data;
        
        [[Mixpanel sharedInstance] track:@"SCN-QR"];
        [self processURI:text];
	}
#endif
}

- (void)showImagePicker
{
#if !TARGET_IPHONE_SIMULATOR
    [self stopQRReader];
    [self stopBLE];

    _readerPicker = [ZBarReaderController new];
    _readerPicker.readerDelegate = self;
    if ([ZBarReaderController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        _readerPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    [_readerPicker.scanner setSymbology:ZBAR_I25 config:ZBAR_CFG_ENABLE to:0];
    _readerPicker.showsHelpOnFail = NO;

    [self presentViewController:_readerPicker animated:YES completion:nil];

#endif
}

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

    for (int i = 0; i < [abcAccount.arrayWallets count]; i++)
    {
        // if this is not our currently selected wallet in the wallet selector
        // in other words, we can move funds from and to the same wallet
        if (abcAccount.currentWalletIndex != i)
        {
            ABCWallet *wallet = [abcAccount.arrayWallets objectAtIndex:i];

            BOOL bAddIt = bUseAll;
            if (!bAddIt)
            {
                // if we can find our current string within this wallet name
                if ([wallet.name rangeOfString:strCur options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
                    bAddIt = YES;
                }
            }

            if (bAddIt)
            {
                [arrayChoices addObject:[NSString stringWithFormat:@"%@ (%@)", wallet.name, [abcAccount.settings.denomination satoshiToBTCString:wallet.balance]]];
                [arrayChoicesIndexes addObject:[NSNumber numberWithInt:i]];
            }
        }

    }

    self.arrayChoicesIndexes = arrayChoicesIndexes;

    return arrayChoices;
}

#pragma mark - Flash Select Delegates

- (void)toggleFlash
{

    //ABCLog(2,@"Flash Item Selected: %i", flashType);
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
    [_readerView start];
    [self startQRReader];

    //[self startCameraScanner:nil];
	[_sendConfirmationViewController.view removeFromSuperview];
    [_sendConfirmationViewController removeFromParentViewController];
	_sendConfirmationViewController = nil;
	
    scanMode = SCAN_MODE_UNINITIALIZED;
    if ([LocalSettings controller].bDisableBLE == NO) {
        [self enableAll];
    }

    [self enableTableSelection];
    [MainViewController changeNavBarOwner:self];
    [self setupNavBar];
    [self updateViews:nil];
}

- (void)SSOViewControllerDone:(SSOViewController *)controller
{
    [_readerView start];
    [self startQRReader];
    
    //[self startCameraScanner:nil];
    [_ssoViewController.view removeFromSuperview];
    [_ssoViewController removeFromParentViewController];
    _ssoViewController = nil;
    
    scanMode = SCAN_MODE_UNINITIALIZED;
    if ([LocalSettings controller].bDisableBLE == NO) {
        [self enableAll];
    }
    
    [self enableTableSelection];
    [MainViewController changeNavBarOwner:self];
    [self setupNavBar];
    [self updateViews:nil];
}


#pragma mark - ButtonSelectorView2 delegates

- (void)ButtonSelector2:(ButtonSelectorView2 *)view selectedItem:(int)itemIndex
{
    NSIndexPath *indexPath = [[NSIndexPath alloc]init];
    indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [abcAccount makeCurrentWalletWithIndex:indexPath];
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

- (void)readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{
    [self processZBarResults:syms];
}

#if !TARGET_IPHONE_SIMULATOR

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)reader
{
    [reader dismissViewControllerAnimated:YES completion:nil];

    self.loopbackState = LoopbackState_Cancelled;

	//cw viewWillAppear will get called which will switch us back into BLE mode
}

- (void)imagePickerController:(UIImagePickerController *)reader didFinishPickingMediaWithInfo:(NSDictionary*) info
{
    id<NSFastEnumeration> results = [info objectForKey:ZBarReaderControllerResults];
    //UIImage *image = [info objectForKey: UIImagePickerControllerOriginalImage];

    self.zBarSymbolSet = (ZBarSymbolSet *) results;
    self.loopbackState = LoopbackState_Go;

    [reader dismissViewControllerAnimated:YES completion:nil];
}

- (void)readerControllerDidFailToRead:(ZBarReaderController*)reader
                            withRetry:(BOOL)retry
{
    [reader dismissViewControllerAnimated:YES completion:nil];
    self.loopbackState = LoopbackState_Scan_Failed;
}

#endif

- (void)processEdgeLogin:(NSString *)token
{
    [MainViewController fadingAlert:fetching_login_request holdTime:FADING_ALERT_HOLD_TIME_FOREVER_WITH_SPINNER notify:^{
        [abcAccount getEdgeLoginRequest:token callback:^(ABCError *error, ABCEdgeLoginInfo *info) {
            [MainViewController fadingAlertDismiss];
            if (!error)
            {
                [[Mixpanel sharedInstance] track:@"SCN-EdgeReq-Success"];
                [self showSSOViewController:nil edgeLoginRequest:info];
            }
            else
            {
                [[Mixpanel sharedInstance] track:@"SCN-EdgeReq-Invalid"];
                [MainViewController fadingAlert:@"Invalid Edge Login Request"];
                [self startQRReader];
            }
        }];
    }];
}

- (void)processURI:(NSString *)uriString;
{
    ABCError *error;
    
    [self stopQRReader];
    abcDebugLog(0, uriString);

    _parsedURI = [ABCUtil parseURI:uriString error:&error];
    if (!_parsedURI)
    {
        if ((uriString.length == 8) && [self isBase32:uriString])
        {
            [self processEdgeLogin:uriString];
            return;
        }
    }

    if (_parsedURI)
    {
        if (_parsedURI.bitIDURI)
        {
            [[Mixpanel sharedInstance] track:@"SCN-Bitid"];

            // Launch SSOViewController
            [self showSSOViewController:_parsedURI edgeLoginRequest:nil];


//            NSString *bitidRequestString = @"";
//            _bitidSParam = NO;
//
//            if (_parsedURI.bitidKYCProvider)
//            {
//                bitidRequestString = [NSString stringWithFormat:@"%@%@", bitidRequestString, provideIdentityTokenText];
//                _bitidSParam = YES;
//                _bitidProvidingKYCToken = YES;
//            }
//            else
//            {
//                _bitidProvidingKYCToken = NO;
//            }
//
//            if (_parsedURI.bitidKYCRequest)
//            {
//                _bitidSParam = YES;
//
//                _kycTokenKeys = [[NSMutableArray alloc] init];
//                [abcAccount.dataStore dataListKeys:@"Identities" keys:_kycTokenKeys];
//                if ([_kycTokenKeys count] > 0)
//                {
//                    bitidRequestString = [NSString stringWithFormat:@"%@%@", bitidRequestString, requestYourIdentityToken];
//                }
//                else
//                {
//                    bitidRequestString = [NSString stringWithFormat:@"%@%@", bitidRequestString, requestYourIdentityTokenButNone];
//                    _kycTokenKeys = nil;
//                }
//            }
//            else
//            {
//                _kycTokenKeys = nil;
//            }
//
//            if (_parsedURI.bitidPaymentAddress)
//            {
//                bitidRequestString = [NSString stringWithFormat:@"%@%@", bitidRequestString, requestPaymentAddress];
//                _bitidSParam = YES;
//            }
//
//            NSString *message = _parsedURI.bitIDDomain;
//
//            if (_bitidSParam)
//            {
//                message = [NSString stringWithFormat:@"%@\n%@\n\n%@", message, wouldLikeToColon, bitidRequestString];
//            }
//
//            if (_parsedURI.bitidKYCRequest)
//            {
//                if (_kycTokenKeys)
//                {
//                    int count = (int)[_kycTokenKeys count];
//
//                    if (count == 1)
//                    {
//
//                        _bitidAlert = [[UIAlertView alloc]
//                                       initWithTitle:bitIDLogin
//                                       message:message
//                                       delegate:self
//                                       cancelButtonTitle:noButtonText
//                                       otherButtonTitles:[NSString stringWithFormat:@"Use ID token [%@]",  _kycTokenKeys[0]],nil];
//                    }
//                    else if (count == 2)
//                    {
//                        _bitidAlert = [[UIAlertView alloc]
//                                       initWithTitle:bitIDLogin
//                                       message:message
//                                       delegate:self
//                                       cancelButtonTitle:noButtonText
//                                       otherButtonTitles:[NSString stringWithFormat:@"Use ID token [%@]", _kycTokenKeys[0]],
//                                       [NSString stringWithFormat:@"Use ID token [%@]", _kycTokenKeys[1]],
//                                       nil];
//
//                    }
//                    else
//                    {
//                        // Only support a max of 3 tokens for now
//                        _bitidAlert = [[UIAlertView alloc]
//                                       initWithTitle:bitIDLogin
//                                       message:message
//                                       delegate:self
//                                       cancelButtonTitle:noButtonText
//                                       otherButtonTitles:[NSString stringWithFormat:@"Use ID token [%@]", _kycTokenKeys[0]],
//                                       [NSString stringWithFormat:@"Use ID token [%@]", _kycTokenKeys[1]],
//                                       [NSString stringWithFormat:@"Use ID token [%@]", _kycTokenKeys[2]],
//                                       nil];
//                    }
//
//                }
//                else
//                {
//                    _bitidAlert = [[UIAlertView alloc]
//                                   initWithTitle:bitIDLogin
//                                   message:message
//                                   delegate:self
//                                   cancelButtonTitle:cancelButtonText
//                                   otherButtonTitles:nil];
//                }
//
//            }
//            else
//            {
//                _bitidAlert = [[UIAlertView alloc]
//                               initWithTitle:bitIDLogin
//                               message:message
//                               delegate:self
//                               cancelButtonTitle:noButtonText
//                               otherButtonTitles:yesButtonText,nil];
//
//            }
//            [_bitidAlert show];
            return;
        }
        else if (_parsedURI.privateKey)
        {
            [[Mixpanel sharedInstance] track:@"SCN-PrivKey"];
            // We can either fund the private key using it's address or ask the user if they want it swept
            _privateKeyAlert = [[UIAlertView alloc]
                                initWithTitle:bitcoinPrivateKeyText
                                message:_parsedURI.address
                                delegate:self
                                cancelButtonTitle:cancelButtonText
                                otherButtonTitles:importFunds,sendFundsToPrivateKey,nil];
            [_privateKeyAlert show];
            _privateKeyURI = uriString;
            return;
        }
        else if (_parsedURI.address || _parsedURI.paymentRequestURL)
        {
            [self doProcessParsedURI:_parsedURI];
            return;
        }
    }
    else
    {
        NSURL *uri = [NSURL URLWithString:uriString];
        NSString *vendorRetString = [NSString stringWithFormat:@"%@-ret", [MainViewController Singleton].appUrlPrefix];
        
        if ([uri.scheme isEqualToString:@"bitcoin-ret"] ||
            [uri.scheme isEqualToString:@"airbitz"] ||
            [uri.scheme isEqualToString:vendorRetString] ||
            [uri.scheme isEqualToString:[MainViewController Singleton].appUrlPrefix] ||
            [uri.host isEqualToString:@"x-callback-url"]) {
            if ([User isLoggedIn]) {
                [self stopQRReader];
                if ([uri.path containsString:@"edgelogin"])
                {
                    NSString *token = uri.lastPathComponent;
                    [self processEdgeLogin:token];
                    return;
                }
                else if ([uri.host isEqualToString:@"edge"])
                {
                    NSString *token = uri.lastPathComponent;
                    [self processEdgeLogin:token];
                    return;
                }
                else
                {
                    
                    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
                    _addressRequestController = [mainStoryboard instantiateViewControllerWithIdentifier:@"AddressRequestController"];
                    _addressRequestController.url = uri;
                    _addressRequestController.delegate = self;
                    
                    [MainViewController animateView:_addressRequestController withBlur:YES];
                    [MainViewController showTabBarAnimated:YES];
                    [MainViewController showNavBarAnimated:YES];
                    return;
                }
            }
        }
    }
    
    // Did not get successfully processed. Throw error
    [MainViewController fadingAlert:invalidQRCode holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
    [self startQRReader];
}

- (BOOL) isBase32:(NSString *)string
{
    NSError *error;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^[A-Z2-7]$" options:0 error:&error];
    NSArray* matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    return !!matches;
}

-(void)AddressRequestControllerDone:(AddressRequestController *)vc
{
    [MainViewController animateOut:vc withBlur:NO complete:^(void) {
        _addressRequestController = nil;
        [MainViewController changeNavBarOwner:self];
        [self setupNavBar];
        [self updateViews:nil];
        [self startQRReader];
    }];
    
}


- (void)doProcessParsedURI:(ABCParsedURI *)parsedURI
{
    [self doProcessParsedURI:parsedURI numRecursions:0];
}

- (void)doProcessParsedURI:(ABCParsedURI *)parsedURI numRecursions:(int) numRecursions;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (numRecursions)
        {
            [NSThread sleepForTimeInterval:0.5f];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (abcAccount.currentWallet.loaded != YES)
            {
                // If the current wallet isn't loaded, callback into doProcessParsedURI and sleep
                ABCLog(1,@"Waiting for wallet to load: %@", abcAccount.currentWallet.name);
                
                if (numRecursions < 2)
                    [MainViewController fadingAlert:loadingWalletsText
                                           holdTime:FADING_ALERT_HOLD_TIME_FOREVER_WITH_SPINNER];

                [self doProcessParsedURI:parsedURI numRecursions:(numRecursions+1)];
                return;
            }
            
            if (parsedURI)
            {
                if (parsedURI.paymentRequestURL)
                {
                    [[Mixpanel sharedInstance] track:@"SCN-BIP70"];
                    [self stopQRReader];
                    [MainViewController fadingAlert:fetchingPaymentRequestText holdTime:FADING_ALERT_HOLD_TIME_DEFAULT notify:^{
                        ABCError *error = nil;
                        ABCPaymentRequest *paymentRequest = [parsedURI getPaymentRequest:&error];
                        
                        if (!error)
                        {
                            [self showSendConfirmationTo:parsedURI destWallet:nil paymentRequest:paymentRequest];
                            [MainViewController fadingAlertDismiss];
                        }
                        else
                        {
                            if (parsedURI.address)
                                [self processPubAddress:parsedURI];
                            NSString *errorString = [NSString stringWithFormat:@"%@\n\n%@",
                                                     error.userInfo[NSLocalizedDescriptionKey],
                                                     error.userInfo[NSLocalizedFailureReasonErrorKey]];
                            [MainViewController fadingAlert:errorString];
                            [self startQRReader];
                        }
                    }];
                    
                }
                else if (parsedURI.address)
                {
                    [[Mixpanel sharedInstance] track:@"SCN-Addr"];
                    [self processPubAddress:parsedURI];
                }
            }
            else
            {
                [[Mixpanel sharedInstance] track:@"SCN-Invalid"];
                [MainViewController fadingAlert:invalidAddressPopupText];
            }
        });
    });
}

- (void)processPubAddress:(ABCParsedURI *)parsedURI
{
    [MainViewController fadingAlert:validatingAddressText
                           holdTime:FADING_ALERT_HOLD_TIME_FOREVER_WITH_SPINNER];
    [self stopQRReader];
    [self showSendConfirmationTo:parsedURI destWallet:nil paymentRequest:nil];
    [MainViewController fadingAlertDismiss];
}

- (void)PopupPickerView2Cancelled:(PopupPickerView2 *)view userData:(id)data
{
    // dismiss the picker
    [view removeFromSuperview];
}

- (void)PopupPickerView2Selected:(PopupPickerView2 *)view onRow:(NSInteger)row userData:(id)data
{
    // set the text field to the choice
    NSInteger index = [[self.arrayChoicesIndexes objectAtIndex:row] integerValue];
    if (index >= 0)
    {
        ABCWallet *wallet = [abcAccount.arrayWallets objectAtIndex:index];

        if (wallet)
        {
            [self stopQRReader];
            [self showSendConfirmationTo:nil destWallet:wallet paymentRequest:nil];
        }
    }
    [view dismiss];

}

- (void)updateState
{
    if (nil == _tweetAlert && nil == _sweptAlert)
    {
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
        [self startQRReader];
    }];
    [self presentViewController:slComposerSheet animated:YES completion:nil];
}

- (void)tweetCancelled
{
    [MainViewController fadingAlert:importAgainToRetryTwitter];
}

- (void)showHbitsResults:(NSString *)address amount:(uint64_t) amount
{
    // make a query with the last bytes of the address
    const int hBitzIDLength = 4;
    if (nil != address && hBitzIDLength <= address.length)
    {
        NSString *hiddenBitzID = [address substringFromIndex:[address length]-hBitzIDLength];
        NSString *hiddenBitzURI = [NSString stringWithFormat:@"%@%@%@", SERVER_API, @"/hiddenbits/", hiddenBitzID];
        
        [self.afmanager GET:hiddenBitzURI parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *results = (NSDictionary *)responseObject;
            
            if (results)
            {
                NSString *token = [results objectForKey:@"token"];
                _tweet = [results objectForKey:@"tweet"];
                if (token && _tweet)
                {
                    if (0 == amount)
                    {
                        NSString *zmessage = [results objectForKey:@"zero_message"];
                        if (zmessage)
                        {
                            _tweetAlert = [[UIAlertView alloc]
                                           initWithTitle:sorryText
                                           message:zmessage
                                           delegate:self
                                           cancelButtonTitle:noButtonText
                                           otherButtonTitles:okButtonText, nil];
                            [_tweetAlert show];
                        }
                    }
                    else
                    {
                        NSString *message = [results objectForKey:@"message"];
                        if (message)
                        {
                            _tweetAlert = [[UIAlertView alloc]
                                           initWithTitle:congratulationsText
                                           message:message
                                           delegate:self
                                           cancelButtonTitle:noButtonText
                                           otherButtonTitles:okButtonText, nil];
                            [_tweetAlert show];
                        }
                    }
                }
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            ABCLog(1, @"*** ERROR Connecting to Network: showHbitsResults");
            NSString *message;
            if (amount == 0)
                message = importFailedPrivateKeyEmpty;
            else
                message = messenger_server_error_funds_imported;
            
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:network_error_text
                                  message:message
                                  delegate:nil
                                  cancelButtonTitle:okButtonText
                                  otherButtonTitles:nil];
            [alert show];
        }];
    }
}

#pragma mark - AlertView delegate

@end

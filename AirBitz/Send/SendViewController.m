//
//  SendViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
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

#define WALLET_BUTTON_WIDTH         210

#define POPUP_PICKER_LOWEST_POINT   360
#define POPUP_PICKER_TABLE_HEIGHT   (IS_IPHONE5 ? 180 : 90)

@interface SendViewController () <SendConfirmationViewControllerDelegate, FlashSelectViewDelegate, UITextFieldDelegate, ButtonSelectorDelegate, ZBarReaderDelegate, ZBarReaderViewDelegate, PickerTextViewDelegate, SyncViewDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>
{
	ZBarReaderView                  *_readerView;
    ZBarReaderController            *_readerPicker;
	NSTimer                         *_startScannerTimer;
	int                             _selectedWalletIndex;
	SendConfirmationViewController  *_sendConfirmationViewController;
    BOOL                            _bUsingImagePicker;
	SyncView                        *_syncingView;
	NSTimeInterval					lastUpdateTime;	//used to remove BLE devices from table when they're no longer around
	NSTimer							*peripheralCleanupTimer; //used to remove BLE devices from table when they're no longer around
}
@property (weak, nonatomic) IBOutlet UIImageView            *scanFrame;
@property (weak, nonatomic) IBOutlet FlashSelectView        *flashSelector;
@property (nonatomic, weak) IBOutlet ButtonSelectorView     *buttonSelector;
@property (weak, nonatomic) IBOutlet UIImageView            *imageTopFrame;
@property (weak, nonatomic) IBOutlet UILabel                *labelSendTo;
@property (weak, nonatomic) IBOutlet UIImageView            *imageSendTo;
@property (weak, nonatomic) IBOutlet UIImageView            *imageFlashFrame;
@property (weak, nonatomic) IBOutlet UIView					*bleView;
@property (weak, nonatomic) IBOutlet UIView					*qrView;
@property (nonatomic, weak)	IBOutlet UITableView			*tableView;

@property (nonatomic, strong) NSArray   *arrayWallets;
@property (nonatomic, strong) NSArray   *arrayWalletNames;
@property (nonatomic, strong) NSArray   *arrayChoicesIndexes;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *scanningSpinner;
@property (nonatomic, weak) IBOutlet UILabel				*scanningLabel;

@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;
@property (strong, nonatomic) NSMutableData         *data;
@property (strong, nonatomic)  NSMutableArray		*peripheralContainers;

@end

@implementation PeripheralContainer
@end

@implementation SendViewController

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

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:nil];

    [self updateDisplayLayout];

    _bUsingImagePicker = NO;
	
	self.flashSelector.delegate = self;
	self.buttonSelector.delegate = self;

    // set up the specifics on our picker text view
    self.pickerTextSendTo.textField.borderStyle = UITextBorderStyleNone;
    self.pickerTextSendTo.textField.backgroundColor = [UIColor clearColor];
    self.pickerTextSendTo.textField.font = [UIFont systemFontOfSize:14];
    self.pickerTextSendTo.textField.clearButtonMode = UITextFieldViewModeNever;
    self.pickerTextSendTo.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.pickerTextSendTo.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.pickerTextSendTo.textField.spellCheckingType = UITextSpellCheckingTypeNo;
    self.pickerTextSendTo.textField.textColor = [UIColor whiteColor];
    self.pickerTextSendTo.textField.returnKeyType = UIReturnKeyDone;
    self.pickerTextSendTo.textField.tintColor = [UIColor whiteColor];
    self.pickerTextSendTo.textField.textAlignment = NSTextAlignmentCenter;
    self.pickerTextSendTo.textField.placeholder = NSLocalizedString(@"Bitcoin address or wallet", nil);
    self.pickerTextSendTo.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.pickerTextSendTo.textField.placeholder
                                                                                            attributes:@{NSForegroundColorAttributeName: [UIColor lightTextColor]}];
    [self.pickerTextSendTo setTopMostView:self.view];
    //self.pickerTextSendTo.pickerMaxChoicesVisible = PICKER_MAX_CELLS_VISIBLE;
    self.pickerTextSendTo.cropPointBottom = POPUP_PICKER_LOWEST_POINT;
    self.pickerTextSendTo.delegate = self;

	self.buttonSelector.textLabel.text = NSLocalizedString(@"From:", @"From: text on Send Bitcoin screen");
    [self.buttonSelector setButtonWidth:WALLET_BUTTON_WIDTH];

    _selectedWalletIndex = 0;
	
	// Start up the CBCentralManager
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    // And somewhere to store the incoming data
    _data = [[NSMutableData alloc] init];
	
	
}

- (void)viewWillAppear:(BOOL)animated
{
	[self loadWalletInfo];
	[self syncTest];
	self.peripheralContainers = nil;
	/* cw
    if (_bUsingImagePicker == NO && !_syncingView)
    {
        _startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];

        [self.flashSelector selectItem:FLASH_ITEM_OFF];
    }
	*/
	//default to BLE view
	self.bleView.hidden = NO;
	self.qrView.hidden = YES;
	[self startBLE];
}

- (void)viewWillDisappear:(BOOL)animated
{
	//cw [_startScannerTimer invalidate];
	//cw _startScannerTimer = nil;
	
	[self closeCameraScanner];
	
	// Don't keep it going while we're not showing.
    [self stopBLE];
	
    NSLog(@"Scanning stopped");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark - Action Methods

- (IBAction)scanQRCode
{
#if !TARGET_IPHONE_SIMULATOR
    // NSLog(@"Scanning...");
	
	[self stopBLE];
	
	_readerView = [ZBarReaderView new];
	[self.qrView insertSubview:_readerView belowSubview:self.scanFrame];
	_readerView.frame = self.scanFrame.frame;
	_readerView.readerDelegate = self;
	_readerView.tracksSymbols = NO;
	
	_readerView.tag = 99999999;
	if ([self.pickerTextSendTo.textField.text length])
	{
		_readerView.alpha = 0.0;
	}
	[_readerView start];
	[self flashItemSelected:FLASH_ITEM_OFF];
	
	self.bleView.hidden = YES;
	self.qrView.hidden = NO;
#endif
}

- (IBAction)info
{
	[self.view endEditing:YES];
    [self resignAllResonders];
    [InfoView CreateWithHTML:@"infoSend" forView:self.view];
}

- (IBAction)buttonCameraTouched:(id)sender
{
    [self resignAllResonders];
    [self showImageScanner];
}

#pragma mark - BLE Central Methods

-(void)startBLE
{
	[self scan];
	//kick off peripheral cleanup timer (removes peripherals from table when they're no longer in range)
	peripheralCleanupTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(cleanupPeripherals:) userInfo:nil repeats:YES];
}

-(void)stopBLE
{
	[self.centralManager stopScan];
	NSLog(@"Getting rid of timer");
	[peripheralCleanupTimer invalidate];
}

/** centralManagerDidUpdateState is a required protocol method.
 *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
 *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
 *  the Central is ready to be used.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn)
	{
        // In a real app, you'd deal with all the states correctly
        return;
    }
    
    // The state must be CBCentralManagerStatePoweredOn...
	
    // ... so start scanning
    [self scan];
    
}


/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
- (void)scan
{
	self.peripheralContainers = nil;
    //[self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
	[self.centralManager scanForPeripheralsWithServices:nil options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    
    NSLog(@"Scanning started");
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
		lastUpdateTime = newUpdateTime;
		[self updateTable];
	}
    
    //NSLog(@"Discovered %@ at %@ with adv data: %@", peripheral.name, RSSI, advertisementData);
    
    // Ok, it's in range - have we already seen it?
	/* if (self.discoveredPeripheral != peripheral)
	 {
	 
	 // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
	 self.discoveredPeripheral = peripheral;
	 
	 // And connect
	 NSLog(@"Connecting to peripheral %@", peripheral);
	 [self.centralManager connectPeripheral:peripheral options:nil];
	 }*/
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
    NSLog(@"Peripheral Connected");
    
    // Stop scanning
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
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


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
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
        
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
		{
			
            // If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
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
    
    // Have we got everything we need?
    if ([stringFromData isEqualToString:@"EOM"])
	{
        // We have, process the data,
		NSString *stringFromRequestor = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
		NSArray *components = [stringFromRequestor componentsSeparatedByString:@"."];
		//first component is address
		//second component is amount in Satoshi
		
		//NSLog(@"############## Address: %@",[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]);
//cw        [self.receivedAddressLabel setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
        
        // Cancel our subscription to the characteristic
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        // and disconnect from the peripehral
        [self.centralManager cancelPeripheralConnection:peripheral];
		
		//show the results
		NSLog(@"Address: %@", [components objectAtIndex:0]);
		NSLog(@"Amount Satoshi: %@", [components objectAtIndex:1]);
		
		[self showSendConfirmationTo:[components objectAtIndex:0] amount:[[components objectAtIndex:1] integerValue] nameLabel:nil toIsUUID:NO];
	}
	
    // Otherwise, just add the data on to what we already have
    [self.data appendData:characteristic.value];
    
    // Log it
    NSLog(@"Received: %@", stringFromData);
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
    
    // Notification has started
    if (characteristic.isNotifying)
	{
        NSLog(@"Notification began on %@", characteristic);
    }
    
    // Notification has stopped
    else
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
    NSLog(@"Did disconnect because: %@", error.description);
	self.peripheralContainers = nil;
    self.discoveredPeripheral = nil;
    
    // We're disconnected, so start scanning again
    [self scan];
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
	if(self.peripheralContainers.count == 0)
	{
		self.scanningLabel.hidden = NO;
		[self.scanningSpinner startAnimating];
	}
	else
	{
		self.scanningLabel.hidden = YES;
		[self.scanningSpinner stopAnimating];
	}
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
	
	scanCell.contactImage.image = [UIImage imageNamed:@"BLE_photo.png"];
	
	NSString *advData = [pc.advertisingData objectForKey:CBAdvertisementDataLocalNameKey];
	if(advData.length >= 10)
	{
		scanCell.contactBitcoinAddress.text = [advData substringToIndex:10];
		if(advData.length > 10)
		{
			scanCell.contactName.text = [advData substringFromIndex:10];
		}
	}
	
	return scanCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 47.0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	//lastSelectedRow = indexPath.row;
	//
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	NSLog(@"Selecting row: %li", (long)indexPath.row);
	
	//cell.textLabel.font = [UIFont fontWithName:@"Stratum2-Bold" size:21.0];
	//cell.textLabel.textColor = [UIColor whiteColor];
	//cell.backgroundColor = BLUE_HIGHLIGHT;
	//cell.contentView.backgroundColor = BLUE_HIGHLIGHT;
	
	//
	
	//attempt to connect to this peripheral
	//[self.sensor cancelScanningForPeripherals];
	PeripheralContainer *pc = [self.peripheralContainers objectAtIndex:indexPath.row];
	
	/*if ([pc.peripheral.name rangeOfString:@"BrainStation"].location != NSNotFound)
	 {
	 NSData *manufData = [pc.advertisingData objectForKey:@"kCBAdvDataManufacturerData"];
	 NSRange snRange = {3, 4};
	 [manufData getBytes:&serialNumber range:snRange];
	 self.sensorName = pc.peripheral.name;
	 [self.sensor connectPeripheral:pc.peripheral];
	 NSLog(@"Connecting to %@\n", pc.peripheral.name);
	 }
	 else
	 {
	 NSLog(@"Peripheral not a BrainStation (it was a %@) or callback was not because of a ScanResponse\n", pc.peripheral.name);
	 [self.sensor.CM cancelPeripheralConnection:pc.peripheral];
	 }*/
	
	// Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
	self.discoveredPeripheral = pc.peripheral;
	
	// And connect
	NSLog(@"Connecting to peripheral %@", pc.peripheral);
	[self.centralManager connectPeripheral:pc.peripheral options:nil];
}

#pragma mark - Misc Methods

- (void)resignAllResonders
{
    [self.pickerTextSendTo.textField resignFirstResponder];
}

- (void)updateDisplayLayout
{
    // if we are on a smaller screen
    if (!IS_IPHONE5)
    {
        // be prepared! lots and lots of magic numbers here to jam the controls to fit on a small screen

        CGRect frame;

        /*
        // put the flash view at the bottom
        frame = self.imageFlashFrame.frame;
        frame.size.height = 60;
        frame.origin.y = self.view.frame.size.height - frame.size.height + 0.0;
        self.imageFlashFrame.frame = frame;

        frame = self.flashSelector.frame;
        frame.origin.y = self.imageFlashFrame.frame.origin.y + 8.0;
        frame.size.height = 48.0;
        self.flashSelector.frame = frame;
*/
        // put the scan frame bottom right to the top of the flash frame
        frame = self.scanFrame.frame;
        frame.size.height = 275;
        self.scanFrame.frame = frame;
    }
}

- (void)loadWalletInfo
{
    // load all the non-archive wallets
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWallets:arrayWallets archived:nil];

    // create the arrays of wallet info
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
        
        self.buttonSelector.arrayItemsToSelect = [arrayWalletNames copy];
        [self.buttonSelector.button setTitle:wallet.strName forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = (int) _selectedWalletIndex;
    }
    self.arrayWallets = arrayWallets;
    self.arrayWalletNames = arrayWalletNames;
}

// if bToIsUUID NO, then it is assumed the strTo is an address
- (void)showSendConfirmationTo:(NSString *)strTo amount:(long long)amount nameLabel:(NSString *)nameLabel toIsUUID:(BOOL)bToIsUUID
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_sendConfirmationViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendConfirmationViewController"];

	_sendConfirmationViewController.delegate = self;
	_sendConfirmationViewController.sendToAddress = strTo;
    _sendConfirmationViewController.bAddressIsWalletUUID = bToIsUUID;
	_sendConfirmationViewController.amountToSendSatoshi = amount;
    _sendConfirmationViewController.wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
    if (bToIsUUID)
    {
        Wallet *destWallet = [CoreBridge getWallet:strTo];
        _sendConfirmationViewController.destWallet = destWallet;
        _sendConfirmationViewController.sendToAddress = destWallet.strName;
    }
	_sendConfirmationViewController.selectedWalletIndex = _selectedWalletIndex;
	_sendConfirmationViewController.nameLabel = nameLabel;

    NSLog(@"Sending to: %@, isUUID: %@, wallet: %@", _sendConfirmationViewController.sendToAddress, (_sendConfirmationViewController.bAddressIsWalletUUID ? @"YES" : @"NO"), _sendConfirmationViewController.wallet.strName);
	
	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
	_sendConfirmationViewController.view.frame = frame;
	[self.view addSubview:_sendConfirmationViewController.view];
	
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 _sendConfirmationViewController.view.frame = self.view.bounds;
	 }
	 completion:^(BOOL finished)
	 {
	 }];
}

- (BOOL)processZBarResults:(ZBarSymbolSet *)syms
{
    BOOL bSuccess = YES;

	for(ZBarSymbol *sym in syms)
	{
		NSString *text = (NSString *)sym.data;

		tABC_Error Error;
		tABC_BitcoinURIInfo *uri;
		ABC_ParseBitcoinURI([text UTF8String], &uri, &Error);
		[Util printABC_Error:&Error];

		if (uri != NULL)
		{
			if (uri->szAddress)
			{
				printf("    address: %s\n", uri->szAddress);

				printf("    amount: %lld\n", uri->amountSatoshi);

				NSString *label;
				if (uri->szLabel)
				{
					printf("    label: %s\n", uri->szLabel);
					label = [NSString stringWithUTF8String:uri->szLabel];
				}
				else
				{
					label = @"";
				}
				if (uri->szMessage)
				{
                    printf("    message: %s\n", uri->szMessage);
				}
                bSuccess = YES;
                [self showSendConfirmationTo:[NSString stringWithUTF8String:uri->szAddress] amount:uri->amountSatoshi nameLabel:label toIsUUID:NO];
			}
			else
			{
				printf("No address!");
                bSuccess = NO;
			}
		}
		else
		{
			printf("URI parse failed!");
            bSuccess = NO;
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

		ABC_FreeURIInfo(uri);
        
		break; //just grab first one
	}

    return bSuccess;
}

- (void)showImageScanner
{
#if !TARGET_IPHONE_SIMULATOR
    [self closeCameraScanner];

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
    //[self presentModalViewController:_readerPicker animated: YES];
#endif
}

- (void)startCameraScanner:(NSTimer *)timer
{
    [self closeCameraScanner];

#if !TARGET_IPHONE_SIMULATOR
    // NSLog(@"Scanning...");

	_readerView = [ZBarReaderView new];
	[self.view insertSubview:_readerView belowSubview:self.scanFrame];
	_readerView.frame = self.scanFrame.frame;
	_readerView.readerDelegate = self;
	_readerView.tracksSymbols = NO;

	_readerView.tag = 99999999;
	if ([self.pickerTextSendTo.textField.text length])
	{
		_readerView.alpha = 0.0;
	}
	[_readerView start];
	[self flashItemSelected:FLASH_ITEM_OFF];
#endif
}

- (void)closeCameraScanner
{
    if (_readerView)
    {
        [_readerView stop];
        [_readerView removeFromSuperview];
        _readerView = nil;
    }
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

    for (int i = 0; i < [self.arrayWallets count]; i++)
    {
        // if this is not our currently selected wallet in the wallet selector
        // in other words, we can move funds from and to the same wallet
        if (_selectedWalletIndex != i)
        {
            Wallet *wallet = [self.arrayWallets objectAtIndex:i];

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

    self.arrayChoicesIndexes = arrayChoicesIndexes;

    return arrayChoices;
}

#pragma mark - Flash Select Delegates

- (void)flashItemSelected:(tFlashItem)flashType
{
	//NSLog(@"Flash Item Selected: %i", flashType);
	AVCaptureDevice *device = _readerView.device;
	if(device)
	{
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
						}
					}
					break;
		}
	}
}

#pragma mark - SendConfirmationViewController Delegates

- (void)sendConfirmationViewControllerDidFinish:(SendConfirmationViewController *)controller
{
    [self loadWalletInfo];
	self.pickerTextSendTo.textField.text = @"";
    //[self startCameraScanner:nil];
	[_sendConfirmationViewController.view removeFromSuperview];
	_sendConfirmationViewController = nil;
	
	self.bleView.hidden = NO;
	self.qrView.hidden = YES;
}

#pragma mark - ButtonSelectorView delegates

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
    _selectedWalletIndex = itemIndex;
    Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
    [self.buttonSelector.button setTitle:wallet.strName forState:UIControlStateNormal];
    self.buttonSelector.selectedItemIndex = _selectedWalletIndex;
    _walletUUID = wallet.strUUID;
}

- (void)ButtonSelectorWillShowTable:(ButtonSelectorView *)view
{
    [self resignAllResonders];
}

- (void)ButtonSelectorWillHideTable:(ButtonSelectorView *)view
{

}

#pragma mark - ZBar's Delegate methods

- (void)readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{
    if ([self processZBarResults:syms])
    {
        [view stop];
    }
    else
    {
        [view start];
    }
}

#if !TARGET_IPHONE_SIMULATOR

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)reader
{
    [reader dismissViewControllerAnimated:YES completion:nil];
    _bUsingImagePicker = NO;
    _startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];
}

- (void)imagePickerController:(UIImagePickerController *)reader didFinishPickingMediaWithInfo:(NSDictionary*) info
{
    id<NSFastEnumeration> results = [info objectForKey:ZBarReaderControllerResults];
    //UIImage *image = [info objectForKey: UIImagePickerControllerOriginalImage];

    BOOL bSuccess = [self processZBarResults:(ZBarSymbolSet *)results];

    [reader dismissViewControllerAnimated:YES completion:nil];
    //[[controller presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    //[reader dismissModalViewControllerAnimated: YES];

    _bUsingImagePicker = NO;

    if (!bSuccess)
    {
        _startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];
    }
}

- (void)readerControllerDidFailToRead:(ZBarReaderController*)reader
                            withRetry:(BOOL)retry
{
    [reader dismissViewControllerAnimated:YES completion:nil];

    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"QR Code Scan Failure", nil)
                          message:NSLocalizedString(@"Unable to scan QR code", nil)
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];

    _bUsingImagePicker = NO;
    _startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];
}

#endif

#pragma mark - PickerTextView Delegates

- (void)pickerTextViewFieldDidChange:(PickerTextView *)pickerTextView
{
    NSArray *arrayChoices = [self createNewSendToChoices:pickerTextView.textField.text];

    [pickerTextView updateChoices:arrayChoices];
}

- (void)pickerTextViewFieldDidBeginEditing:(PickerTextView *)pickerTextView
{
    NSArray *arrayChoices = [self createNewSendToChoices:pickerTextView.textField.text];

    [pickerTextView updateChoices:arrayChoices];
}

- (BOOL)pickerTextViewShouldEndEditing:(PickerTextView *)pickerTextView
{
    // unhighlight text
    // note: for some reason, if we don't do this, the text won't select next time the user selects it
    [pickerTextView.textField setSelectedTextRange:[pickerTextView.textField textRangeFromPosition:pickerTextView.textField.beginningOfDocument toPosition:pickerTextView.textField.beginningOfDocument]];

    return YES;
}

- (void)pickerTextViewFieldDidEndEditing:(PickerTextView *)pickerTextView
{
    //[self forceCategoryFieldValue:pickerTextView.textField forPickerView:pickerTextView];
}

- (BOOL)pickerTextViewFieldShouldReturn:(PickerTextView *)pickerTextView
{
	[pickerTextView.textField resignFirstResponder];
    [self processURI];
    return YES;
}

- (void)processURI
{
    BOOL bSuccess = YES;
    tABC_BitcoinURIInfo *uri = NULL;

    if (_pickerTextSendTo.textField.text.length)
	{
        BOOL bIsUUID = NO;
        
        
        NSString *label;
        NSString *strTo = _pickerTextSendTo.textField.text;

        // see if the text corresponds to one of the wallets
        NSInteger index = [self.arrayWalletNames indexOfObject:_pickerTextSendTo.textField.text];
        if (index != NSNotFound)
        {
            bIsUUID = YES;
            Wallet *wallet = [self.arrayWallets objectAtIndex:index];
            //NSLog(@"using UUID for wallet: %@", wallet.strName);
            strTo = wallet.strUUID;

            [self closeCameraScanner];
            [self showSendConfirmationTo:strTo amount:0.0 nameLabel:@"" toIsUUID:bIsUUID];

        }
        else
        {
            tABC_Error Error;
            ABC_ParseBitcoinURI([strTo UTF8String], &uri, &Error);
            [Util printABC_Error:&Error];
            
            if (uri != NULL)
            {
                if (uri->szAddress)
                {
                    printf("    address: %s\n", uri->szAddress);
                    
                    printf("    amount: %lld\n", uri->amountSatoshi);
                    
                    if (uri->szLabel)
                    {
                        printf("    label: %s\n", uri->szLabel);
                        label = [NSString stringWithUTF8String:uri->szLabel];
                    }
                    else
                    {
                        label = NSLocalizedString(@"", nil);
                    }
                    if (uri->szMessage)
                    {
                        printf("    message: %s\n", uri->szMessage);
                    }
                }
                else
                {
                    printf("No address!");
                    bSuccess = NO;
                }
            }
            else
            {
                printf("URI parse failed!");
                bSuccess = NO;
            }
            
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
            [self closeCameraScanner];
            [self showSendConfirmationTo:[NSString stringWithUTF8String:uri->szAddress] amount:uri->amountSatoshi nameLabel:label toIsUUID:NO];
        }
	}

    if (uri)
    {
        ABC_FreeURIInfo(uri);
    }
}

- (void)pickerTextViewPopupSelected:(PickerTextView *)pickerTextView onRow:(NSInteger)row
{
    // set the text field to the choice
    NSInteger index = [[self.arrayChoicesIndexes objectAtIndex:row] integerValue];
    Wallet *wallet = [self.arrayWallets objectAtIndex:index];
    pickerTextView.textField.text = wallet.strName;
	[pickerTextView.textField resignFirstResponder];

    if (pickerTextView.textField.text.length)
	{
        [self closeCameraScanner];
        //NSLog(@"using UUID for wallet: %@", wallet.strName);
		[self showSendConfirmationTo:wallet.strUUID amount:0.0 nameLabel:@"" toIsUUID:YES];
	}
}

- (void)pickerTextViewFieldDidShowPopup:(PickerTextView *)pickerTextView
{
    // forces the size of the popup picker on the picker text view to a certain size

    // Note: we have to do this because right now the size will start as max needed but as we dynamically
    //       alter the choices, we may end up with more choices than we originally started with
    //       so we want the table to always be as large as it can be

    // first start the popup pickerit right under the control and squished down
    CGRect frame = pickerTextView.popupPicker.frame;
    frame.size.height = POPUP_PICKER_TABLE_HEIGHT;
    pickerTextView.popupPicker.frame = frame;
}

#pragma - Sync View methods

- (void)SyncViewDismissed:(SyncView *)sv
{
    [_syncingView removeFromSuperview];
    _syncingView = nil;

    //cw _startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];
}

- (void)syncTest
{
    Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
    if (![CoreBridge watcherIsReady:wallet.strUUID] && !_syncingView)
    {
        _syncingView = [SyncView createView:self.view forWallet:wallet.strUUID];
        _syncingView.delegate = self;
    }
    if (_syncingView)
    {
        [self resignAllResonders];
        [self closeCameraScanner];
    }
}


@end

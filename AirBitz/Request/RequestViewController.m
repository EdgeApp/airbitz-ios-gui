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
#import <CoreBluetooth/CoreBluetooth.h>
#import "DDData.h"
#import "RequestViewController.h"
#import "Notifications.h"
#import "Transaction.h"
#import "TxOutput.h"
#import "CalculatorView.h"
#import "ButtonSelectorView2.h"
#import "ABC.h"
#import "User.h"
#import "ShowWalletQRViewController.h"
#import "CoreBridge.h"
#import "Util.h"
#import "ImportWalletViewController.h"
#import "InfoView.h"
#import "LocalSettings.h"
#import "MainViewController.h"
#import "Theme.h"
#import "FadingAlertView2.h"
#import "Contact.h"
#import "TransferService.h"
#import "AudioController.h"
#import "RecipientViewController.h"
#import "DropDownAlertView.h"


#define QR_CODE_TEMP_FILENAME @"qr_request.png"
#define QR_CODE_SIZE          200.0
#define QR_ATTACHMENT_WIDTH 100



#define WALLET_REQUEST_BUTTON_WIDTH  200

#define OPERATION_CLEAR		0
#define OPERATION_BACK		1
#define OPERATION_DONE		2
#define OPERATION_DIVIDE	3
#define OPERATION_EQUAL		4
#define OPERATION_MINUS		5
#define OPERATION_MULTIPLY	6
#define OPERATION_PLUS		7
#define OPERATION_PERCENT	8

typedef enum eAddressPickerType
{
    AddressPickerType_SMS,
    AddressPickerType_EMail
} tAddressPickerType;

static NSTimeInterval		lastPeripheralBLEPowerOffNotificationTime = 0;

@interface RequestViewController () <UITextFieldDelegate, CalculatorViewDelegate, ButtonSelector2Delegate,FadingAlertViewDelegate,CBPeripheralManagerDelegate,
                                     ShowWalletQRViewControllerDelegate, ImportWalletViewControllerDelegate,RecipientViewControllerDelegate>
{
	UITextField                 *_selectedTextField;
	int                         _selectedWalletIndex;
//	ShowWalletQRViewController  *_qrViewController;
    ImportWalletViewController  *_importWalletViewController;
    tABC_TxDetails              _details;
    CGRect                      topFrame;
    CGRect                      bottomFrame;
    BOOL                        bInitialized;
    CGFloat                     topTextSize;
    CGFloat                     bottomTextSize;
    BOOL                        bWalletListDropped;
    NSString                    *statusString;
    NSString                    *addressString;
    NSString                    *_uriString;
    NSMutableString                    *previousWalletUUID;
    BOOL                        bLastCalculatorState;
    tAddressPickerType          _addressPickerType;



}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btcWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btcHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fiatTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btcTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fiatWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fiatHeight;
@property (weak, nonatomic) IBOutlet UILabel *statusLine1;
@property (weak, nonatomic) IBOutlet UILabel *statusLine2;
@property (weak, nonatomic) IBOutlet UILabel *statusLine3;
@property (nonatomic, weak) IBOutlet UIImageView	*BLE_LogoImageView;
@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic   *bitcoinURICharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic   *userNameCharacteristic;
@property (strong, nonatomic) NSData                    *dataToSend;
@property (nonatomic, readwrite) NSInteger              sendDataIndex;
@property (nonatomic, strong) NSArray                   *arrayContacts;
@property (nonatomic, weak) IBOutlet UILabel			*connectedName;
@property (nonatomic, assign) int64_t                   amountSatoshiRequested;
@property (nonatomic, assign) int64_t                   previousAmountSatoshiRequested;
@property (nonatomic, assign) int64_t                   amountSatoshiReceived;
@property (nonatomic, assign) RequestState              state;




@property (assign) tABC_TxDetails txDetails;
@property (nonatomic, strong) NSString *requestType;
@property (nonatomic, strong) RecipientViewController   *recipientViewController;
@property (weak, nonatomic) IBOutlet UILabel *btcLabel;
@property (weak, nonatomic) IBOutlet UILabel *fiatLabel;
@property (nonatomic, weak) IBOutlet UIImageView    *qrCodeImageView;
@property (weak, nonatomic) IBOutlet UIView         *viewQRCodeFrame;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControlBTCUSD;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControlCopyEmailSMS;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *calculatorBottom;
@property (nonatomic, weak) IBOutlet CalculatorView     *keypadView;
//@property (nonatomic, weak) IBOutlet UILabel            *BTCLabel_TextField;
@property (nonatomic, weak) IBOutlet UITextField        *currentTopField;
@property (nonatomic, weak) IBOutlet UITextField        *BTC_TextField;
//@property (nonatomic, weak) IBOutlet UILabel            *USDLabel_TextField;
//@property (nonatomic, weak) IBOutlet UILabel            *bottomBTCUSDLabel;
@property (nonatomic, weak) IBOutlet UITextField        *USD_TextField;
@property (nonatomic, weak) IBOutlet ButtonSelectorView2 *buttonSelector; //wallet dropdown
@property (nonatomic, weak) IBOutlet UILabel            *exchangeRateLabel;
//@property (nonatomic, weak) IBOutlet UIButton           *nextButton;

@property (nonatomic, copy)   NSString *strFullName;
@property (nonatomic, copy)   NSString *strPhoneNumber;
@property (nonatomic, copy)   NSString *strEMail;
//@property (nonatomic, strong) NSArray  *arrayWallets;

@end

@implementation RequestViewController
@synthesize segmentedControlBTCUSD;
@synthesize segmentedControlCopyEmailSMS;

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
//    [Util resizeView:self.view withDisplayView:nil];

	self.keypadView.delegate = self;
    self.currentTopField = nil;
    bInitialized = false;
    bWalletListDropped = false;
    previousWalletUUID = nil;

	self.buttonSelector.delegate = self;
    [self.buttonSelector disableButton];

    self.qrCodeImageView.layer.magnificationFilter = kCAFilterNearest;
    self.viewQRCodeFrame.layer.cornerRadius = 8;
    self.viewQRCodeFrame.layer.masksToBounds = YES;
    self.amountSatoshiReceived = 0;
    self.amountSatoshiRequested = 0;
    self.state = kRequest;

    _selectedTextField = self.USD_TextField;
    self.keypadView.calcMode = CALC_MODE_FIAT;




//	self.buttonSelector.textLabel.text = NSLocalizedString(@"Wallet:", @"Label text on Request Bitcoin screen");
//    [self.buttonSelector setButtonWidth:WALLET_REQUEST_BUTTON_WIDTH];

//    self.nextButton.titleLabel.text = NSLocalizedString(@"Next", @"Button label to go to Show Wallet QR view");
//    [self.nextButton setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];

    //
    // All logic below copied from ShowWalletQRView
    //

//    self.statusLabel.text = self.statusString;
    //show first eight characters of address larger than rest

//    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:NO]];

//    if([LocalSettings controller].bDisableBLE)
//    {
//        self.BLE_LogoImageView.hidden = YES;
//    }
//    else
//    {
//        // Start up the CBPeripheralManager.  Warn if settings BLE is on but device BLE is off (but only once every 24 hours)
//        NSTimeInterval curTime = CACurrentMediaTime();
//        if((curTime - lastPeripheralBLEPowerOffNotificationTime) > 86400.0) //24 hours
//        {
//            _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:@{CBPeripheralManagerOptionShowPowerAlertKey: @(YES)}];
//        }
//        else
//        {
//            _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:@{CBPeripheralManagerOptionShowPowerAlertKey: @(NO)}];
//        }
//        lastPeripheralBLEPowerOffNotificationTime = curTime;
//    }
//
    // Replace with fadingAlert2
//    self.connectedView.alpha = 0.0;
//    self.connectedPhoto.layer.cornerRadius = 8.0;
//    self.connectedPhoto.layer.masksToBounds = YES;

    self.arrayContacts = @[];
    // load all the names from the address book
    [self generateListOfContactNames];

    // add left to right swipe detection for going back
//    [self installLeftToRightSwipeDetection];

}

-(void)awakeFromNib
{
	
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.previousAmountSatoshiRequested = -1;

    // create a dummy view to replace the keyboard if we are on a 4.5" screen
    UIView *dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];

//	[self loadWalletInfo];

//XXX	self.BTCLabel_TextField.text = [User Singleton].denominationLabel;
    [self.segmentedControlBTCUSD setTitle:[User Singleton].denominationLabel forSegmentAtIndex:1];
//    self.BTC_TextField.inputView = !IS_IPHONE4 ? dummyView : self.keypadView;
//    self.USD_TextField.inputView = !IS_IPHONE4 ? dummyView : self.keypadView;
    self.BTC_TextField.inputView = dummyView;
    self.USD_TextField.inputView = dummyView;
	self.BTC_TextField.delegate = self;
	self.USD_TextField.delegate = self;

    // if they are on a 4" screen then move the calculator below the bottom of the screen
    if ([LocalSettings controller].bMerchantMode)
    {
        [self changeCalculator:false show:true];
    }
    else
    {
        [self changeCalculator:false show:false];
    }

//    [self exchangeRateUpdate:nil];

    if (!bInitialized) {
        topFrame = self.USD_TextField.frame;
        bottomFrame = self.BTC_TextField.frame;
        topTextSize = self.USD_TextField.font.pointSize;
        bottomTextSize = self.BTC_TextField.font.pointSize;
        bInitialized = true;
    }
    [self changeTopField:true animate:false];

    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].backButtonText side:NAV_BAR_LEFT button:true enable:false action:@selector(Back:) fromObject:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(info:) fromObject:self];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews:) name:NOTIFICATION_WALLETS_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exchangeRateUpdate:) name:NOTIFICATION_EXCHANGE_RATE_CHANGE object:nil];

    if ([[User Singleton] offerRequestHelp]) {
        [MainViewController fadingAlertHelpPopup:NSLocalizedString(@"Present QR code to Sender and have them scan to send you payment",nil)];
    }

    [self updateViews:nil];

    if (_bDoFinalizeTx)
    {
        [self finalizeRequest];
        _bDoFinalizeTx = NO;
    }

}

- (void)updateViews:(NSNotification *)notification
{
    if ([CoreBridge Singleton].arrayWallets && [CoreBridge Singleton].currentWallet)
    {
        self.buttonSelector.arrayItemsToSelect = [CoreBridge Singleton].arrayWalletNames;
        [self.buttonSelector.button setTitle:[CoreBridge Singleton].currentWallet.strName forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = [CoreBridge Singleton].currentWalletID;

        NSString *walletName = [NSString stringWithFormat:@"To: %@ ↓", [CoreBridge Singleton].currentWallet.strName];
        [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle:) fromObject:self];

        self.keypadView.currencyNum = [CoreBridge Singleton].currentWallet.currencyNum;

        [self updateTextFieldContents:YES];

        if (!([[CoreBridge Singleton].arrayWallets containsObject:[CoreBridge Singleton].currentWallet]))
        {
            [FadingAlertView create:self.view
                            message:[Theme Singleton].walletHasBeenArchivedText
                           holdTime:FADING_ALERT_HOLD_TIME_FOREVER];
        }
    }
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
    if(self.peripheralManager.isAdvertising) {
        NSLog(@"Removing all BLE services and stopping advertising");
        [self.peripheralManager removeAllServices];
        [self.peripheralManager stopAdvertising];
        _peripheralManager = nil;
    }
    [CoreBridge prioritizeAddress:nil inWallet:[CoreBridge Singleton].currentWallet.strUUID];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)showingQRCode:(NSString *)walletUUID withTx:(NSString *)txId
{
//    if (_qrViewController == nil || _qrViewController.addressString == nil)
    if (addressString == nil)
    {
        return NO;
    }
    Transaction *transaction = [CoreBridge getTransaction:walletUUID withTx:txId];
    for (TxOutput *output in transaction.outputs)
    {
        if (!output.bInput 
            && [addressString isEqualToString:output.strAddress])
        {
            return YES;
        }
    }
    return NO;
}

- (void)changeCalculator:(BOOL)animate show:(BOOL)bShow
{
    if (animate) {
        [UIView animateWithDuration:0.35
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
                         {
                             [self upCalculator:bShow];
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished)
                         {
                         }];

    }
    else
    {
        [self upCalculator:bShow];
    }
    bLastCalculatorState = bShow;


}

- (void)upCalculator:(BOOL)up
{
    CGFloat destination;
    if (up)
    {
        destination = [MainViewController getFooterHeight];
        self.keypadView.alpha = 1.0;
        self.keypadView.hidden = false;
    }
    else
    {
        destination = -[MainViewController getLargestDimension];
        self.keypadView.alpha = 0.0;
        self.keypadView.hidden = true;
    }

    self.calculatorBottom.constant = destination;

}

//- (BOOL)transactionWasDonation
//{
//    return [self isDonation:amountSatoshi];
//}
//
//
//- (BOOL)isDonation:(SInt64)requestedSatoshis
//{
//    return YES == [LocalSettings controller].bMerchantMode && 0 == requestedSatoshis;
//}
//
//- (SInt64)transactionDifference:(NSString *)walletUUID withTx:(NSString *) txId
//{
//    // If the request was 0, then this was a donation and it's up to payer to
//    // determine amount to send
//    if (_details.amountSatoshi > 0)
//    {
//        Transaction *transaction = [CoreBridge getTransaction:walletUUID withTx:txId];
//        return transaction.amountSatoshi - _details.amountSatoshi;
//    }
//    else
//    {
//        return 0;
//    }
//}
//
- (void)resetViews
{
    if (_importWalletViewController)
    {
        [_importWalletViewController.view removeFromSuperview];
        _importWalletViewController = nil;
    }
//    if (_qrViewController)
//    {
//        [_qrViewController.view removeFromSuperview];
//        _qrViewController = nil;
//    }
    self.BTC_TextField.text = @"";
	self.USD_TextField.text = @"";
    self.amountSatoshiReceived = 0;
    self.amountSatoshiRequested = 0;
    self.state = kRequest;
}


#pragma mark - Action Methods

- (IBAction)didTouchQRCode:(id)sender
{
    if (bLastCalculatorState)
    {
        [self.BTC_TextField resignFirstResponder];
        [self.USD_TextField resignFirstResponder];

        [self changeCalculator:YES show:NO];
    }
    else
    {
        [self changeCalculator:YES show:YES];
        [self.currentTopField becomeFirstResponder];
    }

}



- (IBAction)segmentedControlBTCUSDAction:(id)sender
{
    if(segmentedControlBTCUSD.selectedSegmentIndex == 0)            // Checking which segment is selected using the segment index value
    {
        [self changeTopField:true animate:true];
    }
    else if(segmentedControlBTCUSD.selectedSegmentIndex == 1)
    {
        [self changeTopField:false animate:true];
    }
}

- (IBAction)segmentedControlCopyEmailSMSAction:(id)sender
{
    if(segmentedControlCopyEmailSMS.selectedSegmentIndex == 0)
    {
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setString:addressString];

        [MainViewController fadingAlert:NSLocalizedString(@"Request is copied to the clipboard", nil)];
    }
    else if(segmentedControlCopyEmailSMS.selectedSegmentIndex == 1)
    {
        // Do Email
        self.strFullName = @"";
        self.strEMail = @"";

        [self launchRecipientWithMode:RecipientMode_Email];
    }
    else if(segmentedControlCopyEmailSMS.selectedSegmentIndex == 2)
    {
        // Do SMS
        self.strPhoneNumber = @"";
        self.strFullName = @"";

        [self launchRecipientWithMode:RecipientMode_SMS];
    }
}

- (IBAction)info:(id)sender
{
	[self.view endEditing:YES];
    [InfoView CreateWithHTML:@"infoRequest" forView:self.view];
}

- (IBAction)ImportWallet
{
	[self.view endEditing:YES];
    [self bringUpImportWalletView];
}

//- (IBAction)QRCodeButton
//{
//    [self.view endEditing:YES];
//    SInt64 amountSatoshi = [CoreBridge denominationToSatoshi:self.BTC_TextField.text];
//    RequestState state = [self isDonation:amountSatoshi] ? kDonation : kRequest;
//    [self LaunchQRCodeScreen:amountSatoshi withRequestState:state];
//}
//

//
// This is called from MainViewController to update QR code upon receiving funds
//


//
// Implement the state machine of the QR code screen based on Merchant Mode, amount received, amount requested. All of which could change at any time.
// Returns new state

- (RequestState)updateQRCode:(SInt64)incomingSatoshi
{
    NSLog(@"ENTER updateQRCode");

    BOOL bChangeRequest = false;

    BOOL mm = [LocalSettings controller].bMerchantMode;
    self.amountSatoshiReceived += incomingSatoshi;
    self.amountSatoshiRequested = [CoreBridge denominationToSatoshi:self.BTC_TextField.text];
    SInt64 remaining = self.amountSatoshiRequested;

    if (self.previousAmountSatoshiRequested != self.amountSatoshiRequested)
    {
        self.previousAmountSatoshiRequested = self.amountSatoshiRequested;
        bChangeRequest = true;
    }
    if (previousWalletUUID != [CoreBridge Singleton].currentWallet.strUUID)
    {
        previousWalletUUID = [CoreBridge Singleton].currentWallet.strUUID;
        bChangeRequest = true;
    }
    if (incomingSatoshi)
    {
        bChangeRequest = true;
    }

    if (!bChangeRequest) // Nothing's changed so save some work. Especially BLE start/stop
        return self.state;

    if (self.amountSatoshiRequested == 0)
    {
        if (mm)
        {
            self.state = kDonation;
        }
        else
        {
            if (self.amountSatoshiReceived == 0)
                self.state = kRequest;
            else
                self.state = kDone;

        }
    }
    else
    {
        if (self.amountSatoshiReceived == 0)
        {
            self.state = kRequest;
        }
        else if (self.amountSatoshiReceived < self.amountSatoshiRequested)
        {
            self.state = kPartial;
        }
        else // if (self.amountSatoshiReceived >= self.amountSatoshiRequested)
        {
            self.state = kDone;
        }
    }

    if (self.state == kDone)
    {
        self.amountSatoshiReceived = 0;
        self.amountSatoshiRequested = 0;
    }

    //
    // Done with validation. Now to change the GUI
    //

    NSString *strName = @"";
    NSString *strCategory = @"";
    NSString *strNotes = @"";

    // get the QR Code image
    NSMutableString *strRequestID = [[NSMutableString alloc] init];
    NSMutableString *strRequestAddress = [[NSMutableString alloc] init];
    NSMutableString *strRequestURI = [[NSMutableString alloc] init];

    self.statusLine1.text = @"";
    self.statusLine2.text = @"";
    self.statusLine3.text = @"";

    switch (self.state) {
        case kRequest:
        case kDone:
        {
//            if (self.amountSatoshiRequested > 0)
//            {
//                NSString *string = NSLocalizedString(@"Requested...", @"Requested string on Request screen");
//                self.statusLine1.text = [NSString stringWithFormat:@"%@ %@",[CoreBridge formatSatoshi:self.amountSatoshiRequested],string];
//            }
            self.statusLine2.text = NSLocalizedString(@"Waiting for Payment...", @"Status on Request screen");
            break;
        }
        case kPartial:
        {
            remaining = self.amountSatoshiRequested - self.amountSatoshiReceived;
            NSString *string = NSLocalizedString(@"Requested...", @"Requested string on Request screen");
            self.statusLine1.text = [NSString stringWithFormat:@"%@ %@",[CoreBridge formatSatoshi:self.amountSatoshiRequested],string];

            string = NSLocalizedString(@"Remaining...", @"Remaining string on Request screen");
            self.statusLine2.text = [NSString stringWithFormat:@"%@ %@",[CoreBridge formatSatoshi:remaining],string];
            break;
        }
        case kDonation:
        {

            if (self.amountSatoshiReceived > 0)
            {
                NSString *string = NSLocalizedString(@"Received...", @"Received string on Request screen");
                self.statusLine2.text = [NSString stringWithFormat:@"%@ %@",[CoreBridge formatSatoshi:self.amountSatoshiReceived],string];
            }
            else
            {
                self.statusLine2.text = NSLocalizedString(@"Waiting for Payment...", @"Status on Request screen");
            }
            break;
        }
    }

    //
    // Change the QR code. This is a slow call so put it in a queue
    //
    [CoreBridge postToWalletsQueue:^(void) {

        UIImage *qrImage = [self createRequestQRImageFor:strName withNotes:strNotes withCategory:strCategory
                                        storeRequestIDIn:strRequestID storeRequestURI:strRequestURI storeRequestAddressIn:strRequestAddress
                                            scaleAndSave:NO withAmount:remaining];


        addressString = strRequestAddress;
        _uriString = strRequestURI;
        [CoreBridge prioritizeAddress:addressString inWallet:[CoreBridge Singleton].currentWallet.strUUID];

        dispatch_async(dispatch_get_main_queue(),^{
            self.statusLine3.text = addressString;
            self.qrCodeImageView.image = qrImage;
        });
    }];




//    if(addressString.length >= 8)
//    {
//        self.addressLabel1.text = [addressString substringToIndex:8];
//        [self.addressLabel1 sizeToFit];
//        if(addressString.length > 8)
//        {
//            self.addressLabel2.text = [addressString substringFromIndex:8];
//
//            CGRect frame = self.addressLabel2.frame;
//            float endX = frame.origin.x + frame.size.width;
//            frame.origin.x = self.addressLabel1.frame.origin.x + self.addressLabel1.frame.size.width;
//            frame.size.width = endX - frame.origin.x;
//            self.addressLabel2.frame = frame;
//        }
//    }
//    else

    if (incomingSatoshi)
    {
        [self showPaymentPopup:self.state amount:incomingSatoshi];
    }

    if([LocalSettings controller].bDisableBLE)
    {
        self.BLE_LogoImageView.hidden = YES;
    }

    //
    // If request has changed or is brand new, startup the BLE manager and start broadcasting
    //
    [CoreBridge postToWalletsQueue:^(void) {
        if(self.peripheralManager.isAdvertising) {
            NSLog(@"Removing all BLE services and stopping advertising");
            [self.peripheralManager removeAllServices];
            [self.peripheralManager stopAdvertising];
            _peripheralManager = nil;
        }

        if(![LocalSettings controller].bDisableBLE)
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
    }];

    return self.state;

//
//    ShowWalletQRViewController *tempQRViewController = NULL;
//    if (_qrViewController)
//    {
//        tempQRViewController = _qrViewController;
//    }
//    // bring up the qr code view controller
//    [self showQRCodeViewControllerWithQRImage:qrImage address:strRequestAddress requestURI:strRequestURI withAmount:requestAmount withDonation:donation withRequestState:state];

    NSLog(@"EXIT updateQRCode");

}

//- (void)LaunchQRCodeScreen:(SInt64)amountSatoshi withRequestState:(RequestState)state
//{
//    [self.view endEditing:YES];
//
//    SInt64 requestAmount = amountSatoshi;
//    SInt64 donation = 0;
//    if (kDonation == state)
//    {
//        // parameter represents the received donation amount
//        requestAmount = 0;
//        donation = amountSatoshi;
//    }
//
//    NSString *strName = @"";
//    NSString *strCategory = @"";
//    NSString *strNotes = @"";
//
//    // get the QR Code image
//    NSMutableString *strRequestID = [[NSMutableString alloc] init];
//    NSMutableString *strRequestAddress = [[NSMutableString alloc] init];
//    NSMutableString *strRequestURI = [[NSMutableString alloc] init];
//    UIImage *qrImage = [self createRequestQRImageFor:strName withNotes:strNotes withCategory:strCategory
//        storeRequestIDIn:strRequestID storeRequestURI:strRequestURI storeRequestAddressIn:strRequestAddress
//        scaleAndSave:NO withAmount:requestAmount withRequestState:state];
//
//    ShowWalletQRViewController *tempQRViewController = NULL;
//    if (_qrViewController)
//    {
//        tempQRViewController = _qrViewController;
//    }
//    // bring up the qr code view controller
//    [self showQRCodeViewControllerWithQRImage:qrImage address:strRequestAddress requestURI:strRequestURI withAmount:requestAmount withDonation:donation withRequestState:state];
//
//    if (tempQRViewController)
//    {
//        [tempQRViewController.view removeFromSuperview];
//    }
//}

#pragma mark - Notification Handlers

- (void)exchangeRateUpdate: (NSNotification *)notification
{
    NSLog(@"Updating exchangeRateUpdate");
	[self updateTextFieldContents:NO];
}

#pragma mark - Misc Methods

- (void)setFirstResponder
{
    if ([LocalSettings controller].bMerchantMode)
    {
        // make the USD the first responder
        [self.USD_TextField becomeFirstResponder];
    }
    else
    {
        [self.BTC_TextField resignFirstResponder];
        [self.USD_TextField resignFirstResponder];
    }
}

- (void)changeTopField:(BOOL)bFiat animate:(BOOL)animate
{
    if (animate) {
        [UIView animateWithDuration:0.35
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
                         {
                             [self changeTopFieldRaw:bFiat];
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished)
                         {
                         }];

    }
    else
    {
        [self changeTopFieldRaw:bFiat];
    }
}

- (void)changeTopFieldRaw:(BOOL)bFiat
{

    UITextField *bottomField;
    UILabel *bottomLabel;
    UILabel *topLabel;
    CGRect fiatFrame, btcFrame;
    Wallet *wallet = [self getCurrentWallet];

    if (bFiat)
    {
        if (self.currentTopField == self.USD_TextField)
        {
            return;
        }
        else
        {
            self.currentTopField = self.USD_TextField;
            bottomField = self.BTC_TextField;

            fiatFrame = topFrame;
            btcFrame = bottomFrame;
            topLabel = _fiatLabel;
            bottomLabel = _btcLabel;
            segmentedControlBTCUSD.selectedSegmentIndex = 0;
            


        }
    }
    else
    {
        if (self.currentTopField == self.BTC_TextField)
        {
            return;
        }
        else
        {
            self.currentTopField = self.BTC_TextField;
            bottomField = self.USD_TextField;

            fiatFrame = bottomFrame;
            btcFrame = topFrame;
            topLabel = _btcLabel;
            bottomLabel = _fiatLabel;
            segmentedControlBTCUSD.selectedSegmentIndex = 1;

        }
    }

    self.fiatTop.constant = fiatFrame.origin.y;
    self.fiatWidth.constant = fiatFrame.size.width;
    self.fiatHeight.constant = fiatFrame.size.height;

    self.btcTop.constant = btcFrame.origin.y;
    self.btcWidth.constant = btcFrame.size.width;
    self.btcHeight.constant = btcFrame.size.height;

//    self.currentTopField.frame = topFrame;
    UIColor *color = [UIColor lightGrayColor];
    NSString *string = NSLocalizedString(@"Enter Amount (optional)", "Placeholder text for Receive screen amount");
    self.currentTopField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:string attributes:@{NSForegroundColorAttributeName: [Theme Singleton].colorRequestTopTextFieldPlaceholder}];

    [topLabel setFont:[UIFont fontWithName:@"Lato-Regular" size:topTextSize]];
    [topLabel setTextColor:[Theme Singleton].colorRequestTopTextField];
    [self.currentTopField setFont:[UIFont fontWithName:@"Lato-Regular" size:topTextSize]];
    [self.currentTopField setTextColor:[Theme Singleton].colorRequestTopTextField];
    [self.currentTopField setTintColor:[UIColor lightGrayColor]];
    [self.currentTopField setEnabled:true];
    if (bLastCalculatorState)
    {
        [self.currentTopField becomeFirstResponder];
    }


    self.keypadView.textField = self.currentTopField;

//    bottomField.frame = bottomFrame;
    bottomField.placeholder = @"";
    [bottomLabel setFont:[UIFont fontWithName:@"Lato-Regular" size:bottomTextSize]];
    [bottomLabel setTextColor:[Theme Singleton].colorRequestBottomTextField];
    [bottomField setFont:[UIFont fontWithName:@"Lato-Regular" size:bottomTextSize]];
    [bottomField setTextColor:[Theme Singleton].colorRequestBottomTextField];
    [bottomField setTintColor:[UIColor lightGrayColor]];
    [bottomField setEnabled:false];

}

- (const char *)createReceiveRequestFor:(NSString *)strName withNotes:(NSString *)strNotes 
    withCategory:(NSString *)strCategory withAmount:(SInt64)amountSatoshi
{
	//creates a receive request.  Returns a requestID.  Caller must free this ID when done with it
	tABC_CC result;
	double currency;
	tABC_Error error;

    Wallet *wallet = [self getCurrentWallet];

	//first need to create a transaction details struct
    memset(&_details, 0, sizeof(tABC_TxDetails));

    _details.amountSatoshi = amountSatoshi;

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
	_details.szCategory = (char *) [strCategory UTF8String];
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

//-(void)showQRCodeViewControllerWithQRImage:(UIImage *)image address:(NSString *)address requestURI:(NSString *)strRequestURI withAmount:(SInt64)amountSatoshi  withDonation:(SInt64)donation withRequestState:(RequestState)state
//{
//	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
//
//    _qrViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ShowWalletQRViewController"];
//
//    Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
//	_qrViewController.delegate = self;
//	_qrViewController.qrCodeImage = image;
//	_qrViewController.addressString = address;
//	_qrViewController.uriString = strRequestURI;
//    _qrViewController.amountSatoshi = amountSatoshi;
//    _qrViewController.donation = donation;
//    _qrViewController.state = state;
//
//    if (kPartial == state)
//    {
//        NSMutableString *strBody = [[NSMutableString alloc] init];
//
//        [strBody appendString:NSLocalizedString(@"Partial Payment from ",nil)];
//        [strBody appendFormat:@"%@ ", [CoreBridge formatSatoshi:self.originalAmountSatoshi withSymbol:true]];
//        [strBody appendString:NSLocalizedString(@"Request ",nil)];
//
//        _qrViewController.statusString = [NSString stringWithFormat:@"%@", strBody];
//    }
//    else
//    {
//        _qrViewController.statusString = NSLocalizedString(@"Waiting for Payment...", @"Message on receive request screen");
//    }
//    _qrViewController.requestID = requestID;
//    _qrViewController.walletUUID = wallet.strUUID;
//    _qrViewController.txDetails = _details;
//    _qrViewController.currencyNum = wallet.currencyNum;
//	//CGRect frame = self.view.bounds;
//	//_qrViewController.view.frame = frame;
//	[self.view addSubview:_qrViewController.view];
//	_qrViewController.view.alpha = 0.0;
//
//    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
//	[UIView animateWithDuration:0.35
//						  delay:0.0
//						options:UIViewAnimationOptionCurveEaseInOut
//					 animations:^
//	 {
//		_qrViewController.view.alpha = 1.0;
//	 }
//    completion:^(BOOL finished)
//    {
//        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
//    }];
//}

// generates and returns a request qr image, stores request id in the given mutable string
- (UIImage *)createRequestQRImageFor:(NSString *)strName withNotes:(NSString *)strNotes withCategory:(NSString *)strCategory 
    storeRequestIDIn:(NSMutableString *)strRequestID storeRequestURI:(NSMutableString *)strRequestURI 
    storeRequestAddressIn:(NSMutableString *)strRequestAddress scaleAndSave:(BOOL)bScaleAndSave 
    withAmount:(SInt64)amountSatoshi
{
    NSLog(@"ENTER createRequestQRImageFor");

    UIImage *qrImage = nil;
    [strRequestID setString:@""];
    [strRequestAddress setString:@""];
    [strRequestURI setString:@""];

    unsigned int width = 0;
    unsigned char *pData = NULL;
    char *pszURI = NULL;
    tABC_Error error;

    const char *szRequestID = [self createReceiveRequestFor:strName withNotes:strNotes
        withCategory:strCategory withAmount:amountSatoshi];
    self.requestID = [NSString stringWithUTF8String:szRequestID];

    if (szRequestID)
    {
        Wallet *wallet = [self getCurrentWallet];
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

        Wallet *wallet = [self getCurrentWallet];
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

    NSLog(@"EXIT createRequestQRImageFor");

    return qrImageFinal;
}



- (void)updateTextFieldContents:(BOOL)allowBTCUpdate
{
    tABC_Error error;
    
    Wallet *wallet = [self getCurrentWallet];
    
    self.exchangeRateLabel.text = [CoreBridge conversionString:wallet];
//XXX    self.USDLabel_TextField.text = wallet.currencyAbbrev;
    [self.segmentedControlBTCUSD setTitle:wallet.currencyAbbrev forSegmentAtIndex:0];
    _fiatLabel.text = wallet.currencyAbbrev;

    if (_selectedTextField == self.BTC_TextField)
	{
		double currency;
        int64_t satoshi = [CoreBridge denominationToSatoshi: self.BTC_TextField.text];

        if (satoshi == 0)
        {
            if ([self.BTC_TextField.text hasPrefix:@"."] == NO)
            {
                self.USD_TextField.text = @"";
                self.BTC_TextField.text = @"";
            }
        }
        else
        {
            if (ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                    satoshi, &currency, wallet.currencyNum, &error) == ABC_CC_Ok)
                self.USD_TextField.text = [CoreBridge formatCurrency:currency
                                                     withCurrencyNum:wallet.currencyNum
                                                          withSymbol:false];
        }
	}
	else if (allowBTCUpdate && (_selectedTextField == self.USD_TextField))
	{
		int64_t satoshi;
		double currency = [self.USD_TextField.text doubleValue];
        if (currency == 0.0)
        {
            if ([self.USD_TextField.text hasPrefix:@"."] == NO)
            {
                self.USD_TextField.text = @"";
                self.BTC_TextField.text = @"";
            }
        }
        else
        {
            if (ABC_CurrencyToSatoshi([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                    currency, wallet.currencyNum, &satoshi, &error) == ABC_CC_Ok)
            {
                self.BTC_TextField.text = [CoreBridge formatSatoshi:satoshi
                                                         withSymbol:false
                                                       cropDecimals:[CoreBridge currencyDecimalPlaces]];
            }
        }
	}

//    NSString *walletName;
//
//    walletName = [NSString stringWithFormat:@"To: %@ ↓", wallet.strName];
//
//    [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle:) fromObject:self];
    [self updateQRCode:0];
//
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

//- (void)loadWalletInfo
//{
//    [CoreBridge postToWalletsQueue:^(void) {
//        // load all the non-archive wallets
//        NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
//        NSString *newWalletUUID = nil;
//        int newWalletIndex = 0;
//
//        [CoreBridge loadWallets:arrayWallets archived:nil withTxs:NO];
//
//        // create the array of wallet names
//        NSMutableArray *arrayWalletNames = [[NSMutableArray alloc] initWithCapacity:[arrayWallets count]];
//        for (int i = 0; i < [arrayWallets count]; i++)
//        {
//            Wallet *wallet = [arrayWallets objectAtIndex:i];
//
//            [arrayWalletNames addObject:[NSString stringWithFormat:@"%@ (%@)", wallet.strName, [CoreBridge formatSatoshi:wallet.balance]]];
//
//            if ([_walletUUID length] == 0)
//            {
//                // walletID is uninitialized. Choose the primary wallet
//                if (i == 0)
//                {
//                    newWalletUUID = wallet.strUUID;
//                    newWalletIndex = i;
//                }
//            }
//            else
//            {
//                if (_walletUUID == wallet.strUUID)
//                    newWalletIndex = i;
//            }
//        }
//
//        dispatch_async(dispatch_get_main_queue(),^{
//
//            self.arrayWallets = arrayWallets;
//            _selectedWalletIndex = newWalletIndex;
//            if (newWalletIndex != nil)
//                _walletUUID = newWalletUUID;
//
//            if (_selectedWalletIndex < [arrayWallets count])
//            {
//                Wallet *wallet = [self getCurrentWallet];
//                self.keypadView.currencyNum = wallet.currencyNum;
//
//                self.buttonSelector.arrayItemsToSelect = [arrayWalletNames copy];
//                [self.buttonSelector.button setTitle:wallet.strName forState:UIControlStateNormal];
//                self.buttonSelector.selectedItemIndex = (int) _selectedWalletIndex;
//                _btcLabel.text = [User Singleton].denominationLabel;
//                _fiatLabel.text = wallet.currencyAbbrev;
//
//            }
//
//            [self updateTextFieldContents:YES];
//        });
//    }];
//
//}

- (void)bringUpImportWalletView
{
    if (nil == _importWalletViewController)
    {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
        _importWalletViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ImportWalletViewController"];

        Wallet *wallet = [CoreBridge Singleton].currentWallet;
        _importWalletViewController.walletUUID = wallet.strUUID;
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
    [self didTouchQRCode:nil];
}

- (void)CalculatorValueChanged:(CalculatorView *)calculator
{
	[self updateTextFieldContents:YES];
}


#pragma mark - ButtonSelectorView2 delegates

- (void)ButtonSelector2:(ButtonSelectorView2 *)view selectedItem:(int)itemIndex
{
    NSIndexPath *indexPath = [[NSIndexPath alloc]init];
    indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [CoreBridge makeCurrentWalletWithIndex:indexPath];

//    _selectedWalletIndex = itemIndex;
//
//    // Update wallet UUID
//    Wallet *wallet = [self getCurrentWallet];
//    [self.buttonSelector.button setTitle:wallet.strName forState:UIControlStateNormal];
//    self.buttonSelector.selectedItemIndex = _selectedWalletIndex;
//
//    _walletUUID = wallet.strUUID;
//
//    self.keypadView.currencyNum = wallet.currencyNum;
//    [self updateTextFieldContents:YES];
    bWalletListDropped = false;
}

//#pragma mark - ShowWalletQRViewController delegates
//
//- (void)ShowWalletQRViewControllerDone:(ShowWalletQRViewController *)controller
//{
//	[controller.view removeFromSuperview];
//	_qrViewController = nil;
//
//    [self setFirstResponder];
//}
//
#pragma mark - Textfield delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField != self.currentTopField)
    {
        if (self.currentTopField == self.USD_TextField)
            [self changeTopField:false animate:YES];
        else
            [self changeTopField:true animate:YES];

    }

    _selectedTextField = textField;
    if (_selectedTextField == self.BTC_TextField)
        self.keypadView.calcMode = CALC_MODE_COIN;
    else if (_selectedTextField == self.USD_TextField)
        self.keypadView.calcMode = CALC_MODE_FIAT;

    // Popup numpad
    [self changeCalculator:YES show:true];

//	self.BTC_TextField.text = @"";
//	self.USD_TextField.text = @"";
}

#pragma mark - Import Wallet Delegates

- (void)importWalletViewControllerDidFinish:(ImportWalletViewController *)controller
{
	[controller.view removeFromSuperview];
	_importWalletViewController = nil;

    [self setFirstResponder];
}

- (Wallet *) getCurrentWallet
{
//    return [self.arrayWallets objectAtIndex:_selectedWalletIndex];
    return [CoreBridge Singleton].currentWallet;
}

-(void)showConnectedPopup
{
    NSString *line1;
    NSString *line2;
    NSString *line3;
    UIImage *image;

    line1 = self.connectedName.text;
    line2 = NSLocalizedString(@"Connected", "Popup text when BLE connects");
    line3 = @"";

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
                image = contact.imagePhoto;
                imageIsFromContacts = YES;
                break;
            }
        }
    }


    if(imageIsFromContacts == NO)
    {
        image = [UIImage imageNamed:@"BLE_photo.png"];
    }

    [DropDownAlertView create:self.view
                      message:nil
                        image:image
                        line1:line1
                        line2:line2
                        line3:line3
                     holdTime:DROP_DOWN_HOLD_TIME_DEFAULT
                 withDelegate:nil];

//    [UIView animateWithDuration:3.0
//                          delay:2.0
//                        options:UIViewAnimationOptionCurveLinear
//                     animations:^
//                     {
//                         self.connectedView.alpha = 0.0;
//                         self.qrCodeImageView.alpha = 1.0;
//                     }
//                     completion:^(BOOL finished)
//                     {
//
//                     }];
}

-(void)showPaymentPopup:(RequestState)state amount:(SInt64) amountSatoshi
{
    NSString *line1;
    NSString *line2;
    NSString *line3;
    UIImage *image;

    NSTimeInterval delay;
    NSTimeInterval duration;

    Wallet *wallet = [self getCurrentWallet];


    switch (state) {
        case kPartial:
        {
            delay = 4.0;
            duration = 2.0;
            line1 = @"";
            line2 = NSLocalizedString(@"** Warning **", @"** Warning ** text on partial payment");
            line3 = NSLocalizedString(@"Partial Payment", @"Text on partial payment");
            image = [UIImage imageNamed:@"Warning_icon.png"];
            [[AudioController controller] playPartialReceived];
            break;
        }
        case kDonation:
        {
            delay = 7.0;
            duration = 2.0;
            line1 = NSLocalizedString(@"Payment received", @"Text on payment recived popup");
            tABC_Error error;
            double currency;
            if (ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                    amountSatoshi, &currency, wallet.currencyNum, &error) == ABC_CC_Ok)
            {
                NSString *fiatAmount = [CoreBridge currencySymbolLookup:wallet.currencyNum];
                NSString *fiatSymbol = [NSString stringWithFormat:@"%.2f", currency];
                NSString *fiat = [fiatAmount stringByAppendingString:fiatSymbol];
                line2 = [CoreBridge formatSatoshi:amountSatoshi];
                line3 = fiat;
            }
            else
            {
                // failed to look up the wallet's fiat currency
                line2 = [CoreBridge formatSatoshi:amountSatoshi];
                line3  = @"";
            }
            [[AudioController controller] playReceived];
            break;
        }
        default:
        {
            [[AudioController controller] playReceived];
            return;
        }
    }

    [DropDownAlertView create:self.view
                      message:nil
                        image:image
                        line1:line1
                        line2:line2
                        line3:line3
                     holdTime:[Theme Singleton].alertHoldTimePaymentReceived
                 withDelegate:nil];

//    self.connectedView.alpha = 1.0;
//    self.qrCodeImageView.alpha = 0.0;
//    [UIView animateWithDuration:duration
//                          delay:delay
//                        options:UIViewAnimationOptionCurveLinear
//                     animations:^
//                     {
//                         self.connectedView.alpha = 0.0;
//                         self.qrCodeImageView.alpha = 1.0;
//                     }
//                     completion:^(BOOL finished)
//                     {
//                     }];
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
    if(peripheral.state == CBPeripheralManagerStatePoweredOn && [self isLECapableHardware])
    {
        // We're in CBPeripheralManagerStatePoweredOn state...
        //NSLog(@"self.peripheralManager powered on.");

        // ... so build our service.

        // Start with the CBMutableCharacteristic
        self.bitcoinURICharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                                                           properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite
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
        if(addressString.length >= 10)
        {
            address = [addressString substringToIndex:10];
        }
        else
        {
            address = addressString;
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
            if ([name isEqualToString:@""])
            {
                name = [[UIDevice currentDevice] name];
            }
        }
        else
        {
            name = [[UIDevice currentDevice] name];
        }
        //broadcast first 10 digits of bitcoin address followed by full name (up to 28 bytes total)
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]], CBAdvertisementDataLocalNameKey : [NSString stringWithFormat:@"%@%@", address, name]}];
        self.BLE_LogoImageView.hidden = NO;
    }
    else
    {
//        [self showFadingAlert:NSLocalizedString(@"Bluetooth disconnected", nil)];
        self.BLE_LogoImageView.hidden = YES;
    }

}

/*
 * Central sends their name - acknowledge it
 */
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

/*
 * Central requesting full bitcoin URI. Send it in limited packets up to 512 bytes
 */
-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    //NSLog(@"didReceiveReadRequests");

    if([request.characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
    {
        NSString *stringToSend = [NSString stringWithFormat:@"%@", _uriString];
        NSData *data = [stringToSend dataUsingEncoding:NSUTF8StringEncoding];

        if (request.offset > data.length)
        {
            [self.peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
            return;
        }

        NSRange readRange = NSMakeRange(request.offset, data.length - request.offset);
        request.value = [data subdataWithRange:readRange];
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

// Use CBPeripheralManager to check whether the current platform/hardware supports Bluetooth LE.
- (BOOL)isLECapableHardware
{
    NSString * state = nil;
    switch ([self.peripheralManager state]) {
        case CBPeripheralManagerStateUnsupported:
            state = @"Your hardware doesn't support Bluetooth LE sharing.";
            break;
        case CBPeripheralManagerStateUnauthorized:
            state = @"This app is not authorized to use Bluetooth. You can change this in the Settings app.";
            break;
        case CBPeripheralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBPeripheralManagerStateResetting:
            state = @"Bluetooth is currently resetting.";
            break;
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"powered on");
            return TRUE;
        case CBPeripheralManagerStateUnknown:
            NSLog(@"state unknown");
            return FALSE;
        default:
            return FALSE;
    }
    NSLog(@"Peripheral manager state: %@", state);
    return FALSE;
}

- (void)replaceRequestTags:(NSString **) strContent
{
    NSString *amountBTC = [CoreBridge formatSatoshi:_amountSatoshiRequested
                                         withSymbol:false
                                      forceDecimals:8];
    NSString *amountBits = [CoreBridge formatSatoshi:_amountSatoshiRequested
                                          withSymbol:false
                                       forceDecimals:2];
    // For sending requests, use 8 decimal places which is a BTC (not mBTC or uBTC amount)

    NSString *iosURL;
    NSString *redirectURL = [NSString stringWithString: _uriString];
    NSString *paramsURI;
    NSString *paramsURIEnc;

    NSRange tempRange = [_uriString rangeOfString:@"bitcoin:"];

    if (*strContent == NULL)
    {
        return;
    }

    if (tempRange.location != NSNotFound)
    {
        iosURL = [_uriString stringByReplacingCharactersInRange:tempRange withString:@"bitcoin://"];
        paramsURI = [_uriString stringByReplacingCharactersInRange:tempRange withString:@""];
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
            @"[[abtag AMOUNT_BITS]]",
            @"[[abtag QRCODE]]",
                    nil];

    NSMutableArray* replaceList = [[NSMutableArray alloc] initWithObjects:
            name ? name : @"Unknown User",
            iosURL,
            redirectURL,
                    _uriString,
            addressString,
            amountBTC,
            amountBits,
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

        UIImage *imageAttachment = [self imageWithImage:self.qrCodeImageView.image scaledToSize:CGSizeMake(QR_ATTACHMENT_WIDTH, QR_ATTACHMENT_WIDTH)];
        imgData = [NSData dataWithData:UIImageJPEGRepresentation(imageAttachment, 1.0)];
        [mailComposer addAttachmentData:imgData mimeType:@"image/jpeg" fileName:@"qrcode.jpg"];

        mailComposer.mailComposeDelegate = self;

        [self presentViewController:mailComposer animated:YES completion:nil];

        [MainViewController animateFadeOut:self.view];
        _requestType = [Theme Singleton].emailText;
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
        UIImage *imageAttachment = [self imageWithImage:self.qrCodeImageView.image scaledToSize:CGSizeMake(QR_ATTACHMENT_WIDTH, QR_ATTACHMENT_WIDTH)];
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
        [MainViewController animateFadeOut:self.view];

        _requestType = [Theme Singleton].smsText;
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

    [MainViewController animateView:self.recipientViewController withBlur:NO];
//    CGRect frame = self.view.bounds;
//    frame.origin.x = frame.size.width;
//    self.recipientViewController.view.frame = frame;
//    [self.view addSubview:self.recipientViewController.view];
//
//    [UIView animateWithDuration:ENTER_ANIM_TIME_SECS
//                          delay:0.0
//                        options:UIViewAnimationOptionCurveEaseInOut
//                     animations:^
//                     {
//                         self.recipientViewController.view.frame = self.view.bounds;
//                     }
//                     completion:^(BOOL finished)
//                     {
//                     }];
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


- (void)saveRequest
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
                        [CoreBridge formatCurrency:_txDetails.amountCurrency withCurrencyNum:[CoreBridge Singleton].currentWallet.currencyNum],
                        _requestType,
                        [dateFormatter stringFromDate:now]];
    _txDetails.szNotes = (char *)[notes UTF8String];
    tABC_Error Error;
    // Update the Details
    if (ABC_CC_Ok != ABC_ModifyReceiveRequest([[User Singleton].name UTF8String],
            [[User Singleton].password UTF8String],
            [[CoreBridge Singleton].currentWallet.strUUID UTF8String],
            [self.requestID UTF8String],
            &_txDetails,
            &Error))
    {
        [Util printABC_Error:&Error];
    }

    [self.delegate pleaseRestartRequestViewBecauseAppleSucksWithPresentController];

}

- (void)finalizeRequest
{
    tABC_Error Error;

    // Finalize this request so it isn't used elsewhere
    if (ABC_CC_Ok != ABC_FinalizeReceiveRequest([[User Singleton].name UTF8String],
            [[User Singleton].password UTF8String],
            [[CoreBridge Singleton].currentWallet.strUUID UTF8String],
            [self.requestID UTF8String],
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Airbitz"
                                                            message:@"SMS cancelled"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            [alert show];
        }
            break;

        case MessageComposeResultFailed:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Airbitz"
                                                            message:@"Error sending SMS"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            [alert show];
        }
            break;

        case MessageComposeResultSent:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Airbitz"
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
    [self saveRequest];

}

#pragma mark - Mail Compose Delegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    NSString *strTitle = NSLocalizedString(@"Airbitz", nil);
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
    [self saveRequest];
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


@end

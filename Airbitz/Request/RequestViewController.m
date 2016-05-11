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
#import "ABCTransaction.h"
#import "ABCTxInOut.h"
#import "CalculatorView.h"
#import "ButtonSelectorView2.h"
#import "User.h"
#import "AirbitzCore.h"
#import "Util.h"
#import "InfoView.h"
#import "LocalSettings.h"
#import "MainViewController.h"
#import "Theme.h"
#import "Contact.h"
#import "TransferService.h"
#import "AudioController.h"
#import "RecipientViewController.h"
#import "DropDownAlertView.h"
#import "AppGroupConstants.h"
#import "FadingAlertView.h"


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

@interface RequestViewController () <UITextFieldDelegate, CalculatorViewDelegate, ButtonSelector2Delegate,FadingAlertViewDelegate,CBPeripheralManagerDelegate, RecipientViewControllerDelegate,MFMailComposeViewControllerDelegate,MFMessageComposeViewControllerDelegate>
{
	UITextField                 *_selectedTextField;
	int                         _selectedWalletIndex;
    CGRect                      topFrame;
    CGRect                      bottomFrame;
    BOOL                        bInitialized;
    CGFloat                     topTextSize;
    CGFloat                     bottomTextSize;
    BOOL                        bWalletListDropped;
    NSString                    *statusString;
    NSString                    *addressString;
    NSString                    *_uriString;
    NSString                    *previousWalletUUID;
    BOOL                        bLastCalculatorState;
    tAddressPickerType          _addressPickerType;



}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btcWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btcHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fiatTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btcTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fiatWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fiatHeight;
@property (weak, nonatomic) IBOutlet UILabel            *statusLine1;
@property (weak, nonatomic) IBOutlet UILabel            *statusLine2;
@property (weak, nonatomic) IBOutlet UILabel            *statusLine3;
@property (nonatomic, weak) IBOutlet UIImageView	    *BLE_LogoImageView;
@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic   *bitcoinURICharacteristic;
@property (nonatomic, strong) NSString			        *connectedName;
@property (nonatomic, assign) int64_t                   amountSatoshiRequested;
@property (nonatomic, assign) int64_t                   previousAmountSatoshiRequested;
@property (nonatomic, assign) int64_t                   amountSatoshiReceived;
@property (nonatomic, assign) RequestState              state;
@property (nonatomic, strong) NSTimer                   *qrTimer;
@property (weak, nonatomic)   IBOutlet UILabel          *textUnderQRCode;

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
@property (nonatomic, weak) IBOutlet UITextField        *currentTopField;
@property (nonatomic, weak) IBOutlet UITextField        *BTC_TextField;
@property (nonatomic, weak) IBOutlet UITextField        *USD_TextField;
@property (nonatomic, weak) IBOutlet ButtonSelectorView2 *buttonSelector; //wallet dropdown
@property (nonatomic, weak) IBOutlet UILabel            *exchangeRateLabel;
@property (nonatomic, weak) IBOutlet UIButton                *refreshButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *refreshSpinner;

@property (nonatomic, copy)   NSString *strFullName;
@property (nonatomic, copy)   NSString *strPhoneNumber;
@property (nonatomic, copy)   NSString *strEMail;

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

    // load all the names from the address book
    [MainViewController generateListOfContactNames];
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
    [self.segmentedControlBTCUSD setTitle:abcAccount.settings.denomination.label forSegmentAtIndex:1];
    _btcLabel.text = abcAccount.settings.denomination.label;

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

    [MainViewController changeNavBarOwner:self];

    if (!bInitialized) {
        topFrame = self.USD_TextField.frame;
        bottomFrame = self.BTC_TextField.frame;
        topTextSize = self.USD_TextField.font.pointSize;
        bottomTextSize = self.BTC_TextField.font.pointSize;
        bInitialized = true;
    }
    [self changeTopField:true animate:false];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews:) name:NOTIFICATION_WALLETS_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exchangeRateUpdate:) name:NOTIFICATION_EXCHANGE_RATE_CHANGED object:nil];

    if ([[LocalSettings controller] offerRequestHelp]) {
        [MainViewController fadingAlertHelpPopup:presentQRCodeToSender];
    }

    [self updateViews:nil];

    [self.statusLine1 setTextColor:[Theme Singleton].colorTextDark];
    [self.statusLine2 setTextColor:[Theme Singleton].colorTextDark];
    [self.statusLine3 setTextColor:[Theme Singleton].colorTextDark];
    [self.segmentedControlCopyEmailSMS setTintColor:[Theme Singleton].colorTextDark];
}

- (void)updateViews:(NSNotification *)notification
{
    if (abcAccount.arrayWallets && abcAccount.currentWallet)
    {
        self.buttonSelector.arrayItemsToSelect = abcAccount.arrayWalletNames;
        [self.buttonSelector.button setTitle:abcAccount.currentWallet.name forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = abcAccount.currentWalletIndex;

        NSString *walletName = [NSString stringWithFormat:@"To: %@ ▼", abcAccount.currentWallet.name];
        [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle:) fromObject:self];

        self.keypadView.currency = abcAccount.currentWallet.currency;

        [self updateTextFieldContents:NO];

        if (!([abcAccount.arrayWallets containsObject:abcAccount.currentWallet]))
        {
            self.textUnderQRCode.text = walletHasBeenArchivedText;
            self.qrCodeImageView.hidden = YES;
            self.statusLine1.hidden = YES;
            self.statusLine2.hidden = YES;
            self.statusLine3.hidden = YES;
            self.segmentedControlCopyEmailSMS.hidden = YES;
        }
        else
        {
            self.textUnderQRCode.text = generatingQRCode;
            self.qrCodeImageView.hidden = NO;
            self.statusLine1.hidden = NO;
            self.statusLine2.hidden = NO;
            self.statusLine3.hidden = NO;
            self.segmentedControlCopyEmailSMS.hidden = NO;
        }
    }
    [MainViewController changeNavBar:self title:closeButtonText side:NAV_BAR_LEFT button:true enable:bWalletListDropped action:@selector(didTapTitle:) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(info:) fromObject:self];

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
        ABCLog(2,@"Removing all BLE services and stopping advertising");
        [self.peripheralManager removeAllServices];
        [self.peripheralManager stopAdvertising];
        _peripheralManager = nil;
    }
    if (self.qrTimer)
        [self.qrTimer invalidate];

    [abcAccount.currentWallet deprioritizeAllAddresses];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)showingQRCode:(NSString *)walletUUID withTx:(NSString *)txId
{
//    if (_qrViewController == nil || _qrViewController.addressString == nil)
    if (addressString == nil)
    {
        return NO;
    }
    ABCWallet *wallet = [abcAccount getWallet:walletUUID];
    
    ABCTransaction *transaction = [wallet getTransaction:txId];
    for (ABCTxInOut *output in transaction.inputOutputList)
    {
        if (!output.isInput
            && [addressString isEqualToString:output.address])
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

- (void)resetViews
{
    if (_recipientViewController)
    {
        [_recipientViewController.view removeFromSuperview];
        [_recipientViewController removeFromParentViewController];
        _recipientViewController = nil;
    }

    self.BTC_TextField.text = @"";
	self.USD_TextField.text = @"";
    self.amountSatoshiReceived = 0;
    self.amountSatoshiRequested = 0;
    self.state = kRequest;
}


#pragma mark - Action Methods

- (IBAction)Refresh
{
    if (abcAccount.arrayWallets && abcAccount.currentWallet)
    {
        _refreshButton.hidden = YES;
        _refreshSpinner.hidden = NO;
        [abcAccount.currentWallet refreshServer:NO notify:^
        {
            [NSThread sleepForTimeInterval:2.0f];
            _refreshSpinner.hidden = YES;
            _refreshButton.hidden = NO;
        }];
    }
}

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
        if (pb && addressString)
        {
            [pb setString:addressString];
            [MainViewController fadingAlert:requestIsCopiedToClipboardText];
        }
        else
        {
            [MainViewController fadingAlert:errorOccurredCopyingToClipboard];
        }
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
    [InfoView CreateWithHTML:@"info_request" forView:self.view];
}

//
// Implement the state machine of the QR code screen based on Merchant Mode, amount received, amount requested. All of which could change at any time.
// Returns new state

- (RequestState)updateQRCode:(SInt64)incomingSatoshi
{
    ABCLog(2,@"ENTER updateQRCode");

    BOOL bChangeRequest = false;

    BOOL mm = [LocalSettings controller].bMerchantMode;
    self.amountSatoshiReceived += incomingSatoshi;
    self.amountSatoshiRequested = [abcAccount.settings.denomination btcStringToSatoshi:self.BTC_TextField.text];
    SInt64 remaining = self.amountSatoshiRequested;

    if (self.previousAmountSatoshiRequested != self.amountSatoshiRequested)
    {
        self.previousAmountSatoshiRequested = self.amountSatoshiRequested;
        bChangeRequest = true;
    }
    if (previousWalletUUID != abcAccount.currentWallet.uuid)
    {
        previousWalletUUID = abcAccount.currentWallet.uuid;
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

    self.statusLine1.text = @"";
    self.statusLine2.text = @"";

    switch (self.state) {
        case kRequest:
        case kNone:
        case kDone:
        {
            self.statusLine2.text = waitingForPaymentText;
            break;
        }
        case kPartial:
        {
            remaining = self.amountSatoshiRequested - self.amountSatoshiReceived;
            NSString *string = amountRequestedString;
            self.statusLine1.text = [NSString stringWithFormat:@"%@ %@",[abcAccount.settings.denomination satoshiToBTCString:self.amountSatoshiRequested],string];

            string = amountRemainingString;
            self.statusLine2.text = [NSString stringWithFormat:@"%@ %@",[abcAccount.settings.denomination satoshiToBTCString:remaining],string];
            break;
        }
        case kDonation:
        {

            if (self.amountSatoshiReceived > 0)
            {
                NSString *string = amountReceivedString;
                self.statusLine2.text = [NSString stringWithFormat:@"%@ %@",[abcAccount.settings.denomination satoshiToBTCString:self.amountSatoshiReceived],string];
            }
            else
            {
                self.statusLine2.text = waitingForPaymentText;
            }
            break;
        }
    }

    ABCWallet *wallet = [self getCurrentWallet];
    NSNumber *nsRemaining = [NSNumber numberWithLongLong:remaining];

    //
    // Change the QR code. This is a slow call so put it in a queue and timer. Timer fires every 1 second
    //

    if (self.qrTimer)
        [self.qrTimer invalidate];

    NSArray *args = [NSArray arrayWithObjects:strName,wallet,strNotes,strCategory,nsRemaining,nil];

    ABCLog(2,@"updateQRCode setTimer req=%llu", [nsRemaining longLongValue]);
    self.qrTimer = [NSTimer scheduledTimerWithTimeInterval:[Theme Singleton].qrCodeGenDelayTime target:self selector:@selector(updateQRAsync:) userInfo:args repeats:NO];


    if (incomingSatoshi)
    {
        [self showPaymentPopup:self.state amount:incomingSatoshi];
    }

    if([LocalSettings controller].bDisableBLE)
    {
        self.BLE_LogoImageView.hidden = YES;
    }

    return self.state;
    ABCLog(2,@"EXIT updateQRCode");

}

- (void)updateQRAsync:(NSTimer *)timer
{
    NSArray *args = [timer userInfo];
    
    if ([args count] != 5)
        return;
    
    int i = 0;

    NSString *strName = [args objectAtIndex:i++];
    ABCWallet *wallet = [args objectAtIndex:i++];

    NSString *strNotes = [args objectAtIndex:i++];
    NSString *strCategory = [args objectAtIndex:i++];
    NSNumber *nsRemaining = [args objectAtIndex:i++];

    SInt64 remaining = [nsRemaining longLongValue];


//    ABCReceiveAddress *receiveAddress = [ABCReceiveAddress alloc];

    [wallet createNewReceiveAddress:^(ABCReceiveAddress *receiveAddress){
        
        receiveAddress.metaData.payeeName       = strName;
        receiveAddress.metaData.category        = strCategory;
        receiveAddress.metaData.notes           = strNotes;
        receiveAddress.amountSatoshi            = remaining;
        
        UIImage *qrImage;

        self.abcReceiveAddress = receiveAddress;
        addressString = receiveAddress.address;
        _uriString = receiveAddress.uri;
        qrImage = receiveAddress.qrCode;

        self.statusLine3.text = addressString;
        self.qrCodeImageView.image = qrImage;

        [self.abcReceiveAddress prioritizeAddress:YES];

        if (self.peripheralManager.isAdvertising)
        {
            ABCLog(2, @"Removing all BLE services and stopping advertising");
            [self.peripheralManager removeAllServices];
            [self.peripheralManager stopAdvertising];
            _peripheralManager = nil;
        }

        if (![LocalSettings controller].bDisableBLE)
        {
            // Start up the CBPeripheralManager.  Warn if settings BLE is on but device BLE is off (but only once every 24 hours)
            NSTimeInterval curTime = CACurrentMediaTime();
            if ((curTime - lastPeripheralBLEPowerOffNotificationTime) > 86400.0) //24 hours
            {
                _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:@{CBPeripheralManagerOptionShowPowerAlertKey : @(YES)}];
            }
            else
            {
                _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:@{CBPeripheralManagerOptionShowPowerAlertKey : @(NO)}];
            }
            lastPeripheralBLEPowerOffNotificationTime = curTime;
        }

    }                                 error:^(NSError *error)
    {

    }];

}

#pragma mark - Notification Handlers

- (void)exchangeRateUpdate: (NSNotification *)notification
{
    ABCLog(2,@"Updating exchangeRateUpdate");
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

    NSString *string = enterAmountOptionalText;
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

    bottomField.placeholder = @"";
    [bottomLabel setFont:[UIFont fontWithName:@"Lato-Regular" size:bottomTextSize]];
    [bottomLabel setTextColor:[Theme Singleton].colorRequestBottomTextField];
    [bottomField setFont:[UIFont fontWithName:@"Lato-Regular" size:bottomTextSize]];
    [bottomField setTextColor:[Theme Singleton].colorRequestBottomTextField];
    [bottomField setTintColor:[UIColor lightGrayColor]];
    [bottomField setEnabled:false];

}

- (void)updateTextFieldContents:(BOOL)allowBTCUpdate
{
    
    ABCWallet *wallet = [self getCurrentWallet];
    
    self.exchangeRateLabel.text = [wallet conversionString];
//XXX    self.USDLabel_TextField.text = wallet.currencyAbbrev;
    [self.segmentedControlBTCUSD setTitle:wallet.currency.code forSegmentAtIndex:0];
    _fiatLabel.text = wallet.currency.code;

    if (_selectedTextField == self.BTC_TextField)
	{
		double currency;
        int64_t satoshi = [abcAccount.settings.denomination btcStringToSatoshi:self.BTC_TextField.text];

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
            currency = [abcAccount.exchangeCache satoshiToCurrency:satoshi
                                                      currencyCode:wallet.currency.code
                                                             error:nil];
            self.USD_TextField.text =
            [wallet.currency doubleToPrettyCurrencyString:currency
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
            satoshi = [abcAccount.exchangeCache currencyToSatoshi:currency currencyCode:wallet.currency.code
                                                            error:nil];
            self.BTC_TextField.text = [abcAccount.settings.denomination satoshiToBTCString:satoshi
                                                                                withSymbol:false
                                                                              cropDecimals:YES];
        }
	}

    [self updateQRCode:0];
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
    [MainViewController changeNavBar:self title:closeButtonText side:NAV_BAR_LEFT button:true enable:bWalletListDropped action:@selector(didTapTitle:) fromObject:self];


}

#pragma mark - Calculator delegates



- (void)CalculatorDone:(CalculatorView *)calculator
{
    [self didTouchQRCode:nil];
}

- (void)CalculatorValueChanged:(CalculatorView *)calculator
{
    self.amountSatoshiReceived = 0;
	[self updateTextFieldContents:YES];
}


#pragma mark - ButtonSelectorView2 delegates

- (void)ButtonSelector2:(ButtonSelectorView2 *)view selectedItem:(int)itemIndex
{
    NSIndexPath *indexPath = [[NSIndexPath alloc]init];
    indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [abcAccount makeCurrentWalletWithIndex:indexPath];

    bWalletListDropped = false;
}

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

}

- (ABCWallet *) getCurrentWallet
{
    return abcAccount.currentWallet;
}

-(void)showConnectedPopup
{
    NSString *line1;
    NSString *line2;
    NSString *line3;
    UIImage *image;

    line1 = self.connectedName;
    line2 = @"";
    line3 = connectedText;

    //see if there is a match between advertised name and name in contacts.  If so, use the photo from contacts
    BOOL imageIsFromContacts = NO;

    NSArray *arrayComponents = [self.connectedName componentsSeparatedByString:@" "];
    if(arrayComponents.count >= 2)
    {
        //filter off the nickname.  We just want first name and last name
        NSString *firstName = [arrayComponents objectAtIndex:0];
        NSString *lastName = [arrayComponents objectAtIndex:1];
        NSString *name = [NSString stringWithFormat:@"%@ %@", firstName, lastName ];

        image = [[MainViewController Singleton].dictImages objectForKey:[name lowercaseString]];
        if (image)
            imageIsFromContacts = YES;
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

}

-(void)showPaymentPopup:(RequestState)state amount:(SInt64) amountSatoshi
{
    NSString *line1;
    NSString *line2;
    NSString *line3;
    UIImage *image;

    NSTimeInterval delay;
    NSTimeInterval duration;

    ABCWallet *wallet = [self getCurrentWallet];


    switch (state) {
        case kPartial:
        {
            delay = 4.0;
            duration = 2.0;
            line1 = warningWithAsterisks;
            line2 = @"";
            line3 = partialPaymentText;
            image = [UIImage imageNamed:@"Warning_icon.png"];
            [[AudioController controller] playPartialReceived];
            break;
        }
        case kDonation:
        {
            delay = 7.0;
            duration = 2.0;
            image = [UIImage imageNamed:@"bitcoin_symbol.png"];
            line1 = paymentReceivedText;
            double currency;
            currency = [abcAccount.exchangeCache satoshiToCurrency:amountSatoshi
                                                      currencyCode:wallet.currency.code
                                                            error:nil];
            NSString *fiatSymbol = wallet.currency.symbol;
            NSString *fiatAmount = [NSString stringWithFormat:@"%.2f", currency];
            NSString *fiat = [fiatSymbol stringByAppendingString:fiatAmount];
            line2 = [abcAccount.settings.denomination satoshiToBTCString:amountSatoshi];
            line3 = fiat;
            
            [[AudioController controller] playReceived];
            break;
        }
        default:
        {
            if ([LocalSettings controller].bMerchantMode && self.state == kDone)
            {
                // In merchant mode, popup up the keyboard after a full payment is made
                [self changeCalculator:YES show:YES];
            }
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
        //ABCLog(2,@"self.peripheralManager powered on.");

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

        BOOL sendName = abcAccount.settings.bNameOnPayments;

        NSString *name;
        if(sendName)
        {
            name = abcAccount.settings.fullName ;
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
    //ABCLog(2,@"didReceiveWriteRequests");
    for(CBATTRequest *request in requests)
    {
        if([request.characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
        {
            NSString *userName = [[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding];
            //ABCLog(2,@"Received new string: %@", userName);

            self.connectedName = userName;
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
    //ABCLog(2,@"didReceiveReadRequests");

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
            ABCLog(2,@"powered on");
            return TRUE;
        case CBPeripheralManagerStateUnknown:
            ABCLog(2,@"state unknown");
            return FALSE;
        default:
            return FALSE;
    }
    ABCLog(2,@"Peripheral manager state: %@", state);
    return FALSE;
}

- (void)replaceRequestTags:(NSString **) strContent
{
    ABCDenomination *BTCDenom = [ABCDenomination getDenominationForMultiplier:ABCDenominationMultiplierBTC];
    ABCDenomination *bitsDenom = [ABCDenomination getDenominationForMultiplier:ABCDenominationMultiplierUBTC];
    
    NSString *amountBTC = [BTCDenom satoshiToBTCString:_amountSatoshiRequested
                                            withSymbol:false
                                          cropDecimals:NO];
    NSString *amountBits = [bitsDenom satoshiToBTCString:_amountSatoshiRequested
                                              withSymbol:false
                                            cropDecimals:NO];
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

    if (abcAccount.settings.bNameOnPayments && abcAccount.settings.fullName)
    {
        name = [NSString stringWithString:abcAccount.settings.fullName];
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
        NSString *path = [[NSBundle mainBundle] pathForResource:@"email_template" ofType:@"html"];
        NSString* content = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
        [self replaceRequestTags:&content];
        [Util replaceHtmlTags:&content];

        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];

        if ([self.strEMail length])
        {
            [mailComposer setToRecipients:[NSArray arrayWithObject:self.strEMail]];
        }

        NSString *subject;

        if (abcAccount.settings.bNameOnPayments && abcAccount.settings.fullName)
        {
            subject = [NSString stringWithFormat:bitcoinRequestFormatString, appTitle, abcAccount.settings.fullName];
        }
        else
        {
            subject = [NSString stringWithFormat:bitcoinRequestFromFormatString, appTitle];
        }

        [mailComposer setSubject:subject];

        [mailComposer setMessageBody:content isHTML:YES];

        NSData *imgData;

        UIImage *imageAttachment = [self imageWithImage:self.qrCodeImageView.image scaledToSize:CGSizeMake(QR_ATTACHMENT_WIDTH, QR_ATTACHMENT_WIDTH)];
        imgData = [NSData dataWithData:UIImageJPEGRepresentation(imageAttachment, 1.0)];
        [mailComposer addAttachmentData:imgData mimeType:@"image/jpeg" fileName:@"qrcode.jpg"];

        mailComposer.mailComposeDelegate = self;

        [self presentViewController:mailComposer animated:YES completion:nil];

        _requestType = emailText;
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:cantSendEmailText
                                                       delegate:nil
                                              cancelButtonTitle:okButtonText
                                              otherButtonTitles:nil];
        [alert show];
    }
}



- (void)sendSMS
{
    //ABCLog(2,@"sendSMS to: %@ / %@", self.strFullName, self.strPhoneNumber);

    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    if ([MFMessageComposeViewController canSendText] && [MFMessageComposeViewController canSendAttachments])
    {

        NSError* error = nil;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"sms_template" ofType:@"txt"];
        NSString* content = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
        [self replaceRequestTags:&content];
        [Util replaceHtmlTags:&content];

        // create the attachment
        UIImage *imageAttachment = [self imageWithImage:self.qrCodeImageView.image scaledToSize:CGSizeMake(QR_ATTACHMENT_WIDTH, QR_ATTACHMENT_WIDTH)];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:QR_CODE_TEMP_FILENAME];
        BOOL bAttached = [controller addAttachmentData:UIImagePNGRepresentation(imageAttachment) typeIdentifier:(NSString*)kUTTypePNG filename:filePath];
        if (!bAttached)
        {
            ABCLog(2,@"Could not attach qr code");
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

        _requestType = smsText;
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

    [Util addSubviewControllerWithConstraints:self child:self.recipientViewController];
    [MainViewController animateSlideIn:self.recipientViewController];
}

- (void)dismissRecipient
{
    [MainViewController animateOut:self.recipientViewController withBlur:NO complete:nil];
    self.recipientViewController = nil;
    [MainViewController changeNavBarOwner:self];
    [self updateViews:nil];
}

// used by the guesture recognizer to ignore exit
- (BOOL)haveSubViewsShowing
{
    return (self.recipientViewController != nil);
}


- (void)saveRequest
{
    if (_strFullName) {
        self.abcReceiveAddress.metaData.payeeName = _strFullName;
    } else if (_strEMail) {
        self.abcReceiveAddress.metaData.payeeName = _strFullName;
    } else if (_strPhoneNumber) {
        self.abcReceiveAddress.metaData.payeeName = _strPhoneNumber;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSDate *now = [NSDate date];
    
    ABCWallet *wallet = abcAccount.currentWallet;
    self.abcReceiveAddress.amountSatoshi = _amountSatoshiRequested;
    
    double currency;
    currency = [abcAccount.exchangeCache satoshiToCurrency:self.abcReceiveAddress.amountSatoshi
                                              currencyCode:wallet.currency.code
                                                     error:nil];
    
    // Set notes
    NSMutableString *notes = [[NSMutableString alloc] init];
    [notes appendFormat:requestNotesFormatString,
     [abcAccount.settings.denomination satoshiToBTCString:self.abcReceiveAddress.amountSatoshi],
     [wallet.currency doubleToPrettyCurrencyString:currency],
     _requestType, [dateFormatter stringFromDate:now]];
    self.abcReceiveAddress.metaData.notes = notes;

    [self.abcReceiveAddress modifyRequestWithDetails];
}

#pragma mark - MFMessageComposeViewController delegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    switch (result)
    {
        case MessageComposeResultCancelled:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:appTitle
                                                            message:smsCancelledText
                                                           delegate:nil
                                                  cancelButtonTitle:okButtonText
                                                  otherButtonTitles:nil];
            [alert show];
        }
            break;

        case MessageComposeResultFailed:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:appTitle
                                                            message:errorSendingSMS
                                                           delegate:nil
                                                  cancelButtonTitle:okButtonText
                                                  otherButtonTitles:nil];
            [alert show];
        }
            break;

        case MessageComposeResultSent:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:appTitle
                                                            message:smsSent
                                                           delegate:nil
                                                  cancelButtonTitle:okButtonText
                                                  otherButtonTitles:nil];
            [alert show];
            [self.abcReceiveAddress finalizeRequest];
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
    NSString *strTitle = appTitle;
    NSString *strMsg = nil;

    switch (result)
    {
        case MFMailComposeResultCancelled:
            strMsg = emailCancelled;
            break;

        case MFMailComposeResultSaved:
            strMsg = emailSavedToSendLater;
            break;

        case MFMailComposeResultSent:
            strMsg = emailSent;
            [self.abcReceiveAddress finalizeRequest];
            break;

        case MFMailComposeResultFailed:
        {
            strTitle = errorSendingEmail;
            strMsg = [error localizedDescription];
            break;
        }
        default:
            break;
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle
                                                    message:strMsg
                                                   delegate:nil
                                          cancelButtonTitle:okButtonText
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

        //ABCLog(2,@"name: %@, target: %@", strFullName, strTarget);

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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:appTitle
                                                        message:(controller.mode == RecipientMode_SMS ? smsCancelledText : emailCancelled)
                                                       delegate:nil
                                              cancelButtonTitle:okButtonText
                                              otherButtonTitles:nil];
        [alert show];
    }

    [self dismissRecipient];
}

@end

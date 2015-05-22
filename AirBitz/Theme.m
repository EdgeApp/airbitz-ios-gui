//
//  Theme.m
//  AirBitz
//
//  Created by Paul Puey on 5/2/15.
//  Copyright (c) 2015 AirBitz. All rights reserved.
//

#import "Theme.h"
#import "Util.h"

static BOOL bInitialized = NO;

@implementation Theme

static Theme *singleton = nil;  // this will be the one and only object this static singleton class has

+ (void)initAll
{
    if (NO == bInitialized)
    {
        singleton = [[Theme alloc] init];
        bInitialized = YES;
    }
}

+ (void)freeAll
{
    if (YES == bInitialized)
    {
        // release our singleton
        singleton = nil;
        
        bInitialized = NO;
    }
}

+ (Theme *)Singleton
{
    return singleton;
}

- (id)init
{
    self = [super init];

    //    self.denomination = 100000000;
    self.colorTextBright = [UIColor whiteColor];
    self.colorTextDark = UIColorFromARGB(0xff0C578C);;
    self.colorTextLink = UIColorFromARGB(0xFF007aFF);
    self.deleteAccountWarning = NSLocalizedString(@"Delete '%@' on this device? This will disable access via PIN. If 2FA is enabled on this account, this device will not be able to login without a 2FA reset which takes 7 days.", @"Delete Account Warning");
    self.colorSendButton = UIColorFromARGB(0xFF80c342);
    self.colorRequestButton = UIColorFromARGB(0xff2291cf);

    self.colorRequestButtonDisabled = UIColorFromARGB(0x5580c342);
    self.colorSendButtonDisabled = UIColorFromARGB(0x55006698);

    self.colorRequestTopTextField = self.colorTextBright;
    self.colorRequestTopTextFieldPlaceholder = UIColorFromARGB(0xffdddddd);
    self.colorRequestBottomTextField = self.colorTextDark;

    self.appFont = @"Lato-Regular";

    self.backButtonText = NSLocalizedString(@"Back", @"Back button text on top left");
    self.exitButtonText = NSLocalizedString(@"Exit", @"Exit button text on top left");
    self.helpButtonText = NSLocalizedString(@"Help", @"Help button text on top right");
    self.infoButtonText = NSLocalizedString(@"Info", @"Info button text on top right");
    self.doneButtonText = NSLocalizedString(@"Done", @"Generic DONE button text");
    self.cancelButtonText = NSLocalizedString(@"CANCEL", @"Generic CANCEL button text");
    self.exportButtonText = NSLocalizedString(@"Export", @"EXPORT button text for wallet export");
    self.renameButtonText = NSLocalizedString(@"Rename", @"RENAME button text for wallet rename");
    self.walletBalanceHeaderText = NSLocalizedString(@"TOTAL: ", @"Prefix of wallet balance dropdown header");
    self.walletNameHeaderText = NSLocalizedString(@"Wallet: ", @"Prefix of wallet name on rename popup");
    self.renameWalletWarningText = NSLocalizedString(@"Wallet name must have at least one character", nil);
    self.transactionCellNoTransactionsText = NSLocalizedString(@"No Transactions", @"what to display when wallet has no transactions");
    self.transactionCellNoTransactionsFoundText = NSLocalizedString(@"No Transactions Found", @"what to display when no transactions are found in search");
    self.fiatText = NSLocalizedString(@"Fiat", @"Fiat");
    self.walletHeaderButtonHelpText = NSLocalizedString(@"To sort wallets, tap and drag the 3 bars to the right of a wallet. Drag below the [ARCHIVE] header to archive the wallet", @"Popup wallet help test");
    self.walletHasBeenArchivedText = NSLocalizedString(@"This wallet has been archived. Please select a different wallet from the [Wallets] tab below", @"Popup sessage for when a wallet is archived");
    self.walletsPopupHelpText = NSLocalizedString(@"Tap and hold a wallet for additional options", nil);
    self.selectWalletTransferPopupHeaderText = NSLocalizedString(@"↓ Choose a wallet to transfer funds to ↓", @"Header of popup in SendView from wallet to wallet transfer");
    self.invalidAddressPopupText = NSLocalizedString(@"Invalid Bitcoin Address", nil);
    self.enterBitcoinAddressPopupText= NSLocalizedString(@"Send to Bitcoin Address", nil);
    self.enterBitcoinAddressPlaceholder                     = NSLocalizedString(@"Bitcoin Address or URI", nil);
    self.enterPrivateKeyPopupText                           = NSLocalizedString(@"Sweep Funds From Private Key", nil);
    self.enterPrivateKeyPlaceholder                         = NSLocalizedString(@"Bitcoin Private Key", nil);
    self.smsText                                            = NSLocalizedString(@"SMS", @"text for textmessage/SMS");
    self.emailText                                          = NSLocalizedString(@"Email", @"text for Email");
    self.sendScreenHelpText                                 = NSLocalizedString(@"Scan the QR code of payee to send payment or tap on a bluetooth request from the list below", nil);
    self.creatingWalletText                                 = NSLocalizedString(@"Creating and securing wallet", nil);
    self.createAccountAndTransferFundsText                  = NSLocalizedString(@"Please create a new account and transfer your funds if you forgot your password.", nil);
    self.createPasswordForAccountText                       = NSLocalizedString(@"Please create a password for this account or you will not be able to recover your account if your device is lost or stolen.", nil);
    self.settingsText                                       = NSLocalizedString(@"Settings", nil);

    self.sendRequestButtonDisabled = 0.4f;

    self.animationDurationTimeDefault           = 0.35;     // How long the animation transition should take
    self.animationDelayTimeDefault              = 0.0;      // Delay until animation starts. Should always be zero
    self.animationCurveDefault                  = UIViewAnimationOptionCurveEaseOut;

    self.alertHoldTimeDefault                   = 4.0;      // How long to hold the alert before going away
    self.alertFadeoutTimeDefault                = 2.0;      // How much time it takes to animate the fade away
    self.alertHoldTimePaymentReceived           = 10;       // Hold time for payments
    self.alertHoldTimeHelpPopups                = 6.0;      // Hold time for auto popup help


    self.backgroundApp = [UIImage imageNamed:@"postcard-mountain-blue.jpg"];
    self.backgroundLogin = [UIImage imageNamed:@"postcard-mountain.png"];

//    if (IS_IPHONE4)
    {
        self.heightListings = 90.0;
        self.heightWalletHeader = 44.0;
        self.heightSearchClues = 35.0;
        self.fadingAlertDropdownHeight = 80;
        self.heightBLETableCells = 50;
        self.heightWalletCell = 60;
        self.heightTransactionCell = 72;
        self.heightPopupPicker = 50;
        self.heightMinimumForQRScanFrame = 200;
        self.elementPadding = 5; // Generic padding between elements
        self.heightSettingsTableCell            = 40.0;
        self.heightSettingsTableHeader          = 60.0;
    }
    if (IS_MIN_IPHONE5)
    {
        self.heightListings = 110.0;
        self.heightWalletHeader = 50.0;
        self.heightSearchClues = 40.0;
        self.heightBLETableCells = 55;
        self.heightPopupPicker = 55;
    }
    if (IS_MIN_IPHONE6)
    {
        self.heightListings = 120.0;
        self.heightSearchClues = 45.0;
        self.heightBLETableCells = 65;
        self.heightPopupPicker = 60;
        self.heightSettingsTableCell            = 45.0;
        self.heightSettingsTableHeader          = 65.0;
    }
    if (IS_MIN_IPHONE6_PLUS)
    {
        self.heightWalletHeader = 55.0;
        self.heightListings = 130.0;
        self.heightSearchClues = 45.0;
        self.heightBLETableCells = 70;
        self.heightPopupPicker = 65;
    }
    if (IS_MIN_IPAD_MINI)
    {
        self.heightBLETableCells = 75;
    }

    if ([[UIDevice currentDevice].systemVersion hasPrefix:@"7"])
    {
        self.bTranslucencyEnable = NO;
    }
    else
    {
        self.bTranslucencyEnable = YES;
    }
    return self;
}

@end

//
//  Theme.m
//  AirBitz
//
//  Created by Paul Puey on 5/2/15.
//  Copyright (c) 2015 AirBitz. All rights reserved.
//

#import "Theme.h"
#import "Util.h"
#import <sys/sysctl.h>

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

    self.appTitle = @"Airbitz";
    self.supportEmail = @"support@airbitz.co";
    self.appStoreLink = @"https://itunes.apple.com/us/app/airbitz/id843536046";
    self.playStoreLink = @"https://play.google.com/store/apps/details?id=com.airbitz";

#ifdef WL_COINBTM
    self.appTitle = @"Rack";
    self.supportEmail = @"support@coinbtm.com";
    self.appStoreLink = @"https://itunes.apple.com/us/app/airbitz/id843536046";
    self.playStoreLink = @"https://play.google.com/store/apps/details?id=com.airbitz";
#endif

    //    self.denomination = 100000000;
    self.colorTextBright = [UIColor whiteColor];
    self.colorTextDark = UIColorFromARGB(0xff0C578C);;
    self.colorTextLink = UIColorFromARGB(0xFF007aFF);
    self.colorTextLinkOnDark = UIColorFromARGB(0xFFBFDFFF);
    self.deleteAccountWarning = NSLocalizedString(@"Delete '%@' on this device? This will disable access via PIN. If 2FA is enabled on this account, this device will not be able to login without a 2FA reset which takes 7 days.", @"Delete Account Warning");
    self.colorButtonGreen = UIColorFromARGB(0xff80C342);
    self.colorButtonBlue = UIColorFromARGB(0xff2291CF);
    self.colorSendButton = self.colorButtonBlue;
    self.colorRequestButton = self.colorButtonGreen;

    self.colorRequestButtonDisabled = UIColorFromARGB(0x5580c342);
    self.colorSendButtonDisabled = UIColorFromARGB(0x55006698);

    self.colorRequestTopTextField = self.colorTextBright;
    self.colorRequestTopTextFieldPlaceholder = UIColorFromARGB(0xffdddddd);
    self.colorRequestBottomTextField = self.colorTextDark;

    self.bdButtonBlue = UIColorFromARGB(0xff0079B9);
    self.colorsProfileIcons = [[NSMutableArray alloc] init];

    [self.colorsProfileIcons addObject:UIColorFromRGB(0xec6a5e)];
    [self.colorsProfileIcons addObject:UIColorFromRGB(0xff9c00)];
    [self.colorsProfileIcons addObject:UIColorFromRGB(0xf4d347)];
    [self.colorsProfileIcons addObject:UIColorFromRGB(0x7ccc52)];
    [self.colorsProfileIcons addObject:UIColorFromRGB(0x66aee4)];
    [self.colorsProfileIcons addObject:UIColorFromRGB(0x5ee0ec)];
    [self.colorsProfileIcons addObject:UIColorFromRGB(0xb400ff)];
    [self.colorsProfileIcons addObject:UIColorFromRGB(0x777777)];

    self.appFont = @"Lato-Regular";

    self.backButtonText = NSLocalizedString(@"Back", @"Back button text on top left");
    self.exitButtonText = NSLocalizedString(@"Exit", @"Exit button text on top left");
    self.helpButtonText = NSLocalizedString(@"Help", @"Help button text on top right");
    self.infoButtonText = NSLocalizedString(@"Info", @"Info button text on top right");
    self.doneButtonText = NSLocalizedString(@"Done", @"Generic DONE button text");
    self.cancelButtonText = NSLocalizedString(@"CANCEL", @"Generic CANCEL button text");
    self.closeButtonText = NSLocalizedString(@"Close", @"Generic CLOSE button text");
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
    self.selectWalletTransferPopupHeaderText = NSLocalizedString(@"▼ Choose a wallet to transfer funds to ▼", @"Header of popup in SendView from wallet to wallet transfer");
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
    self.categoriesText                                     = NSLocalizedString(@"Categories", nil);
    self.signupText                                         = NSLocalizedString(@"Sign Up", nil);
    self.changePasswordText                                 = NSLocalizedString(@"Change Password", nil);
    self.changePINText                                      = NSLocalizedString(@"Change PIN", nil);
    self.twoFactorText                                      = NSLocalizedString(@"Two Factor", nil);
    self.importText                                         = NSLocalizedString(@"Import", nil);
    self.buySellText                                        = NSLocalizedString(@"Buy/Sell (Beta)", nil);
    self.passwordRecoveryText                               = NSLocalizedString(@"Password Recovery", nil);
    self.passwordMismatchText                               = NSLocalizedString(@"Password does not match re-entered password", @"");
    self.defaultCurrencyInfoText                            = NSLocalizedString(@"Note: Default Currency setting is only used for new wallets and to show total balance of account. Create a new wallet to change the fiat currency shown in each transaction.", nil);
    self.touchIDPromptText                                  = NSLocalizedString(@"Touch to login user", @"Touch ID prompt text");
    self.usePINText                                         = NSLocalizedString(@"Use PIN", @"Touch ID [Use PIN] button");
    self.usePasswordText                                    = NSLocalizedString(@"Use Password", @"Touch ID [Use Password] button");
    self.twofactorWarningText                               = NSLocalizedString(@"Two Factor Enabled\n\n** Warning **\n\nIf you lose your device or uninstall the app, it will take 7 days to disable 2FA and access your account.\"", @"2FA warning on enable");
    self.loadingWalletsText                                 = NSLocalizedString(@"Loading Wallets...", @"Loading wallets alert text");
    self.loadingWalletsNewDeviceText                        = NSLocalizedString(@"This may take a few minutes as it is the first time logging into this device.", @"Loading Wallets alert text");
    self.loadingTransactionsText                            = NSLocalizedString(@"Loading Transactions...", @"Loading Transactions alert text");
    self.synchronizingText                                  = NSLocalizedString(@"Synchronizing", @"Synchronizing text in confirmation textfield");
    self.pendingText                                        = NSLocalizedString(@"Pending", @"Pending status in transaction list");
    self.doubleSpendText                                    = NSLocalizedString(@"Warning: Double Spend", @"Double spend status in transaction list");
    self.confirmationText                                   = NSLocalizedString(@"Confirmation", @"Num of confirmations in transaction list");
    self.confirmationsText                                  = NSLocalizedString(@"Confirmations", @"Num of confirmations in transaction list");
    self.confirmedText                                      = NSLocalizedString(@"Confirmed", @"Confirmed status in transaction list");
    self.loadingText                                        = NSLocalizedString(@"Loading", @"Loading...");
    self.uploadingLogText                                   = NSLocalizedString(@"Uploading logfile. Please wait...", @"Uploading logfile fading popup");
    self.uploadSuccessfulText                               = NSLocalizedString(@"Upload Successful", @"Upload Successful fading popup");
    self.uploadFailedText                                   = NSLocalizedString(@"Upload Failed", @"Upload Failed");
    self.watcherClearedText                                 = NSLocalizedString(@"Watcher Database Cleared. Please allow a few minutes to resync blockchain info. Transactions and balances may be inaccurate during sync", @"Watcher Database Cleared popup text");

//    self.                         = NSLocalizedString(@"", @"");

    self.sendRequestButtonDisabled = 0.4f;

    self.animationDurationTimeDefault           = 0.35;     // How long the animation transition should take
    self.animationDelayTimeDefault              = 0.0;      // Delay until animation starts. Should always be zero
    self.animationCurveDefault                  = UIViewAnimationOptionCurveEaseOut;

    self.alertHoldTimeDefault                   = 4.0;      // How long to hold the alert before going away
    self.alertFadeoutTimeDefault                = 2.0;      // How much time it takes to animate the fade away
    self.alertHoldTimePaymentReceived           = 10;       // Hold time for payments
    self.alertHoldTimeHelpPopups                = 6.0;      // Hold time for auto popup help

    self.qrCodeGenDelayTime                     = 0.75;     // Timer delay after keypad entry before new QR code is generated
    self.rotateServerInterval                   = 15.0;     // How long (in seconds) before we rotate libbitcoin servers while waiting on QR code screen
    self.walletLoadingTimerInterval             = 30.0;     // How long to wait between wallet updates on new device logins before we consider the account fully loaded

    self.backgroundApp = [UIImage imageNamed:@"postcard-mountain-blue.jpg"];
    self.backgroundLogin = [UIImage imageNamed:@"postcard-mountain.png"];

//    if (IS_IPHONE4)
    {
        self.heightListings = 90.0;
        self.heightLoginScreenLogo = 70;
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
        self.heightButton                       = 45.0;
        self.buttonFontSize                     = 15.0;
        self.fontSizeEnterPINText               = 16.0;     // Font size for PIN login screen "Enter PIN"

    }
    if (IS_MIN_IPHONE5)
    {
        self.heightListings = 110.0;
        self.heightLoginScreenLogo = 100;
        self.heightWalletHeader = 50.0;
        self.heightSearchClues = 40.0;
        self.heightBLETableCells = 55;
        self.heightPopupPicker = 55;
    }
    if (IS_MIN_IPHONE6)
    {
        self.heightSearchClues = 45.0;
        self.heightLoginScreenLogo = 120;
        self.heightBLETableCells = 65;
        self.heightPopupPicker = 60;
        self.heightSettingsTableCell            = 45.0;
        self.heightSettingsTableHeader          = 65.0;
        self.fontSizeEnterPINText               = 18.0;     // Font size for PIN login screen "Enter PIN"
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
        self.fontSizeEnterPINText               = 20.0;     // Font size for PIN login screen "Enter PIN"
    }

    ABLog(2,@"***Device Type: %@ %@", [self platform], [self platformString]);

    NSString *devtype = [self platform];


    if (0 ||
            [devtype hasPrefix:@"iPod"] ||
            [devtype hasPrefix:@"iPhone4"] ||
            [devtype hasPrefix:@"iPhone5"] ||
            [devtype hasPrefix:@"iPad1"] ||
            [devtype hasPrefix:@"iPad2"]
            )
    {
        self.bTranslucencyEnable = NO;
    }
    else
    {
        self.bTranslucencyEnable = YES;
    }
    return self;
}

- (NSString *)platform
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);

    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];

    free(machine);

    return platform;
}

- (NSString *)platformString
{
    NSString *platform = [self platform];

    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad mini 2G (WiFi)";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad mini 2G (Cellular)";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";

    return platform;
}

@end

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
    self.colorTextDark = [UIColor darkGrayColor];
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
    self.walletBalanceHeaderText = NSLocalizedString(@"TOTAL: ", @"Prefix of wallet balance dropdown header");
    self.transactionCellNoTransactionsText = NSLocalizedString(@"No Transactions", @"what to display when wallet has no transactions");
    self.transactionCellNoTransactionsFoundText = NSLocalizedString(@"No Transactions Found", @"what to display when no transactions are found in search");
    self.fiatText = NSLocalizedString(@"Fiat", @"Fiat");
    self.walletHeaderButtonHelpText = NSLocalizedString(@"To sort wallets, tap and drag the 3 bars to the right of a wallet. Drag below the [ARCHIVE] header to archive the wallet", @"Popup wallet help test");
    self.walletHasBeenArchivedText = NSLocalizedString(@"This wallet has been archived. Please select a different wallet from the [Wallets] tab below", @"Popup sessage for when a wallet is archived");
    self.walletsPopupHelpText = NSLocalizedString(@"Tap and hold a wallet for additional options", nil);
    self.sendRequestButtonDisabled = 0.4f;

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
        self.heightPopupPicker = 40;
    }
    if (IS_MIN_IPHONE5)
    {
        self.heightListings = 110.0;
        self.heightWalletHeader = 50.0;
        self.heightSearchClues = 40.0;
        self.heightBLETableCells = 55;
    }
    if (IS_MIN_IPHONE6)
    {
        self.heightListings = 120.0;
        self.heightSearchClues = 45.0;
        self.heightBLETableCells = 65;
    }
    if (IS_MIN_IPHONE6_PLUS)
    {
        self.heightWalletHeader = 55.0;
        self.heightListings = 130.0;
        self.heightSearchClues = 45.0;
        self.heightBLETableCells = 70;
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

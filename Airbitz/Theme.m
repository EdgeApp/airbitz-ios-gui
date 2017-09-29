//
//  Theme.m
//  AirBitz
//
//  Created by Paul Puey on 5/2/15.
//  Copyright (c) 2015 AirBitz. All rights reserved.
//

#import "Theme.h"
#import "Util.h"
#import "ABCUtil.h"

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

#pragma mark Brand Specific Constants
    
    self.defaultBTCDenominationMultiplier = DefaultBTCDenominationMultiplier;
    
    self.colorWhite = ColorWhite;
    self.colorLightGray = ColorLightGray;
    self.colorMidGray = ColorMidGray;
    self.colorDarkGray =  ColorDarkGray;
    self.colorLightPrimary = ColorLightPrimary;
    self.colorMidPrimary = ColorMidPrimary;
    self.colorDarkPrimary = ColorDarkPrimary;
    self.colorFirstAccent = ColorFirstAccent;
    self.colorSecondAccent = ColorSecondAccent;
    
    #ifdef ColorBackground
    self.colorBackground = ColorBackground;
    #else
    self.colorBackground = nil;
    #endif
    
    self.appFont = AppFont;
    self.appFontItalic = AppFontItalic;
    
#pragma mark Animation Constants

    self.animationDurationTimeDefault           = 0.20;     // How long the animation transition should take
    self.animationDurationTimeFast              = 0.15;     // How long the animation transition should take
    self.animationDurationTimeSlow              = 0.35;     // How long the animation transition should take
    self.animationDurationTimeVerySlow          = 0.50;     // How long the animation transition should take
    self.animationDelayTimeDefault              = 0.0;      // Delay until animation starts. Should always be zero
    self.animationCurveDefault                  = UIViewAnimationOptionCurveEaseOut;

    self.alertHoldTimeDefault                   = 4.0;      // How long to hold the alert before going away
    self.alertFadeoutTimeDefault                = 2.0;      // How much time it takes to animate the fade away
    self.alertHoldTimePaymentReceived           = 10;       // Hold time for payments
    self.alertHoldTimeHelpPopups                = 6.0;      // Hold time for auto popup help

#pragma mark Time Constants
    
    self.qrCodeGenDelayTime                     = 0.75;     // Timer delay after keypad entry before new QR code is generated

#pragma mark Images
    self.backgroundApp = [UIImage imageNamed:@"background-fade.jpg"];
    self.backgroundLogin = [UIImage imageNamed:@"background.jpg"];
    
//    if (IS_IPHONE4)
#pragma mark Layout Constants
    
    self.loginTitleTextShadowRadius = 0.5;
    self.pinEntryTextShadowRadius = 0.5;
    
    {
        self.heightListings = 90.0;
        self.heightLoginScreenLogo = 70;
        self.heightWalletHeader = 44.0;
        self.heightSearchClues = 35.0;
        self.fadingAlertDropdownHeight = 80;
        self.fadingAlertMiniDropdownHeight = 20;
        self.heightBLETableCells = 50;
        self.heightWalletCell = 60;
        self.heightTransactionCell = 65;
        self.heightPopupPicker = 50;
        self.heightMinimumForQRScanFrame = 200;
        self.elementPadding = 5; // Generic padding between elements
        self.heightSettingsTableCell            = 40.0;
        self.heightSettingsTableHeader          = 60.0;
        self.heightButton                       = 45.0;
        self.buttonFontSize                     = 15.0;
        self.fontSizeEnterPINText               = 18.0;     // Font size for PIN login screen "Enter PIN"
        self.fontSizeTxListBuyBitcoin           = 18.0;
        self.fontSizeTxListName                 = 15.0;
    }
    if (IS_MIN_IPHONE5)
    {
        self.heightListings = 110.0;
        self.heightLoginScreenLogo = 100;
        self.heightWalletHeader = 50.0;
        self.heightSearchClues = 40.0;
        self.heightBLETableCells = 55;
        self.heightPopupPicker = 55;
        self.fontSizeTxListName                 = 18.0;
    }
    if (IS_MIN_IPHONE6)
    {
        self.heightSearchClues = 45.0;
        self.heightLoginScreenLogo = 120;
        self.heightBLETableCells = 65;
        self.heightPopupPicker = 60;
        self.heightSettingsTableCell            = 55.0;
        self.heightSettingsTableHeader          = 65.0;
        self.fontSizeEnterPINText               = 18.0;     // Font size for PIN login screen "Enter PIN"
        self.fontSizeTxListBuyBitcoin           = 20.0;
    }
    if (IS_MIN_IPHONE6_PLUS)
    {
        self.heightWalletHeader = 55.0;
        self.heightListings = 130.0;
        self.heightSearchClues = 45.0;
        self.heightBLETableCells = 70;
        self.heightPopupPicker = 65;
        self.fontSizeTxListBuyBitcoin           = 22.0;
        self.fontSizeTxListName                 = 20.0;
    }
    if (IS_MIN_IPAD_MINI)
    {
        self.heightBLETableCells = 75;
        self.fontSizeEnterPINText               = 20.0;     // Font size for PIN login screen "Enter PIN"
    }

    ABCLog(1,@"***Device Type: %@ %@", [ABCUtil platform], [ABCUtil platformString]);

    NSString *devtype = [ABCUtil platform];

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
    
    #ifdef ColorBackground
    self.bTranslucencyEnable = NO;
    #endif
    
    return self;
}

@end

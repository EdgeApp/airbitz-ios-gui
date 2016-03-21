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

    //    self.denomination = 100000000;
    self.colorTextBright = [UIColor whiteColor];
    self.colorTextDark = UIColorFromARGB(0xff0C578C);
    self.colorTextLink = UIColorFromARGB(0xFF007aFF);
    self.colorTextLinkOnDark = UIColorFromARGB(0xFFBFDFFF);
    self.colorTextDarkGrey = UIColorFromARGB(0xFF404040);
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
    self.colorBackgroundHighlight = [UIColor colorWithRed:(76.0/255.0) green:(161.0/255.0) blue:(255.0/255.0) alpha:0.25];
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

    self.sendRequestButtonDisabled = 0.4f;

    self.animationDurationTimeDefault           = 0.35;     // How long the animation transition should take
    self.animationDelayTimeDefault              = 0.0;      // Delay until animation starts. Should always be zero
    self.animationCurveDefault                  = UIViewAnimationOptionCurveEaseOut;

    self.alertHoldTimeDefault                   = 4.0;      // How long to hold the alert before going away
    self.alertFadeoutTimeDefault                = 2.0;      // How much time it takes to animate the fade away
    self.alertHoldTimePaymentReceived           = 10;       // Hold time for payments
    self.alertHoldTimeHelpPopups                = 6.0;      // Hold time for auto popup help

    self.qrCodeGenDelayTime                     = 0.75;     // Timer delay after keypad entry before new QR code is generated

    self.backgroundApp = [UIImage imageNamed:@"background-fade.jpg"];
    self.backgroundLogin = [UIImage imageNamed:@"background.jpg"];
    
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
        self.fontSizeEnterPINText               = 18.0;     // Font size for PIN login screen "Enter PIN"
        self.fontSizeTxListBuyBitcoin           = 18.0;
    }
    if (IS_MIN_IPHONE5)
    {
        self.heightTransactionCell = 80;
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
    return self;
}

@end

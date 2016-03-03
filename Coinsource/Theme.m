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


    //    self.denomination = 100000000;
    self.colorTextBright = [UIColor whiteColor];
    self.colorTextDark = UIColorFromARGB(0xff0C578C);;
    self.colorTextLink = UIColorFromARGB(0xFF007aFF);
    self.colorTextLinkOnDark = UIColorFromARGB(0xFFBFDFFF);
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

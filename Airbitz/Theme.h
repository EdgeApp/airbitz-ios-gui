//
//  Theme.h
//  
//
//  Created by Paul Puey on 5/2/15.
//
//

#import <Foundation/Foundation.h>
#import "CommonTypes.h"
#import <UIKit/UIKit.h>
#import "Strings.h"
#import "BrandStrings.h"

#define AppFont                                         @"Lato-Regular"

#define ColorOffBright                                  UIColorFromARGB(0xffeeeeee)
#define ColorDarkGrey                                   UIColorFromARGB(0xff383838)
#define ColorWhiteFrost                                 UIColorFromARGB(0xaaffffff)

#define ColorPinUserNameSelectorShadow                  UIColorFromARGB(0xff3756B8)
#define ColorPinEntryText                               ColorOffBright
#define ColorPinEntryUsernameText                       UIColorFromARGB(0xffCAE3FF)

#define ColorLoginTitleText                             ColorOffBright
#define ColorLoginTitleTextShadow                       UIColorFromARGB(0xff1C3294)

#define DirectoryCategoryButtonsBackgroundColor         ColorWhiteFrost

#define LoginTitleTextShadowRadius                      0.0f
#define PinEntryTextShadowRadius                        1.0f


@interface Theme : NSObject

//@property (nonatomic, copy) NSString *name;
//@property (nonatomic, copy) NSString *password;

// User Settings
@property (nonatomic) UIColor *colorTextLink;
@property (nonatomic) UIColor *colorTextLinkOnDark;
@property (nonatomic) UIColor *colorSendButton;
@property (nonatomic) UIColor *colorRequestButton;
@property (nonatomic) UIColor *colorSendButtonDisabled;
@property (nonatomic) UIColor *colorRequestButtonDisabled;
@property (nonatomic) CGFloat sendRequestButtonDisabled;
@property (nonatomic) UIColor *colorTextBright;
@property (nonatomic) UIColor *colorTextDark;
@property (nonatomic) UIColor *colorRequestTopTextField;
@property (nonatomic) UIColor *colorRequestTopTextFieldPlaceholder;
@property (nonatomic) UIColor *colorRequestBottomTextField;
@property (nonatomic) UIColor *colorButtonGreen;
@property (nonatomic) UIColor *colorButtonBlue;
@property (nonatomic) UIColor *bdButtonBlue;
@property (nonatomic) UIColor *colorBackgroundHighlight;

@property (nonatomic) NSMutableArray *colorsProfileIcons;


@property (nonatomic) BOOL    bTranslucencyEnable;

@property (nonatomic) NSString *appFont;

@property (nonatomic) CGFloat fadingAlertDropdownHeight;
@property (nonatomic) CGFloat buttonFontSize;
@property (nonatomic) CGFloat elementPadding;
@property (nonatomic) CGFloat heightListings;
@property (nonatomic) CGFloat heightLoginScreenLogo;
@property (nonatomic) CGFloat heightSearchClues;
@property (nonatomic) CGFloat heightBLETableCells;
@property (nonatomic) UIImage *backgroundLogin;
@property (nonatomic) UIImage *backgroundApp;
@property (nonatomic) CGFloat heightWalletHeader;
@property (nonatomic) CGFloat heightWalletCell;
@property (nonatomic) CGFloat heightTransactionCell;
@property (nonatomic) CGFloat heightPopupPicker;
@property (nonatomic) CGFloat heightMinimumForQRScanFrame;
@property (nonatomic) CGFloat heightSettingsTableCell;
@property (nonatomic) CGFloat heightSettingsTableHeader;
@property (nonatomic) CGFloat heightButton;

@property (nonatomic) CGFloat fontSizeEnterPINText;


@property (nonatomic) CGFloat animationDelayTimeDefault;
@property (nonatomic) CGFloat animationDurationTimeDefault;
@property (nonatomic) UIViewAnimationOptions animationCurveDefault;
@property (nonatomic) CGFloat alertHoldTimeDefault;
@property (nonatomic) CGFloat alertFadeoutTimeDefault;
@property (nonatomic) CGFloat alertHoldTimePaymentReceived;
@property (nonatomic) CGFloat alertHoldTimeHelpPopups;

@property (nonatomic) CGFloat qrCodeGenDelayTime;
@property (nonatomic) CGFloat rotateServerInterval;
@property (nonatomic) CGFloat walletLoadingTimerInterval;

+ (void)initAll;
+ (void)freeAll;
+ (Theme *)Singleton;
- (id)init;

@end

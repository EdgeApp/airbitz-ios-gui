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
#import "BrandTheme.h"

@interface Theme : NSObject

#pragma mark Colors

@property (nonatomic) UIColor *colorWhite;
@property (nonatomic) UIColor *colorLightGray;
@property (nonatomic) UIColor *colorMidGray;
@property (nonatomic) UIColor *colorDarkGray;
@property (nonatomic) UIColor *colorLightPrimary;
@property (nonatomic) UIColor *colorMidPrimary;
@property (nonatomic) UIColor *colorDarkPrimary;
@property (nonatomic) UIColor *colorFirstAccent;
@property (nonatomic) UIColor *colorSecondAccent;

/*
@property (nonatomic) UIColor *colorTextLink;
@property (nonatomic) UIColor *colorTextLinkOnDark;
@property (nonatomic) UIColor *colorTextDarkGrey;
@property (nonatomic) UIColor *colorTextMediumGrey;
@property (nonatomic) UIColor *colorTextMediumLightGrey;
@property (nonatomic) UIColor *colorSendButton;
@property (nonatomic) UIColor *colorRequestButton;
@property (nonatomic) UIColor *colorSendButtonDisabled;
@property (nonatomic) UIColor *colorRequestButtonDisabled;
@property (nonatomic) UIColor *colorTextBright;
@property (nonatomic) UIColor *colorTextDark;
@property (nonatomic) UIColor *colorRequestTopTextField;
@property (nonatomic) UIColor *colorRequestTopTextFieldPlaceholder;
@property (nonatomic) UIColor *colorRequestBottomTextField;
@property (nonatomic) UIColor *colorButtonGreen;
@property (nonatomic) UIColor *colorButtonBlue;
@property (nonatomic) UIColor *colorButtonOrange;
@property (nonatomic) UIColor *colorButtonOrangeDark;
@property (nonatomic) UIColor *colorButtonOrangeLight;
@property (nonatomic) UIColor *colorTransactionsHeader;
@property (nonatomic) UIColor *colorTransactionName;

@property (nonatomic) NSMutableArray *colorsProfileIcons;

*/

@property (nonatomic) CGFloat defaultBTCDenominationMultiplier;

#pragma mark Fonts

@property (nonatomic) NSString *appFont;
@property (nonatomic) NSString *appFontItalic;
@property (nonatomic) CGFloat fontSizeEnterPINText;
@property (nonatomic) CGFloat fontSizeTxListBuyBitcoin;
@property (nonatomic) CGFloat fontSizeTxListName;

#pragma mark Layout Constants

@property (nonatomic) CGFloat fadingAlertDropdownHeight;
@property (nonatomic) CGFloat fadingAlertMiniDropdownHeight;
@property (nonatomic) CGFloat buttonFontSize;
@property (nonatomic) CGFloat elementPadding;
@property (nonatomic) CGFloat heightListings;
@property (nonatomic) CGFloat heightLoginScreenLogo;
@property (nonatomic) CGFloat heightSearchClues;
@property (nonatomic) CGFloat heightBLETableCells;
@property (nonatomic) CGFloat heightWalletHeader;
@property (nonatomic) CGFloat heightWalletCell;
@property (nonatomic) CGFloat heightTransactionCell;
@property (nonatomic) CGFloat heightPopupPicker;
@property (nonatomic) CGFloat heightMinimumForQRScanFrame;
@property (nonatomic) CGFloat heightSettingsTableCell;
@property (nonatomic) CGFloat heightSettingsTableHeader;
@property (nonatomic) CGFloat heightButton;
@property (nonatomic) BOOL    bTranslucencyEnable;
@property (nonatomic) CGFloat loginTitleTextShadowRadius;
@property (nonatomic) CGFloat pinEntryTextShadowRadius;

#pragma mark Animation Constants

@property (nonatomic) CGFloat animationDelayTimeDefault;
@property (nonatomic) CGFloat animationDurationTimeDefault;
@property (nonatomic) CGFloat animationDurationTimeFast;
@property (nonatomic) CGFloat animationDurationTimeSlow;
@property (nonatomic) CGFloat animationDurationTimeVerySlow;
@property (nonatomic) UIViewAnimationOptions animationCurveDefault;
@property (nonatomic) CGFloat alertHoldTimeDefault;
@property (nonatomic) CGFloat alertFadeoutTimeDefault;
@property (nonatomic) CGFloat alertHoldTimePaymentReceived;
@property (nonatomic) CGFloat alertHoldTimeHelpPopups;

#pragma mark Time Constants

@property (nonatomic) CGFloat qrCodeGenDelayTime;

#pragma mark Images

@property (nonatomic) UIImage *backgroundLogin;
@property (nonatomic) UIImage *backgroundApp;

+ (void)initAll;
+ (void)freeAll;
+ (Theme *)Singleton;
- (id)init;


@end

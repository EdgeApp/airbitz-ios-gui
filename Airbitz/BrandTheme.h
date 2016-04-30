//
//  BrandTheme.h
//  Airbitz
//
//  Created by Paul P on 12/7/15.
//  Copyright © 2015 Airbitz. All rights reserved.
//

#ifndef BrandTheme_h
#define BrandTheme_h
#import "ABCDenomination.h"


#if AIRBITZ

#define AppFont                                         @"Lato-Regular"
#define AppFontItalic                                   @"Lato-Italic"

#define ColorOffBright                                  UIColorFromARGB(0xffeeeeee)
#define ColorOffBrightFrost                             UIColorFromARGB(0xaaeeeeee)
#define ColorDarkGrey                                   UIColorFromARGB(0xff383838)
#define ColorWhiteFrost                                 UIColorFromARGB(0xaaffffff)
#define ColorDarkBlue                                   UIColorFromARGB(0xff0E4379)
#define ColorLightBlue                                  UIColorFromARGB(0xffCFEDF6)

#define ColorPinUserNameSelectorShadow                  UIColorFromARGB(0xff3756B8)
#define ColorPinEntryText                               ColorOffBright
#define ColorPinEntryUsernameText                       UIColorFromARGB(0xffCAE3FF)

#define ColorLoginTitleText                             ColorOffBright
#define ColorLoginTitleTextShadow                       UIColorFromARGB(0xff1C3294)

#define DirectoryCategoryButtonsBackgroundColor         ColorWhiteFrost

#define LoginTitleTextShadowRadius                      0.0f
#define PinEntryTextShadowRadius                        1.0f

#define DefaultBTCDenominationMultiplier                ABCDenominationMultiplierUBTC

#define SHOW_BUY_SELL                                   1
#define SHOW_AFFILIATE                                  1
#define LOCKED_SEARCH_CATEGORY                          0
#define LOCKED_SEARCH_CATEGORY_STRING                   @"ATM"

#elif RACKWALLET

#define AppFont                                         @"Lato-Regular"
#define AppFontItalic                                   @"Lato-Italic"

#define ColorOffBright                                  UIColorFromARGB(0xffeeeeee)
#define ColorOffBrightFrost                             UIColorFromARGB(0xaaeeeeee)
#define ColorDarkGrey                                   UIColorFromARGB(0xff383838)
#define ColorWhiteFrost                                 UIColorFromARGB(0xaaffffff)
#define ColorDarkBlue                                   UIColorFromARGB(0xff0E4379)
#define ColorLightBlue                                  UIColorFromARGB(0xffCFEDF6)

#define ColorPinUserNameSelectorShadow                  UIColorFromARGB(0xff3756B8)
#define ColorPinEntryText                               ColorOffBright
#define ColorPinEntryUsernameText                       ColorLightBlue

#define ColorLoginTitleText                             ColorOffBright
#define ColorLoginTitleTextShadow                       ColorOffBrightFrost

#define DirectoryCategoryButtonsBackgroundColor         ColorWhiteFrost

#define LoginTitleTextShadowRadius                      0.5f
#define PinEntryTextShadowRadius                        0.5f

#define DefaultBTCDenominationMultiplier                ABCDenominationMultiplierBTC

#define SHOW_BUY_SELL                                   0
#define SHOW_AFFILIATE                                  0
#define LOCKED_SEARCH_CATEGORY                          1
#define LOCKED_SEARCH_CATEGORY_STRING                   @"ATM"

#elif ATHENA

#define AppFont                                         @"Lato-Regular"
#define AppFontItalic                                   @"Lato-Italic"

#define ColorOffBright                                  UIColorFromARGB(0xffeeeeee)
#define ColorOffBrightFrost                             UIColorFromARGB(0xaaeeeeee)
#define ColorDarkGrey                                   UIColorFromARGB(0xff383838)
#define ColorWhiteFrost                                 UIColorFromARGB(0xaaffffff)
#define ColorDarkBlue                                   UIColorFromARGB(0xff0E4379)
#define ColorLightBlue                                  UIColorFromARGB(0xffCFEDF6)

#define ColorPinUserNameSelectorShadow                  UIColorFromARGB(0xff3756B8)
#define ColorPinEntryText                               ColorOffBright
#define ColorPinEntryUsernameText                       UIColorFromARGB(0xffCAE3FF)

#define ColorLoginTitleText                             ColorOffBright
#define ColorLoginTitleTextShadow                       UIColorFromARGB(0xff1C3294)

#define DirectoryCategoryButtonsBackgroundColor         ColorWhiteFrost

#define LoginTitleTextShadowRadius                      0.0f
#define PinEntryTextShadowRadius                        1.0f

#define DefaultBTCDenominationMultiplier                ABCDenominationMultiplierUBTC

#define SHOW_BUY_SELL                                   1
#define SHOW_AFFILIATE                                  1
#define LOCKED_SEARCH_CATEGORY                          0
#define LOCKED_SEARCH_CATEGORY_STRING                   @"ATM"

#elif COINSOURCE

#define AppFont                                         @"Lato-Regular"
#define AppFontItalic                                   @"Lato-Italic"

#define ColorOffBright                                  UIColorFromARGB(0xffeeeeee)
#define ColorOffBrightFrost                             UIColorFromARGB(0xaaeeeeee)
#define ColorDarkGrey                                   UIColorFromARGB(0xff383838)
#define ColorWhiteFrost                                 UIColorFromARGB(0xaaffffff)
#define ColorDarkBlue                                   UIColorFromARGB(0xff0E4379)
#define ColorLightBlue                                  UIColorFromARGB(0xffCFEDF6)

#define ColorPinUserNameSelectorShadow                  UIColorFromARGB(0xff3756B8)
#define ColorPinEntryText                               ColorOffBright
#define ColorPinEntryUsernameText                       UIColorFromARGB(0xffCAE3FF)

#define ColorLoginTitleText                             UIColorFromARGB(0xff495f6f)
#define ColorLoginTitleTextShadow                       ColorOffBright

#define DirectoryCategoryButtonsBackgroundColor         ColorWhiteFrost

#define LoginTitleTextShadowRadius                      0.0f
#define PinEntryTextShadowRadius                        1.0f

#define DefaultBTCDenominationMultiplier                ABCDenominationMultiplierUBTC

#define SHOW_BUY_SELL                                   1
#define SHOW_AFFILIATE                                  0
#define LOCKED_SEARCH_CATEGORY                          0
#define LOCKED_SEARCH_CATEGORY_STRING                   @"ATM"

#endif

#endif /* BrandTheme_h */

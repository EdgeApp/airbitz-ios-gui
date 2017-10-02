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

#define ColorWhite                                      UIColorFromRGB(0xffffff)
#define ColorLightGray                                  UIColorFromRGB(0xF4F2F2)
#define ColorMidGray                                    UIColorFromRGB(0xDED9D8)
#define ColorDarkGray                                   UIColorFromRGB(0x484443)
#define ColorLightPrimary                               UIColorFromRGB(0xD3ECF9)
#define ColorMidPrimary                                 UIColorFromRGB(0x2291CF)
#define ColorDarkPrimary                                UIColorFromRGB(0x0C578C)
#define ColorFirstAccent                                UIColorFromRGB(0x81C342)
#define ColorSecondAccent                               UIColorFromRGB(0xFCA600)

#define DefaultBTCDenominationMultiplier                ABCDenominationMultiplierBTC

#define SHOW_BUY_SELL                                   1
#define SHOW_AFFILIATE                                  1
#define SHOW_PLUGINS                                    1
#define LOCKED_SEARCH_CATEGORY                          0
#define LOCKED_SEARCH_CATEGORY_STRING                   @"ATM"

#define LoginTitleTextShadowRadius                      0.0f
#define PinEntryTextShadowRadius                        1.0f

#elif RACKWALLET

#define AppFont                                         @"Lato-Regular"
#define AppFontItalic                                   @"Lato-Italic"

#define ColorWhite                                      UIColorFromRGB(0xffffff)
#define ColorLightGray                                  UIColorFromRGB(0xF4F2F2)
#define ColorMidGray                                    UIColorFromRGB(0xDED9D8)
#define ColorDarkGray                                   UIColorFromRGB(0x484443)
#define ColorLightPrimary                               UIColorFromRGB(0xD3ECF9)
#define ColorMidPrimary                                 UIColorFromRGB(0x2291CF)
#define ColorDarkPrimary                                UIColorFromRGB(0x0C578C)
#define ColorFirstAccent                                UIColorFromRGB(0x81C342)
#define ColorSecondAccent                               UIColorFromRGB(0xFCA600)

#define ColorPinUserNameSelectorShadow                  UIColorFromARGB(0xff3756B8)
#define ColorPinEntryText                               UIColorFromARGB(0xffeeeeee)
#define ColorPinEntryUsernameText                       UIColorFromARGB(0xffCFEDF6)

#define ColorLoginTitleText                             UIColorFromARGB(0xffeeeeee)
#define ColorLoginTitleTextShadow                       UIColorFromARGB(0xaaeeeeee)

#define DefaultBTCDenominationMultiplier                ABCDenominationMultiplierBTC

#define SHOW_BUY_SELL                                   0
#define SHOW_AFFILIATE                                  0
#define SHOW_PLUGINS                                    1
#define LOCKED_SEARCH_CATEGORY                          1
#define LOCKED_SEARCH_CATEGORY_STRING                   @"ATM"

#define LoginTitleTextShadowRadius                      0.0f
#define PinEntryTextShadowRadius                        1.0f

#elif ATHENA

#define AppFont                                         @"Lato-Regular"
#define AppFontItalic                                   @"Lato-Italic"

#define ColorWhite                                      UIColorFromRGB(0xffffff)
#define ColorLightGray                                  UIColorFromRGB(0xF4F2F2)
#define ColorMidGray                                    UIColorFromRGB(0xDED9D8)
#define ColorDarkGray                                   UIColorFromRGB(0x484443)
#define ColorLightPrimary                               UIColorFromRGB(0xD3ECF9)
#define ColorMidPrimary                                 UIColorFromRGB(0x2291CF)
#define ColorDarkPrimary                                UIColorFromRGB(0x0C578C)
#define ColorFirstAccent                                UIColorFromRGB(0x81C342)
#define ColorSecondAccent                               UIColorFromRGB(0xFCA600)

#define ColorPinUserNameSelectorShadow                  UIColorFromARGB(0xff3756B8)
#define ColorPinEntryText                               UIColorFromARGB(0xffeeeeee)
#define ColorPinEntryUsernameText                       UIColorFromARGB(0xffCAE3FF)

#define ColorLoginTitleText                             UIColorFromARGB(0xffeeeeee)
#define ColorLoginTitleTextShadow                       UIColorFromARGB(0xff1C3294)

#define DefaultBTCDenominationMultiplier                ABCDenominationMultiplierBTC

#define SHOW_BUY_SELL                                   0
#define SHOW_AFFILIATE                                  0
#define SHOW_PLUGINS                                    1
#define LOCKED_SEARCH_CATEGORY                          0
#define LOCKED_SEARCH_CATEGORY_STRING                   @"ATM"

#define LoginTitleTextShadowRadius                      0.0f
#define PinEntryTextShadowRadius                        1.0f

#elif COINSOURCE

#define AppFont                                         @"Lato-Regular"
#define AppFontItalic                                   @"Lato-Italic"

#define ColorWhite                                      UIColorFromRGB(0xffffff)
#define ColorLightGray                                  UIColorFromRGB(0xF4F2F2)
#define ColorMidGray                                    UIColorFromRGB(0xDED9D8)
#define ColorDarkGray                                   UIColorFromRGB(0x484443)
#define ColorLightPrimary                               UIColorFromRGB(0xD3ECF9)
#define ColorMidPrimary                                 UIColorFromRGB(0x2291CF)
#define ColorDarkPrimary                                UIColorFromRGB(0x0C578C)
#define ColorFirstAccent                                UIColorFromRGB(0x81C342)
#define ColorSecondAccent                               UIColorFromRGB(0xFCA600)

#define ColorPinUserNameSelectorShadow                  UIColorFromARGB(0xff3756B8)
#define ColorPinEntryText                               UIColorFromARGB(0xffeeeeee)
#define ColorPinEntryUsernameText                       UIColorFromARGB(0xffCAE3FF)

#define ColorLoginTitleText                             UIColorFromARGB(0xff495f6f)
#define ColorLoginTitleTextShadow                       UIColorFromARGB(0xffeeeeee)

#define DefaultBTCDenominationMultiplier                ABCDenominationMultiplierBTC

#define SHOW_BUY_SELL                                   0
#define SHOW_AFFILIATE                                  0
#define HIDE_PROMO_ROWS                                 1
#define SHOW_PLUGINS                                    0
#define LOCKED_SEARCH_CATEGORY                          1
#define LOCKED_SEARCH_CATEGORY_STRING                   @"ATM"

#define LoginTitleTextShadowRadius                      0.0f
#define PinEntryTextShadowRadius                        1.0f

#elif ROCKITCOIN

#define AppFont                                         @"Lato-Regular"
#define AppFontItalic                                   @"Lato-Italic"

#define ColorWhite                                      UIColorFromRGB(0xffffff)
#define ColorLightGray                                  UIColorFromRGB(0xF4F2F2)
#define ColorMidGray                                    UIColorFromRGB(0xDED9D8)
#define ColorDarkGray                                   UIColorFromRGB(0x484443)
#define ColorLightPrimary                               UIColorFromRGB(0xD3ECF9)
#define ColorMidPrimary                                 UIColorFromRGB(0x2291CF)
#define ColorDarkPrimary                                UIColorFromRGB(0x0C578C)
#define ColorFirstAccent                                UIColorFromRGB(0x81C342)
#define ColorSecondAccent                               UIColorFromRGB(0xFCA600)

#define ColorPinUserNameSelectorShadow                  UIColorFromARGB(0xff3756B8)
#define ColorPinEntryText                               UIColorFromARGB(0xffeeeeee)
#define ColorPinEntryUsernameText                       UIColorFromARGB(0xffCFEDF6)

#define ColorLoginTitleText                             UIColorFromARGB(0xffeeeeee)
#define ColorLoginTitleTextShadow                       UIColorFromARGB(0xaaeeeeee)

#define DefaultBTCDenominationMultiplier                ABCDenominationMultiplierBTC

#define SHOW_BUY_SELL                                   0
#define SHOW_AFFILIATE                                  0
#define SHOW_PLUGINS                                    1
#define LOCKED_SEARCH_CATEGORY                          1
#define LOCKED_SEARCH_CATEGORY_STRING                   @"ATM"

#define LoginTitleTextShadowRadius                      0.5f
#define PinEntryTextShadowRadius                        0.5f

#elif BITCOINDEPOT

#define AppFont                                         @"Lato-Regular"
#define AppFontItalic                                   @"Lato-Italic"

#define ColorWhite                                      UIColorFromRGB(0xffffff)
#define ColorLightGray                                  UIColorFromRGB(0xEDEEEF)
#define ColorMidGray                                    UIColorFromRGB(0xCACCCF)
#define ColorDarkGray                                   UIColorFromRGB(0x2E343A)
#define ColorLightPrimary                               UIColorFromRGB(0xE8D9BE)
#define ColorMidPrimary                                 UIColorFromRGB(0x30617F)
#define ColorDarkPrimary                                UIColorFromRGB(0x3F474F)
#define ColorFirstAccent                                UIColorFromRGB(0xCDAD72)
#define ColorSecondAccent                               UIColorFromRGB(0xFFA400)

#define ColorBackground                                 UIColorFromRGB(0xF8F6F2)

#define DefaultBTCDenominationMultiplier                ABCDenominationMultiplierBTC

#define SHOW_BUY_SELL                                   0
#define SHOW_AFFILIATE                                  0
#define SHOW_PLUGINS                                    1
#define LOCKED_SEARCH_CATEGORY                          1
#define LOCKED_SEARCH_CATEGORY_STRING                   @"ATM"

#define LoginTitleTextShadowRadius                      0.5f
#define PinEntryTextShadowRadius                        0.5f

#endif

#endif /* BrandTheme_h */


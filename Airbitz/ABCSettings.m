//
// Created by Paul P on 1/30/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import "ABCSettings.h"
#import <Foundation/Foundation.h>
#import "ABCError.h"
#import "CoreBridge.h"
#import "ABCUtil.h"


@implementation ABCSettings
{

}
- (id)initWithABC:(CoreBridge *)abc
{
    self = [super init];
    self.abc = abc;
    return self;
}

- (ABCConditionCode)loadSettings;
{
    tABC_Error error;
    tABC_AccountSettings *pSettings = NULL;
    tABC_CC result = ABC_LoadAccountSettings([self.abc.name UTF8String],
            [self.abc.password UTF8String],
            &pSettings,
            &error);
    if (ABC_CC_Ok == result)
    {
        self.minutesAutoLogout = pSettings->minutesAutoLogout;
        self.defaultCurrencyNum = pSettings->currencyNum;
        if (pSettings->bitcoinDenomination.satoshi > 0)
        {
            self.denomination = pSettings->bitcoinDenomination.satoshi;
            self.denominationType = pSettings->bitcoinDenomination.denominationType;

            switch (self.denominationType) {
                case ABCDenominationBTC:
                    self.denominationLabel = @"BTC";
                    self.denominationLabelShort = @"Ƀ ";
                    break;
                case ABCDenominationMBTC:
                    self.denominationLabel = @"mBTC";
                    self.denominationLabelShort = @"mɃ ";
                    break;
                case ABCDenominationUBTC:
                    self.denominationLabel = @"bits";
                    self.denominationLabelShort = @"ƀ ";
                    break;

            }
        }
        self.firstName            = pSettings->szFirstName          ? [NSString stringWithUTF8String:pSettings->szFirstName] : nil;
        self.lastName             = pSettings->szLastName           ? [NSString stringWithUTF8String:pSettings->szLastName] : nil;
        self.nickName             = pSettings->szNickname           ? [NSString stringWithUTF8String:pSettings->szNickname] : nil;
        self.fullName             = pSettings->szFullName           ? [NSString stringWithUTF8String:pSettings->szFullName] : nil;
        self.strPIN               = pSettings->szPIN                ? [NSString stringWithUTF8String:pSettings->szPIN] : nil;
        self.exchangeRateSource   = pSettings->szExchangeRateSource ? [NSString stringWithUTF8String:pSettings->szExchangeRateSource] : nil;

        self.bNameOnPayments = pSettings->bNameOnPayments;
        self.bSpendRequirePin = pSettings->bSpendRequirePin;
        self.spendRequirePinSatoshis = pSettings->spendRequirePinSatoshis;
        self.bDisablePINLogin = pSettings->bDisablePINLogin;
    }
    ABC_FreeAccountSettings(pSettings);

    return [ABCError setLastErrors:error];
}

- (ABCConditionCode)saveSettings;
{
    tABC_Error error;
    tABC_AccountSettings *pSettings;
    BOOL pinLoginChanged = NO;

    ABC_LoadAccountSettings([self.abc.name UTF8String], [self.abc.password UTF8String], &pSettings, &error);

    if (ABCConditionCodeOk == [ABCError setLastErrors:error])
    {
        if (pSettings->bDisablePINLogin != self.bDisablePINLogin)
            pinLoginChanged = YES;

        pSettings->minutesAutoLogout                      = self.minutesAutoLogout         ;
        pSettings->currencyNum                            = self.defaultCurrencyNum        ;
        pSettings->bitcoinDenomination.satoshi            = self.denomination              ;
        pSettings->bitcoinDenomination.denominationType   = self.denominationType          ;
        pSettings->bNameOnPayments                        = self.bNameOnPayments           ;
        pSettings->bSpendRequirePin                       = self.bSpendRequirePin          ;
        pSettings->spendRequirePinSatoshis                = self.spendRequirePinSatoshis   ;
        pSettings->bDisablePINLogin                       = self.bDisablePINLogin          ;

        self.firstName          ? [ABCUtil replaceString:&(pSettings->szFirstName         ) withString:[self.firstName          UTF8String]] : nil;
        self.lastName           ? [ABCUtil replaceString:&(pSettings->szLastName          ) withString:[self.lastName           UTF8String]] : nil;
        self.nickName           ? [ABCUtil replaceString:&(pSettings->szNickname          ) withString:[self.nickName           UTF8String]] : nil;
        self.fullName           ? [ABCUtil replaceString:&(pSettings->szFullName          ) withString:[self.fullName           UTF8String]] : nil;
        self.strPIN             ? [ABCUtil replaceString:&(pSettings->szPIN               ) withString:[self.strPIN             UTF8String]] : nil;
        self.exchangeRateSource ? [ABCUtil replaceString:&(pSettings->szExchangeRateSource) withString:[self.exchangeRateSource UTF8String]] : nil;

        if (pinLoginChanged)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {

                if (self.bDisablePINLogin)
                {
                    [self deletePINLogin];
                }
                else
                {
                    [self setupLoginPIN];
                }
            });
        }

        ABC_UpdateAccountSettings([self.abc.name UTF8String], [self.abc.password UTF8String], pSettings, &error);
        if (ABCConditionCodeOk == [ABCError setLastErrors:error])
        {
            ABC_FreeAccountSettings(pSettings);
        }
    }

    return (ABCConditionCode) error.code;
}

- (void)deletePINLogin
{
    NSString *username = NULL;
    if ([self.abc isLoggedIn])
    {
        username = self.abc.name;
    }

    tABC_Error error;
    if (username && 0 < username.length)
    {
        tABC_CC result = ABC_PinLoginDelete([username UTF8String],
                &error);
        if (ABC_CC_Ok != result)
        {
            [ABCError setLastErrors:error];
        }
    }
}



- (void)setupLoginPIN
{
    if (!self.bDisablePINLogin)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
            tABC_Error error;
            ABC_PinSetup([self.abc.name UTF8String],
                    [self.abc.password length] > 0 ? [self.abc.password UTF8String] : nil,
                    &error);
        });
    }
}


@end
//
//  User.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "User.h"
#import "ABC.h"
#import "Util.h"
#import "CommonTypes.h"
#import "CoreBridge.h"

static BOOL bInitialized = NO;

@implementation User

static User *singleton = nil;  // this will be the one and only object this static singleton class has

+ (void)initAll
{
    if (NO == bInitialized)
    {
        singleton = [[User alloc] init];
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

+ (User *)Singleton
{
    return singleton;
}

+ (bool)isLoggedIn
{
    return [User Singleton].name.length && [User Singleton].password.length;
}

+ (void)login:(NSString *)name password:(NSString *)pword
{
    [User Singleton].name = name;
    [User Singleton].password = pword;
    [[User Singleton] loadSettings];
    [CoreBridge login];
}

- (id)init
{
    self = [super init];
    if(self)
    {
        [self clear];
    }
    self.denomination = 100000000;
    self.denominationType = ABC_DENOMINATION_BTC;
    self.denominationLabel = @"BTC";
    self.denominationLabelShort = @"฿ ";
    return self;
}

- (void)loadSettings
{
    tABC_Error Error;
    tABC_AccountSettings *pSettings = NULL;
    tABC_CC result = ABC_LoadAccountSettings([self.name UTF8String],
                                             [self.password UTF8String],
                                             &pSettings,
                                             &Error);
    if (ABC_CC_Ok == result)
    {
        self.minutesAutoLogout = pSettings->minutesAutoLogout;
        self.defaultCurrencyNum = pSettings->currencyNum;
        if (pSettings->bitcoinDenomination.satoshi > 0)
        {
            self.denomination = pSettings->bitcoinDenomination.satoshi;
            self.denominationType = pSettings->bitcoinDenomination.denominationType;

            switch (self.denominationType) {
                case ABC_DENOMINATION_BTC:
                    self.denominationLabel = @"BTC";
                    self.denominationLabelShort = @"฿ ";
                    break;
                case ABC_DENOMINATION_MBTC:
                    self.denominationLabel = @"mBTC";
                    self.denominationLabelShort = @"m฿ ";
                    break;
                case ABC_DENOMINATION_UBTC:
                    self.denominationLabel = @"μBTC";
                    self.denominationLabelShort = @"μ฿ ";
                    break;

            }
        }
        if (pSettings->szFirstName)
            self.firstName = [NSString stringWithUTF8String:pSettings->szFirstName];
        if (pSettings->szLastName)
            self.lastName = [NSString stringWithUTF8String:pSettings->szLastName];
        if (pSettings->szNickname)
            self.nickName = [NSString stringWithUTF8String:pSettings->szNickname];
        if (pSettings->szFullName)
            self.fullName = [NSString stringWithUTF8String:pSettings->szFullName];
        self.bNameOnPayments = pSettings->bNameOnPayments;
    }
    else
    {
        [Util printABC_Error:&Error];
    }
    ABC_FreeAccountSettings(pSettings);
}

- (void)clear
{
    if (self.password != nil)
    {
        [CoreBridge logout];
    }
    self.password = nil;
}

@end

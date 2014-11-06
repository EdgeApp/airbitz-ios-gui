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
    return [User Singleton].name.length;// && [User Singleton].password.length;
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
    self.sendInvalidEntryCount = 0;
    self.sendState = kNormal;
    self.runLoop = [NSRunLoop currentRunLoop];
    self.PINLoginInvalidEntryCount = 0;

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

        self.bDailySpendLimit = pSettings->bDailySpendLimit;
        self.dailySpendLimitSatoshis = pSettings->dailySpendLimitSatoshis;
        self.bSpendRequirePin = pSettings->bSpendRequirePin;
        self.spendRequirePinSatoshis = pSettings->spendRequirePinSatoshis;
        self.bDisablePINLogin = pSettings->bDisablePINLogin;
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
    self.name = nil;
    [CoreBridge deletePINLogin];
}

- (SendViewState)sendInvalidEntry
{
    ++self.sendInvalidEntryCount;
    if (SEND_INVALID_ENTRY_COUNT_MAX <= self.sendInvalidEntryCount)
    {
        [self startInvalidEntryWait];
    }
    return self.sendState;
}

- (void)startInvalidEntryWait
{
    if (kInvalidEntryWait == self.sendState)
    {
        return;
    }
    
    self.sendState = kInvalidEntryWait;
    self.sendInvalidEntryCount = 0;
    self.sendInvalidEntryTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:INVALID_ENTRY_WAIT]
                                                  interval:INVALID_ENTRY_WAIT
                                                    target:self
                                                  selector:@selector(endInvalidEntryWait)
                                                  userInfo:@{kTimerStart : [NSDate date]}
                                                   repeats:NO];
    [self.runLoop addTimer:self.sendInvalidEntryTimer forMode:NSDefaultRunLoopMode];
}

- (void)endInvalidEntryWait
{
    if (self)
    {
        self.sendState = kNormal;
    }
}

- (NSTimeInterval)getRemainingInvalidEntryWait
{
    if (!self.sendInvalidEntryTimer || ![self.sendInvalidEntryTimer isValid]) {
        return 0;
    }
    NSDate *start = [[self.sendInvalidEntryTimer userInfo] objectForKey:kTimerStart];
    NSDate *current = [NSDate date];
    return INVALID_ENTRY_WAIT - [current timeIntervalSinceDate:start];
}

/* Increment the count of invalid entries and return true if the maximum has
 * been exceeded.
 */
- (bool)haveExceededPINLoginInvalidEntries
{
    ++self.PINLoginInvalidEntryCount;
    if (LOGIN_INVALID_ENTRY_COUNT_MAX <= self.PINLoginInvalidEntryCount)
    {
        return YES;
    }
    return NO;
}

- (void)resetPINLoginInvalidEntryCount
{
    self.PINLoginInvalidEntryCount = 0;
}

@end

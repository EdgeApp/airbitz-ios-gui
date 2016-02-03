//
//  User.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "User.h"
#import "Util.h"
#import "AB.h"
#import "LocalSettings.h"


#define SPENDING_LIMIT_AMOUNT  @"spending_limit_amount"
#define SPENDING_LIMIT_ENABLED @"spending_limit_enabled"

#define USER_PIN_LOGIN_COUNT @"user_pin_login_count"

static BOOL bInitialized = NO;

@interface User ()

@property (nonatomic, strong) AirbitzCore *abc;

@end



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

+ (BOOL)isLoggedIn
{
    return (0 != abc.name.length);// && abc.password.length;
}

+ (void)login:(NSString *)name password:(NSString *)pword
{
    [LocalSettings saveAll];
    [[User Singleton] loadLocalSettings];

}

- (id)init
{
    self = [super init];
    self.abc = abc;
    if(self)
    {
        [self clear];
    }
    abc.settings.denomination = 100000000;
    abc.settings.denominationType = ABCDenominationUBTC;
    abc.settings.denominationLabel = @"bits";
    abc.settings.denominationLabelShort = @"Ƀ ";
    self.sendInvalidEntryCount = 0;
    self.sendState = kNormal;
    self.runLoop = [NSRunLoop currentRunLoop];
    self.PINLoginInvalidEntryCount = 0;
    self.needsPasswordCheck = NO;
    self.pinLoginCount = 0;

    return self;
}

- (NSString *)userKey:(NSString *)base
{
    return [NSString stringWithFormat:@"%@_%@", abc.name, base];
}

- (void)loadLocalSettings
{
    NSUserDefaults *localConfig = [NSUserDefaults standardUserDefaults];

    self.dailySpendLimitSatoshis = [[localConfig objectForKey:[self userKey:SPENDING_LIMIT_AMOUNT]] unsignedLongLongValue];
    self.bDailySpendLimit = [localConfig boolForKey:[self userKey:SPENDING_LIMIT_ENABLED]];
    self.pinLoginCount = [localConfig integerForKey:[self userKey:USER_PIN_LOGIN_COUNT]];

}

- (void)saveLocalSettings
{
    NSUserDefaults *localConfig = [NSUserDefaults standardUserDefaults];
    [localConfig setObject:@(_dailySpendLimitSatoshis) forKey:[self userKey:SPENDING_LIMIT_AMOUNT]];
    [localConfig setBool:_bDailySpendLimit forKey:[self userKey:SPENDING_LIMIT_ENABLED]];
    [localConfig setInteger:self.pinLoginCount forKey:[self userKey:USER_PIN_LOGIN_COUNT]];

    [localConfig synchronize];
}

- (void)clear
{
    // Delete webview cookies
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];

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

- (void)incPINorTouchIDLogin
{

    self.pinLoginCount++;
    [self saveLocalSettings];
    
    if (   self.pinLoginCount == 3
        || self.pinLoginCount == 10
        || self.pinLoginCount == 20) {
        _needsPasswordCheck = YES;
    }
    else if (self.pinLoginCount % 20 == 0)
    {
        _needsPasswordCheck = YES;
    }
}
@end

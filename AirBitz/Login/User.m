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

- (id)init
{
    self = [super init];
    if(self)
    {
        [self clear];
    }
    self.denomination = 100000000;
    self.denominationLabel = @"BTC";
    self.denominationLabelShort = @"B ";
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
        if (pSettings->bitcoinDenomination.satoshi > 0)
        {
            self.denomination = pSettings->bitcoinDenomination.satoshi;
            self.denominationLabel = [NSString stringWithUTF8String: pSettings->bitcoinDenomination.szLabel];
            if ([self.denominationLabel isEqualToString:@"mBTC"])
                self.denominationLabelShort = @"mB ";
            else if ([self.denominationLabel isEqualToString:@"μBTC"])
                self.denominationLabelShort = @"μB ";
            else
                self.denominationLabelShort = @"B ";
        }
    }
    else
    {
        [Util printABC_Error:&Error];
    }
    ABC_FreeAccountSettings(pSettings);
}

- (void)clear
{
    self.name = nil;
    self.password = nil;

    tABC_Error Error;
    tABC_CC result = ABC_ClearKeyCache(&Error);
    if (ABC_CC_Ok != result)
    {
        [Util printABC_Error:&Error];
#warning TODO: handle error
    }
}

@end

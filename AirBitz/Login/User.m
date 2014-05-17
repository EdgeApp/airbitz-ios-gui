//
//  User.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "User.h"
#import "Config.h"
#import "ABC.h"



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

+(User *)Singleton
{
    return singleton;
}

-(id)init
{
    self = [super init];
    if(self)
    {
        [self clear];
    }
    self.denomination = 100000000;
    self.denominationLabel = @"Bitcoin";
    return self;
}

-(void)loadSettings
{
    tABC_Error Error;
    tABC_AccountSettings *pSettings = NULL;
    ABC_LoadAccountSettings([self.name UTF8String],
                            [self.password UTF8String],
                            &pSettings,
                            &Error);
    if (ABC_CC_Ok == Error.code)
    {
        if (pSettings->bitcoinDenomination.satoshi > 0)
        {
            self.denomination = pSettings->bitcoinDenomination.satoshi;
            self.denominationLabel = [NSString stringWithUTF8String: pSettings->bitcoinDenomination.szLabel];
        }
    }
    else
    {
#warning TODO Handle error
    }
    ABC_FreeAccountSettings(pSettings);
}

-(void)clear
{
#if HARD_CODED_LOGIN
    self.name = HARD_CODED_LOGIN_NAME;
    self.password = HARD_CODED_LOGIN_PASSWORD;
#else
    self.name = nil;
    self.password = nil;
#endif
}

@end

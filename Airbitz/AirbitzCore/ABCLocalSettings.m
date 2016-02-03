//
// Created by Paul P on 1/31/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import "ABCLocalSettings.h"
#import "AirbitzCore.h"

#define KEY_LOCAL_SETTINGS_TOUCHID_USERS_ENABLED    @"touchIDUsersEnabled"
#define KEY_LOCAL_SETTINGS_TOUCHID_USERS_DISABLED   @"touchIDUsersDisabled"
#define KEY_LOCAL_SETTINGS_CACHED_USERNAME          @"cachedUsername"

static BOOL bInitialized = NO;

__strong static ABCLocalSettings *singleton = nil; // this will be the one and only object this static singleton class has


@interface ABCLocalSettings ()

@property (nonatomic) AirbitzCore *abc;

@end

@implementation ABCLocalSettings
{

}


- (id)init:(AirbitzCore *)abc
{
    self = [super init];
    if (self)
    {
        if (!bInitialized)
        {
            self.touchIDUsersDisabled = nil;
            self.touchIDUsersEnabled  = nil;
            self.abc = abc;
            
            // load the settings
            [self loadAll];
            
            bInitialized = YES;
        }
    }
    return self;
}

- (void)dealloc
{
    if (bInitialized)
    {
        bInitialized = NO;
    }
    
}

// loads all the settings from persistant memory
- (void)loadAll
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults synchronize];
    
    self.lastLoggedInAccount = [defaults stringForKey:KEY_LOCAL_SETTINGS_CACHED_USERNAME];

    NSData *touchIDUsersEnabledData = [defaults objectForKey:KEY_LOCAL_SETTINGS_TOUCHID_USERS_ENABLED];
    if (touchIDUsersEnabledData) {
        self.touchIDUsersEnabled = [NSKeyedUnarchiver unarchiveObjectWithData:touchIDUsersEnabledData];
    } else {
        self.touchIDUsersEnabled = [[NSMutableArray alloc] init];
    }

    NSData *touchIDUsersDisabledData = [defaults objectForKey:KEY_LOCAL_SETTINGS_TOUCHID_USERS_DISABLED];
    if (touchIDUsersDisabledData) {
        self.touchIDUsersDisabled = [NSKeyedUnarchiver unarchiveObjectWithData:touchIDUsersDisabledData];
    } else {
        self.touchIDUsersDisabled = [[NSMutableArray alloc] init];
    }
}

// saves all the settings to persistant memory
- (void)saveAll
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setValue:self.lastLoggedInAccount forKey:KEY_LOCAL_SETTINGS_CACHED_USERNAME];

    NSData *touchIDUsersEnabledData = [NSKeyedArchiver archivedDataWithRootObject:self.touchIDUsersEnabled];
    [defaults setObject:touchIDUsersEnabledData forKey:KEY_LOCAL_SETTINGS_TOUCHID_USERS_ENABLED];

    NSData *touchIDUsersDisabledData = [NSKeyedArchiver archivedDataWithRootObject:self.touchIDUsersDisabled];
    [defaults setObject:touchIDUsersDisabledData forKey:KEY_LOCAL_SETTINGS_TOUCHID_USERS_DISABLED];

    // flush the buffer
    [defaults synchronize];
}

@end
//
//  LocalSettings.m
//  AirBitz
//
//  Created by Adam Harris on 8/16/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "LocalSettings.h"

#define KEY_LOCAL_SETTINGS_DISABLE_BLE			@"disableBLE"
#define KEY_LOCAL_SETTINGS_MERCHANT_MODE    	@"merchantMode"
#define KEY_LOCAL_SETTINGS_CACHED_USERNAME      @"cachedUsername"
#define KEY_LOCAL_SETTINGS_PREV_NOTIF_ID        @"previousNotificationID"
#define KEY_LOCAL_SETTINGS_NOTIFICATION_DATA    @"notificationData"
#define KEY_LOCAL_SETTINGS_OTP_NOTIF_DATA       @"otpNotificationData"
#define KEY_LOCAL_SETTINGS_CLIENT_ID            @"clientID"

static BOOL bInitialized = NO;

__strong static LocalSettings *singleton = nil; // this will be the one and only object this static singleton class has

@implementation LocalSettings

#pragma mark - Static methods

+ (void)initAll
{
	if (NO == bInitialized)
	{
        // create the one object of ourselves which everyone can retrieve with data
        singleton = [[LocalSettings alloc] init];
        
		// load the settings
		[LocalSettings loadAll];
        if (!singleton.clientID) {
            singleton.clientID = [[NSUUID UUID] UUIDString];
            [LocalSettings saveAll];
        }

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

// loads all the settings from persistant memory
+ (void)loadAll
{	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults synchronize];

    singleton.bDisableBLE = [defaults boolForKey:KEY_LOCAL_SETTINGS_DISABLE_BLE];
    singleton.bMerchantMode = [defaults boolForKey:KEY_LOCAL_SETTINGS_MERCHANT_MODE];
    singleton.cachedUsername = [defaults stringForKey:KEY_LOCAL_SETTINGS_CACHED_USERNAME];
    singleton.previousNotificationID = [defaults integerForKey:KEY_LOCAL_SETTINGS_PREV_NOTIF_ID];
    singleton.clientID = [defaults stringForKey:KEY_LOCAL_SETTINGS_CLIENT_ID];

    NSData *notifsData = [defaults objectForKey:KEY_LOCAL_SETTINGS_NOTIFICATION_DATA];
    if (notifsData) {
        singleton.notifications = [NSKeyedUnarchiver unarchiveObjectWithData:notifsData];
    } else {
        singleton.notifications = [[NSMutableArray alloc] init];
    }

    NSData *notifsOtpData = [defaults objectForKey:KEY_LOCAL_SETTINGS_OTP_NOTIF_DATA];
    if (notifsOtpData) {
        singleton.otpNotifications = [NSKeyedUnarchiver unarchiveObjectWithData:notifsOtpData];
    } else {
        singleton.otpNotifications = [[NSMutableArray alloc] init];
    }
}

// saves all the settings to persistant memory
+ (void)saveAll
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setBool:[singleton bDisableBLE] forKey:KEY_LOCAL_SETTINGS_DISABLE_BLE];
    [defaults setBool:[singleton bMerchantMode] forKey:KEY_LOCAL_SETTINGS_MERCHANT_MODE];
    [defaults setValue:[singleton cachedUsername] forKey:KEY_LOCAL_SETTINGS_CACHED_USERNAME];
    [defaults setInteger:[singleton previousNotificationID] forKey:KEY_LOCAL_SETTINGS_PREV_NOTIF_ID];
    [defaults setValue:[singleton clientID] forKey:KEY_LOCAL_SETTINGS_CLIENT_ID];

    NSData *notifsData = [NSKeyedArchiver archivedDataWithRootObject:singleton.notifications];
    [defaults setObject:notifsData forKey:KEY_LOCAL_SETTINGS_NOTIFICATION_DATA];

    NSData *otpNotifsData = [NSKeyedArchiver archivedDataWithRootObject:singleton.otpNotifications];
    [defaults setObject:otpNotifsData forKey:KEY_LOCAL_SETTINGS_OTP_NOTIF_DATA];

    // flush the buffer
    [defaults synchronize];
}

// returns the singleton 
// (this call is both a container and an object class and the container holds one of itself)
+ (LocalSettings *)controller
{
    return (singleton);
}

#pragma mark - Object Methods

- (id)init
{
    self = [super init];
    if (self) 
	{
        // init all here
        self.bDisableBLE = NO;
        self.bMerchantMode = NO;
        self.cachedUsername = nil;
        self.notifications = nil;
        self.otpNotifications = nil;
        self.previousNotificationID = 0;
    }
    return self;
}

- (void)dealloc
{

}

// overriding the description - used in debugging
- (NSString *)description
{
	return([NSString stringWithFormat:@"Settings: DisableBLE=%@", self.bDisableBLE ? @"YES" : @"NO"]);
}

@end

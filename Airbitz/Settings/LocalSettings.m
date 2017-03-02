//
//  LocalSettings.m
//  Airbitz
//
//  Created by Adam Harris on 8/16/14.
//  Copyright (c) 2014 Airbitz. All rights reserved.
//
//  Contains all application local settings (not sync'ed across devices)
//  This does not include per user settings which are instead stored in User.h
//

#import "LocalSettings.h"

#define KEY_LOCAL_SETTINGS_DISABLE_BLE			    @"disableBLE"
#define KEY_LOCAL_SETTINGS_MERCHANT_MODE    	    @"merchantMode"
#define KEY_LOCAL_SETTINGS_PREV_NOTIF_ID            @"previousNotificationID"
#define KEY_LOCAL_SETTINGS_RECEIVE_COUNT            @"receiveBitcoinCount"
#define KEY_LOCAL_SETTINGS_NOTIFICATION_DATA        @"notificationData"
#define KEY_LOCAL_SETTINGS_OTP_NOTIF_DATA           @"otpNotificationData"
#define KEY_LOCAL_SETTINGS_CLIENT_ID                @"clientID"
#define KEY_LOCAL_SETTINGS_NO_PASSWORD_NOTIF_TIME   @"noPasswordNotificationTime"

#define KEY_LOCAL_SETTINGS_REVIEW_NOTIFIED          @"review_notified"
#define KEY_LOCAL_SETTINGS_DISCLAIMER_VIEWED        @"disclaimer_viewed"
#define KEY_LOCAL_SETTINGS_FIRST_LOGIN_TIME         @"first_login_time"
#define KEY_LOCAL_SETTINGS_LOGIN_COUNT              @"login_count"
#define KEY_LOCAL_SETTINGS_REQUEST_VIEW_COUNT       @"request_view_count"
#define KEY_LOCAL_SETTINGS_SEND_VIEW_COUNT          @"send_view_count"
#define KEY_LOCAL_SETTINGS_BLE_VIEW_COUNT           @"ble_view_count"
#define KEY_LOCAL_SETTINGS_WALLETS_VIEW_COUNT       @"wallets_view_count"
#define KEY_LOCAL_SETTINGS_PLUGINS_VIEW_COUNT       @"plugins_view_count"
#define KEY_LOCAL_SETTINGS_HIDE_BALANCE             @"hide_balance"
#define KEY_LOCAL_SETTINGS_SHOW_RUNNING_BALANCE     @"show_running_balance"
#define KEY_LOCAL_SETTINGS_HAVE_CHECKED_AFFILIATE   @"have_checked_affiliate"
#define KEY_LOCAL_SETTINGS_AFFILIATE_INFO           @"affiliate_info"

#define REVIEW_ACCOUNT_AGE 14
#define REVIEW_LOGIN_COUNT 7
#define REVIEW_TX_COUNT    7

#define FORCE_HELP_SCREENS 0



static BOOL bInitialized = NO;

__strong static LocalSettings *singleton = nil; // this will be the one and only object this static singleton class has

@interface LocalSettings ()

@property (nonatomic, assign) NSInteger requestViewCount;
@property (nonatomic, assign) NSInteger sendViewCount;
@property (nonatomic, assign) NSInteger bleViewCount;
@property (nonatomic, assign) NSInteger walletsViewCount;
@property (nonatomic, assign) NSInteger pluginsViewCount;
@property (nonatomic) BOOL notifiedSend;
@property (nonatomic) BOOL notifiedRequest;
@property (nonatomic) BOOL notifiedBle;
@property (nonatomic) BOOL notifiedWallet;
@property (nonatomic) BOOL notifiedPlugins;

@end

@implementation LocalSettings

#pragma mark - Static methods

+ (void)initAll
{
	if (NO == bInitialized)
	{
        // create the one object of ourselves which everyone can retrieve with data
        singleton = [[LocalSettings alloc] init];

        singleton.bLocalNotificationsAllowed = NO;
        singleton.reviewNotified = NO;
        singleton.bDisclaimerViewed = NO;
        singleton.loginCount = 0;
        singleton.firstLoginTime = nil;
        singleton.requestViewCount = 0;
        singleton.sendViewCount = 0;
        singleton.bleViewCount = 0;
        singleton.showRunningBalance = NO;
        singleton.hideBalance = NO;
        singleton.bCheckedForAffiliate = NO;

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
+ (void)loadAll  { [singleton loadAll]; }
- (void)loadAll
{	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults synchronize];

    self.bDisableBLE = [defaults boolForKey:KEY_LOCAL_SETTINGS_DISABLE_BLE];
    self.bMerchantMode = [defaults boolForKey:KEY_LOCAL_SETTINGS_MERCHANT_MODE];
    self.previousNotificationID = [defaults integerForKey:KEY_LOCAL_SETTINGS_PREV_NOTIF_ID];
    self.receiveBitcoinCount = [defaults integerForKey:KEY_LOCAL_SETTINGS_RECEIVE_COUNT];
    self.noPasswordNotificationTime = [defaults doubleForKey:KEY_LOCAL_SETTINGS_NO_PASSWORD_NOTIF_TIME];
    self.clientID = [defaults stringForKey:KEY_LOCAL_SETTINGS_CLIENT_ID];
    self.affiliateInfo = [defaults stringForKey:KEY_LOCAL_SETTINGS_AFFILIATE_INFO];

    self.bCheckedForAffiliate   = [defaults boolForKey:   KEY_LOCAL_SETTINGS_HAVE_CHECKED_AFFILIATE];
    self.showRunningBalance     = [defaults boolForKey:   KEY_LOCAL_SETTINGS_SHOW_RUNNING_BALANCE];
    self.hideBalance            = [defaults boolForKey:   KEY_LOCAL_SETTINGS_HIDE_BALANCE];
    self.bDisclaimerViewed      = [defaults boolForKey:   KEY_LOCAL_SETTINGS_DISCLAIMER_VIEWED];
    self.reviewNotified         = [defaults boolForKey:   KEY_LOCAL_SETTINGS_REVIEW_NOTIFIED];
    self.firstLoginTime         = [defaults objectForKey: KEY_LOCAL_SETTINGS_FIRST_LOGIN_TIME];
    self.loginCount             = [defaults integerForKey:KEY_LOCAL_SETTINGS_LOGIN_COUNT];
    self.requestViewCount       = [defaults integerForKey:KEY_LOCAL_SETTINGS_REQUEST_VIEW_COUNT];
    self.sendViewCount          = [defaults integerForKey:KEY_LOCAL_SETTINGS_SEND_VIEW_COUNT];
    self.bleViewCount           = [defaults integerForKey:KEY_LOCAL_SETTINGS_BLE_VIEW_COUNT];
    self.walletsViewCount       = [defaults integerForKey:KEY_LOCAL_SETTINGS_WALLETS_VIEW_COUNT];
    self.pluginsViewCount       = [defaults integerForKey:KEY_LOCAL_SETTINGS_PLUGINS_VIEW_COUNT];

    NSData *notifsData = [defaults objectForKey:KEY_LOCAL_SETTINGS_NOTIFICATION_DATA];
    if (notifsData) {
        self.notifications = [NSKeyedUnarchiver unarchiveObjectWithData:notifsData];
    } else {
        self.notifications = [[NSMutableArray alloc] init];
    }

    NSData *notifsLoginData = [defaults objectForKey:KEY_LOCAL_SETTINGS_OTP_NOTIF_DATA];
    if (notifsLoginData) {
        self.loginNotifications = [NSKeyedUnarchiver unarchiveObjectWithData:notifsLoginData];
    } else {
        self.loginNotifications = [[NSMutableArray alloc] init];
    }

}

// saves all the settings to persistant memory
+ (void)saveAll { [singleton saveAll]; }
- (void)saveAll
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setBool:      [self showRunningBalance] forKey:KEY_LOCAL_SETTINGS_SHOW_RUNNING_BALANCE];
    [defaults setBool:      [self hideBalance] forKey:KEY_LOCAL_SETTINGS_HIDE_BALANCE];
    [defaults setBool:      [self bDisableBLE] forKey:KEY_LOCAL_SETTINGS_DISABLE_BLE];
    [defaults setBool:      [self bMerchantMode] forKey:KEY_LOCAL_SETTINGS_MERCHANT_MODE];
    [defaults setInteger:   [self previousNotificationID] forKey:KEY_LOCAL_SETTINGS_PREV_NOTIF_ID];
    [defaults setInteger:   [self receiveBitcoinCount] forKey:KEY_LOCAL_SETTINGS_RECEIVE_COUNT];
    [defaults setDouble:    [self noPasswordNotificationTime] forKey:KEY_LOCAL_SETTINGS_NO_PASSWORD_NOTIF_TIME];
    [defaults setValue:     [self clientID] forKey:KEY_LOCAL_SETTINGS_CLIENT_ID];
    [defaults setValue:     [self affiliateInfo] forKey:KEY_LOCAL_SETTINGS_AFFILIATE_INFO];

    [defaults setBool:   self.bCheckedForAffiliate    forKey:KEY_LOCAL_SETTINGS_HAVE_CHECKED_AFFILIATE];
    [defaults setBool:   self.reviewNotified    forKey:KEY_LOCAL_SETTINGS_REVIEW_NOTIFIED];
    [defaults setBool:   self.bDisclaimerViewed forKey:KEY_LOCAL_SETTINGS_DISCLAIMER_VIEWED];
    [defaults setObject: self.firstLoginTime    forKey:KEY_LOCAL_SETTINGS_FIRST_LOGIN_TIME];
    [defaults setInteger:self.loginCount        forKey:KEY_LOCAL_SETTINGS_LOGIN_COUNT];
    [defaults setInteger:self.requestViewCount  forKey:KEY_LOCAL_SETTINGS_REQUEST_VIEW_COUNT];
    [defaults setInteger:self.sendViewCount     forKey:KEY_LOCAL_SETTINGS_SEND_VIEW_COUNT];
    [defaults setInteger:self.bleViewCount      forKey:KEY_LOCAL_SETTINGS_BLE_VIEW_COUNT];
    [defaults setInteger:self.walletsViewCount  forKey:KEY_LOCAL_SETTINGS_WALLETS_VIEW_COUNT];
    [defaults setInteger:self.pluginsViewCount  forKey:KEY_LOCAL_SETTINGS_PLUGINS_VIEW_COUNT];

    NSData *notifsData = [NSKeyedArchiver archivedDataWithRootObject:self.notifications];
    [defaults setObject:notifsData forKey:KEY_LOCAL_SETTINGS_NOTIFICATION_DATA];

    NSData *notifsLoginData = [NSKeyedArchiver archivedDataWithRootObject:self.loginNotifications];
    [defaults setObject:notifsLoginData forKey:KEY_LOCAL_SETTINGS_OTP_NOTIF_DATA];
    
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
        self.notifications = nil;
        self.loginNotifications = nil;
        self.previousNotificationID = 0;
        self.receiveBitcoinCount = 0;
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



- (BOOL)offerUserReview:(int)numTransactions earliestDate:(NSDate *)earliestDate;
{
    if ([LocalSettings controller].reviewNotified) {
        return NO;
    }
    BOOL ret = NO;
    BOOL timeTrigger = [self timeUseTriggered:earliestDate];
    self.loginCount++;
    if (self.loginCount >= REVIEW_LOGIN_COUNT && timeTrigger
        && (numTransactions >= REVIEW_TX_COUNT)) {
        self.reviewNotified = true;
        ret = YES;
    }
    [self saveAll];
    return ret;
}

- (BOOL)offerRequestHelp
{
    return [self offerHelp:&_requestViewCount
               thisSession:&_notifiedRequest];
}

- (BOOL)offerSendHelp
{
    return [self offerHelp:&_sendViewCount
               thisSession:&_notifiedSend];
}

- (BOOL)offerBleHelp
{
    return [self offerHelp:&_bleViewCount
               thisSession:&_notifiedBle];
}

- (BOOL)offerWalletHelp
{
    return [self offerHelp:&_walletsViewCount
               thisSession:&_notifiedWallet];
}
- (BOOL)offerPluginsHelp
{
    return [self offerHelp:&_pluginsViewCount
               thisSession:&_notifiedPlugins];
}

- (BOOL)offerHelp:(NSInteger *)value thisSession:(BOOL *)session
{
    if (*session) {
        return NO;
    }
    *session = YES;
    
    if (FORCE_HELP_SCREENS)
        return YES;
    
    if (*value > 2) {
        return NO;
    }
    (*value)++;
    [self saveAll];
    return *value <= 2;
}

- (BOOL)timeUseTriggered:(NSDate *)earliestDate;
{
    if (self.firstLoginTime == nil) {
        self.firstLoginTime = earliestDate;
        return NO;
    }
    if ([earliestDate compare:self.firstLoginTime] == NSOrderedAscending) {
        self.firstLoginTime = earliestDate;
    }
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:self.firstLoginTime
                                                 toDate:[NSDate date]
                                                options:0];
    return [difference day] >= REVIEW_ACCOUNT_AGE;
}


@end

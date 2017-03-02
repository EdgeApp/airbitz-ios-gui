//
//  NotificationChecker.m
//  AirBitz
//
//  Created by Allan on 11/24/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "NotificationChecker.h"
#import "Server.h"
#import "CommonTypes.h"
#import "LocalSettings.h"
#import "CJSONDeserializer.h"
#import "User.h"
#import "ABCContext.h"
#import "Strings.h"
#import "MainViewController.h"
#import "AFNetworking.h"
#import "AB.h"
#import "Config.h"

#define OTP_NOTIFICATION          @"otp_notification"
#define OTP_TIME                  @"otp_time"
#define OTP_REPEAT_PERIOD         60 * 60 * 24
#define NOTIFICATION_SEEN_KEY     @"viewed"
#define NOTIFICATION_SHOWN_IN_APP @"shown_in_app"
#define NOTIFICATION_USERNAME                   @"username"
#define NOTIFICATION_TYPE                       @"type"
#define NOTIFICATION_TYPE_OTP_RESET             @"otpResetPending"
#define NOTIFICATION_TYPE_RECOVERY2_CORRUPT     @"recovery2Corrupt"

static BOOL bInitialized = NO;
static NotificationChecker *singleton = nil;

@interface NotificationChecker ()
{
    NSTimer *_notificationTimer;
}

@property (strong, nonatomic) AFHTTPRequestOperationManager         *afmanager;

@end

@implementation NotificationChecker

#pragma mark Public Methods
+ (void)initAll
{
    if (NO == bInitialized)
    {
        singleton = [[NotificationChecker alloc] init];
        singleton.afmanager = [MainViewController createAFManager];

        bInitialized = YES;
    }
}

+ (void)freeAll
{
    if (YES == bInitialized)
    {
//        [[DL_URLServer controller] cancelAllRequestsForDelegate:singleton];
        singleton = nil;
        bInitialized = NO;
    }
}

+ (void)requestNotificationsFromBackgroundFetch
{
    ABCLog(2,@"ENTER requestNotificationsFromBackgroundFetch\n");
    [singleton checkLoginNotifications];
    [singleton checkDirectoryNotifications];
    ABCLog(2,@"EXIT requestNotificationsFromBackgroundFetch\n");
}

+ (NSDictionary *)haveNotifications
{
    return [singleton haveNotifications];
}

+ (NSDictionary *)firstNotification
{
    return [singleton getNextNotification];
}

+ (NSDictionary *)unseenNotification
{
    return [singleton getFirstUnseenNotification];
}

#pragma mark Private Methods

- (NSDictionary *)haveNotifications
{
    return [[LocalSettings controller].notifications firstObject];
}

- (NSDictionary *)getNextNotification
{
    NSDictionary *notif = [[LocalSettings controller].notifications firstObject];
    if (notif) {
        [[LocalSettings controller].notifications removeObject:notif];
        [LocalSettings saveAll];
        return notif;
    }
    int i = 0;
    // Find the first unseen notification
    for (NSDictionary *dict in [LocalSettings controller].loginNotifications) {
        NSNumber *shown = [dict objectForKey:NOTIFICATION_SHOWN_IN_APP];
        if (![shown boolValue]) {
            notif = dict;
            break;
        }
        i++;
    }
    if (notif) {
        NSMutableDictionary *temp = [notif mutableCopy];
        [temp setValue:[NSNumber numberWithBool:YES] 
                forKey:NOTIFICATION_SEEN_KEY];
        [temp setValue:[NSNumber numberWithBool:YES]
                forKey:NOTIFICATION_SHOWN_IN_APP];
        [[LocalSettings controller].loginNotifications
            replaceObjectAtIndex:i withObject:temp];
        [LocalSettings saveAll];
    }
    return notif;
}

- (NSDictionary *)getFirstUnseenNotification
{
    ABCLog(2,@"ENTER getFirstUnseenNotification\n");

    NSMutableArray *arrays = [[NSMutableArray alloc] init];
    
    if ([LocalSettings controller].notifications)
        [arrays addObject:[LocalSettings controller].notifications];
    if ([LocalSettings controller].loginNotifications)
        [arrays addObject:[LocalSettings controller].loginNotifications];
    
    for (NSMutableArray *array in arrays) {
        int i = 0;
        for (NSDictionary *notif in array) {
            NSNumber *seen = [notif objectForKey:NOTIFICATION_SEEN_KEY];
            if (nil == seen || ![seen boolValue]) {
                ABCLog(2,@"EXIT getFirstUnseenNotification: %@\n", notif);
                return notif;
            }
            i++;
        }
    }
    ABCLog(2,@"EXIT getFirstUnseenNotification: nil\n");

    return nil;
}

- (void)postNotification
{
    ABCLog(2,@"GO postNotification\n");

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NOTIFICATION_RECEIVED object:self];
    });
}

//
// Set a notification as SEEN
//
+ (BOOL)setNotificationSeen:(NSDictionary *)setSeenNotif
{
    ABCLog(2,@"ENTER setNotificationSeen\n");

    NSArray *arrays = @[[LocalSettings controller].notifications,
            [LocalSettings controller].loginNotifications];

    //
    // Verify that this notification is in our notification pool
    //
    for (NSMutableArray *array in arrays) {
        int i = 0;
        for (NSDictionary *notif in array) {
            if (notif == setSeenNotif)
            {
                NSNumber *seen = [notif objectForKey:NOTIFICATION_SEEN_KEY];

                if (nil == seen || ![seen boolValue])
                {
                    // add the seen key to the dictionary
                    NSMutableDictionary *temp = [setSeenNotif mutableCopy];
                    [temp setValue:[NSNumber numberWithBool:YES] forKey:NOTIFICATION_SEEN_KEY];
                    [array replaceObjectAtIndex:i withObject:temp];

                    [LocalSettings saveAll];
                    ABCLog(2,@"EXIT setNotificationSeen: true %@\n",notif);

                    return true;
                }
            }
            i++;
        }
    }
    ABCLog(2,@"EXIT setNotificationSeen: false\n");
    return false;
}

+ (void)start;
{
    [singleton start];
}

- (void)start
{
    if (nil == [LocalSettings controller].notifications)
    {
        [LocalSettings controller].notifications = [[NSMutableArray alloc] init];
    }
    _notificationTimer = [NSTimer scheduledTimerWithTimeInterval:NOTIF_PULL_REFRESH_INTERVAL_SECONDS
                                                          target:self
                                                        selector:@selector(checkNotifications)
                                                        userInfo:nil
                                                         repeats:YES];

    [_notificationTimer fire];
}

- (void)checkNotifications
{
    ABCLog(2,@"ENTER checkNotifications\n");
    
    if (![LocalSettings controller].bDisclaimerViewed)
        return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self checkLoginNotifications];
        [self checkDirectoryNotifications];
        
        if ([self getFirstUnseenNotification] != nil)
        {
            [self postNotification];
        }
    });
    
    ABCLog(2,@"EXIT checkNotifications\n");
}

+ (void)resetLoginNotifications
{
    int i = 0;
    while (i < [[LocalSettings controller].loginNotifications count]) {
        NSDictionary *notif = [[LocalSettings controller].loginNotifications firstObject];
        if ([[notif objectForKey:NOTIFICATION_USERNAME] isEqualToString:abcAccount.name]) {
            [[LocalSettings controller].loginNotifications removeObject:notif];
            break;
        }
        i++;
    }
    [LocalSettings saveAll];
}

- (void)resetLoginNotification:(NSDictionary *)notif
{

    [[LocalSettings controller].loginNotifications removeObject:notif];

    [LocalSettings saveAll];
}

- (void)createNotificationIfNeeded:(NSString *)username type:(NSString *)type;
{
    bool bHasNotification = false;
    
    // If there is already an OTP notification, then if it's over a day old, replace it, else ignore it
    for (NSDictionary *d in [LocalSettings controller].loginNotifications)
    {
        if ([[d objectForKey:NOTIFICATION_USERNAME] isEqualToString:username])
        {
            if ([[d objectForKey:NOTIFICATION_TYPE] isEqualToString:type])
            {
                //
                // Already a notification for this user
                //
                bHasNotification = true;
                double currentTime = [[NSDate date] timeIntervalSince1970]; // in seconds
                double notifBegan = [[d objectForKey:OTP_TIME] doubleValue];
                double delta = currentTime - notifBegan;
                
                //
                // If notification is older than the repeat period, then remove this user's notification
                // and re-add it below with new timestamp
                //
                if (delta > OTP_REPEAT_PERIOD)
                {
                    [self resetLoginNotification:d];
                    bHasNotification = false;
                    
                    // Must break out of otpNotifications loop since we have modified the dictionary
                    // during the reset
                }
                break;

            }
        }
    }
    
    if (!bHasNotification)
    {
        NSMutableDictionary *notif = [[NSMutableDictionary alloc] init];
        [notif setObject:username forKey:NOTIFICATION_USERNAME];
        [notif setObject:type forKey:NOTIFICATION_TYPE];
        [notif setValue:[NSNumber numberWithBool:NO] forKey:NOTIFICATION_SEEN_KEY];
        [notif setValue:[NSNumber numberWithBool:NO] forKey:NOTIFICATION_SHOWN_IN_APP];
        [notif setValue:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:OTP_TIME];
        
        if ([type isEqualToString:NOTIFICATION_TYPE_OTP_RESET])
        {
            [notif setObject:twoFactorResetText forKey:@"title"];
            NSString *message = [NSString stringWithFormat:aTwoFactorResetHasBeenRequested, username];
            [notif setObject:message forKey:@"message"];
            [[LocalSettings controller].loginNotifications addObject:notif];
        }
        else if ([type isEqualToString:NOTIFICATION_TYPE_RECOVERY2_CORRUPT])
        {
            [notif setObject:recoveryAnswersCorruptTitle forKey:@"title"];
            NSString *message = [NSString stringWithFormat:recoveryAnswersCorrupt, username];
            [notif setObject:message forKey:@"message"];
            [[LocalSettings controller].loginNotifications addObject:notif];
        }
        
    }
}

- (void)checkLoginNotifications
{
    NSError *error = nil;
    
    NSArray *arrayMessages = [abc getLoginMessages:&error];
    
    if (error) return;
    if (!arrayMessages) return;

    for (NSDictionary *dictMessage in arrayMessages)
    {
        if (!dictMessage)
            continue;
        
        NSString *username = dictMessage[NOTIFICATION_USERNAME];
        NSNumber *otpResetPending = dictMessage[NOTIFICATION_TYPE_OTP_RESET];
        NSNumber *recovery2Corrupt = dictMessage[NOTIFICATION_TYPE_RECOVERY2_CORRUPT];

        if (!username || ![username length])
            continue;
        
        if ([otpResetPending boolValue] == true)
            [self createNotificationIfNeeded:username type:NOTIFICATION_TYPE_OTP_RESET];
        
        if ([recovery2Corrupt boolValue] == true)
            [self createNotificationIfNeeded:username type:NOTIFICATION_TYPE_RECOVERY2_CORRUPT];
    }
}

- (void)checkDirectoryNotifications
{
    NSInteger prevNotifID = [LocalSettings controller].previousNotificationID;
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    build = [build stringByReplacingOccurrencesOfString:@"." withString:@""];
    build = [build stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString *serverQuery = [NSString stringWithFormat:@"%@/notifications/?since_id=%ld&ios_build=%@",
                             SERVER_API, (long)prevNotifID, build];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:serverQuery]];
    
    NSString *token = [NSString stringWithFormat:@"Token %@", AIRBITZ_DIRECTORY_API_KEY];
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    [request setValue:[[NSUUID UUID] UUIDString] forHTTPHeaderField:@"X-Client-ID"];
    
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
    if (error) return;

    NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error) return;
    
    if ([results objectForKey: @"results"] != (id)[NSNull null])
    {
        NSArray *notifsArray;
        notifsArray = [[results objectForKey:@"results"] copy];
        
        NSInteger highestNotifID = [LocalSettings controller].previousNotificationID;
        for(NSDictionary *dict in notifsArray)
        {
            NSInteger notifID = [[dict objectForKey:@"id"] intValue];
            if (highestNotifID < notifID)
            {
                highestNotifID = notifID;
            }
            [[LocalSettings controller].notifications addObject:dict];
        }
        
        [LocalSettings controller].previousNotificationID = highestNotifID;
        [LocalSettings saveAll];
        
    }
    
}

@end

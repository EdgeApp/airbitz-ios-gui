//
//  NotificationChecker.m
//  AirBitz
//
//  Created by Allan on 11/24/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "NotificationChecker.h"
#import "Server.h"
#import "DL_URLServer.h"
#import "CommonTypes.h"
#import "LocalSettings.h"
#import "CJSONDeserializer.h"
#import "User.h"
#import "ABC.h"

#define OTP_NOTIFICATION          @"otp_notification"
#define NOTIFICATION_SEEN_KEY     @"viewed"
#define NOTIFICATION_SHOWN_IN_APP @"shown_in_app"

static BOOL bInitialized = NO;
static NotificationChecker *singleton = nil;

@interface NotificationChecker () <DL_URLRequestDelegate>
{
    NSTimer *_notificationTimer;
}
@end

@implementation NotificationChecker

#pragma mark Public Methods
+ (void)initAll
{
    if (NO == bInitialized)
    {
        singleton = [[NotificationChecker alloc] init];
        bInitialized = YES;
        [singleton start];
    }
}

+ (void)freeAll
{
    if (YES == bInitialized)
    {
        [[DL_URLServer controller] cancelAllRequestsForDelegate:singleton];
        singleton = nil;
        bInitialized = NO;
    }
}

+ (void)requestNotifications
{
    [singleton checkNotifications:nil];
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
    for (NSDictionary *dict in [LocalSettings controller].otpNotifications) {
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
        [[LocalSettings controller].otpNotifications
            replaceObjectAtIndex:i withObject:temp];
        [LocalSettings saveAll];
    }
    return notif;
}

- (NSDictionary *)getFirstUnseenNotification
{
    NSArray *arrays = @[[LocalSettings controller].notifications,
                        [LocalSettings controller].otpNotifications];
    for (NSMutableArray *array in arrays) {
        int i = 0;
        for (NSDictionary *notif in array) {
            NSNumber *seen = [notif objectForKey:NOTIFICATION_SEEN_KEY];
            if (nil == seen || ![seen boolValue]) {
                // add the seen key to the dictionary
                NSMutableDictionary *temp = [notif mutableCopy];
                [temp setValue:[NSNumber numberWithBool:YES] forKey:NOTIFICATION_SEEN_KEY];
                [array replaceObjectAtIndex:i withObject:temp];

                [LocalSettings saveAll];
                return temp;
            }
            i++;
        }
    }
    return nil;
}

- (void)start
{
    if (nil == [LocalSettings controller].notifications)
    {
        [LocalSettings controller].notifications = [[NSMutableArray alloc] init];
    }
    _notificationTimer = [NSTimer scheduledTimerWithTimeInterval:NOTIF_PULL_REFRESH_INTERVAL_SECONDS
                                                          target:self
                                                        selector:@selector(checkNotifications:)
                                                        userInfo:nil
                                                         repeats:YES];

    [_notificationTimer fire];
}

- (void)checkNotifications:(NSTimer *)timer
{
    [self checkOtpResetPending];
    [self checkDirectoryNotifications];
}

+ (void)resetOtpNotifications
{
    while ([[LocalSettings controller].otpNotifications count] > 0) {
        NSDictionary *notif = [[LocalSettings controller].otpNotifications firstObject];
        if ([[notif objectForKey:@"id"] isEqualToString:[User Singleton].name]) {
            [[LocalSettings controller].otpNotifications removeObject:notif];
        }
    }
    [LocalSettings saveAll];
}

- (void)checkOtpResetPending
{
    char *szUsernames = NULL;
    NSArray *arrayUsers = nil;
    NSString *usernames = nil;
    tABC_Error error;
    tABC_CC cc = ABC_IsTwoFactorResetPending(&szUsernames, &error);
    if (cc != ABC_CC_Ok || !szUsernames) {
        goto exit;
    }
    usernames = [NSString stringWithUTF8String:szUsernames];
    usernames = [usernames stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    arrayUsers = [[NSMutableArray alloc] initWithArray:[usernames componentsSeparatedByString:@"\n"]];
    for (NSString *username in arrayUsers) {
        if (!username || ![username length]) {
            continue;
        }
        // If there is already an OTP notification, do not add another
        for (NSDictionary *d in [LocalSettings controller].otpNotifications) {
            if ([[d objectForKey:@"id"] isEqualToString:username]) {
                continue;
            }
        }

        NSMutableDictionary *notif = [[NSMutableDictionary alloc] init];
        [notif setObject:username forKey:@"id"];
        [notif setObject:OTP_NOTIFICATION forKey:@"type"];
        [notif setValue:[NSNumber numberWithBool:NO] forKey:NOTIFICATION_SEEN_KEY];
        [notif setValue:[NSNumber numberWithBool:NO] forKey:NOTIFICATION_SHOWN_IN_APP];
        [notif setObject:NSLocalizedString(@"Two Factor Reset", nil) forKey:@"title"];
        NSString *message = [NSString stringWithFormat:
            @"A two factor reset has been requested. Please login as %@ and approve or cancel the request.", username];
        [notif setObject:NSLocalizedString(message, nil) forKey:@"message"];
        [[LocalSettings controller].otpNotifications addObject:notif];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NOTIFICATION_RECEIVED object:self];
    }
exit:
    if (szUsernames) {
        free(szUsernames);
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
    [[DL_URLServer controller] issueRequestURL:serverQuery
                                    withParams:nil
                                    withObject:nil
                                  withDelegate:self
                            acceptableCacheAge:60
                                   cacheResult:YES];
}

#pragma mark - DLURLServer Callbacks

- (void)onDL_URLRequestCompleteWithStatus: (tDL_URLRequestStatus)status resultData: (NSData *)data resultObj: (id)object
{
    NSString *jsonString = [[NSString alloc] initWithBytes: [data bytes] length: [data length] encoding: NSUTF8StringEncoding];
    
    //    NSLog(@"Results download returned: %@", jsonString );
    
    NSData *jsonData = [jsonString dataUsingEncoding: NSUTF32BigEndianStringEncoding];
    NSError *myError;
    NSDictionary *dictFromServer = [[CJSONDeserializer deserializer] deserializeAsDictionary: jsonData error: &myError];
    
    if ([dictFromServer objectForKey: @"results"] != (id)[NSNull null])
    {
        NSArray *notifsArray;
        notifsArray = [[dictFromServer objectForKey:@"results"] copy];
        
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
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NOTIFICATION_RECEIVED object:self];
    }
}

@end

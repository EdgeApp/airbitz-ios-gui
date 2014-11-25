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

static BOOL bInitialized = NO;
static NotificationChecker *singleton = nil;

@interface NotificationChecker () <DL_URLRequestDelegate>
{
    NSTimer *_notificationTimer;
    NSMutableArray *_notifications;
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

+ (NSDictionary *)firstNotification
{
    return [singleton getNextNotification];
}

#pragma mark Private Methods

- (NSDictionary *)getNextNotification
{
    NSDictionary *notif = [_notifications firstObject];
    if (notif)
    {
        [_notifications removeObject:notif];
    }
    return notif;
}

- (void)start
{
    _notifications = [[NSMutableArray alloc] init];
    _notificationTimer = [NSTimer scheduledTimerWithTimeInterval:NOTIF_PULL_REFRESH_INTERVAL_SECONDS
                                                          target:self
                                                        selector:@selector(checkNotifications:)
                                                        userInfo:nil
                                                         repeats:YES];

    [_notificationTimer fire];
}

- (void)checkNotifications:(NSTimer *)timer
{
    NSInteger prevNotifID = [LocalSettings controller].previousNotificationID;
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    build = [build stringByReplacingOccurrencesOfString:@"." withString:@""];
    build = [build stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString *serverQuery = [NSString stringWithFormat:@"%@/notifications/?since_id=%d&ios_build=%@",
                             SERVER_API, prevNotifID, build];
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
            [_notifications addObject:dict];
        }
        
        [LocalSettings controller].previousNotificationID = highestNotifID;
        [LocalSettings saveAll];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NOTIFICATION_RECEIVED object:self];
    }
}

@end

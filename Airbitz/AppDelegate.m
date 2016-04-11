//
//  AppDelegate.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/4/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "AppDelegate.h"
#import "User.h"
#import "AirbitzCore.h"
#import "CommonTypes.h"
#import "PopupPickerView.h"
#import "Plugin.h"
#import "LocalSettings.h"
#import "AudioController.h"
#import "Config.h"
#import <HockeySDK/HockeySDK.h>
#import <SDWebImage/SDImageCache.h>
#import "NotificationChecker.h"
#import "NSString+StripHTML.h"
#import "Reachability.h"
#import "Util.h"
#import "Config.h"
#import "Theme.h"
#import "AB.h"

UIBackgroundTaskIdentifier bgLogoutTask;
UIBackgroundTaskIdentifier bgNotificationTask;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [application setStatusBarHidden:NO];
    [application setStatusBarStyle:UIStatusBarStyleDefault];

    [[SDImageCache sharedImageCache] clearDisk];
    [[SDImageCache sharedImageCache] cleanDisk];
    [[SDImageCache sharedImageCache] clearMemory];

    [LocalSettings initAll];

    [PopupPickerView initAll];

    [AudioController initAll];

    abc = [[AirbitzCore alloc] init:API_KEY_HEADER hbits:HIDDENBITZ_KEY];

    // Reset badges to 0
    application.applicationIconBadgeNumber = 0;

    // Set background fetch in seconds
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];


    Reachability *reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    [reachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(reachabilityDidChange:)
                                                name:kReachabilityChangedNotification
                                            object:nil];
    
    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    
#if (!AIRBITZ_IOS_DEBUG) || (0 == AIRBITZ_IOS_DEBUG)
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:HOCKEY_MANAGER_ID];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
#endif

    return YES;
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    if (notificationSettings.types & UIUserNotificationTypeAlert)
    {
        [LocalSettings controller].bLocalNotificationsAllowed = YES;
        ABCLog(1, @"Local notifications allowed");
    }
    else
    {
        [LocalSettings controller].bLocalNotificationsAllowed = NO;
        ABCLog(1, @"Local notifications not allowed");
    }
    
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    // Reset badges to 0
    application.applicationIconBadgeNumber = 0;
}

//  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    NSDictionary *d = @{ KEY_URL: url };
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HANDLE_BITCOIN_URI object:self userInfo:d];
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    ABCLog(2,@"ENTER performFetch...\n");

    bool bDidNotification = [self showNotifications];

    if (bDidNotification)
    {
        ABCLog(2,@"EXIT performFetch() NewData...\n");
        completionHandler(UIBackgroundFetchResultNewData);
    }
    else
    {
        ABCLog(2,@"EXIT performFetch() NoData...\n");
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[SDImageCache sharedImageCache] clearDisk];
    [[SDImageCache sharedImageCache] cleanDisk];
    [[SDImageCache sharedImageCache] clearMemory];

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [LocalSettings saveAll];

    bgNotificationTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [self bgNotificationCleanup];
    }];

    if ([User isLoggedIn])
    {
        [abc enterBackground];
        bgLogoutTask = [application beginBackgroundTaskWithExpirationHandler:^{
            [self bgLogoutCleanup];
        }];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self bgNotificationCleanup];
    [self bgLogoutCleanup];
    [abc enterForeground];
    if (![self isAppActive] && !abcAccount)
    {
        [[User Singleton] clear];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self bringNotificationsToForeground];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [LocalSettings freeAll];
    [[User Singleton] clear];

    [abc free];

}

- (void)bgLogoutCleanup
{
    [[UIApplication sharedApplication] endBackgroundTask:bgLogoutTask];
    bgLogoutTask = UIBackgroundTaskInvalid;
}

- (void)bgNotificationCleanup
{
    [[UIApplication sharedApplication] endBackgroundTask:bgNotificationTask];
    bgNotificationTask = UIBackgroundTaskInvalid;
}


- (BOOL)isAppActive
{
    return [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
}

- (BOOL)showNotifications
{
    ABCLog(2,@"ENTER showNotifications\n");

    bool bDidNotification = false;

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        [NotificationChecker requestNotifications];

        NSDictionary *notif = [NotificationChecker unseenNotification];
        while (notif)
        {
            ABCLog(2,@"IN showNotifications: while loop\n");

            UILocalNotification *localNotif = [[UILocalNotification alloc] init];
            
            if ([localNotif respondsToSelector:@selector((setAlertTitle:))])
            {
                NSString *title = [notif objectForKey:@"title"];
                NSString *strippedTitle = [title stringByStrippingHTML];
                [localNotif setAlertTitle:strippedTitle];
            }
            
            NSString *message = [notif objectForKey:@"message"];
            NSString *strippedMessage = [message stringByStrippingHTML];
            [localNotif setAlertBody:strippedMessage];
            
            // fire the notification now
            [localNotif setFireDate:[NSDate date]];
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];

            // Mark seen
            [NotificationChecker setNotificationSeen:notif];

            // get the next one
            notif = [NotificationChecker unseenNotification];

            bDidNotification = true;
        };
        
        const NSTimeInterval MinTimeBetweenNoPasswordNotifications = (60 * 60 * 24); // One day
        
        //
        // Popup notification if user has accounts with no passwords
        //
        NSMutableArray *arrayAccounts = [[NSMutableArray alloc] init];
        [abc listLocalAccounts:arrayAccounts];
        BOOL bDidNoPasswordNotification = false;

        [LocalSettings loadAll];
        NSTimeInterval intervalNow = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval intervalLast = [LocalSettings controller].noPasswordNotificationTime;

        if (arrayAccounts)
        {
            if ((intervalNow - intervalLast) > MinTimeBetweenNoPasswordNotifications)
            {
                for (NSString *acct in arrayAccounts)
                {
                    if (![abc accountHasPassword:acct error:nil])
                    {
                        UILocalNotification *localNotif = [[UILocalNotification alloc] init];

                        if ([localNotif respondsToSelector:@selector((setAlertTitle:))])
                        {
                            NSString *title = accountsNeedsPasswordNotificationTitle;
                            [localNotif setAlertTitle:title];
                        }
                        
                        NSString *message = [NSString stringWithFormat:accountsNeedsPasswordNotificationMessage, acct];
                        [localNotif setAlertBody:message];
                        
                        // fire the notification now
                        [localNotif setFireDate:[NSDate date]];
                        [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
                        bDidNotification = true;
                        bDidNoPasswordNotification = true;
                        
                    }
                }
            }
            
        }
        
        if (bDidNoPasswordNotification)
        {
            [LocalSettings controller].noPasswordNotificationTime = intervalNow;
            [LocalSettings saveAll];
        }
        
    }

    ABCLog(2,@"EXIT showNotifications\n");

    return bDidNotification;
}

- (void)bringNotificationsToForeground
{
    if ([NotificationChecker haveNotifications])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NOTIFICATION_RECEIVED object:self];
    }
}

#pragma mark - Notification handlers

- (void)reachabilityDidChange:(NSNotification *)notification
{
    Reachability *reachability = (Reachability *)[notification object];
    if ([reachability isReachable]) {
        [abc setConnectivity:YES];
    }
}

@end

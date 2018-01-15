//
//  AppDelegate.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/4/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "AppDelegate.h"
#import "User.h"
#import "ABCContext.h"
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
#import "Util.h"
#import "Config.h"
#import "Theme.h"
#import "AB.h"
#import "Airbitz-Swift.h"
#import "Mixpanel/Mixpanel.h"

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

    abc = [ABCContext makeABCContext:AIRBITZ_CORE_API_KEY type:@"account:repo:co.airbitz.wallet" hbits:HIDDENBITZ_KEY];

    if (AUTO_UPLOAD_LOGS)
    {
        [abc uploadLogs:@"Auto-uploaded Logs" complete:^{
            ABCLog(1, @"Logs auto-uploaded");
        } error:^(ABCError *error) {
            ABCLog(1, @"Error auto-uploading logs: %@", error.description);
        }];
    }

    // Reset badges to 0
    application.applicationIconBadgeNumber = 0;

    // Set background fetch in seconds
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    
#if (!AIRBITZ_IOS_DEBUG) || (0 == AIRBITZ_IOS_DEBUG)
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:HOCKEY_MANAGER_ID];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
#endif

    //DropDown configuration
    [DropDown startListeningToKeyboard];
    
    Mixpanel *mixPanel = [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    [mixPanel setEnableLogging:FALSE];
    
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

    [NotificationChecker initAll];
    
    bool bDidNotification = [self showNotificationsFromBackgroundFetch];

    if (abc)
    {
        [abc enterForeground];
        [abc enterBackground];
    }
    
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
    UIApplication*    app = [UIApplication sharedApplication];
    
    [LocalSettings saveAll];
    [abc enterBackground];

    bgNotificationTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [self bgNotificationCleanup];
    }];

    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if ([User isLoggedIn])
        {
            // Do the work associated with the task.

            NSTimeInterval time;
            do
            {
                time = [app backgroundTimeRemaining];
                NSLog(@"Started background task timeremaining = %f", [app backgroundTimeRemaining]);
                [NSThread sleepForTimeInterval:0.5f];
                if (bgNotificationTask == UIBackgroundTaskInvalid)
                {
                    break;
                }
            }
            while (time > 10);

            if (bgNotificationTask != UIBackgroundTaskInvalid)
            {
                [abc startSuspend];
                [self bgNotificationCleanup];
            }
        }
        
    });

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self bgNotificationCleanup];
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

//- (void)bgLogoutCleanup
//{
//    [[UIApplication sharedApplication] endBackgroundTask:bgLogoutTask];
//    bgLogoutTask = UIBackgroundTaskInvalid;
//}

- (void)bgNotificationCleanup
{
    [[UIApplication sharedApplication] endBackgroundTask:bgNotificationTask];
    bgNotificationTask = UIBackgroundTaskInvalid;
}


- (BOOL)isAppActive
{
    return [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
}

- (BOOL)showNotificationsFromBackgroundFetch
{
    ABCLog(2,@"ENTER showNotificationsFromBackgroundFetch\n");

    bool bDidNotification = false;

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        [NotificationChecker requestNotificationsFromBackgroundFetch];

        NSDictionary *notif = [NotificationChecker unseenNotification];
        while (notif)
        {
            ABCLog(2,@"IN showNotificationsFromBackgroundFetch: while loop\n");

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
        NSArray *arrayAccounts = [abc listUsernames:nil];
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

    ABCLog(2,@"EXIT showNotificationsFromBackgroundFetch\n");

    return bDidNotification;
}

- (void)bringNotificationsToForeground
{
    if ([NotificationChecker haveNotifications])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NOTIFICATION_RECEIVED object:self];
    }
}

@end

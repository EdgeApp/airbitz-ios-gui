//
//  AppDelegate.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/4/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "AppDelegate.h"
#import "ABC.h"
#import "User.h"
#import "CoreBridge.h"
#import "CommonTypes.h"
#import "PopupPickerView.h"
#import "LocalSettings.h"
#import <HockeySDK/HockeySDK.h>

UIBackgroundTaskIdentifier bgLogoutTask;
NSTimer *logoutTimer = NULL;
NSDate *logoutDate = NULL;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [application setStatusBarHidden:NO];
    [application setStatusBarStyle:UIStatusBarStyleLightContent];

    [LocalSettings initAll];

    [PopupPickerView initAll];

    [CoreBridge initAll];

    // Reset badges to 0
    application.applicationIconBadgeNumber = 0;
    
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"***REMOVED***"];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];

    return YES;
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
    if (![self isAppActive])
    {
        [self autoLogout];
    }
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    if ([User isLoggedIn])
    {
        logoutDate = [NSDate date];
        [application setMinimumBackgroundFetchInterval: [User Singleton].minutesAutoLogout * 60];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [LocalSettings saveAll];

    if ([User isLoggedIn])
    {
        [CoreBridge stopQueues];
        bgLogoutTask = [application beginBackgroundTaskWithExpirationHandler:^{
            [self bgCleanup];
        }];
        // start a logout timer
        logoutTimer = [NSTimer scheduledTimerWithTimeInterval:[User Singleton].minutesAutoLogout * 60
                                                       target:self
                                                       selector:@selector(autoLogout)
                                                       userInfo:application
                                                       repeats:NO];
        if ([CoreBridge allWatchersReady])
        {
            [CoreBridge stopWatchers];
        }
        else
        {
            // If the watchers aren't finished, let them finish
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                while (![CoreBridge allWatchersReady])
                {
                    // if app is active, break out of loop
                    if ([self isAppActive])
                    {
                        break;
                    }
                    sleep(5);
                }
                // if the app *is not* active, stop watchers
                if (![self isAppActive])
                {
                    [CoreBridge stopWatchers];
                }
                if (![logoutTimer isValid])
                {
                    [self bgCleanup];
                }
            });
        }
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self bgCleanup];
    [self checkLoginExpired];
    if ([User isLoggedIn])
    {
        [CoreBridge startWatchers];
        [CoreBridge startQueues];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [LocalSettings freeAll];
    
    [[User Singleton] clear];
    ABC_Terminate();
}

- (void)watchStatus
{
}

- (void)bgCleanup
{
    if (logoutTimer)
    {
        [logoutTimer invalidate];
    }
    [[UIApplication sharedApplication] endBackgroundTask:bgLogoutTask];
    bgLogoutTask = UIBackgroundTaskInvalid;
}

// This is a fallback for auto logout. It is better to have the background task
// or network fetch log the user out
- (void)checkLoginExpired
{
    if (!logoutDate || ![User isLoggedIn])
    {
        return;
    }
    NSDate *now = [NSDate date];
    int minutes = [now timeIntervalSinceDate:logoutDate] / 60.0;
    if (minutes >= [User Singleton].minutesAutoLogout) {
        [self autoLogout];
    }
}

// If the app is *not* active, log the user out
- (void)autoLogout
{
    if (![self isAppActive])
    {
        [[User Singleton] clear];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MAIN_RESET object:self];
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval: UIApplicationBackgroundFetchIntervalNever];
    }
    [self bgCleanup];
}

- (BOOL)isAppActive
{
    return [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
}

@end

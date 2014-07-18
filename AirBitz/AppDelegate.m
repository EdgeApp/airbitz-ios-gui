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

UIBackgroundTaskIdentifier bgLogoutTask;
NSTimer *logoutTimer = NULL;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [application setStatusBarHidden:NO];
    [application setStatusBarStyle:UIStatusBarStyleLightContent];
    [PopupPickerView initAll];
    [CoreBridge initAll];

    // Reset badges to 0
    application.applicationIconBadgeNumber = 0;
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

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"Resign Active background!!!!");
    if ([User isLoggedIn])
    {
        NSLog(@("Settings background fetch interval to %d\n"), [User Singleton].minutesAutoLogout * 60);
        [application setMinimumBackgroundFetchInterval: [User Singleton].minutesAutoLogout * 60];
    }

}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    NSLog(@"Calling fetch!!!!");
    if (![self isAppActive])
    {
        [self autoLogout];
    }
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"Entered background!!!!");
    if ([User isLoggedIn])
    {
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
    NSLog(@"Entered Foreground!!!!");
    [self bgCleanup];
    if ([User isLoggedIn])
    {
        [CoreBridge startWatchers];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive!!!!");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[User Singleton] clear];
    ABC_Terminate();
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

- (void)autoLogout
{
    if (![self isAppActive])
    {
        NSLog(@"**********Autologout**********");
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

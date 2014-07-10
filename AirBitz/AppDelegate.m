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
#import "CommonTypes.h"
#import "PopupPickerView.h"

UIBackgroundTaskIdentifier bgLogoutTask;
NSTimer *logoutTimer = NULL;
bool IN_BACKGROUND   = false;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
	[application setStatusBarHidden:NO];
	[application setStatusBarStyle:UIStatusBarStyleLightContent];
	[PopupPickerView initAll];

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
    if ([User isLoggedIn])
    {
        bgLogoutTask = [application beginBackgroundTaskWithExpirationHandler:^{
            [self autoLogout];
        }];
        logoutTimer = [NSTimer scheduledTimerWithTimeInterval:[User Singleton].minutesAutoLogout * 60
                                                       target:self
                                                       selector:@selector(autoLogout)
                                                       userInfo:application
                                                       repeats:NO];
    }
    IN_BACKGROUND = YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    IN_BACKGROUND = YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    IN_BACKGROUND = NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (logoutTimer)
    {
        [logoutTimer invalidate];
    }
    [application endBackgroundTask:bgLogoutTask];
    bgLogoutTask = UIBackgroundTaskInvalid;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[User Singleton] clear];
    ABC_Terminate();
}

- (void)autoLogout
{
    if (IN_BACKGROUND)
    {
        [[User Singleton] clear];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MAIN_RESET object:self];
    }
    [[UIApplication sharedApplication] endBackgroundTask:bgLogoutTask];
    bgLogoutTask = UIBackgroundTaskInvalid;
}

@end

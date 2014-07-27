//
//  AppDelegate.m
//
//  Copyright (c) 2014, Airbitz
//  All rights reserved.
//
//  Redistribution and use in source and binary forms are permitted provided that
//  the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//  3. Redistribution or use of modified source code requires the express written
//  permission of Airbitz Inc.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the Airbitz Project.
//
//  See AUTHORS for contributing developers
//


#import "AppDelegate.h"
#import "ABC.h"
#import "User.h"
#import "CoreBridge.h"
#import "CommonTypes.h"
#import "PopupPickerView.h"

UIBackgroundTaskIdentifier bgLogoutTask;
NSTimer *logoutTimer = NULL;
NSDate *logoutDate = NULL;

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

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    NSLog(@"Calling fetch!!!!");
    if (![self isAppActive])
    {
        [self autoLogout];
    }
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"Resign Active background!!!!");
    if ([User isLoggedIn])
    {
        NSLog(@("Settings background fetch interval to %d\n"), [User Singleton].minutesAutoLogout * 60);
        logoutDate = [NSDate date];
        [application setMinimumBackgroundFetchInterval: [User Singleton].minutesAutoLogout * 60];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"Entered background!!!!");
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
    NSLog(@"Entered Foreground!!!!");
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
    NSLog(@"applicationDidBecomeActive!!!!");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
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

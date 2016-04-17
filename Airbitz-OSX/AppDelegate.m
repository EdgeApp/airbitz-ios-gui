//
//  AppDelegate.m
//  Airbitz-OSX
//
//  Created by Paul P on 4/14/16.
//  Copyright © 2016 Airbitz. All rights reserved.
//

#import "AppDelegate.h"
#import "AudioController.h"
#import "LocalSettings.h"
#import "AirbitzCore.h"
#import "Config.h"
#import "AB.h"
#import "Reachability.h"
#import "User.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [LocalSettings initAll];
//    [AudioController initAll];

    abc = [[AirbitzCore alloc] init:AIRBITZ_CORE_API_KEY hbits:HIDDENBITZ_KEY];
    
    Reachability *reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    [reachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityDidChange:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    
    [LocalSettings freeAll];
    [[User Singleton] clear];
    
    [abc free];
    

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

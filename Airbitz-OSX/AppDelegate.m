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
#import "ABCContext.h"
#import "Config.h"
#import "AB.h"
#import "Reachability.h"
#import "User.h"

@interface AppDelegate ()
{
}
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    
    [LocalSettings freeAll];
    [[User Singleton] clear];
    
    [abc free];
    

}

@end

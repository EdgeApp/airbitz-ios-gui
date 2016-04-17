//
//  ViewController.m
//  Airbitz-OSX
//
//  Created by Paul P on 4/14/16.
//  Copyright © 2016 Airbitz. All rights reserved.
//

#import "MainController.h"
#import "ViewController.h"
#import "AudioController.h"
#import "LocalSettings.h"
#import "AirbitzCore.h"
#import "Config.h"
#import "AB.h"
#import "Reachability.h"
#import "User.h"


@implementation ViewController

- (void)viewDidLoad {
    [self didFinishLaunching];
    [super viewDidLoad];
    
    NSError *error;
    abcAccount = [abc passwordLogin:@"hello8" password:@"Hello12345" delegate:self error:&error];
    
    NSLog(@"%@", abcAccount.name);
}

- (void) abcAccountWalletLoaded:(ABCWallet *)wallet;
{
    
}

- (void) didFinishLaunching
{
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

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
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

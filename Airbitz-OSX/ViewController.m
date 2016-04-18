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

@interface ViewController () <NSTextFieldDelegate, ABCAccountDelegate>
{
    
}

@property (weak)            IBOutlet    NSTextField                     *usernameTextField;
@property (weak)            IBOutlet    NSSecureTextField               *passwordTextField;
@property (weak)            IBOutlet    NSTextField                     *infoTextLabel;
@property (weak)            IBOutlet    NSImageView                     *qrcodeImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [self didFinishLaunching];
    [super viewDidLoad];
    
    _usernameTextField.delegate = self;
    [_usernameTextField setTarget:self];
    [_usernameTextField setAction:@selector(usernameTextFieldDidHitEnter:)];
    
    _passwordTextField.delegate = self;
    [_passwordTextField setTarget:self];
    [_passwordTextField setAction:@selector(passwordTextFieldDidHitEnter:)];
    
    [_usernameTextField becomeFirstResponder];
    
    [_qrcodeImageView setWantsLayer:YES];
    [_qrcodeImageView.layer setBackgroundColor:[[NSColor clearColor] CGColor]];
}

- (void)usernameTextFieldDidHitEnter:(id)sender
{
    
}



- (void)passwordTextFieldDidHitEnter:(id)sender
{
    if (abcAccount)
    {
        [abcAccount logout];
    }
    
    NSError *error;
    NSString *str = [NSString stringWithFormat:@"Attempting to log into account: %@", _usernameTextField.stringValue];
    [_infoTextLabel setStringValue:str];
    abcAccount = [abc passwordLogin:_usernameTextField.stringValue password:_passwordTextField.stringValue delegate:self error:&error];
    
    if (abcAccount && abcAccount.name)
    {
        NSString *str = [NSString stringWithFormat:@"Successfully logged into account: %@ (Loading Wallets...)", _usernameTextField.stringValue];
        [_infoTextLabel setStringValue:str];
    }
    else
    {
        NSString *str = [NSString stringWithFormat:@"Failed to log into account: %@", _usernameTextField.stringValue];
        [_infoTextLabel setStringValue:str];
    }
    NSLog(@"%@", abcAccount.name);
    
}

- (void) abcAccountWalletLoaded:(ABCWallet *)wallet;
{
    NSString *str = [NSString stringWithFormat:@"Wallets Loaded"];
    [_infoTextLabel setStringValue:str];
    
    
    if ([wallet.uuid isEqualToString:((ABCWallet *)abcAccount.arrayWallets[0]).uuid])
    {
        ABCReceiveAddress *address = [wallet createNewReceiveAddress];
        
        if (address)
        {
            [_qrcodeImageView setWantsLayer:YES];
            [_qrcodeImageView.layer setBackgroundColor:[[NSColor whiteColor] CGColor]];
            
            [_qrcodeImageView setImage:address.qrCode];
            [_qrcodeImageView setImageScaling:NSScaleToFit];
        }
    }
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

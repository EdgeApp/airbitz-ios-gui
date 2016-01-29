//
//  DebugViewController.m
//  AirBitz
//
//  Created by Timbo on 6/16/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "DebugViewController.h"
#import "User.h"
#import "CoreBridge.h"
#import "CommonTypes.h"
#import "MainViewController.h"
#import "Theme.h"
#import "Util.h"
#import "Strings.h"

@interface DebugViewController ()  <UIAlertViewDelegate, UIGestureRecognizerDelegate>
{
    UIAlertView                     *_uploadLogAlert;
}

@property (nonatomic, weak) IBOutlet UIButton *clearWatcherButton;
@property (nonatomic, weak) IBOutlet UIButton *uploadLogsButton;
@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@property (nonatomic, weak) IBOutlet UILabel *coreLabel;
@property (nonatomic, weak) IBOutlet UILabel *networkLabel;


@end

@implementation DebugViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];

    self.versionLabel.text = [NSString stringWithFormat:@"%@ %@", version, build];
    self.coreLabel.text = [NSString stringWithFormat:@"%@", [[AppDelegate abc] coreVersion]];
#if NETWORK_FAKE
    self.networkLabel.text = @"Fake";
#else
    if ([[AppDelegate abc] isTestNet]) {
        self.networkLabel.text = @"Testnet";
    } else {
        self.networkLabel.text = @"Mainnet";
    }
#endif

    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionDetailsExit) name:NOTIFICATION_TRANSACTION_DETAILS_EXITED object:nil];

}

- (void)viewWillAppear:(BOOL)animated
{
    [self setupNavBar];
}

- (void)setupNavBar
{
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBarTitle:self title:NSLocalizedString(@"Debug Options", @"Debug screen header title")];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(back) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
}


- (void)transactionDetailsExit
{
    // An async tx details happened and exited. Drop everything and kill ourselves or we'll
    // corrupt the background. This is needed on every subview of a primary screen
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (_uploadLogAlert == alertView)
    {
        if (1 == buttonIndex)
        {
            ABLog(2,@"Uploading Logs\n");
            [MainViewController fadingAlert:uploadingLogText holdTime:FADING_ALERT_HOLD_TIME_FOREVER_WITH_SPINNER];
            [[AppDelegate abc] uploadLogs:[[alertView textFieldAtIndex:0] text] complete:^
            {
                [MainViewController fadingAlert:uploadSuccessfulText holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
                
            } error:^(ABCConditionCode ccode, NSString *errorString)
            {
                [MainViewController fadingAlert:uploadFailedText holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
            }];
        }
    }
}

#pragma mark - Actions Methods

- (void)back
{
    [self.delegate sendDebugViewControllerDidFinish:self];
}

- (IBAction)uploadLogs:(id)sender
{
    NSString *title = NSLocalizedString(@"Upload Log File", nil);
    NSString *message = NSLocalizedString(@"Enter any notes you would like to send to our support staff", nil);
    // show password reminder test
    _uploadLogAlert = [[UIAlertView alloc] initWithTitle:title
                                                 message:message
                                                delegate:self
                                       cancelButtonTitle:@"Cancel"
                                       otherButtonTitles:@"Upload Log", nil];
    _uploadLogAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_uploadLogAlert show];
}

- (IBAction)clearWatcher:(id)sender
{
    ABLog(2,@"Clearing Watcher\n");
    NSString *buttonText = self.clearWatcherButton.titleLabel.text;

    self.clearWatcherButton.titleLabel.text = @"Restarting watcher service";

    [[AppDelegate abc] clearBlockchainCache:^{
        self.clearWatcherButton.titleLabel.text = buttonText;
        [MainViewController fadingAlert:watcherClearedText holdTime:FADING_ALERT_HOLD_TIME_DEFAULT];
    } error:^(ABCConditionCode ccode, NSString *errorString) {
        self.clearWatcherButton.titleLabel.text = buttonText;
        [MainViewController fadingAlert:watcherClearedWithErrorText holdTime:FADING_ALERT_HOLD_TIME_DEFAULT];
    }];
}

#pragma mark - Misc Methods

- (void)installLeftToRightSwipeDetection
{
	UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeftToRight:)];
	gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:gesture];
}

// used by the gesture recognizer to ignore exit
- (BOOL)haveSubViewsShowing
{
    return NO;
}

#pragma mark - GestureRecognizer methods

- (void)didSwipeLeftToRight:(UIGestureRecognizer *)gestureRecognizer
{
    if (![self haveSubViewsShowing])
    {
        [self back];
    }
}

#pragma mark - Custom Notification Handlers

// called when a tab bar button that is already selected, is reselected again
- (void)tabBarButtonReselect:(NSNotification *)notification
{
    if (![self haveSubViewsShowing])
    {
        [self back];
    }
}

@end

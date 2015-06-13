//
//  DebugViewController.m
//  AirBitz
//
//  Created by Timbo on 6/16/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "DebugViewController.h"
#import "ABC.h"
#import "User.h"
#import "CoreBridge.h"
#import "CommonTypes.h"
#import "MainViewController.h"
#import "Theme.h"
#import "Util.h"

@interface DebugViewController ()  <UIGestureRecognizerDelegate>
{
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
    self.coreLabel.text = [NSString stringWithFormat:@"%@", [CoreBridge coreVersion]];
#if NETWORK_FAKE
    self.networkLabel.text = @"Fake";
#else
    if ([CoreBridge isTestNet]) {
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
    [MainViewController changeNavBar:self title:[Theme Singleton].backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(back) fromObject:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].helpButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
}


- (void)transactionDetailsExit
{
    // An async tx details happened and exited. Drop everything and kill ourselves or we'll
    // corrupt the background. This is needed on every subview of a primary screen
    [self.view removeFromSuperview];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions Methods

- (void)back
{
    [self.delegate sendDebugViewControllerDidFinish:self];
}

- (IBAction)uploadLogs:(id)sender
{
    ABLog(2,@"Uploading Logs\n");

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        tABC_Error Error;
        ABC_UploadLogs([[User Singleton].name UTF8String],
                       [[User Singleton].password UTF8String],
                       &Error);
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if (ABC_CC_Ok == Error.code)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Debug Log File"
                                                                message:@"Upload Succeeded"
                                                               delegate:self
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Debug Log File"
                                                                message:@"Upload Failed. Please check your network connection or contact support@airbitz.co"
                                                               delegate:self
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
            }

        });
    });
}

- (IBAction)clearWatcher:(id)sender
{
    ABLog(2,@"Clearing Watcher\n");
    NSString *buttonText = self.clearWatcherButton.titleLabel.text;
//    NSMutableArray *wallets = [[NSMutableArray alloc] init];
//    NSMutableArray *archived = [[NSMutableArray alloc] init];
//    [CoreBridge loadWallets:wallets archived:archived];
    [CoreBridge refreshWallets];

    self.clearWatcherButton.titleLabel.text = @"Restarting watcher service";

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [CoreBridge stopWatchers];
        [CoreBridge startWatchers];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.clearWatcherButton.titleLabel.text = buttonText;
        });
    });
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

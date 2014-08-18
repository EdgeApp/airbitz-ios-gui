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

@interface DebugViewController ()  <UIGestureRecognizerDelegate>
{
}

@property (nonatomic, weak) IBOutlet UIButton *clearWatcherButton;
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions Methods

- (IBAction)back:(id)sender
{
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         CGRect frame = self.view.frame;
         frame.origin.x = frame.size.width;
         self.view.frame = frame;
     }
     completion:^(BOOL finished)
     {
         [self.delegate sendDebugViewControllerDidFinish:self];
     }];
}

- (IBAction)clearWatcher:(id)sender
{
    NSLog(@"Clearing Watcher\n");
    NSString *buttonText = self.clearWatcherButton.titleLabel.text;
    NSMutableArray *wallets = [[NSMutableArray alloc] init];
    NSMutableArray *archived = [[NSMutableArray alloc] init];
    [CoreBridge loadWallets:wallets archived:archived];

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

// used by the guesture recognizer to ignore exit
- (BOOL)haveSubViewsShowing
{
    return NO;
}

#pragma mark - GestureReconizer methods

- (void)didSwipeLeftToRight:(UIGestureRecognizer *)gestureRecognizer
{
    if (![self haveSubViewsShowing])
    {
        [self back:nil];
    }
}

#pragma mark - Custom Notification Handlers

// called when a tab bar button that is already selected, is reselected again
- (void)tabBarButtonReselect:(NSNotification *)notification
{
    if (![self haveSubViewsShowing])
    {
        [self back:nil];
    }
}

@end

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

@interface DebugViewController ()
{
}

@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
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

    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    self.versionLabel.text = infoDictionary[(NSString*)kCFBundleVersionKey];
#if NETWORK_FAKE
    self.networkLabel.text = @"Fake";
#else
    self.networkLabel.text = @"Mainnet";
#endif
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
    NSString *buttonText = _clearWatcherButton.titleLabel.text;
    NSMutableArray *wallets = [[NSMutableArray alloc] init];
    NSMutableArray *archived = [[NSMutableArray alloc] init];
    [CoreBridge loadWallets:wallets archived:archived];

    _clearWatcherButton.titleLabel.text = @"Restarting watcher service";

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        for (Wallet *w in wallets) {
            NSLog(@"Restarting %@\n", w.strName);
            dispatch_async(dispatch_get_main_queue(), ^(void){
                _clearWatcherButton.titleLabel.text = [NSString stringWithFormat:@"Restarting %@", w.strName];
            });
            tABC_Error Error;
            ABC_WatcherRestart([[User Singleton].name UTF8String],
                               [[User Singleton].password UTF8String],
                               [w.strUUID UTF8String], true, &Error);
        }
        dispatch_async(dispatch_get_main_queue(), ^(void){
            _clearWatcherButton.titleLabel.text = buttonText;
        });
    });
}

@end

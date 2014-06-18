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
    tABC_Error Error;
    NSString *buttonText = _clearWatcherButton.titleLabel.text;
    NSMutableArray *wallets = [[NSMutableArray alloc] init];
    NSMutableArray *archived = [[NSMutableArray alloc] init];
    [CoreBridge loadWallets:wallets archived:archived];

    _clearWatcherButton.titleLabel.text = @"Restarting watcher service";

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        for (Wallet *w in wallets)
        {
            NSLog(@"Restarting %@\n", w.strName);
            dispatch_async(dispatch_get_main_queue(), ^(void){
                _clearWatcherButton.titleLabel.text = [NSString stringWithFormat:@"Restarting %@", w.strName];
            });
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

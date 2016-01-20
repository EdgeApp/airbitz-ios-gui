//
//  SyncView.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/21/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "SyncView.h"
#import "CoreBridge.h"
#import "Util.h"
#import "AppDelegate.h"

#define SYNC_CHECK_INTERVAL 1.0 // second

@interface SyncView ()

@property (nonatomic, weak) IBOutlet UIView *alertView;
@property (nonatomic, weak) IBOutlet UIView *backgroundView;
@property (nonatomic, strong) IBOutlet NSString *walletUUID;
@property (nonatomic, weak) NSTimer *syncTimer;

@end

@implementation SyncView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (SyncView *)createView:(UIView *)parentView forWallet:(NSString *)walletUUID
{
    SyncView *sv;
    // show yellow alert
    sv = [[[NSBundle mainBundle] loadNibNamed:@"SyncView~iphone" owner:nil options:nil] objectAtIndex:0];
    sv.walletUUID = walletUUID;

    CGRect frame = sv.frame;
    CGRect parent = parentView.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    frame.size.width = parent.size.width;
    frame.size.height = parent.size.height;
    sv.frame = frame;

    sv.backgroundView.frame = frame;

    // Round those corners and add shadows
    sv.alertView.layer.cornerRadius = 8.0;
    sv.alertView.layer.shadowColor = [UIColor blackColor].CGColor;
    sv.alertView.layer.shadowOpacity = 0.8;
    sv.alertView.layer.shadowRadius = 3.0;
    sv.alertView.layer.shadowOffset = CGSizeMake(2.0, 2.0);

    [parentView addSubview:sv];

    sv.alpha = 0.0;
    [UIView animateWithDuration:0.35
                        delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                    animations:^
    {
        sv.alpha = 1.0;
    }
                    completion:^(BOOL finished)
    {
        [sv startTimer];
    }];
    return sv;
}

- (void)startTimer
{
    _syncTimer = [NSTimer scheduledTimerWithTimeInterval:SYNC_CHECK_INTERVAL
        target:self
        selector:@selector(checkSyncView:)
        userInfo:nil
        repeats:YES];
}

- (void)checkSyncView:(NSNotification *)notification
{
    if ([[AppDelegate abc] watcherIsReady:_walletUUID])
    {
        [self dismiss];
    }
}

- (void)dismiss
{
    [_syncTimer invalidate];
    _syncTimer = nil;

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         CGRect frame = self.frame;
         frame.origin.y = -frame.size.height;
         self.frame = frame;
     }
     completion:^(BOOL finished)
     {
         [self.delegate SyncViewDismissed:self];
     }];
}

@end

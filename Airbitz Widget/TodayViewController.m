//
//  TodayViewController.m
//  Airbitz Widget
//
//  Created by Paul P on 8/31/15.
//  Copyright (c) 2015 AirBitz. All rights reserved.
//

#import "TodayViewController.h"
#import "AppGroupConstants.h"
#import <NotificationCenter/NotificationCenter.h>

#define SEND_URL @"airbitz://x-callback-url/sendqr"

@interface TodayViewController () <NCWidgetProviding>
@property (nonatomic, strong) NSUserDefaults *appGroupSharedUserDefs;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *qrCodeImage;
@property (weak, nonatomic) IBOutlet UIImageView *scanButton;
@property (weak, nonatomic) IBOutlet UIView *qrViewBackground;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    if (! self.appGroupSharedUserDefs)
        self.appGroupSharedUserDefs= [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_ID];
    
    self.qrCodeImage.layer.magnificationFilter = kCAFilterNearest;
    self.preferredContentSize = CGSizeMake(0, 250);
    self.qrViewBackground.layer.cornerRadius = 8;
    self.qrViewBackground.layer.masksToBounds = YES;
    self.extensionContext.widgetLargestAvailableDisplayMode = NCWidgetDisplayModeExpanded;
}

- (void)widgetActiveDisplayModeDidChange:(NCWidgetDisplayMode)activeDisplayMode withMaximumSize:(CGSize)maxSize{
    if (activeDisplayMode == NCWidgetDisplayModeCompact) {
        self.preferredContentSize = maxSize;
    }
    else
        self.preferredContentSize = CGSizeMake(0, 250);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIEdgeInsets) widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets) defaultMarginInsets {
    return UIEdgeInsetsZero;
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    // Perform any setup necessary in order to update the view.
    NSData *imageData = [self.appGroupSharedUserDefs objectForKey:APP_GROUP_LAST_QR_IMAGE_KEY];
    
    UIImage *qrImage = [UIImage imageWithData:imageData];
    
    self.qrCodeImage.image = qrImage;
    
    NSString *address = [NSString stringWithFormat:@"%@", [self.appGroupSharedUserDefs objectForKey:APP_GROUP_LAST_ADDRESS_KEY]];
    self.addressLabel.text = address;
    NSString *accountWallet = [NSString stringWithFormat:@"Account: %@ / %@",
                    [self.appGroupSharedUserDefs stringForKey:APP_GROUP_LAST_ACCOUNT_KEY],
                    [self.appGroupSharedUserDefs objectForKey:APP_GROUP_LAST_WALLET_KEY]];

    self.accountLabel.text = accountWallet;
    
    completionHandler(NCUpdateResultNewData);
}

- (IBAction)ButtonScanQR:(id)sender
{
    [self.extensionContext openURL:[NSURL URLWithString:SEND_URL] completionHandler:nil];
}



@end

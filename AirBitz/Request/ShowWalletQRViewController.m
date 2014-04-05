//
//  ShowWalletQRViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "ShowWalletQRViewController.h"
#import "Notifications.h"
#import "ABC.h"

@interface ShowWalletQRViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *qrCodeImageView;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UILabel *amountLabel;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;

@end

@implementation ShowWalletQRViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.qrCodeImageView.layer.magnificationFilter = kCAFilterNearest;
	self.qrCodeImageView.image = self.qrCodeImage;
	self.statusLabel.text = self.statusString;
	self.addressLabel.text = self.addressString;
	self.amountLabel.text = [NSString stringWithFormat:@"B %.5f", ABC_SatoshiToBitcoin(self.amountSatoshi)];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:NO]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)CopyAddress
{
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	[pb setString:self.addressLabel.text];
}

-(IBAction)Cancel
{
	[self Back];
}

-(IBAction)Back
{
	[self.delegate ShowWalletQRViewControllerDone:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:YES]];
}

-(IBAction)Info
{

}


@end

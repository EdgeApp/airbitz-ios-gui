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
#import "CommonTypes.h"

@interface ShowWalletQRViewController ()

@property (nonatomic, weak) IBOutlet UIImageView    *qrCodeImageView;
@property (nonatomic, weak) IBOutlet UILabel        *statusLabel;
@property (nonatomic, weak) IBOutlet UILabel        *amountLabel;
@property (nonatomic, weak) IBOutlet UILabel        *addressLabel;
@property (weak, nonatomic) IBOutlet UIView         *viewQRCodeFrame;
@property (weak, nonatomic) IBOutlet UIImageView    *imageBottomFrame;
@property (weak, nonatomic) IBOutlet UIButton       *buttonCancel;
@property (weak, nonatomic) IBOutlet UIButton       *buttonCopyAddress;

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

    [self updateDisplayLayout];

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

#pragma mark - Action Methods

- (IBAction)CopyAddress
{
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	[pb setString:self.addressLabel.text];
}

- (IBAction)Cancel
{
	[self Back];
}

- (IBAction)Back
{
	[self.delegate ShowWalletQRViewControllerDone:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:YES]];
}

- (IBAction)Info
{

}

#pragma mark - Misc Methods

- (void)updateDisplayLayout
{
    // if we are on a smaller screen
    if (!IS_IPHONE5)
    {
        // be prepared! lots and lots of magic numbers here to jam the controls to fit on a small screen

        CGRect frame;

        frame = self.viewQRCodeFrame.frame;
        frame.origin.y = 67.0;
        self.viewQRCodeFrame.frame = frame;

        frame = self.qrCodeImageView.frame;
        frame.origin.y = self.viewQRCodeFrame.frame.origin.y + 8.0;
        self.qrCodeImageView.frame = frame;

        frame = self.imageBottomFrame.frame;
        frame.origin.y = self.viewQRCodeFrame.frame.origin.y + self.viewQRCodeFrame.frame.size.height + 2.0;
        frame.size.height = 165.0;
        self.imageBottomFrame.frame = frame;

        frame = self.statusLabel.frame;
        frame.origin.y = self.imageBottomFrame.frame.origin.y + 2.0;
        self.statusLabel.frame = frame;

        frame = self.amountLabel.frame;
        frame.origin.y = self.statusLabel.frame.origin.y + self.statusLabel.frame.size.height + 3.0;
        self.amountLabel.frame = frame;

        frame = self.addressLabel.frame;
        frame.origin.y = self.amountLabel.frame.origin.y + self.amountLabel.frame.size.height + 3.0;
        self.addressLabel.frame = frame;

        frame = self.buttonCancel.frame;
        frame.origin.y = self.addressLabel.frame.origin.y + self.addressLabel.frame.size.height + 3.0;
        self.buttonCancel.frame = frame;

        frame = self.buttonCopyAddress.frame;
        frame.origin.y = self.buttonCancel.frame.origin.y + self.buttonCancel.frame.size.height + 3.0;
        self.buttonCopyAddress.frame = frame;

    }
}


@end

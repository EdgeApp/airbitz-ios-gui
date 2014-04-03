//
//  ShowWalletQRViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "ShowWalletQRViewController.h"

@interface ShowWalletQRViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *qr_imageView;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UILabel *amountLabel;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@end

@implementation ShowWalletQRViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)CopyAddress
{
}

-(IBAction)Cancel
{
}

-(IBAction)Back
{
}

-(IBAction)Info
{
}


@end

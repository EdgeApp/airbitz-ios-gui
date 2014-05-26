//
//  ExportWalletViewController.m
//  AirBitz
//
//  Created by Adam Harris on 5/26/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "ExportWalletViewController.h"
#import "ExportWalletOptionsViewController.h"
#import "InfoView.h"
#import "Util.h"

@interface ExportWalletViewController () <ExportWalletOptionsViewControllerDelegate>
{
    ExportWalletOptionsViewController   *_exportWalletOptionsViewController;
}

@property (weak, nonatomic) IBOutlet UIView *viewDisplay;

@end

@implementation ExportWalletViewController

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

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:self.viewDisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Action Methods

- (IBAction)buttonBackTouched:(id)sender
{
    [self animatedExit];
}

- (IBAction)buttonInfoTouched:(id)sender
{
    [InfoView CreateWithHTML:@"infoExportWallet" forView:self.view];
}

#pragma mark - Misc Methods

- (void)animatedExit
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
		 [self exit];
	 }];
}

- (void)exit
{
	[self.delegate exportWalletViewControllerDidFinish:self];
}

#pragma mark - Export Wallet Optinos Delegates

- (void)exportWalletOptionsViewControllerDidFinish:(ExportWalletOptionsViewController *)controller
{
	[controller.view removeFromSuperview];
	_exportWalletOptionsViewController = nil;
}

@end

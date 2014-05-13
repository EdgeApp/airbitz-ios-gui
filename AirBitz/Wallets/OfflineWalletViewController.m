//
//  OfflineWalletViewController.m
//  AirBitz
//
//  Created by Adam Harris on 5/13/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "OfflineWalletViewController.h"
#import "CommonTypes.h"
#import "ABC.h"

@interface OfflineWalletViewController ()
{

}

@property (weak, nonatomic) IBOutlet UIButton *buttonDone;

@end

@implementation OfflineWalletViewController

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

- (IBAction)buttonDoneTouched:(id)sender
{
    [self animatedExit];
}

- (IBAction)buttonCopyTouched:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Offline Wallet", nil)
                          message:NSLocalizedString(@"Public Key copied to clipboard", nil)
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)buttonPrintTouched:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Offline Wallet", nil)
                          message:@"TODO: bring up print"
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)buttonInfoTouched:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Offline Wallet", nil)
                          message:@"TODO: bring up info"
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Misc Methods

- (void)printABC_Error:(const tABC_Error *)pError
{
    if (pError)
    {
        if (pError->code != ABC_CC_Ok)
        {
            printf("Code: %d, Desc: %s, Func: %s, File: %s, Line: %d\n",
                   pError->code,
                   pError->szDescription,
                   pError->szSourceFunc,
                   pError->szSourceFile,
                   pError->nSourceLine
                   );
        }
    }
}

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
	[self.delegate offlineWalletViewControllerDidFinish:self];
}

@end

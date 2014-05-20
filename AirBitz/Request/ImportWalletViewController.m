//
//  ImportWalletViewController.m
//  AirBitz
//
//  Created by Adam Harris on 5/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "CommonTypes.h"
#import "ABC.h"
#import "ImportWalletViewController.h"

@interface ImportWalletViewController ()

@end

@implementation ImportWalletViewController

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

    [self updateDisplayLayout];
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

#pragma - Action Methods

- (IBAction)buttonBackTouched:(id)sender
{
    [self animatedExit];
}

- (IBAction)buttonInfoTouched:(id)sender
{
}

#pragma mark - Misc Methods

- (void)updateDisplayLayout
{
    // update for iPhone 4
    if (!IS_IPHONE5)
    {

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
	[self.delegate importWalletViewControllerDidFinish:self];
}

@end

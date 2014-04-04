//
//  SendStatusViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "SendStatusViewController.h"

@interface SendStatusViewController ()

@property (nonatomic, weak) IBOutlet UIView *currencyView;

@end

@implementation SendStatusViewController

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
	self.currencyView.alpha = 0.0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showCurrency
{
	[UIView animateWithDuration:0.25
						  delay:0.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^
	 {
		 self.currencyView.alpha = 1.0;
	 }
	 completion:^(BOOL finished)
	 {
		 
	 }];
}


@end

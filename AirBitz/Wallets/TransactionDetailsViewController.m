//
//  TransactionDetailsViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "TransactionDetailsViewController.h"
#import "User.h"

@interface TransactionDetailsViewController ()

@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *walletLabel;
@property (nonatomic, weak) IBOutlet UILabel *bitCoinLabel;
@property (nonatomic, weak) IBOutlet UIButton *addressButton;
@property (nonatomic, weak) IBOutlet UIButton *doneButton;
@property (nonatomic, weak) IBOutlet UITextField *fiatTextField;
@property (nonatomic, weak) IBOutlet UITextField *categoryTextField;
@property (nonatomic, weak) IBOutlet UITextField *notesTextField;

@end

@implementation TransactionDetailsViewController

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
	UIImage *blue_button_image = [self stretchableImage:@"btn_blue.png"];
	[self.addressButton setBackgroundImage:blue_button_image forState:UIControlStateNormal];
	[self.addressButton setBackgroundImage:blue_button_image forState:UIControlStateSelected];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)Done
{
	[self.delegate TransactionDetailsViewControllerDone:self];
}

-(IBAction)Address
{
}

-(UIImage *)stretchableImage:(NSString *)imageName
{
	UIImage *img = [UIImage imageNamed:imageName];
	UIImage *stretchable = [img resizableImageWithCapInsets:UIEdgeInsetsMake(28, 28, 28, 28)]; //top, left, bottom, right
	return stretchable;
}
@end

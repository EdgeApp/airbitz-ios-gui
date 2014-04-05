//
//  TransactionDetailsViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "TransactionDetailsViewController.h"
#import "User.h"
#import "NSDate+Helper.h"
#import "ABC.h"

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
	
	/*
	 @property (nonatomic, copy)     NSString        *strID;
	 @property (nonatomic, copy)     NSString        *strWalletUUID;
	 @property (nonatomic, copy)     NSString        *strWalletName;
	 @property (nonatomic, copy)     NSString        *strName;
	 @property (nonatomic, copy)     NSString        *strAddress;
	 @property (nonatomic, strong)   NSDate          *date;
	 @property (nonatomic, assign)   BOOL            bConfirmed;
	 @property (nonatomic, assign)   unsigned int    confirmations;
	 @property (nonatomic, assign)   double          amount;
	 @property (nonatomic, assign)   double          balance;
	 @property (nonatomic, copy)     NSString        *strCategory;
	 @property (nonatomic, copy)     NSString        *strNotes;
	 */
	 
	// self.dateLabel.text = [NSDate stringForDisplayFromDate:self.transaction.date prefixed:NO alwaysDisplayTime:YES];
	
	self.dateLabel.text = [NSDate stringFromDate:self.transaction.date withFormat:[NSDate timestampFormatString]];
	self.nameLabel.text = self.transaction.strName;
	[self.addressButton setTitle:self.transaction.strAddress forState:UIControlStateNormal]; 
	
	self.walletLabel.text = self.transaction.strWalletName;
	self.bitCoinLabel.text = [NSString stringWithFormat:@"B %.5f", ABC_SatoshiToBitcoin(self.transaction.amountSatoshi)];
	
	
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

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
#import "ButtonSelectorView.h"
#import "User.h"
#import "CommonTypes.h"
#import "CoreBridge.h"

#define WALLET_BUTTON_WIDTH         110
#define WALLET_TABLE_CONTENT_HEIGHT 225

typedef enum eDatePeriod
{
    DatePeriod_None,
    DatePeriod_ThisWeek,
    DatePeriod_ThisMonth,
    DatePeriod_ThisYear
} tDatePeriod;

@interface ExportWalletViewController () <ExportWalletOptionsViewControllerDelegate, ButtonSelectorDelegate>
{
    tDatePeriod                         _datePeriod; // chosen with the 3 buttons
    ExportWalletOptionsViewController   *_exportWalletOptionsViewController;
    NSInteger                           _selectedWallet;
}

@property (weak, nonatomic) IBOutlet UIView             *viewDisplay;
@property (weak, nonatomic) IBOutlet UIImageView        *imageButtonThisWeek;
@property (weak, nonatomic) IBOutlet UIImageView        *imageButtonThisMonth;
@property (weak, nonatomic) IBOutlet UIImageView        *imageButtonThisYear;
@property (weak, nonatomic) IBOutlet UIButton           *buttonThisWeek;
@property (weak, nonatomic) IBOutlet UIButton           *buttonThisMonth;
@property (weak, nonatomic) IBOutlet UIButton           *buttonThisYear;
@property (weak, nonatomic) IBOutlet ButtonSelectorView *buttonSelector;
@property (weak, nonatomic) IBOutlet UIButton           *buttonFrom;
@property (weak, nonatomic) IBOutlet UIButton           *buttonTo;
@property (weak, nonatomic) IBOutlet UILabel            *labelFromDate;
@property (weak, nonatomic) IBOutlet UILabel            *labelToDate;
@property (weak, nonatomic) IBOutlet UIScrollView       *scrollView;

@property (nonatomic, strong) NSArray *arrayWalletUUIDs;
@property (nonatomic, strong) NSArray *arrayWallets;

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

    [self updateDisplayLayout];

    UIImage *blue_button_image = [self stretchableImage:@"btn_blue.png"];
    [self.buttonFrom setBackgroundImage:blue_button_image forState:UIControlStateNormal];
    [self.buttonFrom setBackgroundImage:blue_button_image forState:UIControlStateSelected];
    [self.buttonTo setBackgroundImage:blue_button_image forState:UIControlStateNormal];
    [self.buttonTo setBackgroundImage:blue_button_image forState:UIControlStateSelected];

    [self setWalletData];

    _datePeriod = DatePeriod_None;
    [self updateDisplay];


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

- (IBAction)buttonDatePeriodTouched:(UIButton *)sender
{
    if (sender == self.buttonThisWeek)
    {
        _datePeriod = DatePeriod_ThisWeek;
    }
    else if (sender == self.buttonThisMonth)
    {
        _datePeriod = DatePeriod_ThisMonth;
    }
    else if (sender == self.buttonThisYear)
    {
        _datePeriod = DatePeriod_ThisYear;
    }

    [self updateDisplay];
}

- (IBAction)buttonCSVTouched:(id)sender
{
    [self showExportWalletOptionsWithType:WalletExportType_CSV];
}

- (IBAction)buttonQuickenTouched:(id)sender
{
    [self showExportWalletOptionsWithType:WalletExportType_Quicken];
}

- (IBAction)buttonQuickbooksTouched:(id)sender
{
    [self showExportWalletOptionsWithType:WalletExportType_Quickbooks];
}

- (IBAction)buttonPDFTouched:(id)sender
{
    [self showExportWalletOptionsWithType:WalletExportType_PDF];
}

- (IBAction)buttonPrivateSeedTouched:(id)sender
{
    [self showExportWalletOptionsWithType:WalletExportType_PrivateSeed];
}

#pragma mark - Misc Methods

- (void)updateDisplay
{
    self.imageButtonThisWeek.hidden = (DatePeriod_ThisWeek != _datePeriod);
    self.imageButtonThisMonth.hidden = (DatePeriod_ThisMonth != _datePeriod);
    self.imageButtonThisYear.hidden = (DatePeriod_ThisYear != _datePeriod);
}

- (void)updateDisplayLayout
{
    // update for iPhone 4
    if (!IS_IPHONE5)
    {
        // warning: magic numbers for iphone layout

        self.scrollView.contentSize = self.scrollView.frame.size;
        CGRect frame = self.scrollView.frame;
        frame.size.height = 140;
        self.scrollView.frame = frame;

    }
}

- (void)showExportWalletOptionsWithType:(tWalletExportType)type
{
    // find the wallet to use
    NSString *strUUID = [self.arrayWalletUUIDs objectAtIndex:_selectedWallet];
    Wallet *wallet = nil;
    for (wallet in self.arrayWallets)
    {
        if ([strUUID isEqualToString:wallet.strUUID])
        {
            // found it
            break;
        }
    }

    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    _exportWalletOptionsViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ExportWalletOptionsViewController"];

    _exportWalletOptionsViewController.delegate = self;
    _exportWalletOptionsViewController.type = type;
    _exportWalletOptionsViewController.wallet = wallet;

    CGRect frame = self.view.bounds;
    frame.origin.x = frame.size.width;
    _exportWalletOptionsViewController.view.frame = frame;
    [self.view addSubview:_exportWalletOptionsViewController.view];

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         _exportWalletOptionsViewController.view.frame = self.view.bounds;
     }
                     completion:^(BOOL finished)
     {

     }];
}

- (UIImage *)stretchableImage:(NSString *)imageName
{
	UIImage *img = [UIImage imageNamed:imageName];
	UIImage *stretchable = [img resizableImageWithCapInsets:UIEdgeInsetsMake(28, 28, 28, 28)]; //top, left, bottom, right
	return stretchable;
}

- (void)setWalletData
{
    self.buttonSelector.delegate = self;
	self.buttonSelector.textLabel.text = @"";
    [self.buttonSelector setButtonWidth:WALLET_BUTTON_WIDTH];
    self.buttonSelector.button.titleLabel.font = [UIFont systemFontOfSize:12];
    self.buttonSelector.button.titleLabel.font = [UIFont fontWithName:@"Lato-Bold" size:15];

	tABC_WalletInfo **aWalletInfo = NULL;
    unsigned int nCount;
	tABC_Error Error;
    ABC_GetWallets([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &aWalletInfo, &nCount, &Error);
    [Util printABC_Error:&Error];

    // assign list of wallets to buttonSelector
	NSMutableArray *arrayWalletNames = [[NSMutableArray alloc] init];
    NSMutableArray *arrayWalletUUIDs = [[NSMutableArray alloc] init];

    for (int i = 0; i < nCount; i++)
    {
        tABC_WalletInfo *pInfo = aWalletInfo[i];
		[arrayWalletNames addObject:[NSString stringWithUTF8String:pInfo->szName]];
        [arrayWalletUUIDs addObject:[NSString stringWithUTF8String:pInfo->szUUID]];
    }

	self.buttonSelector.arrayItemsToSelect = [arrayWalletNames copy];
    self.arrayWalletUUIDs = arrayWalletUUIDs;

    ABC_FreeWalletInfoArray(aWalletInfo, nCount);

    _selectedWallet = [arrayWalletUUIDs indexOfObject:self.wallet.strUUID];
    if (_selectedWallet != NSNotFound)
	{
		[self.buttonSelector.button setTitle:[arrayWalletNames objectAtIndex:_selectedWallet] forState:UIControlStateNormal];
		self.buttonSelector.selectedItemIndex = (int) _selectedWallet;
	}

    // get an array of all the wallets
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    NSMutableArray *arrayArchivedWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWallets:arrayWallets archived:arrayArchivedWallets];
    [arrayWallets addObjectsFromArray:arrayArchivedWallets];
    self.arrayWallets = arrayWallets;
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
	[self.delegate exportWalletViewControllerDidFinish:self];
}

#pragma mark - Export Wallet Optinos Delegates

- (void)exportWalletOptionsViewControllerDidFinish:(ExportWalletOptionsViewController *)controller
{
	[controller.view removeFromSuperview];
	_exportWalletOptionsViewController = nil;
}

#pragma mark - ButtonSelectorView delegate

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
	//NSLog(@"Selected item %i", itemIndex);
    _selectedWallet = itemIndex;
}

@end

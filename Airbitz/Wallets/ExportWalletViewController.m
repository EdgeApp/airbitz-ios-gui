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
#import "User.h"
#import "CommonTypes.h"
#import "AirbitzCore.h"
#import "PopupWheelPickerView.h"
#import "DateTime.h"
#import "ButtonSelectorView2.h"
#import "MainViewController.h"
#import "Theme.h"
#import "FadingAlertView.h"

#define STARTING_YEAR               2014

#define PICKER_COL_MONTH        0
#define PICKER_COL_DAY          1
#define PICKER_COL_YEAR         2
#define PICKER_COL_SPACER       3
#define PICKER_COL_HOUR         4
#define PICKER_COL_COLON        5
#define PICKER_COL_MINUTE       6
#define PICKER_COL_AM_PM        7
#define PICKER_COL_COUNT        8


@interface ExportWalletViewController () <ExportWalletOptionsViewControllerDelegate, ButtonSelector2Delegate, UIGestureRecognizerDelegate>
{
    BOOL                                bWalletListDropped;

}

@property (weak, nonatomic) IBOutlet ButtonSelectorView2 *buttonSelector;

//@property (nonatomic, strong) NSArray               *arrayWalletUUIDs;
//@property (nonatomic, strong) NSArray               *arrayWallets;
//@property (nonatomic, strong) PopupWheelPickerView  *popupWheelPicker;
@property (nonatomic, strong) UIButton              *buttonBlocker;
//@property (nonatomic, strong) DateTime              *fromDateTime;
//@property (nonatomic, strong) DateTime              *toDateTime;

@property (nonatomic, strong) ExportWalletOptionsViewController   *exportWalletOptionsViewController;


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

    self.buttonBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonBlocker.backgroundColor = [UIColor clearColor];
    [self.buttonBlocker addTarget:self action:@selector(buttonBlockerTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonBlocker.frame = self.view.bounds;
    self.buttonBlocker.hidden = YES;
    [self.view addSubview:self.buttonBlocker];

    self.buttonSelector.delegate = self;
    [self.buttonSelector disableButton];

    bWalletListDropped = false;

    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews:) name:NOTIFICATION_WALLETS_CHANGED object:nil];

}

- (void)viewWillAppear:(BOOL)animated
{
    [self forceUpdateNavBar];
}

- (void)forceUpdateNavBar;
{
    [MainViewController changeNavBarOwner:self];
    [self updateNavBar];
    [self updateViews:nil];
}

- (void)updateNavBar;
{
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(buttonBackTouched) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(buttonInfoTouched) fromObject:self];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didTapTitle: (UIButton *)sender
{
    if (bWalletListDropped)
    {
        [self.buttonSelector close];
        bWalletListDropped = false;
    }
    else
    {
        [self.buttonSelector open];
        bWalletListDropped = true;
    }

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

- (IBAction)buttonBlockerTouched:(id)sender
{
    [self dismissPopupPicker];
}

- (void)buttonBackTouched
{
    [self dismissPopupPicker];
    [self animatedExit];
}

- (void)buttonInfoTouched
{
    [self dismissPopupPicker];
    [InfoView CreateWithHTML:@"info_export_wallet" forView:self.view];
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

- (IBAction)buttonPublicSeedTouched:(id)sender
{
    [self showExportWalletOptionsWithType:WalletExportType_PublicSeed];
}

#pragma mark - Misc Methods

- (void)showExportWalletOptionsWithType:(tWalletExportType)type
{

    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    self.exportWalletOptionsViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ExportWalletOptionsViewController"];

    self.exportWalletOptionsViewController.delegate = self;
    self.exportWalletOptionsViewController.type = type;
//    self.exportWalletOptionsViewController.fromDateTime = self.fromDateTime;
//    self.exportWalletOptionsViewController.toDateTime = self.toDateTime;

    [Util addSubviewControllerWithConstraints:self child:self.exportWalletOptionsViewController];
    [MainViewController animateSlideIn:self.exportWalletOptionsViewController];
}

- (UIImage *)stretchableImage:(NSString *)imageName
{
	UIImage *img = [UIImage imageNamed:imageName];
	UIImage *stretchable = [img resizableImageWithCapInsets:UIEdgeInsetsMake(10,10,10,10)]; //top, left, bottom, right
	return stretchable;
}

- (void)updateViews:(id)object
{
    if (abcAccount.arrayWallets && abcAccount.currentWallet)
    {
        self.buttonSelector.arrayItemsToSelect = abcAccount.arrayWalletNames;
        [self.buttonSelector.button setTitle:abcAccount.currentWallet.name forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = abcAccount.currentWalletIndex;

        NSString *walletName;
        walletName = [NSString stringWithFormat:@"%@ %@ ▼",export_from_text, abcAccount.currentWallet.name];

        [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle:) fromObject:self];
        if (!([abcAccount.arrayWallets containsObject:abcAccount.currentWallet]))
        {
            [FadingAlertView create:self.view
                            message:walletHasBeenArchivedText
                           holdTime:FADING_ALERT_HOLD_TIME_FOREVER];
        }
    }

}

- (void)dismissPopupPicker
{
    [self blockUser:NO];
//    if (self.popupWheelPicker)
//    {
//        self.viewDisplay.frame = _viewDisplayFrame;
//        [self.popupWheelPicker removeFromSuperview];
//        self.popupWheelPicker = nil;
//    }
}

- (void)blockUser:(BOOL)bBlock
{
    self.buttonBlocker.hidden = !bBlock;
}

- (void)installLeftToRightSwipeDetection
{
	UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeftToRight:)];
	gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:gesture];
}

// used by the guesture recognizer to ignore exit
- (BOOL)haveSubViewsShowing
{
    return (self.exportWalletOptionsViewController != nil);
}

- (void)animatedExit
{
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
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

#pragma mark - Export Wallet Options Delegates

- (void)exportWalletOptionsViewControllerDidFinish:(ExportWalletOptionsViewController *)controller
{
    [MainViewController animateOut:controller withBlur:NO complete:^(void) {
        self.exportWalletOptionsViewController = nil;
        [self forceUpdateNavBar];
    }];
}

#pragma mark - ButtonSelectorView delegate

- (void)ButtonSelector2:(ButtonSelectorView2 *)view selectedItem:(int)itemIndex
{
    NSIndexPath *indexPath = [[NSIndexPath alloc]init];
    indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [abcAccount makeCurrentWalletWithIndex:indexPath];
    bWalletListDropped = false;
}

#pragma mark - Popup Wheel Picker Delegate Methods

//- (void)PopupWheelPickerViewExit:(PopupWheelPickerView *)view withSelections:(NSArray *)arraySelections userData:(id)data
//{
//    [self dismissPopupPicker];
//
//    _datePeriod = DatePeriod_None;
//    [self setDateTime:(data == self.buttonFrom ? self.fromDateTime : self.toDateTime) fromPickerSelections:arraySelections];
//    [self updateDisplay];
//}
//
//- (void)PopupWheelPickerViewCancelled:(PopupWheelPickerView *)view userData:(id)data
//{
//    [self dismissPopupPicker];
//}
//
//- (CGFloat)PopupWheelPickerView:(PopupWheelPickerView *)view widthForComponent:(NSInteger)component userData:(id)data
//{
//    CGFloat retVal = 20; // default
//
//    if (component == PICKER_COL_MONTH)
//    {
//        retVal = 40;
//    }
//    else if (component == PICKER_COL_YEAR)
//    {
//        retVal = 40;
//    }
//    else if (component == PICKER_COL_SPACER)
//    {
//        retVal = 10;
//    }
//    else if (component == PICKER_COL_COLON)
//    {
//        retVal = 5;
//    }
//    else if (component == PICKER_COL_AM_PM)
//    {
//        retVal = 30;
//    }
//
//    return retVal;
//}

#pragma mark - GestureReconizer methods

- (void)didSwipeLeftToRight:(UIGestureRecognizer *)gestureRecognizer
{
    if (![self haveSubViewsShowing])
    {
        [self buttonBackTouched];
    }
}

#pragma mark - Custom Notification Handlers

// called when a tab bar button that is already selected, is reselected again
- (void)tabBarButtonReselect:(NSNotification *)notification
{
    if (![self haveSubViewsShowing])
    {
        [self buttonBackTouched];
    }
}

@end

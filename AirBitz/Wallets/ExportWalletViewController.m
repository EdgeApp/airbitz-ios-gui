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
#import "CoreBridge.h"
#import "PopupWheelPickerView.h"
#import "DateTime.h"
#import "ButtonSelectorView2.h"
#import "MainViewController.h"
#import "Theme.h"

#define STARTING_YEAR               2014

#define WALLET_BUTTON_WIDTH         160

#define PICKER_COL_MONTH        0
#define PICKER_COL_DAY          1
#define PICKER_COL_YEAR         2
#define PICKER_COL_SPACER       3
#define PICKER_COL_HOUR         4
#define PICKER_COL_COLON        5
#define PICKER_COL_MINUTE       6
#define PICKER_COL_AM_PM        7
#define PICKER_COL_COUNT        8


typedef enum eDatePeriod
{
    DatePeriod_None,
    DatePeriod_ThisWeek,
    DatePeriod_ThisMonth,
    DatePeriod_ThisYear
} tDatePeriod;

@interface ExportWalletViewController () <ExportWalletOptionsViewControllerDelegate, ButtonSelector2Delegate, PopupWheelPickerViewDelegate, UIGestureRecognizerDelegate>
{
    tDatePeriod                         _datePeriod; // chosen with the 3 buttons
    BOOL                                bWalletListDropped;

}

//@property (weak, nonatomic) IBOutlet UIImageView        *imageButtonThisWeek;
//@property (weak, nonatomic) IBOutlet UIImageView        *imageButtonThisMonth;
//@property (weak, nonatomic) IBOutlet UIImageView        *imageButtonThisYear;
//@property (weak, nonatomic) IBOutlet UIButton           *buttonThisWeek;
//@property (weak, nonatomic) IBOutlet UIButton           *buttonThisMonth;
//@property (weak, nonatomic) IBOutlet UIButton           *buttonThisYear;
@property (weak, nonatomic) IBOutlet ButtonSelectorView2 *buttonSelector;
//@property (weak, nonatomic) IBOutlet UIButton           *buttonFrom;
//@property (weak, nonatomic) IBOutlet UIButton           *buttonTo;
//@property (weak, nonatomic) IBOutlet UILabel            *labelFromDate;
//@property (weak, nonatomic) IBOutlet UILabel            *labelToDate;
//@property (weak, nonatomic) IBOutlet UIScrollView       *scrollView;

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

//    self.fromDateTime = [[DateTime alloc] init];
//    [self.fromDateTime setWithCurrentDateAndTime];
//    self.fromDateTime.second = 0;
//    self.toDateTime = [[DateTime alloc] init];
//    [self.toDateTime setWithCurrentDateAndTime];
//    self.fromDateTime.second = 0;
//
//    _datePeriod = DatePeriod_None;
//    [self updateDisplay];

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews) name:NOTIFICATION_WALLETS_CHANGED object:nil];

}

- (void)viewWillAppear:(BOOL)animated
{
    [self setupNavBar];
    [self updateViews];
}

- (void)setupNavBar
{
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(buttonBackTouched) fromObject:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].helpButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
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
    [InfoView CreateWithHTML:@"infoExportWallet" forView:self.view];
}
//
//- (IBAction)buttonFromTouched:(id)sender
//{
//    [self showPopupPickerFor:sender];
//}
//
//- (IBAction)buttonToTouched:(id)sender
//{
//    [self showPopupPickerFor:sender];
//}

//- (IBAction)buttonDatePeriodTouched:(UIButton *)sender
//{
//
//    if (sender == self.buttonThisWeek)
//    {
//        _datePeriod = DatePeriod_ThisWeek;
//        NSDate *today = [NSDate date];
//        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//
//         // Get the weekday component of the current date
//         NSDateComponents *weekdayComponents = [gregorian components:NSWeekdayCalendarUnit fromDate:today];
//
//        /*
//         Create a date components to represent the number of days to subtract
//         from the current date.
//         The weekday value for Sunday in the Gregorian calendar is 1, so
//         subtract 1 from the number
//         of days to subtract from the date in question.  (If today's Sunday,
//         subtract 0 days.)
//         */
//         NSDateComponents *componentsToSubtract = [[NSDateComponents alloc]  init];
//         [componentsToSubtract setDay: - ([weekdayComponents weekday] - 1)];
//
//         NSDate *beginningOfWeek = [gregorian dateByAddingComponents:componentsToSubtract toDate:today options:0];
//
//        [self.fromDateTime setWithDate:beginningOfWeek];
//    }
//    else if (sender == self.buttonThisMonth)
//    {
//        _datePeriod = DatePeriod_ThisMonth;
//        [self.fromDateTime setWithCurrentDateAndTime];
//        self.fromDateTime.day = 1;
//    }
//    else if (sender == self.buttonThisYear)
//    {
//        [self.fromDateTime setWithCurrentDateAndTime];
//        self.fromDateTime.month = 1;
//        self.fromDateTime.day = 1;
//        _datePeriod = DatePeriod_ThisYear;
//    }
//
//    self.fromDateTime.hour = 0;
//    self.fromDateTime.minute = 0;
//    self.fromDateTime.second = 0;
//
//    [self.toDateTime setWithCurrentDateAndTime];
//
//    [self updateDisplay];
//}

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

//- (void)updateDisplay
//{
//    self.imageButtonThisWeek.hidden = (DatePeriod_ThisWeek != _datePeriod);
//    self.imageButtonThisMonth.hidden = (DatePeriod_ThisMonth != _datePeriod);
//    self.imageButtonThisYear.hidden = (DatePeriod_ThisYear != _datePeriod);
//    self.labelFromDate.text = [NSString stringWithFormat:@"%d/%d/%d   %d:%.02d %@",
//                               (int) self.fromDateTime.month, (int) self.fromDateTime.day, (int) self.fromDateTime.year,
//                               [self displayFor12From24:(int) self.fromDateTime.hour], (int) self.fromDateTime.minute, self.fromDateTime.hour > 11 ? @"pm" : @"am"];
//    self.labelToDate.text = [NSString stringWithFormat:@"%d/%d/%d   %d:%.02d %@",
//                             (int) self.toDateTime.month, (int) self.toDateTime.day, (int) self.toDateTime.year,
//                             [self displayFor12From24:(int) self.toDateTime.hour], (int) self.toDateTime.minute, self.toDateTime.hour > 11 ?  @"pm" : @"am"];
//}

- (int)displayFor12From24:(int)hour24
{
    int retHour = hour24;

    if (hour24 == 0)
    {
        retHour = 12;
    }
    else if (hour24 > 12)
    {
        retHour -= 12;
    }

    return retHour;
}

- (NSArray *)getPopupPickerChoices
{
    NSMutableArray *arrayChoices = [[NSMutableArray alloc] init];
    NSMutableArray *arraySubChoices;

    // month
    [arrayChoices addObject:@[@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Nov", @"Dec"]];

    // day
    arraySubChoices = [[NSMutableArray alloc] init];
    for (int i = 1; i <= 31; i++)
    {
        [arraySubChoices addObject:[NSString stringWithFormat:@"%d", i]];
    }
    [arrayChoices addObject:arraySubChoices];

    // year
    arraySubChoices = [[NSMutableArray alloc] init];
    for (int i = STARTING_YEAR; i <= 2100; i++)
    {
        [arraySubChoices addObject:[NSString stringWithFormat:@"%d", i]];
    }
    [arrayChoices addObject:arraySubChoices];

    // spacer
    [arrayChoices addObject:@[@""]];

    // hour
    arraySubChoices = [[NSMutableArray alloc] init];
    for (int i = 1; i <= 12; i++)
    {
        [arraySubChoices addObject:[NSString stringWithFormat:@"%@%d", (i < 10 ? @"  " : @""), i]];
    }
    [arrayChoices addObject:arraySubChoices];

    [arrayChoices addObject:@[@":"]];

    // min
    arraySubChoices = [[NSMutableArray alloc] init];
    for (int i = 0; i <= 59; i++)
    {
        [arraySubChoices addObject:[NSString stringWithFormat:@"%.02d", i]];
    }
    [arrayChoices addObject:arraySubChoices];

    // am/pm
    [arrayChoices addObject:@[@"AM", @"PM"]];

    return arrayChoices;
}

- (void)setDateTime:(DateTime *)dateTime fromPickerSelections:(NSArray *)arraySelections
{
    for (int nCol = 0; nCol < PICKER_COL_COUNT; nCol++)
    {
        NSInteger value = [[arraySelections objectAtIndex:nCol] integerValue];

        if (PICKER_COL_MONTH == nCol)
        {
            dateTime.month = value + 1;
        }
        else if (PICKER_COL_DAY == nCol)
        {
            dateTime.day = value + 1;
        }
        else if (PICKER_COL_YEAR == nCol)
        {
            dateTime.year = value + STARTING_YEAR;
        }
        else if (PICKER_COL_HOUR == nCol)
        {
            BOOL bPM = ([[arraySelections objectAtIndex:PICKER_COL_AM_PM] integerValue] == 1);
            dateTime.hour = value + 1;
            if (bPM)
            {
                dateTime.hour += 12;
            }
            else if (value == 11)
            {
                dateTime.hour = 0;
            }
        }
        else if (PICKER_COL_MINUTE == nCol)
        {
            dateTime.minute = value;
        }
    }

    dateTime.second = 0;
}

- (NSArray *)getPopupPickerSelectionsFor:(DateTime *)dateTime givenChoices:(NSArray *)arrayChoices
{
    NSMutableArray *arraySelections = [[NSMutableArray alloc] init];

    for (int nCol = 0; nCol < PICKER_COL_COUNT; nCol++)
    {
        NSInteger selection = 0;

        if (PICKER_COL_MONTH == nCol)
        {
            selection = dateTime.month - 1;
        }
        else if (PICKER_COL_DAY == nCol)
        {
            selection = dateTime.day - 1;
        }
        else if (PICKER_COL_YEAR == nCol)
        {
            selection = dateTime.year - STARTING_YEAR;
        }
        else if (PICKER_COL_HOUR == nCol)
        {
            selection = dateTime.hour - 1;
            if (selection > 11)
            {
                selection -= 12;
            }
            else if (selection < 0)
            {
                selection = 11;
            }
        }
        else if (PICKER_COL_MINUTE == nCol)
        {
            selection = dateTime.minute;
        }
        else if (PICKER_COL_AM_PM == nCol)
        {
            if (dateTime.hour > 11)
            {
                selection = 1; // PM
            }
            else
            {
                selection = 0; // AM
            }
        }

        [arraySelections addObject:[NSNumber numberWithInteger:selection]];
    }

    // month
    [arraySelections addObject:[NSNumber numberWithInteger:dateTime.month - 1]];

    // day
    [arraySelections addObject:[NSNumber numberWithInteger:dateTime.day - 1]];

    // year
    [arraySelections addObject:[NSNumber numberWithInteger:dateTime.year - STARTING_YEAR]];

    // hour
    [arraySelections addObject:[NSNumber numberWithInteger:dateTime.hour]];

    // minute
    [arraySelections addObject:[NSNumber numberWithInteger:dateTime.minute]];

    return arraySelections;
}

//- (void)showPopupPickerFor:(UIButton *)button
//{
//    [self blockUser:YES];
//
//    NSArray *arrayChoices = [self getPopupPickerChoices];
//    NSArray *arraySelections = [self getPopupPickerSelectionsFor:(button == self.buttonFrom ? self.fromDateTime : self.toDateTime)
//                                                    givenChoices:arrayChoices];
//    self.popupWheelPicker = [PopupWheelPickerView CreateForView:self.view
//                                             positionRelativeTo:button
//                                                   withPosition:PopupWheelPickerPosition_Below
//                                                    withChoices:arrayChoices
//                                             startingSelections:arraySelections
//                                                       userData:button
//                                                    andDelegate:self];
//}

- (void)showExportWalletOptionsWithType:(tWalletExportType)type
{

    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    self.exportWalletOptionsViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ExportWalletOptionsViewController"];

    self.exportWalletOptionsViewController.delegate = self;
    self.exportWalletOptionsViewController.type = type;
//    self.exportWalletOptionsViewController.fromDateTime = self.fromDateTime;
//    self.exportWalletOptionsViewController.toDateTime = self.toDateTime;

    [MainViewController animateView:self.exportWalletOptionsViewController withBlur:NO];
}

- (UIImage *)stretchableImage:(NSString *)imageName
{
	UIImage *img = [UIImage imageNamed:imageName];
	UIImage *stretchable = [img resizableImageWithCapInsets:UIEdgeInsetsMake(10,10,10,10)]; //top, left, bottom, right
	return stretchable;
}

- (void)updateViews
{
    if ([CoreBridge Singleton].arrayWallets && [CoreBridge Singleton].currentWallet)
    {
        self.buttonSelector.arrayItemsToSelect = [CoreBridge Singleton].arrayWalletNames;
        [self.buttonSelector.button setTitle:[CoreBridge Singleton].currentWallet.strName forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = [CoreBridge Singleton].currentWalletID;

        NSString *walletName;
        walletName = [NSString stringWithFormat:@"Export From: %@ ↓", [CoreBridge Singleton].currentWallet.strName];

        [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle:) fromObject:self];
        if (!([[CoreBridge Singleton].arrayWallets containsObject:[CoreBridge Singleton].currentWallet]))
        {
            [FadingAlertView create:self.view
                            message:[Theme Singleton].walletHasBeenArchivedText
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

#pragma mark - Export Wallet Options Delegates

- (void)exportWalletOptionsViewControllerDidFinish:(ExportWalletOptionsViewController *)controller
{
    [MainViewController animateOut:controller withBlur:NO complete:^(void) {
        [controller.view removeFromSuperview];
        self.exportWalletOptionsViewController = nil;
        [self viewWillAppear:YES];
    }];
}

#pragma mark - ButtonSelectorView delegate

- (void)ButtonSelector2:(ButtonSelectorView2 *)view selectedItem:(int)itemIndex
{
    NSIndexPath *indexPath = [[NSIndexPath alloc]init];
    indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [CoreBridge makeCurrentWalletWithIndex:indexPath];
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

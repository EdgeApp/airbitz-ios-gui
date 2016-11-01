//
//  ExportWalletOptionsViewController.m
//  AirBitz
//
//  Created by Adam Harris on 5/26/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "MinCharTextField.h"
#import "ExportWalletOptionsViewController.h"
#import "ExportWalletPDFViewController.h"
#import "InfoView.h"
#import "User.h"
#import "Util.h"
#import "ABCContext.h"
#import "ExportWalletOptionsCell.h"
#import "CommonTypes.h"
#import "GDrive.h"
#import "ButtonSelectorView2.h"
#import "CommonTypes.h"
#import "FadingAlertView.h"
#import "MainViewController.h"
#import "Theme.h"

#define CELL_HEIGHT 45.0

#define ARRAY_CHOICES_FOR_TYPES @[ \
                                    @[@2, @3],          /* CSV */\
                                    @[@2, @3],          /* Quicken */\
                                    @[@2, @3],          /* Quickbooks */\
                                    @[@0, @2, @5],  /* PDF */\
                                    @[@0, @5],                   /* PrivateSeed */\
                                    @[@0, @2, @3, @5]                   /* PublicSeed */\
                                ]
#define ARRAY_NAMES_FOR_OPTIONS @[@"AirPrint", @"Save to SD card", @"Email", @"Google Drive", @"Dropbox", @"View"]
#define ARRAY_IMAGES_FOR_OPTIONS @[@"icon_export_printer", @"icon_export_sdcard", @"icon_export_email", @"icon_export_google", @"icon_export_dropbox", @"icon_export_view"]

typedef enum eDatePeriod
{
    DatePeriod_None,
    DatePeriod_ThisWeek,
    DatePeriod_ThisMonth,
    DatePeriod_ThisYear
} tDatePeriod;


typedef enum eExportOption
{
    ExportOption_AirPrint = 0,
    ExportOption_SDCard = 1,
    ExportOption_Email = 2,
    ExportOption_GoogleDrive = 3,
    ExportOption_Dropbox = 4,
    ExportOption_View = 5
} tExportOption;

@interface ExportWalletOptionsViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate,
                                                 ExportWalletPDFViewControllerDelegate, GDriveDelegate, FadingAlertViewDelegate,
                                                 UIGestureRecognizerDelegate, ButtonSelector2Delegate, UITextFieldDelegate, UIAlertViewDelegate>
{
	GDrive                              *drive;
    MFMailComposeViewController         *_mailComposer;
    BOOL                                bWalletListDropped;
    tDatePeriod                         _datePeriod; // chosen with the 3 buttons
    BOOL                                _bDatePickerFrom;
    UIAlertView                         *_showKeyAlert;
}

@property (weak, nonatomic) IBOutlet UIView                     *viewPassword;
@property (weak, nonatomic) IBOutlet UITableView                *tableView;
@property (weak, nonatomic) IBOutlet ButtonSelectorView2        *buttonSelector;
@property (nonatomic, weak) IBOutlet MinCharTextField           *passwordTextField;

@property (nonatomic, strong) ExportWalletPDFViewController     *exportWalletPDFViewController;
@property (nonatomic, strong) NSArray                           *arrayChoices;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordFieldHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dateSelectorHeight;
@property (weak, nonatomic) IBOutlet UIView             *dateSelectorView;

@property (weak, nonatomic) IBOutlet UIButton           *buttonThisWeek;
@property (weak, nonatomic) IBOutlet UIButton           *buttonThisMonth;
@property (weak, nonatomic) IBOutlet UIButton           *buttonThisYear;
@property (weak, nonatomic) IBOutlet UIButton           *buttonLastWeek;
@property (weak, nonatomic) IBOutlet UIButton           *buttonLastMonth;
@property (weak, nonatomic) IBOutlet UIButton           *buttonLastYear;

@property (weak, nonatomic) IBOutlet UITextField        *dateFromTextField;
@property (weak, nonatomic) IBOutlet UITextField        *dateToTextField;
@property (strong, nonatomic)        UIDatePicker       *datePicker;

@property (nonatomic, strong) DateTime                  *fromDateTime;
@property (nonatomic, strong) DateTime                  *toDateTime;


@end

@implementation ExportWalletOptionsViewController

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

    self.passwordTextField.delegate = self;
    self.passwordTextField.minimumCharacters = [ABCContext getMinimumPasswordLength];

    self.arrayChoices = [ARRAY_CHOICES_FOR_TYPES objectAtIndex:(NSUInteger) self.type];

    if (![abcAccount accountHasPassword]) {
        self.viewPassword.hidden = YES;
    } else if (WalletExportType_PrivateSeed == self.type) {
        self.viewPassword.hidden = NO;
        [self.passwordTextField becomeFirstResponder];
    }

    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    self.buttonSelector.delegate = self;

    self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.delaysContentTouches = NO;
    
    self.fromDateTime = [DateTime alloc];
    self.toDateTime = [DateTime alloc];
    
    [self.fromDateTime setWithDate:[NSDate dateWithTimeIntervalSince1970:0]];
    [self.toDateTime setWithDate:[NSDate date]];
    
    if (WalletExportType_PrivateSeed == self.type ||
        WalletExportType_PublicSeed == self.type)
    {
        self.dateSelectorHeight.constant = 0;
        self.dateSelectorView.hidden = YES;
    }
    else
    {
        self.passwordFieldHeight.constant = 0;
        self.viewPassword.hidden = YES;
    }

    
    self.datePicker = [[UIDatePicker alloc]init];
    self.datePicker.datePickerMode = UIDatePickerModeDate;
    [self.dateFromTextField setInputView:self.datePicker];
    [self.dateToTextField setInputView:self.datePicker];
    self.dateToTextField.delegate = self;
    self.dateFromTextField.delegate = self;
    
    UIToolbar *toolBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    [toolBar setTintColor:[UIColor grayColor]];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(datePickerAction:)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [toolBar setItems:[NSArray arrayWithObjects:space,doneBtn, nil]];
    [self.dateFromTextField setInputAccessoryView:toolBar];
    [self.dateToTextField setInputAccessoryView:toolBar];

    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews:) name:NOTIFICATION_WALLETS_CHANGED object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(buttonBackTouched) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(buttonInfoTouched) fromObject:self];

    [self updateViews:nil];
    [self updateDateDisplay];
}

-(void)viewDidDisappear:(BOOL)animated
{
	//[drive dismissAuthenticationController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateViews:(NSNotification *)notification
{
    if (abcAccount.arrayWallets && abcAccount.currentWallet)
    {
        self.buttonSelector.arrayItemsToSelect = abcAccount.arrayWalletNames;
        [self.buttonSelector.button setTitle:abcAccount.currentWallet.name forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = abcAccount.currentWalletIndex;

        NSString *walletName;
        walletName = [NSString stringWithFormat:@"%@ %@",export_from_text, abcAccount.currentWallet.name];

        [MainViewController changeNavBarTitle:self title:walletName];
        if (!([abcAccount.arrayWallets containsObject:abcAccount.currentWallet]))
        {
            [FadingAlertView create:self.view
                            message:walletHasBeenArchivedText
                           holdTime:FADING_ALERT_HOLD_TIME_FOREVER];
        }
    }
}

- (void)didTapTitle
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

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (_showKeyAlert == alertView)
    {
        if (1 == buttonIndex)
        {
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            NSString *message = [alertView message];
            if (pb)
            {
                [pb setString:message];
                [MainViewController fadingAlert:copied_text];
            }
        }
    }
}

#pragma mark - Keyboard Notifications

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField;
{
    if (textField == self.dateFromTextField)
    {
        _bDatePickerFrom = YES;
        [self.datePicker setDate:self.fromDateTime.date];
        
    }
    else if (textField == self.dateToTextField)
    {
        _bDatePickerFrom = NO;
        [self.datePicker setDate:self.toDateTime.date];
    }
    

}
#pragma mark - Action Methods

- (void)buttonBackTouched
{
    [self exit];
}

- (void)buttonInfoTouched
{
    [InfoView CreateWithHTML:@"info_export_wallet_options" forView:self.view];
}

- (IBAction)datePickerAction:(id)sender
{
    if (_bDatePickerFrom)
        [self.fromDateTime setWithDate:self.datePicker.date];
    else
        [self.toDateTime setWithDate:self.datePicker.date];
    
    [self.dateFromTextField resignFirstResponder];
    [self.dateToTextField resignFirstResponder];
    [self updateDateDisplay];
}

- (IBAction)buttonDatePeriodTouched:(UIButton *)sender
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDate *startOfInterval;
    NSDate *endOfInterval;
    NSCalendarUnit calendarUnit;
    
    if (sender == self.buttonThisWeek)
    {
        calendarUnit = NSCalendarUnitWeekOfMonth;
    }
    else if (sender == self.buttonThisMonth)
    {
        calendarUnit = NSCalendarUnitMonth;
    }
    else if (sender == self.buttonThisYear)
    {
        calendarUnit = NSCalendarUnitYear;
    }
    else if (sender == self.buttonLastWeek)
    {
        calendarUnit = NSCalendarUnitWeekOfMonth;
        now = [now dateByAddingTimeInterval:-7*24*60*60];
    }
    else if (sender == self.buttonLastMonth)
    {
        calendarUnit = NSCalendarUnitMonth;
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *comps = [NSDateComponents new];
        comps.month = -1;
        now = [calendar dateByAddingComponents:comps toDate:[NSDate date] options:0];
    }
    else if (sender == self.buttonLastYear)
    {
        calendarUnit = NSCalendarUnitYear;
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *comps = [NSDateComponents new];
        comps.year = -1;
        now = [calendar dateByAddingComponents:comps toDate:[NSDate date] options:0];
    }
    
    NSTimeInterval interval;
    [cal rangeOfUnit:calendarUnit
           startDate:&startOfInterval
            interval:&interval
             forDate:now];
    
    endOfInterval = [startOfInterval dateByAddingTimeInterval:interval-1];
    [self.fromDateTime setWithDate:startOfInterval];
    [self.toDateTime setWithDate:endOfInterval];

    [self updateDateDisplay];
}

#pragma mark - Date selection methods

- (void)updateDateDisplay
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    
    self.dateFromTextField.text = [dateFormatter stringFromDate:self.fromDateTime.date];
    self.dateToTextField.text = [dateFormatter stringFromDate:self.toDateTime.date];
}

#pragma mark - Misc Methods

- (ExportWalletOptionsCell *)getOptionsCellForTableView:(UITableView *)tableView withImage:(UIImage *)bkgImage andIndexPath:(NSIndexPath *)indexPath
{
	ExportWalletOptionsCell *cell;
	static NSString *cellIdentifier = @"ExportWalletOptionsCell";

	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[ExportWalletOptionsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}

    NSInteger index = [[self.arrayChoices objectAtIndex:indexPath.row] integerValue];
    cell.name.text = [ARRAY_NAMES_FOR_OPTIONS objectAtIndex:index];
    cell.imageIcon.image = [UIImage imageNamed:[ARRAY_IMAGES_FOR_OPTIONS objectAtIndex:index]];

    cell.tag = index;

	return cell;
}

- (void)exportUsing:(tExportOption)option
{
    switch (option)
    {
        case ExportOption_AirPrint:
        {
            [self exportWithAirPrint];
        }
            break;

        case ExportOption_SDCard:
        {
            ABCLog(2,@"Unsupported export option");
        }
            break;

        case ExportOption_Email:
        {
            [self exportWithEMail];
        }
            break;

        case ExportOption_GoogleDrive:
        {
            [self exportWithGoogle];
        }
            break;

        case ExportOption_Dropbox:
        {
            [self exportWithDropbox];
        }
            break;

        case ExportOption_View:
        {
            [self exportView];
        }
            break;

        default:
            ABCLog(2,@"Unknown export type");
            break;
    }
}

- (void)exportWithAirPrint
{
    if ([UIPrintInteractionController isPrintingAvailable])
    {
        UIPrintInteractionController *pc = [UIPrintInteractionController sharedPrintController];
        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
        printInfo.outputType = UIPrintInfoOutputGeneral;
        printInfo.jobName = walletExport;
        pc.printInfo = printInfo;
        pc.showsPageRange = YES;
        NSData *dataExport = [self getExportDataInForm:self.type];
        if (dataExport == nil)
            return;

        if (self.type == WalletExportType_PrivateSeed ||
            self.type == WalletExportType_PublicSeed)
        {

            NSString *strSeed = [[NSString alloc] initWithData:dataExport encoding:NSUTF8StringEncoding];
            NSMutableString *strBody = [[NSMutableString alloc] init];
            [strBody appendFormat:@"%@%@\n\n", walletNameHeaderText, abcAccount.currentWallet.name];
            if (self.type == WalletExportType_PrivateSeed)
                [strBody appendString:privateSeedText];
            else
                [strBody appendString:publicSeedText];
            [strBody appendString:@":\n"];
            [strBody appendString:strSeed];
            [strBody appendString:@"\n\n"];

            UISimpleTextPrintFormatter *textFormatter = [[UISimpleTextPrintFormatter alloc] initWithText:strBody];
            textFormatter.startPage = 0;
            textFormatter.contentInsets = UIEdgeInsetsMake(72.0, 72.0, 72.0, 72.0); // 1 inch margins
            textFormatter.maximumContentWidth = 6 * 72.0;
            pc.printFormatter = textFormatter;
        }
        else if (self.type == WalletExportType_PDF)
        {
            if ([UIPrintInteractionController canPrintData:dataExport])
            {
                pc.delegate = nil;
                pc.printingItem = dataExport;
            }
        }
        else
        {
            ABCLog(2,@"unsupported type for AirPrint");
            return;
        }

        UIPrintInteractionCompletionHandler completionHandler =
        ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
            if(!completed && error){
                ABCLog(2,@"Print failed - domain: %@ error code %u", error.domain, (unsigned int)error.code);
            }
        };

        [pc presentAnimated:YES completionHandler:completionHandler];
    }
    else
    {
        // not available
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:exportWalletTransactions
                              message:airprintIsNotAvailable
                              delegate:nil
                              cancelButtonTitle:okButtonText
                              otherButtonTitles:nil];
        [alert show];
    }
    
}

- (void)exportWithEMail
{
    // if mail is available
    if ([MFMailComposeViewController canSendMail])
    {
        NSMutableString *strBody = [[NSMutableString alloc] init];

        [strBody appendString:@"<html><body>\n"];

        [strBody appendString:abcAccount.currentWallet.name];
        [strBody appendString:@"\n"];
        [strBody appendString:@"<br><br>\n"];

        [strBody appendString:@"</body></html>\n"];


        _mailComposer = [[MFMailComposeViewController alloc] init];

        NSString *tempText = [NSString stringWithFormat:@"%@ %@", appTitle, bitcoinWalletTransactionsText];
        
        [_mailComposer setSubject:tempText];

        [_mailComposer setMessageBody:strBody isHTML:YES];

        // set up the attachment
        NSData *dataExport = [self getExportDataInForm:self.type];
        if (dataExport == nil)
            return;

        NSString *strFilename = [NSString stringWithFormat:@"%@.%@", abcAccount.currentWallet.name, [self suffixFor:self.type]];
        NSString *strMimeType = [self mimeTypeFor:self.type];
        [_mailComposer addAttachmentData:dataExport mimeType:strMimeType fileName:strFilename];

        _mailComposer.mailComposeDelegate = self;

        [self presentViewController:_mailComposer animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:cantSendEmailText
                                                       delegate:nil
                                              cancelButtonTitle:okButtonText
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)exportWithGoogle
{
	 drive = [GDrive CreateForViewController:self];
}

- (void)exportWithDropbox
{

}

- (void)exportView
{
    NSData *dataExport = [self getExportDataInForm:self.type];
    if (dataExport == nil)
        return;

    if (self.type ==  WalletExportType_PDF)
    {

        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
        self.exportWalletPDFViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ExportWalletPDFViewController"];
        self.exportWalletPDFViewController.delegate = self;
        self.exportWalletPDFViewController.dataPDF = dataExport;

        CGRect frame = self.view.bounds;
        frame.origin.x = frame.size.width;
        self.exportWalletPDFViewController.view.frame = frame;
        [self.view addSubview:self.exportWalletPDFViewController.view];

        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                              delay:[Theme Singleton].animationDelayTimeDefault
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             self.exportWalletPDFViewController.view.frame = self.view.bounds;
         }
                         completion:^(BOOL finished)
         {
             
         }];
    }
    
    else if (self.type == WalletExportType_PrivateSeed ||
             self.type == WalletExportType_PublicSeed)
    {
        NSString *strSeed = [[NSString alloc] initWithData:dataExport encoding:NSUTF8StringEncoding];
        NSString *seedTitle;
        
        if (self.type == WalletExportType_PrivateSeed)
            seedTitle = privateSeedText;
        else
            seedTitle = publicSeedText;

        _showKeyAlert = [[UIAlertView alloc] initWithTitle:seedTitle
                                                   message:strSeed
                                                  delegate:self
                                         cancelButtonTitle:okButtonText
                                         otherButtonTitles:copyButtonText, nil];
        [_showKeyAlert show];
    } 
    else 
    {
        ABCLog(2,@"Only PDF and Wallet Seed are supported for viewing");
    }
}

- (NSData *)getExportDataInForm:(tWalletExportType)type
{
    NSData *dataExport = nil;

    // TODO: create the proper export in the proper from using self.wallet

    // for now just hard code
    switch (type)
    {
        case WalletExportType_CSV:
        {
            NSMutableString *str = [[NSMutableString alloc] init];
            
            NSError *error = [abcAccount.currentWallet exportTransactionsToCSV:str
                                                                         start:self.fromDateTime.date
                                                                           end:self.toDateTime.date];
            if (!error)
            {
                dataExport = [str dataUsingEncoding:NSUTF8StringEncoding];
            }
            else
            {
                NSString *title;
                title = exportWalletTransactions;
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:title
                                      message:error.userInfo[NSLocalizedDescriptionKey]
                                      delegate:nil
                                      cancelButtonTitle:okButtonText
                                      otherButtonTitles:nil];
                [alert show];
            }
        }
        break;

        case WalletExportType_Quicken:
        {
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"WalletExportQuicken" ofType:@"QIF"];
            dataExport = [NSData dataWithContentsOfFile:filePath];
        }
            break;

        case WalletExportType_Quickbooks:
        {
            NSMutableString *str = [[NSMutableString alloc] init];
            
            NSError *error = [abcAccount.currentWallet exportTransactionsToQBO:str
                                                                         start:self.fromDateTime.date
                                                                           end:self.toDateTime.date];

            if (!error)
            {
                dataExport = [str dataUsingEncoding:NSUTF8StringEncoding];
            }
            else
            {
                NSString *title;
                title = exportWalletTransactions;
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:title
                                      message:error.userInfo[NSLocalizedDescriptionKey]
                                      delegate:nil
                                      cancelButtonTitle:okButtonText
                                      otherButtonTitles:nil];
                [alert show];
            }
        }
            break;

        case WalletExportType_PDF:
        {
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"WalletExportPDF" ofType:@"pdf"];
            dataExport = [NSData dataWithContentsOfFile:filePath];
        }
            break;

        case WalletExportType_PrivateSeed:
        {
            NSMutableString *str = [[NSMutableString alloc] init];
            
            NSError *error = [abcAccount.currentWallet exportWalletPrivateSeed:str];
            if (!error)
            {
                dataExport = [str dataUsingEncoding:NSUTF8StringEncoding];
            }
            else
            {
                NSString *title;
                title = exportPrivateSeed;
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:title
                                      message:error.userInfo[NSLocalizedDescriptionKey]
                                      delegate:nil
                                      cancelButtonTitle:okButtonText
                                      otherButtonTitles:nil];
                [alert show];
            }
        }
        break;

        case WalletExportType_PublicSeed:
        {
            NSMutableString *str = [[NSMutableString alloc] init];
            
            NSError *error = [abcAccount.currentWallet exportWalletXPub:str];
            if (!error)
            {
                dataExport = [str dataUsingEncoding:NSUTF8StringEncoding];
            }
            else
            {
                NSString *title;
                title = exportPrivateSeed;
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:title
                                      message:error.userInfo[NSLocalizedDescriptionKey]
                                      delegate:nil
                                      cancelButtonTitle:okButtonText
                                      otherButtonTitles:nil];
                [alert show];
            }
        }
            
        break;
        default:
            ABCLog(2,@"Unknown export option");
            break;
    }

    return dataExport;
}

- (NSString *)suffixFor:(tWalletExportType)type
{
    NSString *strSuffix = @"???";

    switch (type)
    {
        case WalletExportType_CSV:
            strSuffix = @"csv";
            break;

        case WalletExportType_Quicken:
            strSuffix = @"QIF";
            break;

        case WalletExportType_Quickbooks:
            strSuffix = @"QBO";
            break;

        case WalletExportType_PDF:
            strSuffix = @"pdf";
            break;

        case WalletExportType_PrivateSeed:
        case WalletExportType_PublicSeed:
            strSuffix = @"txt";
            break;

        default:
            ABCLog(2,@"Unknown export type");
            break;
    }

    return strSuffix;
}

- (NSString *)mimeTypeFor:(tWalletExportType)type
{
    NSString *strMimeType = @"???";

    switch (type)
    {
        case WalletExportType_CSV:
            strMimeType = @"text/plain";
            break;

        case WalletExportType_Quicken:
            strMimeType = @"application/qif";
            break;

        case WalletExportType_Quickbooks:
            strMimeType = @"text/plain";
            break;

        case WalletExportType_PDF:
            strMimeType = @"application/pdf";
            break;

        case WalletExportType_PrivateSeed:
        case WalletExportType_PublicSeed:
            strMimeType = @"text/plain";
            break;

        default:
            ABCLog(2,@"Unknown export type");
            break;
    }
    
    return strMimeType;
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
    return (self.exportWalletPDFViewController != nil);
}

- (void)exit
{
    if (_mailComposer && _mailComposer.presentingViewController)
    {
        [_mailComposer.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }

    if([self.delegate respondsToSelector:@selector(exportWalletOptionsViewControllerDidFinish:)])
    {
        [self.delegate exportWalletOptionsViewControllerDidFinish:self];
    }

}

#pragma mark - GDrive Delegates
-(void)GDrive:(GDrive *)gDrive isAuthenticated:(BOOL)authenticated
{
	if(authenticated)
	{
		NSData *dataExport = [self getExportDataInForm:self.type];
        if (dataExport == nil)
            return;
		NSString *strFilename = [NSString stringWithFormat:@"%@.%@", abcAccount.currentWallet.name, [self suffixFor:self.type]];
		NSString *strMimeType = [self mimeTypeFor:self.type];
		
		[gDrive uploadFile:dataExport name:strFilename mimeType:strMimeType];
	}
}

-(void)GDrive:(GDrive *)gDrive uploadSuccessful:(BOOL)success
{
	gDrive = nil;
}

-(void)GDriveAuthControllerPresented
{
	ABCLog(2,@"Auth Controller Presented");
//	[self.view bringSubviewToFront:self.viewHeader];
}
#pragma mark - UITableView Delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.arrayChoices count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
    UIImage *cellImage;

//    if ([self.arrayChoices count] == 1)
//    {
//        cellImage = [UIImage imageNamed:@"bd_cell_middle"];
//    }
//    else
//    {
//
//        if (indexPath.row == 0)
//        {
//            cellImage = [UIImage imageNamed:@"bd_cell_top"];
//        }
//        else
//        {
//            if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1)
//            {
//                cellImage = [UIImage imageNamed:@"bd_cell_bottom"];
//            }
//            else
//            {
//                cellImage = [UIImage imageNamed:@"bd_cell_middle"];
//            }
//        }
//    }

    cell = [self getOptionsCellForTableView:tableView withImage:cellImage andIndexPath:(NSIndexPath *)indexPath];

	cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//ABCLog(2,@"Selected section:%i, row:%i", (int)indexPath.section, (int)indexPath.row);

    tExportOption exportOption = (tExportOption) [[self.arrayChoices objectAtIndex:indexPath.row] intValue];

    //ABCLog(2,@"Export option: %d", exportOption);

    if (WalletExportType_PrivateSeed != self.type)
    {
        [self exportUsing:exportOption];
    }
    else
    {
        if ([abcAccount accountHasPassword] && ![abcAccount checkPassword:self.passwordTextField.text])
        {
            [MainViewController fadingAlert:incorrectPasswordText];
            [self.passwordTextField becomeFirstResponder];
            [self.passwordTextField selectAll:nil];
        }
        else
        {
            [self exportUsing:exportOption];
        }
    }
}

#pragma mark - ButtonSelectorView delegate

- (void)ButtonSelector2:(ButtonSelectorView2 *)view selectedItem:(int)itemIndex
{
    NSIndexPath *indexPath = [[NSIndexPath alloc]init];
    indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [abcAccount makeCurrentWalletWithIndex:indexPath];
    bWalletListDropped = NO;

}


#pragma mark - Mail Compose Delegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    NSString *strTitle = nil;
    NSString *strMsg = nil;

	switch (result)
    {
		case MFMailComposeResultCancelled:
            strMsg = emailCancelled;
			break;

		case MFMailComposeResultSaved:
            strMsg = emailSavedToSendLater;
			break;

		case MFMailComposeResultSent:
            strMsg = emailSent;
			break;

		case MFMailComposeResultFailed:
		{
            strTitle = errorSendingEmail;
            strMsg = [error localizedDescription];
			break;
		}
		default:
			break;
	}

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle
                                                    message:strMsg
                                                   delegate:nil
                                          cancelButtonTitle:okButtonText
                                          otherButtonTitles:nil];
    [alert show];

    [[controller presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Export Wallet PDF Delegates

- (void)exportWalletPDFViewControllerDidFinish:(ExportWalletPDFViewController *)controller
{
	[controller.view removeFromSuperview];
    [controller removeFromParentViewController];
	self.exportWalletPDFViewController = nil;
}

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

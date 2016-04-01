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
#import "AirbitzCore.h"
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
                                    @[@0, @5]                   /* PrivateSeed */\
                                ]
#define ARRAY_NAMES_FOR_OPTIONS @[@"AirPrint", @"Save to SD card", @"Email", @"Google Drive", @"Dropbox", @"View"]
#define ARRAY_IMAGES_FOR_OPTIONS @[@"icon_export_printer", @"icon_export_sdcard", @"icon_export_email", @"icon_export_google", @"icon_export_dropbox", @"icon_export_view"]


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
                                                 UIGestureRecognizerDelegate, ButtonSelector2Delegate, UITextFieldDelegate>
{
	GDrive                              *drive;
    MFMailComposeViewController         *_mailComposer;
    BOOL                                bWalletListDropped;
}

@property (weak, nonatomic) IBOutlet UIView                     *viewPassword;
@property (weak, nonatomic) IBOutlet UITableView                *tableView;
@property (weak, nonatomic) IBOutlet ButtonSelectorView2        *buttonSelector;
@property (nonatomic, weak) IBOutlet MinCharTextField           *passwordTextField;

@property (nonatomic, strong) ExportWalletPDFViewController     *exportWalletPDFViewController;
@property (nonatomic, strong) NSArray                           *arrayChoices;

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
    self.passwordTextField.minimumCharacters = [AirbitzCore getMinimumPasswordLength];

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

//    self.labelFromDate.text = [NSString stringWithFormat:@"%d/%d/%d   %d:%.02d %@",
//                               (int) self.fromDateTime.month, (int) self.fromDateTime.day, (int) self.fromDateTime.year,
//                               [self displayFor12From24:(int) self.fromDateTime.hour], (int) self.fromDateTime.minute, self.fromDateTime.hour > 11 ? @"pm" : @"am"];
//    self.labelToDate.text = [NSString stringWithFormat:@"%d/%d/%d   %d:%.02d %@",
//                             (int) self.toDateTime.month, (int) self.toDateTime.day, (int) self.toDateTime.year,
//                             [self displayFor12From24:(int) self.toDateTime.hour], (int) self.toDateTime.minute, self.toDateTime.hour > 11 ?  @"pm" : @"am"];


    //ABCLog(2,@"type: %d", self.type);

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
        walletName = [NSString stringWithFormat:@"Export From: %@ ▼", abcAccount.currentWallet.name];

        [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle) fromObject:self];
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


#pragma mark - Keyboard Notifications

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Action Methods

- (void)buttonBackTouched
{
    [self exit];
}

- (void)buttonInfoTouched
{
    [InfoView CreateWithHTML:@"infoExportWalletOptions" forView:self.view];
}

#pragma mark - Misc Methods

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
        printInfo.jobName = NSLocalizedString(@"Wallet Export", nil);
        pc.printInfo = printInfo;
        pc.showsPageRange = YES;
        NSData *dataExport = [self getExportDataInForm:self.type];
        if (dataExport == nil)
            return;

        if (self.type == WalletExportType_PrivateSeed)
        {

            NSString *strPrivateSeed = [[NSString alloc] initWithData:dataExport encoding:NSUTF8StringEncoding];
            NSMutableString *strBody = [[NSMutableString alloc] init];
            [strBody appendFormat:@"Wallet: %@\n\n", abcAccount.currentWallet.name];
            [strBody appendString:@"Private Seed:\n"];
            [strBody appendString:strPrivateSeed];
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
                              initWithTitle:NSLocalizedString(@"Export Wallet Transactions", nil)
                              message:@"AirPrint is not currently available"
                              delegate:nil
                              cancelButtonTitle:@"OK"
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

//        [strBody appendString:NSLocalizedString(@"Attached are the transactions for the AirBitz Bitcoin Wallet: ", nil)];
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
                                                        message:@"Can't send e-mail"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
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

        [UIView animateWithDuration:0.35
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             self.exportWalletPDFViewController.view.frame = self.view.bounds;
         }
                         completion:^(BOOL finished)
         {
             
         }];
    }
    
    else if (self.type == WalletExportType_PrivateSeed)
    {
        NSString *strPrivateSeed = [[NSString alloc] initWithData:dataExport encoding:NSUTF8StringEncoding];

        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Wallet Private Seed", nil)
                                    message:strPrivateSeed
                                   delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
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
            
            NSError *error = [abcAccount.currentWallet exportTransactionsToCSV:str];
            if (!error)
            {
                dataExport = [str dataUsingEncoding:NSUTF8StringEncoding];
            }
            else
            {
                NSString *title;
                title = NSLocalizedString(@"Export Wallet Transactions", nil);
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
            
            NSError *error = [abcAccount.currentWallet exportTransactionsToQBO:str];
            if (!error)
            {
                dataExport = [str dataUsingEncoding:NSUTF8StringEncoding];
            }
            else
            {
                NSString *title;
                title = NSLocalizedString(@"Export Wallet Transactions", nil);
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
                title = NSLocalizedString(@"Export Private Seed", nil);
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
            [MainViewController fadingAlert:NSLocalizedString(@"Incorrect password", nil)];
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
            strMsg = NSLocalizedString(@"Email cancelled.", nil);
			break;

		case MFMailComposeResultSaved:
            strMsg = NSLocalizedString(@"Email saved to send later.", nil);
			break;

		case MFMailComposeResultSent:
            strMsg = NSLocalizedString(@"Email sent.", nil);
			break;

		case MFMailComposeResultFailed:
		{
            strTitle = NSLocalizedString(@"Error sending Email.", nil);
            strMsg = [error localizedDescription];
			break;
		}
		default:
			break;
	}

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle
                                                    message:strMsg
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
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

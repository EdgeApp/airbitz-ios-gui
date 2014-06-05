//
//  ExportWalletOptionsViewController.m
//  AirBitz
//
//  Created by Adam Harris on 5/26/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "ExportWalletOptionsViewController.h"
#import "ExportWalletPDFViewController.h"
#import "InfoView.h"
#import "Util.h"
#import "ExportWalletOptionsCell.h"
#import "CommonTypes.h"
#import "GDrive.h"

#define CELL_HEIGHT 37.0

#define ARRAY_CHOICES_FOR_TYPES @[ \
                                    @[@2, @3, @4],          /* CSV */\
                                    @[@2, @3, @4],          /* Quicken */\
                                    @[@2, @3, @4],          /* Quickbooks */\
                                    @[@0, @2, @3, @4, @5],  /* PDF */\
                                    @[@0]                   /* PrivateSeed */\
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

@interface ExportWalletOptionsViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, GDriveDelegate>
{
	GDrive *drive;
}

@property (weak, nonatomic) IBOutlet UIView         *viewDisplay;
@property (weak, nonatomic) IBOutlet UITableView    *tableView;
@property (weak, nonatomic) IBOutlet UILabel        *labelWalletName;
@property (weak, nonatomic) IBOutlet UILabel        *labelFromDate;
@property (weak, nonatomic) IBOutlet UILabel        *labelToDate;
@property (weak, nonatomic) IBOutlet UIView			*viewHeader;

@property (nonatomic, strong) NSArray               *arrayChoices;

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

    self.arrayChoices = [ARRAY_CHOICES_FOR_TYPES objectAtIndex:(NSUInteger) self.type];

    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.delaysContentTouches = NO;

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:self.viewDisplay];

    [self updateDisplayLayout];

    self.labelWalletName.text = self.wallet.strName;
    self.labelFromDate.text = [NSString stringWithFormat:@"%d/%d/%d   %d:%.02d %@",
                               (int) self.fromDateTime.month, (int) self.fromDateTime.day, (int) self.fromDateTime.year,
                               [self displayFor12From24:(int) self.fromDateTime.hour], (int) self.fromDateTime.minute, self.fromDateTime.hour > 11 ? @"pm" : @"am"];
    self.labelToDate.text = [NSString stringWithFormat:@"%d/%d/%d   %d:%.02d %@",
                             (int) self.toDateTime.month, (int) self.toDateTime.day, (int) self.toDateTime.year,
                             [self displayFor12From24:(int) self.toDateTime.hour], (int) self.toDateTime.minute, self.toDateTime.hour > 11 ?  @"pm" : @"am"];


    //NSLog(@"type: %d", self.type);
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
    [InfoView CreateWithHTML:@"infoExportWalletOptions" forView:self.view];
}

#pragma mark - Misc Methods

- (void)updateDisplayLayout
{
    // update for iPhone 4
    if (!IS_IPHONE5)
    {
        // warning: magic numbers for iphone layout

        CGRect frame = self.tableView.frame;
        frame.size.height = 200;
        self.tableView.frame = frame;
        
    }
}

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
	cell.bkgImage.image = bkgImage;

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
            NSLog(@"Unsupported export option");
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
            NSLog(@"Unknown export type");
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

        if (self.type == WalletExportType_PrivateSeed)
        {

            NSString *strPrivateSeed = [[NSString alloc] initWithData:dataExport encoding:NSUTF8StringEncoding];
            NSMutableString *strBody = [[NSMutableString alloc] init];
            [strBody appendFormat:@"Wallet: %@\n\n", self.wallet.strName];
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
            NSLog(@"unsupported type for AirPrint");
            return;
        }

        UIPrintInteractionCompletionHandler completionHandler =
        ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
            if(!completed && error){
                NSLog(@"Print failed - domain: %@ error code %u", error.domain, (unsigned int)error.code);
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

        [strBody appendString:NSLocalizedString(@"Attached are the transactions for the AirBitz Bitcoin Wallet: ", nil)];
        [strBody appendString:self.wallet.strName];
        [strBody appendString:@"\n"];
        [strBody appendString:@"<br><br>\n"];

        [strBody appendString:@"</body></html>\n"];


        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];

        [mailComposer setSubject:NSLocalizedString(@"AirBitz Bitcoin Wallet Transactions", nil)];

        [mailComposer setMessageBody:strBody isHTML:YES];

        // set up the attachment
        NSData *dataExport = [self getExportDataInForm:self.type];
        NSString *strFilename = [NSString stringWithFormat:@"%@.%@", self.wallet.strName, [self suffixFor:self.type]];
        NSString *strMimeType = [self mimeTypeFor:self.type];
        [mailComposer addAttachmentData:dataExport mimeType:strMimeType fileName:strFilename];

        mailComposer.mailComposeDelegate = self;

        [self presentViewController:mailComposer animated:YES completion:nil];
        //[self presentModalViewController:mailComposer animated:NO];
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
    if (self.type ==  WalletExportType_PDF)
    {

        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
        _exportWalletPDFViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ExportWalletPDFViewController"];
        _exportWalletPDFViewController.delegate = self;
        _exportWalletPDFViewController.dataPDF = [self getExportDataInForm:self.type];

        CGRect frame = self.view.bounds;
        frame.origin.x = frame.size.width;
        _exportWalletPDFViewController.view.frame = frame;
        [self.view addSubview:_exportWalletPDFViewController.view];

        [UIView animateWithDuration:0.35
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             _exportWalletPDFViewController.view.frame = self.view.bounds;
         }
                         completion:^(BOOL finished)
         {
             
         }];
    }
    else
    {
        NSLog(@"Only PDF is supported for viewing");
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
            NSString* str = @"[CSV Data Here]";
            dataExport = [str dataUsingEncoding:NSUTF8StringEncoding];
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
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"WalletExportQuicken" ofType:@"QIF"];
            dataExport = [NSData dataWithContentsOfFile:filePath];
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
            NSString* str = @"[Private Seed Here]";
            dataExport = [str dataUsingEncoding:NSUTF8StringEncoding];
        }
            break;

        default:
            NSLog(@"Unknown export option");
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
            strSuffix = @"QIF";
            break;

        case WalletExportType_PDF:
            strSuffix = @"pdf";
            break;

        case WalletExportType_PrivateSeed:
            strSuffix = @"txt";
            break;

        default:
            NSLog(@"Unknown export type");
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
            strMimeType = @"application/qbooks";
            break;

        case WalletExportType_PDF:
            strMimeType = @"application/pdf";
            break;

        case WalletExportType_PrivateSeed:
            strMimeType = @"text/plain";
            break;

        default:
            NSLog(@"Unknown export type");
            break;
    }
    
    return strMimeType;
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
	[self.delegate exportWalletOptionsViewControllerDidFinish:self];
}

#pragma mark - GDrive Delegates
-(void)GDrive:(GDrive *)gDrive isAuthenticated:(BOOL)authenticated
{
	if(authenticated)
	{
		NSData *dataExport = [self getExportDataInForm:self.type];
		NSString *strFilename = [NSString stringWithFormat:@"%@.%@", self.wallet.strName, [self suffixFor:self.type]];
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
	NSLog(@"Auth Controller Presented");
	[self.view bringSubviewToFront:self.viewHeader];
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

    if ([self.arrayChoices count] == 1)
    {
        cellImage = [UIImage imageNamed:@"bd_cell_middle"];
    }
    else
    {

        if (indexPath.row == 0)
        {
            cellImage = [UIImage imageNamed:@"bd_cell_top"];
        }
        else
        {
            if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1)
            {
                cellImage = [UIImage imageNamed:@"bd_cell_bottom"];
            }
            else
            {
                cellImage = [UIImage imageNamed:@"bd_cell_middle"];
            }
        }
    }

    cell = [self getOptionsCellForTableView:tableView withImage:cellImage andIndexPath:(NSIndexPath *)indexPath];

	cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"Selected section:%i, row:%i", (int)indexPath.section, (int)indexPath.row);

    tExportOption exportOption = (tExportOption) [[self.arrayChoices objectAtIndex:indexPath.row] intValue];

    //NSLog(@"Export option: %d", exportOption);

    [self exportUsing:exportOption];
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
	_exportWalletPDFViewController = nil;
}

@end

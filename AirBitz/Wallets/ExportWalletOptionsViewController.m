//
//  ExportWalletOptionsViewController.m
//  AirBitz
//
//  Created by Adam Harris on 5/26/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "ExportWalletOptionsViewController.h"
#import "InfoView.h"
#import "Util.h"
#import "ExportWalletOptionsCell.h"
#import "CommonTypes.h"

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

@interface ExportWalletOptionsViewController () <UITableViewDataSource, UITableViewDelegate>
{

}

@property (weak, nonatomic) IBOutlet UIView     *viewDisplay;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel    *labelWalletName;
@property (weak, nonatomic) IBOutlet UILabel    *labelFromDate;
@property (weak, nonatomic) IBOutlet UILabel    *labelToDate;

@property (nonatomic, strong) NSArray           *arrayChoices;

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
    self.labelFromDate.text = [NSString stringWithFormat:@"%d/%d/%d   %d:%.02d:%.02d",
                               (int) self.fromDateTime.month, (int) self.fromDateTime.day, (int) self.fromDateTime.year,
                               (int) self.fromDateTime.hour, (int) self.fromDateTime.minute, (int) self.fromDateTime.second];
    self.labelToDate.text = [NSString stringWithFormat:@"%d/%d/%d   %d:%.02d:%.02d",
                             (int) self.toDateTime.month, (int) self.toDateTime.day, (int) self.toDateTime.year,
                             (int) self.toDateTime.hour, (int) self.toDateTime.minute, (int) self.toDateTime.second];


    //NSLog(@"type: %d", self.type);
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
	NSLog(@"Selected section:%i, row:%i", (int)indexPath.section, (int)indexPath.row);
}

@end

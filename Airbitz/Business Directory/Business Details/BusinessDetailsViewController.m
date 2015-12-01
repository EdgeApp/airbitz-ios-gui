//
//  BusinessDetailsViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/17/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "BusinessDetailsViewController.h"
#import "Server.h"
#import "Util.h"
#import "BD_Social_Cell.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "RibbonView.h"
#import "CommonTypes.h"
#import "UIPhotoGalleryView.h"
#import "UIPhotoGalleryViewController.h"
#import "UIPhotoGallerySliderView.h"
#import "UIPhotoGalleryViewController+Slider.h"

#import "CJSONDeserializer.h"
#import "MainViewController.h"
#import "BD_CommonCell.h"
#import "Theme.h"

#define SHOW_PHONE_CALL_ARE_YOU_SURE_ALERT 0	/* set to 1 to show are you sure alert before dialing */
#define TOP_IMAGE_HEIGHT 200.0

typedef NS_ENUM(NSUInteger, CellType) {
    kAddress,
    kPhone,
    kWebsite,
    kShare,
    kHours,
    kDetails,
    kSocial
};

#define SINGLE_ROW_CELL_HEIGHT	50
#define LABEL_WIDTH_WILD_GUESS  300

#define CLOSED_STRING	@"closed"

@interface BusinessDetailsViewController () <UITableViewDataSource, UITableViewDelegate,
                                             UIAlertViewDelegate, UIPhotoGalleryDataSource, UIPhotoGalleryDelegate>
{
	CGFloat hoursCellHeight;
	CGFloat detailsCellHeight;
	CGFloat detailsLabelWidth;
	BOOL needToLoadImageInfo;
    NSArray *details;
    UIPhotoGalleryViewController *galleryController;
    UIActivityIndicatorView *gallerySpinner;
	NSMutableArray *imageURLs;
    NSMutableArray *rowTypes;
    NSMutableArray *socialRows;
    UIView         *shareView;
}

@property (nonatomic, weak) IBOutlet UIImageView *darkenImageView;
@property (nonatomic, weak) IBOutlet UIPhotoGalleryView *galleryView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *imageLoadActivityView;
@property (nonatomic, weak) IBOutlet UIView *imageArea;
@property (nonatomic, weak) IBOutlet UILabel *categoriesLabel;
@property (nonatomic, weak) IBOutlet UILabel *BTC_DiscountLabel;

@property (nonatomic, strong) NSDictionary *businessDetails;
@property (strong, nonatomic) AFHTTPRequestOperationManager         *afmanager;

@end

@implementation BusinessDetailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.galleryView.dataSource = self;
    self.galleryView.delegate = self;
    self.galleryView.galleryMode = UIPhotoGalleryModeCustomView;
    self.galleryView.subviewGap = 0;
    self.galleryView.photoItemContentMode = UIViewContentModeScaleAspectFill;

    details = nil;
	imageURLs = [[NSMutableArray alloc] init];
    rowTypes = [[NSMutableArray alloc] init];
    socialRows = [[NSMutableArray alloc] init];
	hoursCellHeight = SINGLE_ROW_CELL_HEIGHT;
	detailsCellHeight = SINGLE_ROW_CELL_HEIGHT;
    detailsLabelWidth = LABEL_WIDTH_WILD_GUESS;
    
    self.darkenImageView.hidden = YES; //hide until business image gets loaded

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = SINGLE_ROW_CELL_HEIGHT; // set to whatever your "average" cell height is

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionDetailsExit) name:NOTIFICATION_TRANSACTION_DETAILS_EXITED object:nil];

    [self.tableView setContentInset:UIEdgeInsetsMake([MainViewController getHeaderHeight],0,[MainViewController getFooterHeight],0)];

    //get business details
	NSString *requestURL = [NSString stringWithFormat:@"%@/business/%@/?ll=%f,%f", SERVER_API, self.bizId, self.latLong.latitude, self.latLong.longitude];
	//ABLog(2,@"Requesting: %@", requestURL);
    
    self.afmanager = [MainViewController createAFManager];
    
    [self.afmanager GET:requestURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        //
        // Query business details
        //
        
        [self.activityView stopAnimating];
        
        NSDictionary *results = (NSDictionary *)responseObject;

        self.businessDetails = results;
        
        [self determineVisibleRows];
        
        [MainViewController changeNavBarTitle:self title:[self.businessDetails objectForKey:@"name"]];
        
        NSArray *daysOfOperation = [self.businessDetails objectForKey:@"hours"];
        
        if(daysOfOperation.count)
        {
            hoursCellHeight = SINGLE_ROW_CELL_HEIGHT + 16 * [daysOfOperation count] - 16;
        }
        else
        {
            hoursCellHeight = SINGLE_ROW_CELL_HEIGHT;
        }
        
        BD_CommonCell *commonCell = [self getCommonCellForTableView:self.tableView];
        
        //calculate height of details cell
        CGSize size = [ [self.businessDetails objectForKey:@"description"] sizeWithFont:commonCell.leftLabel.font constrainedToSize:CGSizeMake(detailsLabelWidth, 9999) lineBreakMode:NSLineBreakByWordWrapping];
        detailsCellHeight = size.height + 28.0;
        
        [self.tableView reloadData];
        
        //Get image URLs
        NSString *requestURL = [NSString stringWithFormat:@"%@/business/%@/photos/", SERVER_API, self.bizId];

        [self.afmanager GET:requestURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            //
            // Query business image URLs for the gallery
            //

            NSDictionary *results = (NSDictionary *)responseObject;

            details = [results objectForKey:@"results"];
            
            self.galleryView.galleryMode = UIPhotoGalleryModeImageRemote;
            self.galleryView.photoItemContentMode = UIViewContentModeScaleAspectFill;
            [self.galleryView layoutSubviews];
            
            self.darkenImageView.hidden = NO;
            [gallerySpinner stopAnimating];
            
            //create the distance ribbon
            NSNumber *distance = [self.businessDetails objectForKey:@"distance"];
            if(distance && distance != (id)[NSNull null])
            {
                [self setRibbon:[RibbonView metersToDistance:[distance floatValue]]];
            }
            
            NSString *bitCoinDiscount = [self.businessDetails objectForKey:@"has_bitcoin_discount"];
            if(bitCoinDiscount)
            {
                float discount = [bitCoinDiscount floatValue] * 100.0;
                if(discount)
                {
                    self.BTC_DiscountLabel.text = [NSString stringWithFormat:@"BTC Discount: %.0f%%", [bitCoinDiscount floatValue] * 100.0];
                }
                else
                {
                    [self hideDiscountLabel];
                }
            }
            else
            {
                [self hideDiscountLabel];
            }
            [self setCategoriesAndName];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            ABLog(1, @"*** ERROR Connecting to Network: BusinessDetailsViewController: get image URLs");
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        ABLog(1, @"*** ERROR Connecting to Network: BusinessDetailsViewController: getting business details");
    }];
	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	[self.activityView startAnimating];
	
	UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
	gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:gesture];
}

- (void)viewWillAppear:(BOOL)animated
{
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Back:) fromObject:self];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_RIGHT button:true enable:false action:@selector(Back:) fromObject:self];

    if (self.businessDetails)
        [MainViewController changeNavBarTitle:self title:[self.businessDetails objectForKey:@"name"]];
}

- (void)transactionDetailsExit
{
    // An async tx details happened and exited. Drop everything and kill ourselves or we'll
    // corrupt the background. This is needed on every subview of a primary screen
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}



-(void)didSwipe:(UIGestureRecognizer *)gestureRecognizer
{
    if (!galleryController)
    {
        [self Back:nil];
    }
}

-(void)dealloc
{
//	[[DL_URLServer controller] cancelAllRequestsForDelegate:self];
}

-(void)setCategoriesAndName
{
	NSMutableString *categoriesString = [[NSMutableString alloc] init];
	NSArray *categoriesArray = [self.businessDetails objectForKey:@"categories"];
	BOOL firstObject = YES;
	for(NSDictionary *dict in categoriesArray)
	{
		if(firstObject == NO)
		{
			[categoriesString appendString:@" | "];
		}
		[categoriesString appendString:[dict objectForKey:@"name"]];
		firstObject = NO;
	}
	self.categoriesLabel.text = categoriesString;

//    [MainViewController changeNavBarTitle:self title:[self.businessDetails objectForKey:@"name"]];

}

-(void)setRibbon:(NSString *)ribbon
{
	RibbonView *ribbonView;
	
	ribbonView = (RibbonView *)[self.imageArea viewWithTag:TAG_RIBBON_VIEW];
	if(ribbonView)
	{
		[ribbonView flyIntoPosition];
		if(ribbon.length)
		{
			ribbonView.hidden = NO;
			ribbonView.string = ribbon;
		}
		else
		{
			ribbonView.hidden = YES;
		}
	}
	else
	{
		if(ribbon.length)
		{
			ribbonView = [[RibbonView alloc] initAtLocation:CGPointMake(self.imageArea.bounds.origin.x + self.imageArea.bounds.size.width, 0.0) WithString:ribbon];
			[self.imageArea addSubview:ribbonView];
		}
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)Back:(id)sender
{
	[self.delegate businessDetailsViewControllerDone:self];
}

-(NSString *)time12Hr:(NSString *)time24Hr
{
	NSString *pmamDateString;
	
	if(time24Hr != (id)[NSNull null])
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"HH:mm:ss";
		NSDate *date = [dateFormatter dateFromString:time24Hr];
		
		dateFormatter.dateFormat = @"h:mm a";
		pmamDateString = [dateFormatter stringFromDate:date];
	}
	else
	{
		pmamDateString = CLOSED_STRING;
	}
	return [pmamDateString lowercaseString];
}

-(void)launchMapApp
{
	NSDictionary *locationDict = [self.businessDetails objectForKey:@"location"];
	if(locationDict.count == 2)
	{
		//launch with specific coordinate
		CLLocationCoordinate2D coordinate;
		coordinate.latitude = [[locationDict objectForKey:@"latitude"] floatValue];
		coordinate.longitude = [[locationDict objectForKey:@"longitude"] floatValue];
		
		NSMutableDictionary *addressDict = [[NSMutableDictionary alloc] init];
		[addressDict setObject:[self.businessDetails objectForKey:@"city"] forKey:@"City"];
		[addressDict setObject:[self.businessDetails objectForKey:@"address"] forKey:@"Street"];
		[addressDict setObject:[self.businessDetails objectForKey:@"state"] forKey:@"State"];
		[addressDict setObject:[self.businessDetails objectForKey:@"postalcode"] forKey:@"ZIP"];
		
		MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:addressDict];
		
		// Create a map item for the geocoded address to pass to Maps app
		MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
		[mapItem setName:[self.businessDetails objectForKey:@"name"]];
		
		// Set the directions mode to "Driving"
		// Can use MKLaunchOptionsDirectionsModeWalking instead
		NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
		
		// Get the "Current User Location" MKMapItem
		MKMapItem *currentLocationMapItem = [MKMapItem mapItemForCurrentLocation];
		
		// Pass the current location and destination map items to the Maps app
		// Set the direction mode in the launchOptions dictionary
		[MKMapItem openMapsWithItems:@[currentLocationMapItem, mapItem] launchOptions:launchOptions];
		
	}
	else
	{
		//no coordinate so launch with address instead
		NSString *address = [NSString stringWithFormat:@"%@ %@, %@  %@", [self.businessDetails objectForKey:@"address"], [self.businessDetails objectForKey:@"city"], [self.businessDetails objectForKey:@"state"], [self.businessDetails objectForKey:@"postalcode"]];
		CLGeocoder *geocoder = [[CLGeocoder alloc] init];
		[geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error)
		 {
			 ABLog(2,@"error: %li", (long)error.code);
			 
			 // Convert the CLPlacemark to an MKPlacemark
			 // Note: There's no error checking for a failed geocode
			 CLPlacemark *geocodedPlacemark = [placemarks objectAtIndex:0];
			 MKPlacemark *placemark = [[MKPlacemark alloc]
									   initWithCoordinate:geocodedPlacemark.location.coordinate
									   addressDictionary:geocodedPlacemark.addressDictionary];
			 
			 // Create a map item for the geocoded address to pass to Maps app
			 MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
			 [mapItem setName:geocodedPlacemark.name];
			 
			 // Set the directions mode to "Driving"
			 // Can use MKLaunchOptionsDirectionsModeWalking instead
			 NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
			 
			 // Get the "Current User Location" MKMapItem
			 MKMapItem *currentLocationMapItem = [MKMapItem mapItemForCurrentLocation];
			 
			 // Pass the current location and destination map items to the Maps app
			 // Set the direction mode in the launchOptions dictionary
			 [MKMapItem openMapsWithItems:@[currentLocationMapItem, mapItem] launchOptions:launchOptions];
			 
		 }];
	}
}

-(void)callBusinessNumber
{
	NSString *telNum = [NSString stringWithFormat:@"tel://%@", [self.businessDetails objectForKey:@"phone"]];
    [Util callTelephoneNumber:telNum];
}

-(void)hideDiscountLabel
{
	//hide BTC discount label
	//Make categories label longer to fill space previously occupied by BTC discount label
	CGRect categoryFrame = self.categoriesLabel.frame;
	CGRect discountFrame = self.BTC_DiscountLabel.frame;
	
	categoryFrame.size.width = discountFrame.origin.x + discountFrame.size.width - categoryFrame.origin.x;
	self.categoriesLabel.frame = categoryFrame;
	self.BTC_DiscountLabel.hidden = YES;
}

-(void)determineVisibleRows
{
    [rowTypes removeAllObjects];

    // If business detail data is available for row type, increment count
    
    //Address (must have at least city and state)
    NSString *city = [self.businessDetails objectForKey:@"city"];
    NSString *state = [self.businessDetails objectForKey:@"state"];
    
    if((city != nil) && (city != (id)[NSNull null]) && city.length)
    {
        if((state != nil) && (state != (id)[NSNull null]) && state.length)
        {
            [rowTypes addObject:[NSNumber numberWithInt:kAddress]];
        }
    }
    
    //phone (must have length)
    NSString *phone = [self.businessDetails objectForKey:@"phone"];
    if((phone != nil) && (phone != (id)[NSNull null]) && phone.length)
    {
        [rowTypes addObject:[NSNumber numberWithInt:kPhone]];
    }
    
    //web (must have length)
    NSString *web = [self.businessDetails objectForKey:@"website"];
    if((web != nil) && (web != (id)[NSNull null]) && web.length)
    {
        [rowTypes addObject:[NSNumber numberWithInt:kWebsite]];
    }
    
    //share always visible
    [rowTypes addObject:[NSNumber numberWithInt:kShare]];

    //hours (must have at least one item)
    NSArray *daysOfOperation = [self.businessDetails objectForKey:@"hours"];
    if((daysOfOperation != nil) && (daysOfOperation != (id)[NSNull null]) && daysOfOperation.count)
    {
        [rowTypes addObject:[NSNumber numberWithInt:kHours]];
    }
    
    //details always visible
    [rowTypes addObject:[NSNumber numberWithInt:kDetails]];

    //social
    NSArray *social = [self.businessDetails objectForKey:@"social"];
    if((social != nil) && (social != (id)[NSNull null]))
    {
        for (NSDictionary *data in social)
        {
            // store row index and social type for later retrieval
            NSString *type = [data objectForKey:@"social_type"];
            NSNumber *typeEnum = [BD_Social_Cell getSocialTypeAsEnum:type];
            if (typeEnum != [NSNumber numberWithInt:kNull])
            {
                NSDictionary *rowData = @{[NSNumber numberWithInt:(int)[rowTypes count]] : typeEnum};
                [socialRows addObject:rowData];

                [rowTypes addObject:[NSNumber numberWithInt:kSocial]];
            }
        }
    }
}

-(NSUInteger)primaryImage:(NSArray *)arrayImageResults
{
	NSUInteger primaryImage = 0;
	NSUInteger count = 0;
	for(NSDictionary *dict in arrayImageResults)
	{
		NSArray *tags = [dict objectForKey:@"tags"];
		if(tags && (tags != (id)[NSNull null]))
		{
			for(NSString *tag in tags)
			{
				if([tag isEqualToString:@"Primary"])
				{
					//found primary image
					//ABLog(2,@"Found primary tag at object index: %i", count);
					primaryImage = count;
					break;
				}
			}
			if(primaryImage)
			{
				break;
			}
		}
		count++;
	}
	return primaryImage;
}

#pragma mark - DLURLServer Callbacks

#pragma mark Table View delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [rowTypes count];
}

-(BD_CommonCell *)getCommonCellForTableView:(UITableView *)tableView
{
    BD_CommonCell *cell;
    static NSString *cellIdentifier = @"BD_CommonCell";

    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (nil == cell)
    {
        cell = [[BD_CommonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    return cell;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = [indexPath row];
	UITableViewCell *cell;
	
	
	int cellType = [self cellTypeForRow:indexPath.row];

    //common cell
    BD_CommonCell *commonCell = [self getCommonCellForTableView:tableView];

	if (cellType == kAddress)
	{
		if(self.businessDetails)
		{
            commonCell.leftLabel.numberOfLines = 2;
			commonCell.leftLabel.text = [NSString stringWithFormat:@"%@\n%@, %@  %@", [self.businessDetails objectForKey:@"address"],
                            [self.businessDetails objectForKey:@"city"], [self.businessDetails objectForKey:@"state"], [self.businessDetails objectForKey:@"postalcode"]];
		}
	}
	else if(cellType == kPhone)
	{
        commonCell.cellIcon.hidden = NO;
        commonCell.cellIcon.image = [UIImage imageNamed:@"bd_icon_phone.png"];
		commonCell.leftLabel.text = [self.businessDetails objectForKey:@"phone"];
	}
	else if(cellType == kWebsite)
	{
		//website cell
        commonCell.cellIcon.hidden = NO;
        commonCell.cellIcon.image = [UIImage imageNamed:@"bd_icon_web.png"];
		commonCell.leftLabel.text = [self.businessDetails objectForKey:@"website"];
	}
	else if(cellType == kShare)
	{
		//share cell
        commonCell.cellIcon.hidden = NO;
        commonCell.cellIcon.image = [UIImage imageNamed:@"bd_icon_share.png"];
        commonCell.leftLabel.text = NSLocalizedString(@"Share", @"Share button text");
        shareView = commonCell;
	}
	else if(cellType == kHours)
	{
		if(self.businessDetails)
		{
			[self.activityView stopAnimating];
			NSArray *operatingDays = [self.businessDetails objectForKey:@"hours"];
			NSMutableString *dayString = [[NSMutableString alloc] init];
			NSMutableString *hoursString = [[NSMutableString alloc] init];
			if(operatingDays.count)
			{
				NSString *lastDayString = @" ";
				for(NSDictionary *day in operatingDays)
				{
					NSString *weekday = [day objectForKey:@"dayOfWeek"];
					if([weekday isEqualToString:lastDayString])
					{
						[dayString appendString:@"\n"];
					}
					else
					{
						[dayString appendFormat:@"%@\n", weekday];
					}
					lastDayString = [weekday copy];
					NSString *openTime = [self time12Hr:[day objectForKey:@"hourStart"]];
					NSString *closedTime = [self time12Hr:[day objectForKey:@"hourEnd"]];
					if([openTime isEqualToString:closedTime])
					{
						[hoursString appendFormat:@"%@\n", closedTime];
					}
					else if(![openTime isEqualToString:CLOSED_STRING] && [closedTime isEqualToString:CLOSED_STRING])
					{
						[hoursString appendString:@"Open 24 hours\n"];
					}
					else
					{
						[hoursString appendFormat:@"%@ - %@\n", [self time12Hr:[day objectForKey:@"hourStart"]], [self time12Hr:[day objectForKey:@"hourEnd"]]];
					}
				}
				//remove last CR
				[dayString deleteCharactersInRange:NSMakeRange([dayString length]-1, 1)];
				[hoursString deleteCharactersInRange:NSMakeRange([hoursString length]-1, 1)];
			}
			else
			{
				[dayString appendString:@"Open 24"];
				[hoursString appendString:@"hours\n"];
			}
            NSInteger leftLines = [[dayString componentsSeparatedByCharactersInSet:
                    [NSCharacterSet newlineCharacterSet]] count];

            NSInteger rightLines = [[hoursString componentsSeparatedByCharactersInSet:
                    [NSCharacterSet newlineCharacterSet]] count];

            //apply new strings to text labels
			commonCell.leftLabel.text = [dayString copy];
            commonCell.leftLabel.numberOfLines = leftLines;
            commonCell.leftLabel.textColor = [UIColor blackColor];

			commonCell.rightLabel.text = [hoursString copy];
            commonCell.rightLabel.numberOfLines = rightLines;
            commonCell.rightLabel.textColor = [UIColor blackColor];

            commonCell.rightIcon.hidden = YES;
            commonCell.cellIcon.hidden = NO;
            commonCell.cellIcon.image = [UIImage imageNamed:@"bd_icon_clock.png"];

        }
	}
	else if(cellType == kDetails)
	{
		//details cell
		if(self.businessDetails)
		{
            commonCell.leftLabel.text = [self.businessDetails objectForKey:@"description"];

            commonCell.leftLabel.numberOfLines = 0;
			[commonCell.leftLabel sizeToFit];
            commonCell.leftLabel.textColor = [UIColor blackColor];
            commonCell.rightIcon.hidden = YES;
            commonCell.cellIcon.hidden = YES;
            commonCell.leftLabel.lineBreakMode = NSLineBreakByWordWrapping;

        }
	}
	else if(cellType == kSocial)
	{
        for (NSDictionary *pair in socialRows)
        {
            NSNumber *socialType = [pair objectForKey:[NSNumber numberWithInt:(int)row]];
            if (socialType)
            {
                commonCell.cellIcon.hidden = NO;
                commonCell.rightIcon.hidden = NO;
                commonCell.leftLabel.textColor = [Theme Singleton].bdButtonBlue;
                commonCell.cellIcon.image = [UIImage imageNamed:[BD_Social_Cell getSocialTypeImage:socialType]];
                commonCell.leftLabel.text = [BD_Social_Cell getSocialTypeAsString:socialType];
                break;
            }
        }
	}

    [commonCell.leftLabel sizeToFit];
    [commonCell.rightLabel sizeToFit];

    cell = commonCell;

    return cell;
}

-(int)cellTypeForRow:(NSInteger)row
{
    if (row < [rowTypes count])
        return [((NSNumber*)[rowTypes objectAtIndex:row]) intValue];
	return kSocial;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	int cellType = [self cellTypeForRow:indexPath.row];
	
	if(cellType == kHours)
	{
		return hoursCellHeight;
	}
	else if(cellType == kDetails)
	{
		//ABLog(2,@"returning details cell height of %f", detailsCellHeight);
		return detailsCellHeight;
	}
	else if(cellType == kWebsite)
	{
		NSString *website = [self.businessDetails objectForKey:@"website"];
		if(website.length)
		{
			return SINGLE_ROW_CELL_HEIGHT;
		}
		else
		{
			return 0;
		}
	}
	else if(cellType == kPhone)
	{
		NSString *phone = [self.businessDetails objectForKey:@"phone"];
		if(phone.length)
		{
			return SINGLE_ROW_CELL_HEIGHT;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return SINGLE_ROW_CELL_HEIGHT;
	}
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSURL *url = [[NSURL alloc] initWithString:[self.businessDetails objectForKey:@"website"] ];
//    [[UIApplication sharedApplication] openURL:url];

    switch ([self cellTypeForRow:indexPath.row]) {
        case kAddress:
        {
            [self launchMapApp];
            break;
        }
        case kPhone:
        {
#if SHOW_PHONE_CALL_ARE_YOU_SURE_ALERT
            NSString *msg = NSLocalizedString(@"Are you sure you want to call", nil);
            
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Place Call", nil)
                                  message:[NSString stringWithFormat:@"%@ %@?", msg, [self.businessGeneralInfo objectForKey:@"phone"]]
                                  delegate:self
                                  cancelButtonTitle:@"No"
                                  otherButtonTitles:@"Yes", nil];
            [alert show];
#else
            [self callBusinessNumber];
#endif
            break;
        }
        case kWebsite:
        {
            NSURL *url = [[NSURL alloc] initWithString:[self.businessDetails objectForKey:@"website"] ];
            [[UIApplication sharedApplication] openURL:url];
            break;
        }
        case kShare:
        {
            NSString *subject = [NSString stringWithFormat:@"%@ - %@ %@",
                             [self.businessDetails objectForKey:@"name"],
                             [self.businessDetails objectForKey:@"city"],
                             NSLocalizedString(@"Bitcoin | Airbitz", nil)
                             ];
            NSString *msg = [NSString stringWithFormat:@"%@ https://airbitz.co/biz/%@",
                                subject, [self.businessDetails objectForKey:@"bizId"]
            ];
            NSArray *activityItems = [NSArray arrayWithObjects: msg, nil, nil];
            UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
            [activityController setValue:subject forKey:@"subject"];
            if (shareView) {
                activityController.popoverPresentationController.permittedArrowDirections = 0;
                activityController.popoverPresentationController.sourceView = shareView;
            }
            [self presentViewController:activityController animated:YES completion:nil];
            break;
        }
        case kSocial:
        {
            NSArray *social = [self.businessDetails objectForKey:@"social"];
            if((social != nil) && (social != (id)[NSNull null]))
            {
                // TODO : refactor, possibly by including the URL into socialRows
                for (NSDictionary *data in social)
                {
                    NSString *type = [data objectForKey:@"social_type"];
                    NSNumber *typeEnum = [BD_Social_Cell getSocialTypeAsEnum:type];
                    for (NSDictionary *pair in socialRows)
                    {
                        NSNumber *socialType = [pair objectForKey:[NSNumber numberWithInt:(int)indexPath.row]];
                        if (typeEnum == socialType)
                        {
                            NSString *urlStr = [data objectForKey:@"social_url"];
                            NSURL *url = [[NSURL alloc] initWithString:urlStr];
                            [[UIApplication sharedApplication] openURL:url];
                        }
                    }
                }
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark UIAlertView delegates

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	//ABLog(2,@"Clicked button %li", (long)buttonIndex);
	if(buttonIndex == 1)
	{
		[self callBusinessNumber];
	}
}

#pragma mark UIPhotoGalleryDataSource methods
- (NSInteger)numberOfViewsInPhotoGallery:(UIPhotoGalleryView *)photoGallery
{
    if (details)
    {
        return [details count];
    }
    return 1;
}

- (NSURL*)photoGallery:(UIPhotoGalleryView *)photoGallery remoteImageURLAtIndex:(NSInteger)index
{
    NSString *imageKey;
    if (details)
    {
        imageKey = galleryController ? @"image" : @"thumbnail";
        NSDictionary *bizData = [details objectAtIndex:index % [details count]];
        NSString *imageRequest = [NSString stringWithFormat:@"%@%@", SERVER_URL, [bizData objectForKey:imageKey]];
        return [NSURL URLWithString:imageRequest];
    }
    return nil;
}

- (UIView*)photoGallery:(UIPhotoGalleryView *)photoGallery customViewAtIndex:(NSInteger)index
{
    if (!gallerySpinner)
    {
        CGRect frame = CGRectMake(0, 0, photoGallery.frame.size.width, photoGallery.frame.size.height);
        gallerySpinner = [[UIActivityIndicatorView alloc] initWithFrame:frame];
        [gallerySpinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    [gallerySpinner startAnimating];
    return gallerySpinner;
}

- (UIView*)customTopViewForGalleryViewController:(UIPhotoGalleryViewController *)galleryViewController
{
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    CGRect topFrame = CGRectMake(0, 0,
                                 self.view.frame.size.width, statusBarHeight + MINIMUM_BUTTON_SIZE);

    UIView *topView = [[UIView alloc] initWithFrame:topFrame];
    topView.backgroundColor = [UIColor clearColor];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = topView.frame;

    // Add colors to layer
    UIColor *topColor = UIColorFromARGB(0xa0000000);
    UIColor *centerColor = UIColorFromARGB(0x48000000);
    UIColor *endColor = UIColorFromARGB(0x00000000);

    gradient.colors = @[(id) topColor.CGColor,
            (id) centerColor.CGColor,
            (id) endColor.CGColor];

    [topView.layer insertSublayer:gradient atIndex:0];

    UIButton *btnDone = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect btnFrame = CGRectMake(self.view.frame.size.width - MINIMUM_BUTTON_SIZE, statusBarHeight,
                                 MINIMUM_BUTTON_SIZE, MINIMUM_BUTTON_SIZE);
    btnDone.frame = btnFrame;
    [btnDone setBackgroundImage:[UIImage imageNamed:@"btn_close_white.png"] forState:UIControlStateNormal];
    [btnDone addTarget:self
                action:@selector(returnFromGallery)
      forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:btnDone];
    return topView;
}

- (void)returnFromGallery
{
    [MainViewController lockSidebar:NO];
    [MainViewController animateOut:galleryController withBlur:NO complete:^(void) {
        galleryController = nil;
        [MainViewController showNavBarAnimated:YES];
        [MainViewController showTabBarAnimated:YES];
    }];

}

- (UIView*)customBottomViewForGalleryViewController:(UIPhotoGalleryViewController *)galleryViewController
{
    UIPhotoGallerySliderView *bottomView = [UIPhotoGallerySliderView CreateWithPhotoCount:[details count]
                                                                          andCurrentIndex:[galleryViewController initialIndex]];
    bottomView.delegate = galleryViewController;
    return bottomView;
}

#pragma mark UIPhotoGalleryDelegate methods

- (void)photoGallery:(UIPhotoGalleryView *)photoGallery didTapAtIndex:(NSInteger)index
{
    if (details && !galleryController)
    {
        galleryController = [[UIPhotoGalleryViewController alloc] init];
        [galleryController setScrollIndicator:NO];
        galleryController.galleryMode = UIPhotoGalleryModeImageRemote;
        galleryController.initialIndex = index;
        galleryController.showStatusBar = YES;
        galleryController.dataSource = self;

        [MainViewController hideNavBarAnimated:YES];
        [MainViewController hideTabBarAnimated:YES];
        [MainViewController lockSidebar:YES];

        [Util addSubviewControllerWithConstraints:self child:galleryController];
        [MainViewController animateSlideIn:galleryController];
    }
}

- (UIPhotoGalleryDoubleTapHandler)photoGallery:(UIPhotoGalleryView *)photoGallery doubleTapHandlerAtIndex:(NSInteger)index
{
    return UIPhotoGalleryDoubleTapHandlerNone;
}

@end


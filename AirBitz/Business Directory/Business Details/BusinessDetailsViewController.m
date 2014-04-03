//
//  BusinessDetailsViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/17/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "BusinessDetailsViewController.h"
#import "DL_URLServer.h"
#import "Server.h"
#import "BD_Address_Cell.h"
#import "BD_Phone_Cell.h"
#import "BD_Website_Cell.h"
#import "BD_Hours_Cell.h"
#import "BD_Details_Cell.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "RibbonView.h"

#import "CJSONDeserializer.h"

#define SHOW_PHONE_CALL_ARE_YOU_SURE_ALERT 0	/* set to 1 to show are you sure alert before dialing */

#define ADDRESS_CELL_ROW	0
#define PHONE_CELL_ROW		1
#define WEBSITE_CELL_ROW	2
#define HOURS_CELL_ROW		3
#define DETAILS_CELL_ROW	4
#define MAX_NUM_ROWS		5

#define SINGLE_ROW_CELL_HEIGHT	44

#define CLOSED_STRING	@"closed"

@interface BusinessDetailsViewController () <DL_URLRequestDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
{
	CGFloat hoursCellHeight;
	CGFloat detailsCellHeight;
	CGFloat detailsLabelWidth;
	BOOL needToLoadImageInfo;
	NSMutableArray *imageURLs;
	BOOL rowVisible[MAX_NUM_ROWS];
}

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIImageView *darkenImageView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *imageLoadActivityView;
@property (nonatomic, weak) IBOutlet UILabel *businessTitleLabel;
@property (nonatomic, weak) IBOutlet UIView *imageArea;
@property (nonatomic, weak) IBOutlet UILabel *categoriesLabel;
@property (nonatomic, weak) IBOutlet UILabel *BTC_DiscountLabel;

@property (nonatomic, strong) NSDictionary *businessDetails;

@end

@implementation BusinessDetailsViewController

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
	imageURLs = [[NSMutableArray alloc] init];
	hoursCellHeight = SINGLE_ROW_CELL_HEIGHT;
	detailsCellHeight = SINGLE_ROW_CELL_HEIGHT;
	
	self.darkenImageView.hidden = YES; //hide until business image gets loaded
	
	[self.imageLoadActivityView startAnimating];
	
	//get business details
	NSString *requestURL = [NSString stringWithFormat:@"%@/business/%@/?ll=%f,%f", SERVER_API, self.bizId, self.latLong.latitude, self.latLong.longitude];
	NSLog(@"Requesting: %@", requestURL);
	[[DL_URLServer controller] issueRequestURL:requestURL
									withParams:nil
									withObject:nil
								  withDelegate:self
							acceptableCacheAge:CACHE_24_HOURS
								   cacheResult:YES];
	
	//get Image URLs
	//http://api.airbitz.co:80/api/v1/business/2939/photos/
	/*requestURL = [NSString stringWithFormat:@"%@/business/%@/photos/", SERVER_API, self.bizId];
	//NSLog(@"Requesting: %@ for row: %i", requestURL, row);
	[[DL_URLServer controller] issueRequestURL:requestURL
									withParams:nil
									withObject:imageURLs
								  withDelegate:self
							acceptableCacheAge:CACHE_24_HOURS
								   cacheResult:YES];*/
				
	//self.businessTitleLabel.text = [self.businessGeneralInfo objectForKey:@"name"];
	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	[self.activityView startAnimating];
	
	UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
	gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:gesture];
}

-(void)didSwipe:(UIGestureRecognizer *)gestureRecognizer
{
	[self Back:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
	
	
	/*if(self.businessGeneralInfo)
	{
		//load the image for this business
		self.bizId = [self.businessGeneralInfo objectForKey:@"bizId"];
		NSDictionary *imageInfo = [self.businessGeneralInfo objectForKey:@"profile_image"];
		NSString *imageURL = [imageInfo objectForKey:@"image"];
		if(imageURL)
		{
			NSString *requestURL = [NSString stringWithFormat:@"%@%@", SERVER_URL, imageURL];
			NSLog(@"Requesting: %@", requestURL);
			[[DL_URLServer controller] issueRequestURL:requestURL
											withParams:nil
											withObject:self.imageView
										  withDelegate:self
									acceptableCacheAge:CACHE_24_HOURS
										   cacheResult:YES];
		}
	}
	if(self.bizId)
	{
		needToLoadImageInfo = YES;
		NSString *requestURL = [NSString stringWithFormat:@"%@/business/%@/", SERVER_API, self.bizId];
		//NSLog(@"Requesting: %@ for row: %i", requestURL, row);
		[[DL_URLServer controller] issueRequestURL:requestURL
										withParams:nil
										withObject:nil
									  withDelegate:self
								acceptableCacheAge:CACHE_24_HOURS
									   cacheResult:YES];
	}*/
}

-(void)dealloc
{
	[[DL_URLServer controller] cancelAllRequestsForDelegate:self];
}

-(void)setCategories
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
			 NSLog(@"error: %li", (long)error.code);
			 
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

-(void)callTelephoneNumber
{
	NSString *telNum = [NSString stringWithFormat:@"tel://%@", [self.businessDetails objectForKey:@"phone"]];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:telNum]];
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
	//look at business details data.  If data is missing for certain rows, mark those rows as invisible
	
	//Address (must have at least city and state)
	NSString *city = [self.businessDetails objectForKey:@"city"];
	NSString *state = [self.businessDetails objectForKey:@"state"];
	
	if((city != nil) && (city != (id)[NSNull null]))
	{
		if(city.length)
		{
			if((state != nil) && (state != (id)[NSNull null]))
			{
				if(state.length)
				{
					rowVisible[ADDRESS_CELL_ROW] = YES;
				}
			}
		}
	}
	
	//phone (must have length)
	NSString *phone = [self.businessDetails objectForKey:@"phone"];
	if((phone != nil) && (phone != (id)[NSNull null]))
	{
		if(phone.length)
		{
			rowVisible[PHONE_CELL_ROW] = YES;
		}
	}
	
	//web (must have length)
	NSString *web = [self.businessDetails objectForKey:@"website"];
	if((web != nil) && (web != (id)[NSNull null]))
	{
		if(web.length)
		{
			rowVisible[WEBSITE_CELL_ROW] = YES;
		}
	}
	
	//hours (must have at least one item)
	NSArray *daysOfOperation = [self.businessDetails objectForKey:@"hours"];
	if((daysOfOperation != nil) && (daysOfOperation != (id)[NSNull null]))
	{
		if(daysOfOperation.count)
		{
			rowVisible[HOURS_CELL_ROW] = YES;
		}
	}
	
	//description always visible
	rowVisible[DETAILS_CELL_ROW] = YES;
}

-(NSDictionary *)primaryImage:(NSArray *)arrayImageResults
{
	NSDictionary *primaryImage = nil;
	int count = 0;
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
					//NSLog(@"Found primary tag at object index: %i", count);
					primaryImage = dict;
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
	if(primaryImage == nil)
	{
		//NSLog(@"No primary tag.  Grabbing object zero");
		primaryImage = [arrayImageResults objectAtIndex:0];
	}
	return primaryImage;
}

#pragma mark - DLURLServer Callbacks

- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
	if(data)
	{
        if (DL_URLRequestStatus_Success == status)
        {
			//UIImageView *imageView = (UIImageView *)self.backgroundView;
			//imageView.image = [self darkenImage:[UIImage imageWithData:data] toLevel:0.5];
			//imageView.image = [UIImage imageWithData:data];
			//[images setObject:[UIImage imageWithData:data] forKey:object];
			if(object == imageURLs)
			{
				NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
				
				//NSLog(@"Results download returned: %@", jsonString );
				
				NSError *myError;
				NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
				NSDictionary *dict = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:&myError];
				
				NSArray *results = [dict objectForKey:@"results"];
				NSDictionary *imageInfo = [self primaryImage:results];
				
				//load image thumbnail
				NSString *imageRequest = [NSString stringWithFormat:@"%@%@", SERVER_URL, [imageInfo objectForKey:@"thumbnail"]];
				//NSLog(@"%@", imageRequest);
				[[DL_URLServer controller] issueRequestURL:imageRequest
												withParams:nil
												withObject:self.imageView
											  withDelegate:self
										acceptableCacheAge:CACHE_24_HOURS
											   cacheResult:YES];
			}
			else if(object == self.imageView)
			{
				((UIImageView *)object).image = [UIImage imageWithData:data];
				self.darkenImageView.hidden = NO;
				[self.imageLoadActivityView stopAnimating];
				
				//create the distance ribbon
				//NSString *distance = [self.businessDetails objectForKey:@"distance"];
				//if(distance && (distance != (id)[NSNull null]))
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
				[self setCategories];
			}
			else
			{
				if(object)
				{
				
					if([object isKindOfClass:[UIImageView class]])
					{
						((UIImageView *)object).image = [UIImage imageWithData:data];
						self.darkenImageView.hidden = NO;
					}
					[self.imageLoadActivityView stopAnimating];
					
					//create the distance ribbon
					NSString *distance = [self.businessDetails objectForKey:@"distance"];
					if(distance && (distance != (id)[NSNull null]))
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
					[self setCategories];
				}
				else
				{
					NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
					
					//NSLog(@"Results download returned: %@", jsonString );
					
					NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
					NSError *myError;
					self.businessDetails = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:&myError];
					
					[self determineVisibleRows];
					
					self.businessTitleLabel.text = [self.businessDetails objectForKey:@"name"];
					
					NSArray *daysOfOperation = [self.businessDetails objectForKey:@"hours"];
					
					if(daysOfOperation.count)
					{
						hoursCellHeight = SINGLE_ROW_CELL_HEIGHT + 16 * [daysOfOperation count] - 16;
					}
					else
					{
						hoursCellHeight = SINGLE_ROW_CELL_HEIGHT;
					}
					
					BD_Details_Cell *detailsCell = [self getDetailsCellForTableView:self.tableView];
					
					//calculate height of details cell
					CGSize size = [ [self.businessDetails objectForKey:@"description"] sizeWithFont:detailsCell.detailsLabel.font constrainedToSize:CGSizeMake(detailsLabelWidth, 999) lineBreakMode:NSLineBreakByWordWrapping];
					detailsCellHeight = size.height + 28.0;

					
					//cause table to reload hours and details cells to adjust for new heights
					//NSLog(@"business details loaded");
					
					/*
					[self.tableView beginUpdates];
					[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:ADDRESS_CELL_ROW inSection:0], [NSIndexPath indexPathForRow:PHONE_CELL_ROW inSection:0], [NSIndexPath indexPathForRow:WEBSITE_CELL_ROW inSection:0], [NSIndexPath indexPathForRow:HOURS_CELL_ROW inSection:0], [NSIndexPath indexPathForRow:DETAILS_CELL_ROW inSection:0], nil] withRowAnimation:UITableViewRowAnimationAutomatic];
					//[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:HOURS_CELL_ROW inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
					
					[self.tableView endUpdates];*/
					[self.tableView reloadData];
					/*
					if(needToLoadImageInfo)
					{
						needToLoadImageInfo = NO;
						NSDictionary *imageInfo = [self.businessGeneralInfo objectForKey:@"profile_image"];
						NSString *imageURL = [imageInfo objectForKey:@"image"];
						if(imageURL)
						{
							NSString *requestURL = [NSString stringWithFormat:@"%@%@", SERVER_URL, imageURL];
							NSLog(@"Requesting: %@", requestURL);
							[[DL_URLServer controller] issueRequestURL:requestURL
															withParams:nil
															withObject:self.imageView
														  withDelegate:self
													acceptableCacheAge:CACHE_24_HOURS
														   cacheResult:YES];
						}
					}*/
					
					//Get image URLs
					NSString *requestURL = [NSString stringWithFormat:@"%@/business/%@/photos/", SERVER_API, self.bizId];
					//NSLog(@"Requesting: %@ for row: %i", requestURL, row);
					[[DL_URLServer controller] issueRequestURL:requestURL
													withParams:nil
													withObject:imageURLs
												  withDelegate:self
											acceptableCacheAge:CACHE_24_HOURS
												   cacheResult:YES];
					
				}
			}
		}
    }
	[self.activityView stopAnimating];
}

#pragma mark Table View delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger numVisibleRows = 0;
	
	for(int i=0; i<MAX_NUM_ROWS; i++)
	{
		if(rowVisible[i])
		{
			numVisibleRows++;
		}
	}
	//NSLog(@"Number of table rows: %i", numVisibleRows);
	return numVisibleRows;
}

-(BD_Address_Cell *)getAddressCellForTableView:(UITableView *)tableView
{
	BD_Address_Cell *cell;
	static NSString *cellIdentifier = @"BD_Address_Cell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[BD_Address_Cell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	return cell;
}

-(BD_Phone_Cell *)getPhoneCellForTableView:(UITableView *)tableView
{
	BD_Phone_Cell *cell;
	static NSString *cellIdentifier = @"BD_Phone_Cell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[BD_Phone_Cell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	return cell;
}

-(BD_Website_Cell *)getWebsiteCellForTableView:(UITableView *)tableView
{
	BD_Website_Cell *cell;
	static NSString *cellIdentifier = @"BD_Website_Cell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[BD_Website_Cell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	return cell;
}

-(BD_Hours_Cell *)getHoursCellForTableView:(UITableView *)tableView
{
	BD_Hours_Cell *cell;
	static NSString *cellIdentifier = @"BD_Hours_Cell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[BD_Hours_Cell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	return cell;
}

-(BD_Details_Cell *)getDetailsCellForTableView:(UITableView *)tableView
{
	BD_Details_Cell *cell;
	static NSString *cellIdentifier = @"BD_Details_Cell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[BD_Details_Cell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	detailsLabelWidth = cell.detailsLabel.frame.size.width;
	return cell;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = [indexPath row];
	UITableViewCell *cell;
	
	
	int cellType = [self cellTypeForRow:indexPath.row];
	
	UIImage *cellImage;
	//if((row == 0) && (row == [tableView numberOfRowsInSection:indexPath.section] - 1))
	if([tableView numberOfRowsInSection:indexPath.section] == 1)
	{
		cellImage = [UIImage imageNamed:@"bd_cell_single"];
	}
	else
	{
		if(row == 0)
		{
			cellImage = [UIImage imageNamed:@"bd_cell_top"];
		}
		else
			if(row == [tableView numberOfRowsInSection:indexPath.section] - 1)
			{
				cellImage = [UIImage imageNamed:@"bd_cell_bottom_white"];
			}
			else
			{
				cellImage = [UIImage imageNamed:@"bd_cell_middle"];
			}
	}
	
	if (cellType == ADDRESS_CELL_ROW)
	{
		//address cell
		BD_Address_Cell *addressCell = [self getAddressCellForTableView:tableView];
		if(self.businessDetails)
		{
			addressCell.topAddress.text = [self.businessDetails objectForKey:@"address"];
			addressCell.botAddress.text = [NSString stringWithFormat:@"%@, %@  %@", [self.businessDetails objectForKey:@"city"], [self.businessDetails objectForKey:@"state"], [self.businessDetails objectForKey:@"postalcode"]];
			addressCell.bkg_image.image = cellImage;
		}
		cell = addressCell;
	}
	else if(cellType == PHONE_CELL_ROW)
	{
		//phone cell
		BD_Phone_Cell *phoneCell = [self getPhoneCellForTableView:tableView];
		phoneCell.phoneLabel.text = [self.businessDetails objectForKey:@"phone"];
		phoneCell.bkg_image.image = cellImage;
		cell = phoneCell;
	}
	else if(cellType == WEBSITE_CELL_ROW)
	{
		//website cell
		BD_Website_Cell *websiteCell = [self getWebsiteCellForTableView:tableView];
		websiteCell.websiteLabel.text = [self.businessDetails objectForKey:@"website"];
		websiteCell.bkg_image.image = cellImage;
		cell = websiteCell;
	}
	else if(cellType == HOURS_CELL_ROW)
	{
		BD_Hours_Cell *hoursCell = [self getHoursCellForTableView:tableView];
		hoursCell.bkg_image.image = cellImage;
		if(self.businessDetails)
		{
			[hoursCell.activityView stopAnimating];
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
			
			//apply new strings to text labels
			hoursCell.dayLabel.text = [dayString copy];
			[hoursCell.dayLabel sizeToFit];
			hoursCell.timeLabel.text = [hoursString copy];
			[hoursCell.timeLabel sizeToFit];
		}
		cell = hoursCell;
	}
	else if(cellType == DETAILS_CELL_ROW)
	{
		//details cell
		BD_Details_Cell *detailsCell = [self getDetailsCellForTableView:tableView];
		detailsCell.bkg_image.image = cellImage;
		if(self.businessDetails)
		{
			[detailsCell.activityView stopAnimating];
			detailsCell.detailsLabel.text = [self.businessDetails objectForKey:@"description"];
			[detailsCell.detailsLabel sizeToFit];
		}
		cell = detailsCell;
	}
	
	return cell;
}

-(int)cellTypeForRow:(NSInteger)row
{
	int cellType;
	int count = 0;
	for(cellType = 0; cellType < MAX_NUM_ROWS; cellType++)
	{
		if(rowVisible[cellType])
		{
			if(count == row)
			{
				break;
			}
			count++;
		}
	}
	return cellType;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	int cellType = [self cellTypeForRow:indexPath.row];
	
	if(cellType == HOURS_CELL_ROW)
	{
		return hoursCellHeight;
	}
	else if(cellType == DETAILS_CELL_ROW)
	{
		//NSLog(@"returning details cell height of %f", detailsCellHeight);
		return detailsCellHeight;
	}
	else if(cellType == WEBSITE_CELL_ROW)
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
	else if(cellType == PHONE_CELL_ROW)
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
	if([self cellTypeForRow:indexPath.row] == ADDRESS_CELL_ROW)
	{
		[self launchMapApp];
	}
	else if([self cellTypeForRow:indexPath.row] == PHONE_CELL_ROW)
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
		[self callTelephoneNumber];
		#endif
	}
	else if([self cellTypeForRow:indexPath.row] == WEBSITE_CELL_ROW)
	{
		NSURL *url = [[NSURL alloc] initWithString:[self.businessDetails objectForKey:@"website"] ];
		[[UIApplication sharedApplication] openURL:url];
	}
}

#pragma mark UIAlertView delegates

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	//NSLog(@"Clicked button %li", (long)buttonIndex);
	if(buttonIndex == 1)
	{
		[self callTelephoneNumber];
	}
}

@end


//
//  AutoCompleteTextField.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/6/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "AutoCompleteTextField.h"
#import <AddressBook/AddressBook.h>
#import "DL_URLServer.h"
#import "Server.h"
#import "Location.h"
#import "CJSONDeserializer.h"

@interface AutoCompleteTextField () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, DL_URLRequestDelegate>
{
	NSArray *namesArray;		//list of names from contacts
	NSMutableArray *businessNames;	//list of names from business search
	NSMutableArray *searchArray;
	UITableView *autoCompleteTableView;
	
	NSArray *autoCompleteResults;	//contacts and business all merged together and sorted
}
@end

@implementation AutoCompleteTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib
{
	CGRect frame = self.frame;
	frame.origin.y += (frame.size.height + 5.0);
	frame.size.height *= 5;
	
	autoCompleteTableView = [[UITableView alloc] initWithFrame:frame];
	businessNames = [[NSMutableArray alloc] init];
	
	autoCompleteTableView.delegate = self;
	autoCompleteTableView.dataSource = self;
	autoCompleteTableView.layer.cornerRadius = 6.0;
	autoCompleteTableView.scrollEnabled = YES;
	autoCompleteTableView.allowsSelection = YES;
	autoCompleteTableView.userInteractionEnabled = YES;
	
	[self.superview addSubview:autoCompleteTableView];
	[self hideTableViewAnimated:NO];
	[self generateListOfContactNames];
	
	self.delegate = self;
}

-(void)dealloc
{
	[autoCompleteTableView removeFromSuperview];
	businessNames = nil;
	autoCompleteTableView = nil;
}


- (void)generateListOfContactNames
{
    searchArray = [[NSMutableArray alloc]init];
    
	CFErrorRef error;
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
	
	__block BOOL accessGranted = NO;
	
	if (ABAddressBookRequestAccessWithCompletion != NULL)
	{
		// we're on iOS 6
		dispatch_semaphore_t sema = dispatch_semaphore_create(0);
		
		ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
												 {
													 accessGranted = granted;
													 dispatch_semaphore_signal(sema);
												 });
		
		dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
		//dispatch_release(sema);
	}
	else
	{
		// we're on iOS 5 or older
		accessGranted = YES;
	}
	
	if (accessGranted)
	{
		CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
		NSMutableArray *allNames = [[NSMutableArray alloc] initWithCapacity:CFArrayGetCount(people)];
		for (CFIndex i = 0; i < CFArrayGetCount(people); i++)
		{
			ABRecordRef person = CFArrayGetValueAtIndex(people, i);
			
			NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
			NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
			
			
			[allNames addObject:[NSString stringWithFormat:@"%@ %@", firstName, lastName]];
		}
		
		namesArray = allNames;
		autoCompleteResults = allNames; //start autoCompleteResults with something (don't have business names at this point)
		NSLog(@"All Email %@", namesArray);
	}
}

-(void)hideTableViewAnimated:(BOOL)animated
{
	if(animated)
	{
		[UIView animateWithDuration:0.25
							  delay:0.0
							options:UIViewAnimationOptionCurveLinear
						 animations:^
		 {
			 autoCompleteTableView.alpha = 0.0;
		 }
		completion:^(BOOL finished)
		 {
			
		 }];
	}
	else
	{
		autoCompleteTableView.alpha = 0.0;
	}
}

-(void)showTableViewAnimated:(BOOL)animated
{
	if(animated)
	{
		[UIView animateWithDuration:0.25
							  delay:0.0
							options:UIViewAnimationOptionCurveLinear
						 animations:^
		 {
			 autoCompleteTableView.alpha = 1.0;
		 }
						 completion:^(BOOL finished)
		 {
			 
		 }];
	}
	else
	{
		autoCompleteTableView.alpha = 1.0;
	}
}

-(void)addLocationToQuery:(NSMutableString *)query
{
	if ([query rangeOfString:@"&ll="].location == NSNotFound)
	{
		CLLocation *location = [Location controller].curLocation;
		if(location) //can be nil if user has locationServices turned off
		{
			NSString *locationString = [NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude];
			[query appendFormat:@"&ll=%@", locationString];
		}
	}
	else
	{
		//NSLog(@"string already contains ll");
	}
}

-(void)mergeAutoCompleteResults
{
	NSMutableSet *set = [NSMutableSet setWithArray:searchArray];
	[set addObjectsFromArray:businessNames];
	
	autoCompleteResults = [[set allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	[autoCompleteTableView reloadData];
}

#pragma mark UITextField delegates

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString * searchStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
	[[DL_URLServer controller] cancelAllRequestsForDelegate:self];
	NSMutableString *urlString = [[NSMutableString alloc] init];
	
	NSString *searchTerm = [textField.text stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	if(searchTerm == nil)
	{
		//there are non ascii characters in the string
		searchTerm = @" ";
		
	}
	else
	{
		searchTerm = textField.text;
	}
	
	[urlString appendString:[NSString stringWithFormat:@"%@/autocomplete-business/?term=%@", SERVER_API, searchTerm]];
	
	[self addLocationToQuery:urlString];
	//NSLog(@"Autocomplete Query: %@", [urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]);
	if(urlString != (id)[NSNull null])
	{
		[[DL_URLServer controller] issueRequestURL:[urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]
										withParams:nil
										withObject:textField
									  withDelegate:self
								acceptableCacheAge:15.0
									   cacheResult:YES];
	}
	
    [self searchAutocompleteEntriesWithSubstring:searchStr];
    
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self resignFirstResponder];
	[self hideTableViewAnimated:YES];
	return YES;
}


#pragma mark UITableView delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [autoCompleteResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"AutoCompleteCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    //5.1 you do not need this if you have set SettingsCell as identifier in the storyboard (else you can remove the comments on this code)
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    
    cell.textLabel.text = [autoCompleteResults objectAtIndex:indexPath.row];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.text = [autoCompleteResults objectAtIndex:indexPath.row];
    [self hideTableViewAnimated:YES];
    [self resignFirstResponder];
}

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring
{
    NSLog(@"Search Text %@",substring);
    
    [searchArray removeAllObjects];
    
    for(NSString *curString in namesArray)
    {
        NSRange substringRange = [curString rangeOfString:substring options:NSCaseInsensitiveSearch];
        //
		if(substringRange.length > 1)
        {
            [searchArray addObject:curString];
        }
		else if (substringRange.location == 0)
		{
			[searchArray addObject:curString];
		}
    }
    
    if ([searchArray count] > 0)
    {
		[self showTableViewAnimated:YES];
    }
	else
	{
		[self showTableViewAnimated:NO];
	}
    
    //[autoCompleteTableView reloadData];
	//[self mergeAutoCompleteResults];
}

#pragma mark - DLURLServer Callbacks

- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
	NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
	
	//NSLog(@"Results download returned: %@", jsonString );
	
	NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
	NSError *myError;
	NSDictionary *dictFromServer = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:&myError];
	
	
	NSArray *searchResultsArray;
	//NSLog(@"Got search results: %@", [dictFromServer objectForKey:@"results"]);
	searchResultsArray = [[dictFromServer objectForKey:@"results"] mutableCopy];

	//build array of business (prune categories out of list)
	[businessNames removeAllObjects];
	for(NSDictionary *dict in searchResultsArray)
	{
		NSString *type = [dict objectForKey:@"type"];
		if([type isEqualToString:@"business"])
		{
			[businessNames addObject:[dict objectForKey:@"text"]];
		}
	}
	
	if(searchResultsArray.count)
	{
		NSLog(@"Results: %@", businessNames);
	}
	else
	{
		NSLog(@"SEARCH RESULTS ARRAY IS EMPTY!");
	}

	[self mergeAutoCompleteResults];
}


@end

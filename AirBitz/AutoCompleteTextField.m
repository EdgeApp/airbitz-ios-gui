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
#import "Util.h"

#define USE_AUTOCOMPLETE_QUERY 0

@interface AutoCompleteTextField () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, DL_URLRequestDelegate>
{
	NSArray *contactsArray;		//list of all names from contacts
	NSMutableArray *foundBusinessNames;	//list of found names from business search
	NSMutableArray *foundContactsArray;	//list of found names from contacts search
	UITableView *autoCompleteTableView;
	
	NSArray *autoCompleteResults;	//found Contacts and found Businesses all merged together and sorted
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
	
	[super awakeFromNib];
	
	if(_tableAbove)
	{
		//this isn't getting called
		frame.size.height *= 5;
		frame.origin.y = 200.0; //cw hack
	}
	else
	{
		frame.origin.y += (frame.size.height + 5.0);
		frame.size.height *= 5;
	}
	
	autoCompleteTableView = [[UITableView alloc] initWithFrame:frame];
	foundBusinessNames = [[NSMutableArray alloc] init];
	
	autoCompleteTableView.delegate = self;
	autoCompleteTableView.dataSource = self;
	autoCompleteTableView.layer.cornerRadius = 6.0;
	autoCompleteTableView.scrollEnabled = YES;
	autoCompleteTableView.allowsSelection = YES;
	autoCompleteTableView.userInteractionEnabled = YES;
	
	[self.superview.superview.superview addSubview:autoCompleteTableView];
	[self hideTableViewAnimated:NO];
	[self generateListOfContactNames];
	
	//self.delegate = self;  <-- BAD!  App will hang
}

-(void)setTableBelow:(BOOL)tableBelow
{
	_tableBelow = tableBelow;
	
	CGRect frame = autoCompleteTableView.frame;
	frame.origin.y = 130.0; // th hack
	autoCompleteTableView.frame = frame;
}

-(void)setTableAbove:(BOOL)tableAbove
{
	_tableAbove = tableAbove;
	
	CGRect frame = autoCompleteTableView.frame;
	frame.origin.y = 150.0;
	autoCompleteTableView.frame = frame;
}

-(void)dealloc
{
	[autoCompleteTableView removeFromSuperview];
	foundBusinessNames = nil;
	autoCompleteTableView = nil;
}


- (void)generateListOfContactNames
{
    foundContactsArray = [[NSMutableArray alloc]init];
    
	CFErrorRef error;
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
	
	CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
	NSMutableArray *allNames = [[NSMutableArray alloc] initWithCapacity:CFArrayGetCount(people)];
	for (CFIndex i = 0; i < CFArrayGetCount(people); i++)
	{
		ABRecordRef person = CFArrayGetValueAtIndex(people, i);

		NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
		NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));


		[allNames addObject:[NSString stringWithFormat:@"%@ %@", firstName, lastName]];
		CFRelease((__bridge CFTypeRef)firstName);
		CFRelease((__bridge CFTypeRef)lastName);
	}
	CFRelease(people);

	contactsArray = allNames;
	autoCompleteResults = allNames; //start autoCompleteResults with something (don't have business names at this point)
	ABLog(2,@"All Email %@", contactsArray);
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
	[autoCompleteTableView.superview bringSubviewToFront:autoCompleteTableView];
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
		//ABLog(2,@"string already contains ll");
	}
}

-(void)mergeAutoCompleteResults
{
	NSMutableSet *set = [NSMutableSet setWithArray:foundContactsArray];
	[set addObjectsFromArray:foundBusinessNames];
	
	autoCompleteResults = [[set allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	[autoCompleteTableView reloadData];
}

#pragma mark UITextField delegates

-(void)kickOffSearchWithString:(NSString *)searchStr
{
	[[DL_URLServer controller] cancelAllRequestsForDelegate:self];
	NSMutableString *urlString = [[NSMutableString alloc] init];
	
	NSString *searchTerm = [searchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	if(searchTerm == nil)
	{
		//there are non ascii characters in the string
		searchTerm = @" ";
		
	}
	//else
	//{
	//searchTerm = searchStr;
	//}
	
#if USE_AUTOCOMPLETE_QUERY
	[urlString appendString:[NSString stringWithFormat:@"%@/autocomplete-business/?term=%@", SERVER_API, searchTerm]];
	
	[self addLocationToQuery:urlString];
	
	if(urlString != (id)[NSNull null])
	{
		ABLog(2,@"Autocomplete Query: %@", [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
		[[DL_URLServer controller] issueRequestURL:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
										withParams:nil
										withObject:self
									  withDelegate:self
								acceptableCacheAge:15.0
									   cacheResult:YES];
	}
#else
	[urlString appendString:[NSString stringWithFormat:@"%@/search/?term=%@&radius=48283&sort=1", SERVER_API, searchTerm]];
	
	[self addLocationToQuery:urlString];
	
	if(urlString != (id)[NSNull null])
	{
		ABLog(2,@"Autocomplete Query: %@", [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
		[[DL_URLServer controller] issueRequestURL:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
										withParams:nil
										withObject:self
									  withDelegate:self
								acceptableCacheAge:15.0
									   cacheResult:YES];
	}
#endif
}

//call these from our parent's UITextField delegates (couldn't make ourself our own delegate.  Would cause infinite recursion hang)
-(void)autoCompleteTextFieldShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	//call from - (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
    NSString * searchStr = [self.text stringByReplacingCharactersInRange:range withString:string];
    
	if(self.arrayAutoCompleteStrings.count)
	{
		autoCompleteResults = self.arrayAutoCompleteStrings;
	}
	else
	{
		[self kickOffSearchWithString:searchStr];
		
		
    }
	[self searchAutocompleteEntriesWithSubstring:searchStr];
    //return YES;
}

-(void)autoCompleteTextFieldDidBeginEditing
{
	if(self.arrayAutoCompleteStrings.count)
	{
		autoCompleteResults = self.arrayAutoCompleteStrings;
	}
	else
	{
		[self kickOffSearchWithString:self.text];
		
		
    }
	[self searchAutocompleteEntriesWithSubstring:self.text];
}

-(void)autoCompleteTextFieldShouldReturn
{
	//[self resignFirstResponder];
	[[DL_URLServer controller] cancelAllRequestsForDelegate:self];
	[self hideTableViewAnimated:YES];
	//return YES;
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
	if([self.autoTextFieldDelegate respondsToSelector:@selector(autoCompleteTextFieldDidSelectFromTable:)])
	{
		[self.autoTextFieldDelegate autoCompleteTextFieldDidSelectFromTable:self];
	}
}

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring
{
    ABLog(2,@"Search Text %@",substring);
    
    [foundContactsArray removeAllObjects];
    
	if(self.arrayAutoCompleteStrings.count)
	{
		if([substring isEqualToString:@""])
		{
			[foundContactsArray addObjectsFromArray:self.arrayAutoCompleteStrings];
		}
		else
		{
			for(NSString *curString in self.arrayAutoCompleteStrings)
			{
				NSArray *myArray = [curString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
				NSString *theString;
				//search for the stuff after the colon (i.e. don't search for Income: Expense: etc.)
				if(myArray.count == 2)
				{
					theString = [myArray objectAtIndex:1];
				}
				else
				{
					theString = [myArray objectAtIndex:0];
				}
				NSRange substringRange = [theString rangeOfString:substring options:NSCaseInsensitiveSearch];
				//
				if(substringRange.length > 1)
				{
					[foundContactsArray addObject:curString];
				}
				else if (substringRange.location == 0)
				{
					[foundContactsArray addObject:curString];
				}
			}
		}
	}
	else
	{
		for(NSString *curString in contactsArray)
		{
			NSRange substringRange = [curString rangeOfString:substring options:NSCaseInsensitiveSearch];
			//
			if(substringRange.length > 1)
			{
				[foundContactsArray addObject:curString];
			}
			else if (substringRange.location == 0)
			{
				[foundContactsArray addObject:curString];
			}
		}
	}
    
    if ([foundContactsArray count] > 0)
    {
		[self showTableViewAnimated:YES];
    }
	/*else
	{
		[self hideTableViewAnimated:YES];
	}*/
	if(self.arrayAutoCompleteStrings)
	{
		autoCompleteResults = foundContactsArray;
		[autoCompleteTableView reloadData];
	}
}

#pragma mark - DLURLServer Callbacks

- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
	NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
	
	//ABLog(2,@"Results download returned: %@", jsonString );
	
	NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
	NSError *myError;
	NSDictionary *dictFromServer = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:&myError];
	
	
	NSArray *searchResultsArray;
	//ABLog(2,@"Got search results: %@", [dictFromServer objectForKey:@"results"]);
	searchResultsArray = [[dictFromServer objectForKey:@"results"] mutableCopy];

	//build array of business (prune categories out of list)
	[foundBusinessNames removeAllObjects];
	

	for(NSDictionary *dict in searchResultsArray)
	{
#if USE_AUTOCOMPLETE_QUERY
		NSString *type = [dict objectForKey:@"type"];
		if([type isEqualToString:@"business"])
		{
			[foundBusinessNames addObject:[dict objectForKey:@"text"]];
		}
#else
		NSString *name = [dict objectForKey:@"name"];
		if(name && name != (id)[NSNull null])
		{
			[foundBusinessNames addObject:name];
		}
#endif
	}

	if(searchResultsArray.count)
	{
		ABLog(2,@"Results: %@", foundBusinessNames);
	}
	else
	{
		ABLog(2,@"SEARCH RESULTS ARRAY IS EMPTY!");
	}
	if (([foundContactsArray count] > 0) || (foundBusinessNames.count))
    {
		[self showTableViewAnimated:YES];
    }
	/*else
	{
		[self hideTableViewAnimated:YES];
	}*/
	

	[self mergeAutoCompleteResults];
}


@end

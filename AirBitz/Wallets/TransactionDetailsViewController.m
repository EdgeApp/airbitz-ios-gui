//
//  TransactionDetailsViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "TransactionDetailsViewController.h"
#import "CoreBridge.h"
#import "User.h"
#import "NSDate+Helper.h"
#import "ABC.h"
#import "InfoView.h"
#import "CalculatorView.h"
#import "PickerTextView.h"
#import "StylizedTextField.h"
#import "DL_URLServer.h"
#import "Server.h"
#import "Location.h"
#import "CJSONDeserializer.h"
#import "Util.h"
#import "CommonTypes.h"
#import "PayeeCell.h"

#define ARRAY_CATEGORY_PREFIXES         @[@"Expense:",@"Income:",@"Transfer:"]

#define PICKER_MAX_CELLS_VISIBLE 4

#define USE_AUTOCOMPLETE_QUERY 0

#define DOLLAR_CURRENCY_NUM	840

#define TEXTFIELD_VERTICAL_SPACE_OFFSET	7.0 /* how much space between screen header and textField when textField is scrolled all the way to the top */

#define SEARCH_RADIUS        16093
#define CACHE_AGE_SECS       25
#define CACHE_IMAGE_AGE_SECS (60 * 60)

@interface TransactionDetailsViewController () <UITextFieldDelegate, InfoViewDelegate, CalculatorViewDelegate, DL_URLRequestDelegate, UITableViewDataSource, UITableViewDelegate, PickerTextViewDelegate>
{
	UITextField     *_activeTextField;
	CGRect          _originalFrame;
	CGRect          _originalHeaderFrame;
	CGRect          _originalContentFrame;
	CGRect          _originalScrollableContentFrame;
	UITableView     *_autoCompleteTable; //table of autoComplete search results (including address book entries)
}

@property (nonatomic, weak) IBOutlet UIView                 *headerView;
@property (nonatomic, weak) IBOutlet UIView                 *contentView;
@property (nonatomic, weak) IBOutlet UIView                 *scrollableContentView;
@property (nonatomic, weak) IBOutlet UILabel                *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel                *walletLabel;
@property (nonatomic, weak) IBOutlet UILabel                *bitCoinLabel;
@property (nonatomic, weak) IBOutlet UIButton               *advancedDetailsButton;
@property (nonatomic, weak) IBOutlet UIButton               *doneButton;
@property (nonatomic, weak) IBOutlet UITextField            *fiatTextField;
@property (nonatomic, weak) IBOutlet UITextField            *notesTextField;
@property (nonatomic, weak) IBOutlet StylizedTextField      *nameTextField;
@property (nonatomic, weak) IBOutlet CalculatorView         *keypadView;
@property (weak, nonatomic) IBOutlet PickerTextView         *pickerTextCategory;

@property (nonatomic, strong)        NSArray                *arrayCategories;
@property (nonatomic, strong)        NSArray                *arrayContacts;
@property (nonatomic, strong)        NSArray                *arrayBusinesses;
@property (nonatomic, strong)        NSArray                *arrayAutoComplete;
@property (nonatomic, strong)        NSMutableDictionary    *dictImages; // images for the contacts and businesses
@property (nonatomic, strong)        NSDictionary           *dictThumbnailURLs; // urls for business thumbnails

@end

@implementation TransactionDetailsViewController

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
    [Util resizeView:self.view withDisplayView:self.contentView];

    self.arrayAutoComplete = @[];
    self.dictImages = [[NSMutableDictionary alloc] init];
    self.dictThumbnailURLs = [[NSDictionary alloc] init];

    // get the list of businesses
    [self generateListOfBusinesses];

    // update our array of categories
    [self loadCategories];

    // set the keyboard return button based upon mode
    self.nameTextField.returnKeyType = (self.bOldTransaction ? UIReturnKeyDone : UIReturnKeyNext);
    self.pickerTextCategory.textField.returnKeyType = (self.bOldTransaction ? UIReturnKeyDone : UIReturnKeyNext);
    self.notesTextField.returnKeyType = UIReturnKeyDone;

    // load all the names from the address book
	[self generateListOfContactNames];

	UIImage *blue_button_image = [self stretchableImage:@"btn_blue.png"];
	[self.advancedDetailsButton setBackgroundImage:blue_button_image forState:UIControlStateNormal];
	[self.advancedDetailsButton setBackgroundImage:blue_button_image forState:UIControlStateSelected];

	self.keypadView.delegate = self;
    self.keypadView.textField = self.fiatTextField;
	
	self.fiatTextField.delegate = self;
	self.fiatTextField.inputView = self.keypadView;
	self.notesTextField.delegate = self;
	self.nameTextField.delegate = self;

    // get a callback when there are changes
    [self.nameTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    // set up the specifics on our picker text view
    self.pickerTextCategory.textField.borderStyle = UITextBorderStyleNone;
    self.pickerTextCategory.textField.backgroundColor = [UIColor clearColor];
    self.pickerTextCategory.textField.font = [UIFont systemFontOfSize:14];
    self.pickerTextCategory.textField.clearButtonMode = UITextFieldViewModeAlways;
    self.pickerTextCategory.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.pickerTextCategory.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.pickerTextCategory.textField.spellCheckingType = UITextSpellCheckingTypeNo;
    self.pickerTextCategory.textField.textColor = [UIColor whiteColor];
    [self.pickerTextCategory setTopMostView:self.view];
    //self.pickerTextCategory.pickerMaxChoicesVisible = PICKER_MAX_CELLS_VISIBLE;
    self.pickerTextCategory.cropPointBottom = 360; // magic number
    self.pickerTextCategory.delegate = self;

	
    self.dateLabel.text = [NSDate stringFromDate:self.transaction.date withFormat:[NSDate timestampFormatString]];
	self.nameTextField.text = self.transaction.strName;
    self.notesTextField.text = self.transaction.strNotes;
    self.pickerTextCategory.textField.text = self.transaction.strCategory;

    self.bitCoinLabel.text = [CoreBridge formatSatoshi:self.transaction.amountSatoshi];

	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

	self.nameTextField.placeholder = NSLocalizedString(@"Payee or Business Name", nil);
    if (!self.bOldTransaction)
    {
        [self.nameTextField becomeFirstResponder];
    }

	_originalHeaderFrame = self.headerView.frame;
	_originalContentFrame = self.contentView.frame;
	_originalScrollableContentFrame = self.scrollableContentView.frame;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];

	if (_originalFrame.size.height == 0)
	{
		CGRect frame = self.view.frame;
		frame.origin.x = 0;
		frame.origin.y = 0;
		_originalFrame = frame;
		
		if (_transactionDetailsMode == TD_MODE_SENT)
		{
			self.walletLabel.text = [NSString stringWithFormat:@"From: %@", self.transaction.strWalletName];
		}
		else
		{
			self.walletLabel.text = [NSString stringWithFormat:@"To: %@", self.transaction.strWalletName];
		}
		
        if (self.transaction.amountFiat == 0)
		{
            double currency;
            tABC_Error error;
            ABC_SatoshiToCurrency(self.transaction.amountSatoshi, &currency, DOLLAR_CURRENCY_NUM, &error);
            self.fiatTextField.text = [NSString stringWithFormat:@"%.2f", currency];
        }
		else
		{
            self.fiatTextField.text = [NSString stringWithFormat:@"%.2f", self.transaction.amountFiat];
        }

        // push the calculator keypad to below the bottom of the screen
		frame = self.keypadView.frame;
		frame.origin.y = frame.origin.y + frame.size.height;
		self.keypadView.frame = frame;
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self.delegate TransactionDetailsViewControllerDone:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [DL_URLServer cancelPreviousPerformRequestsWithTarget:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Action Methods

- (IBAction)Done
{
    [self resignAllResponders];

    // add the category if we didn't have it
    [self addCategory:self.pickerTextCategory.textField.text];

    self.transaction.strName = [self.nameTextField text];
    self.transaction.strNotes = [self.notesTextField text];
    self.transaction.strCategory = [self.pickerTextCategory.textField text];
    self.transaction.amountFiat = [[self.fiatTextField text] doubleValue];

    [CoreBridge storeTransaction: self.transaction];
	[self.delegate TransactionDetailsViewControllerDone:self];
}

- (IBAction)AdvancedDetails
{
    [self resignAllResponders];

	//spawn infoView
	InfoView *iv = [InfoView CreateWithDelegate:self];
	iv.frame = self.view.bounds;
	
	NSString* path = [[NSBundle mainBundle] pathForResource:@"transactionDetails" ofType:@"html"];
	NSString* content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	
	//transaction ID
	content = [content stringByReplacingOccurrencesOfString:@"*1" withString:self.transaction.strID];
	//Total sent
	content = [content stringByReplacingOccurrencesOfString:@"*2" withString:[NSString stringWithFormat:@"BTC %.5f", ABC_SatoshiToBitcoin(self.transaction.amountSatoshi)]];
	//source
#warning TODO: source and destination addresses are faked for now, so's miner's fee.
	content = [content stringByReplacingOccurrencesOfString:@"*3" withString:@"1.002<BR>1K7iGspRyQsposdKCSbsoXZntsJ7DPNssN<BR>0.0345<BR>1z8fkj4igkh498thgkjERGG23fhD4gGaNSHa<BR>0.2342<BR>1Wfh8d9csf987gT7H6fjkhd0fkj4tkjhf8S4er3"];
	//Destination
	content = [content stringByReplacingOccurrencesOfString:@"*4" withString:@"1M6TCZJTdVX1xGC8iAcQLTDtRKF2zM6M38<BR>1.27059<BR>12HUD1dsrc9dhQgGtWxqy8dAM2XDgvKdzq<BR>0.00001"];
	//Miner Fee
	content = [content stringByReplacingOccurrencesOfString:@"*5" withString:@"0.0001"];
	iv.htmlInfoToDisplay = content;
	[self.view addSubview:iv];
}

#pragma mark - Misc Methods


- (void)generateListOfBusinesses
{
    // start with nothing
    self.arrayBusinesses = @[];

    // query the server
    [[DL_URLServer controller] cancelAllRequestsForDelegate:self];

	NSMutableString *strURL = [[NSMutableString alloc] init];

    // create the search query
    [strURL appendString:[NSString stringWithFormat:@"%@/search/?radius=%d&sort=%d", SERVER_API, SEARCH_RADIUS, SORT_RESULT_DISTANCE]];

    // add our location
    [self addLocationToQuery:strURL];

    // run the search
    //NSLog(@"Query: %@", strURL);
    [[DL_URLServer controller] issueRequestURL:[strURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                    withParams:nil
                                    withObject:nil
                                  withDelegate:self
                            acceptableCacheAge:CACHE_AGE_SECS
                                   cacheResult:YES];
}

- (void)generateListOfContactNames
{
    NSMutableArray *arrayContacts = [[NSMutableArray alloc] init];

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
		for (CFIndex i = 0; i < CFArrayGetCount(people); i++)
		{
			ABRecordRef person = CFArrayGetValueAtIndex(people, i);

            NSString *strFullName = [Util getNameFromAddressRecord:person];
            if ([strFullName length])
            {
                if ([arrayContacts indexOfObject:strFullName] == NSNotFound)
                {
                    // add this contact
                    [arrayContacts addObject:strFullName];

                    // does this contact has an image
                    if (ABPersonHasImageData(person))
                    {
                        NSData *data = (__bridge_transfer NSData*)ABPersonCopyImageData(person);
                        [self.dictImages setObject:[UIImage imageWithData:data] forKey:strFullName];
                    }
                }
            }
		}
	}

    // store the final
    self.arrayContacts = arrayContacts;
    //NSLog(@"contacts: %@", self.arrayContacts);
}

- (UIImage *)stretchableImage:(NSString *)imageName
{
	UIImage *img = [UIImage imageNamed:imageName];
	UIImage *stretchable = [img resizableImageWithCapInsets:UIEdgeInsetsMake(28, 28, 28, 28)]; //top, left, bottom, right
	return stretchable;
}

- (void)scrollContentViewToFrame:(CGRect)newFrame
{
    [UIView animateWithDuration:0.35
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^
     {
         self.scrollableContentView.frame = newFrame;
     }
                     completion:^(BOOL finished)
     {

     }];
}

- (void)scrollContentViewBackToOriginalPosition
{
	[UIView animateWithDuration:0.35
						  delay: 0.0
						options: UIViewAnimationOptionCurveEaseOut
					 animations:^
	 {
         self.headerView.frame = _originalHeaderFrame;
         self.contentView.frame = _originalContentFrame;
         self.scrollableContentView.frame = _originalScrollableContentFrame;
	 }
	 completion:^(BOOL finished)
	 {
	 }];
}

// returns which prefix the given string starts with
// returns nil in none of them
- (NSString *)categoryPrefix:(NSString *)strCategory
{
    if (strCategory)
    {
        for (NSString *strPrefix in ARRAY_CATEGORY_PREFIXES)
        {
            if ([strCategory hasPrefix:strPrefix])
            {
                return strPrefix;
            }
        }
    }

    return nil;
}

- (void)addMatchesToArray:(NSMutableArray *)arrayMatches forCategoryType:(NSString *)strPrefix withMatchesFor:(NSString *)strMatch inArray:(NSArray *)arraySource
{
    for (NSString *strCategory in arraySource)
    {
        if ([strCategory hasPrefix:strPrefix])
        {
            BOOL bAddIt = YES;

            if ([strMatch length])
            {
                bAddIt = NO;
                // if the string is long enough
                if ([strCategory length] >= [strPrefix length] + [strMatch length])
                {
                    // search for it
                    NSRange searchRange;
                    searchRange.location = [strPrefix length];
                    searchRange.length = [strCategory length] - [strPrefix length];
                    NSRange range = [strCategory rangeOfString:strMatch options:NSCaseInsensitiveSearch range:searchRange];
                    if (range.location != NSNotFound)
                    {
                        bAddIt = YES;
                    }
                }
            }
            if (bAddIt)
            {
                [arrayMatches addObject:strCategory];
            }
        }
    }
}

- (NSArray *)createNewCategoryChoices:(NSString *)strVal
{
    NSMutableArray *arrayChoices = [[NSMutableArray alloc] init];

    // start with the value given
    NSMutableString *strCurVal = [[NSMutableString alloc] initWithString:@""];
    if (strVal)
    {
        if ([strVal length])
        {
            [strCurVal setString:strVal];
        }
    }

    // remove the prefix if it exists
    NSString *strPrefix = [self categoryPrefix:strCurVal];
    if (strPrefix)
    {
        [strCurVal setString:[strCurVal substringFromIndex:[strPrefix length]]];
    }

    NSString *strFirstType = @"Expense:";
    NSString *strSecondType = @"Income:";
    NSString *strThirdType = @"Transfer:";

    if (self.transactionDetailsMode == TD_MODE_RECEIVED)
    {
        strFirstType = @"Income:";
        strSecondType = @"Expense:";
    }

    NSArray *arrayTypes = @[strFirstType, strSecondType, strThirdType];

    // run through each type
    for (NSString *strPrefix in arrayTypes)
    {
        [self addMatchesToArray:arrayChoices forCategoryType:strPrefix withMatchesFor:strCurVal inArray:self.arrayCategories];
    }

    // add the choices constructed with the current string
    for (NSString *strPrefix in arrayTypes)
    {
        NSString *strCategory = [NSString stringWithFormat:@"%@%@", strPrefix, strCurVal];

        // if it isn't already in our array
        if (NSNotFound == [arrayChoices indexOfObject:strCategory])
        {
            [arrayChoices addObject:strCategory];
        }
    }

    return arrayChoices;
}

- (void)forceCategoryFieldValue:(UITextField *)textField forPickerView:(PickerTextView *)pickerTextView
{
    NSMutableString *strNewVal = [[NSMutableString alloc] init];
    [strNewVal appendString:textField.text];

    NSString *strPrefix = [self categoryPrefix:textField.text];

    // if it doesn't start with a prefix, make it
    if (strPrefix == nil)
    {
        [strNewVal insertString:[ARRAY_CATEGORY_PREFIXES objectAtIndex:0] atIndex:0];
    }

    textField.text = strNewVal;

    NSArray *arrayChoices = [self createNewCategoryChoices:textField.text];

    [pickerTextView updateChoices:arrayChoices];
}

- (void)resignAllResponders
{
    [self.notesTextField resignFirstResponder];
    [self.pickerTextCategory.textField resignFirstResponder];
    [self.nameTextField resignFirstResponder];
    [self.fiatTextField resignFirstResponder];
    [self dismissPayeeTable];
    [self scrollContentViewBackToOriginalPosition];
}

- (void)loadCategories
{
    char            **aszCategories = NULL;
    unsigned int    countCategories = 0;

    // get the categories from the core
    tABC_Error Error;
    ABC_GetCategories([[User Singleton].name UTF8String],
                      &aszCategories,
                      &countCategories,
                      &Error);
    [Util printABC_Error:&Error];

    // store them in our own array
    NSMutableArray *arrayCategories = [[NSMutableArray alloc] init];
    if (aszCategories)
    {
        for (int i = 0; i < countCategories; i++)
        {
            [arrayCategories addObject:[NSString stringWithUTF8String:aszCategories[i]]];
        }
    }

    // store the final as storted
    self.arrayCategories = [arrayCategories sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    // free the core categories
    if (aszCategories != NULL)
    {
        [Util freeStringArray:aszCategories count:countCategories];
    }
}

- (void)addCategory:(NSString *)strCategory
{
    // check and see if there is more text than just the prefix
    //if ([ARRAY_CATEGORY_PREFIXES indexOfObject:strCategory] == NSNotFound)
    {
        // check and see that it doesn't already exist
        if ([self.arrayCategories indexOfObject:strCategory] == NSNotFound)
        {
            // add the category to the core
            tABC_Error Error;
            ABC_AddCategory([[User Singleton].name UTF8String], (char *)[strCategory UTF8String], &Error);
            [Util printABC_Error:&Error];
        }
    }
}

- (void)updateAutoCompleteArray
{
    if (_autoCompleteTable)
    {
        // if there is anything in the payee field
        if ([self.nameTextField.text length])
        {
            NSString *strTerm = self.nameTextField.text;

            NSMutableArray *arrayAutoComplete = [[NSMutableArray alloc] init];

            // go through all the businesses
            for (NSString *strBusiness in self.arrayBusinesses)
            {
                // if it is in there
                if ([strBusiness rangeOfString:strTerm options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
                    [arrayAutoComplete addObject:strBusiness];
                }
            }

            // go through all the contacts
            for (NSString *strContact in self.arrayContacts)
            {
                // if it is in there
                if ([strContact rangeOfString:strTerm options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
                    [arrayAutoComplete addObject:strContact];
                }
            }

            self.arrayAutoComplete = [arrayAutoComplete sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        }
        else
        {
            // since nothing in payee yet, just populate with businesses (already sorted by distance)
            self.arrayAutoComplete = self.arrayBusinesses;
        }
        
        
        [_autoCompleteTable reloadData];
    }
}

- (void)addLocationToQuery:(NSMutableString *)query
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

- (void)getBusinessThumbnails
{
    for (NSString *strKey in self.dictThumbnailURLs)
    {
        NSString *strThumbnailURL = [self.dictThumbnailURLs objectForKey:strKey];

        NSMutableString *strURL = [[NSMutableString alloc] init];

        // create the search query
        [strURL appendString:[NSString stringWithFormat:@"%@%@", SERVER_URL, strThumbnailURL]];

        // run the qurey
        //NSLog(@"Query: %@", strURL);
        [[DL_URLServer controller] issueRequestURL:[strURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                        withParams:nil
                                        withObject:strKey
                                      withDelegate:self
                                acceptableCacheAge:CACHE_IMAGE_AGE_SECS
                                       cacheResult:YES];
    }
}

- (UIImage *)imageByCroppingImage:(UIImage *)image toSize:(CGSize)size
{
    double x = (image.size.width - size.width) / 2.0;
    double y = (image.size.height - size.height) / 2.0;

    CGRect cropRect = CGRectMake(x, y, size.height, size.width);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);

    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);

    return cropped;
}

#pragma mark - Calculator delegates

- (void)CalculatorDone:(CalculatorView *)calculator
{
	[self.fiatTextField resignFirstResponder];
}

- (void)CalculatorValueChanged:(CalculatorView *)calculator
{
    //NSLog(@"calc change. Field now: %@ (%@)", self.fiatTextField.text, calculator.textField.text);
}

#pragma mark - Category Table

- (void)spawnCategoryTableInFrame:(CGRect)frame
{
	CGRect startingFrame = frame;
	startingFrame.size.height = 0;
	_autoCompleteTable = [[UITableView alloc] initWithFrame:startingFrame];
	[self.view addSubview:_autoCompleteTable];
	
	_autoCompleteTable.dataSource = self;
	_autoCompleteTable.delegate = self;
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 _autoCompleteTable.frame = frame;
	 }
					 completion:^(BOOL finished)
	 {
		 
	 }];
}

#pragma mark - Payee Table

- (void)spawnPayeeTableInFrame:(CGRect)frame
{
	CGRect startingFrame = frame;
	startingFrame.size.height = 0;
	_autoCompleteTable = [[UITableView alloc] initWithFrame:startingFrame];
	[self.view addSubview:_autoCompleteTable];
	
	_autoCompleteTable.dataSource = self;
	_autoCompleteTable.delegate = self;
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 _autoCompleteTable.frame = frame;
	 }
	 completion:^(BOOL finished)
	 {
		 
	 }];
}

- (void)dismissPayeeTable
{
	if (_autoCompleteTable)
	{
		CGRect frame = _autoCompleteTable.frame;
		frame.size.height = 0.0;
		frame.origin.y = frame.origin.y + 100;// (_originalScrollableContentFrame.origin.y - self.scrollableContentView.frame.origin.y);
		[UIView animateWithDuration:0.35
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^
		 {
			 _autoCompleteTable.frame = frame;
		 }
						 completion:^(BOOL finished)
		 {
			 [_autoCompleteTable removeFromSuperview];
			 _autoCompleteTable = nil;
		 }];
	}
}

#pragma mark - UITableView delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.arrayAutoComplete count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"PayeeCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    //5.1 you do not need this if you have set SettingsCell as identifier in the storyboard (else you can remove the comments on this code)
    if (cell == nil)
    {
        cell = [[PayeeCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = [self.arrayAutoComplete objectAtIndex:indexPath.row];
    cell.backgroundColor = [UIColor colorWithRed:213.0/255.0 green:237.0/255.0 blue:249.0/255.0 alpha:1.0];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UIImage *imageForCell = [self.dictImages objectForKey:cell.textLabel.text];
    if (imageForCell == nil)
    {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 0.0);
        imageForCell = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    cell.imageView.image = imageForCell;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.nameTextField.text = [self.arrayAutoComplete objectAtIndex:indexPath.row];
	
	// dismiss the tableView
	[self.nameTextField resignFirstResponder];
    [self dismissPayeeTable];
    if (!self.bOldTransaction)
    {
        [self.pickerTextCategory.textField becomeFirstResponder];
    }
}

#pragma mark - infoView delegates

-(void)InfoViewFinished:(InfoView *)infoView
{
	[infoView removeFromSuperview];
}

#pragma mark - DLURLServer Callbacks

- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
    if (DL_URLRequestStatus_Success == status)
    {
        // if this is a business listing query
        if (nil == object)
        {
            NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];

            //NSLog(@"Results download returned: %@", jsonString );

            NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
            NSError *myError;
            NSDictionary *dictFromServer = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:&myError];


            NSArray *searchResultsArray;
            //NSLog(@"Got search results: %@", [dictFromServer objectForKey:@"results"]);
            searchResultsArray = [[dictFromServer objectForKey:@"results"] mutableCopy];

            NSMutableArray *arrayBusinesses = [[NSMutableArray alloc] init];
            NSMutableDictionary *dictThumbnailURLs = [[NSMutableDictionary alloc] init];

            for (NSDictionary *dict in searchResultsArray)
            {
                NSString *name = [dict objectForKey:@"name"];
                if (name && name != (id)[NSNull null])
                {
                    [arrayBusinesses addObject:name];

                    // check if we can get a thumbnail
                    NSDictionary *dictProfileImage = [dict objectForKey:@"profile_image"];
                    if (dictProfileImage && dictProfileImage != (id)[NSNull null])
                    {
                        NSString *strThumbnail = [dictProfileImage objectForKey:@"thumbnail"];
                        if (strThumbnail && strThumbnail != (id)[NSNull null])
                        {
                            //NSLog(@"thumbnail path: %@", strThumbnail);
                            [dictThumbnailURLs setObject:strThumbnail forKey:name];
                        }
                    }
                }
            }
            
            self.arrayBusinesses = arrayBusinesses;
            //NSLog(@"Businesses: %@", arrayBusinesses);
            self.dictThumbnailURLs = dictThumbnailURLs;
            
            [self performSelector:@selector(updateAutoCompleteArray) withObject:nil afterDelay:0.0];
            [self performSelector:@selector(getBusinessThumbnails) withObject:nil afterDelay:0.0];
        }
        else
        {
            NSString *strNameForImage = (NSString *) object;
            //NSLog(@"got image for %@", strNameForImage);
            UIImage *srcImage = [UIImage imageWithData:data];
            CGSize imageSize;
            imageSize = srcImage.size;
            imageSize.width = imageSize.height;
            UIImage *croppedImage = [self imageByCroppingImage:srcImage toSize:imageSize];
            [self.dictImages setObject:croppedImage forKey:strNameForImage];
            [self performSelector:@selector(updateAutoCompleteArray) withObject:nil afterDelay:0.0];
        }
    }
}

#pragma mark - UITextField delegates

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	_activeTextField = textField;

    CGRect scrollFrame = self.scrollableContentView.frame;

    // WARNING: Lots of magic numbers - but we have to make this change quick for the demo
    // Change some of these for iPhone 4

    if (textField == self.nameTextField)
    {
        scrollFrame.origin.y = -30;

        CGRect frame = self.view.bounds;
        frame.origin.y = 100;
        frame.size.height = 252;
        [self spawnPayeeTableInFrame:frame];
        [self updateAutoCompleteArray];
    }
    else if (textField == self.notesTextField)
    {
        scrollFrame.origin.y = -90;
        [self dismissPayeeTable];
    }
    else
    {
        scrollFrame.origin.y = _originalScrollableContentFrame.origin.y;
    }

    [self scrollContentViewToFrame:scrollFrame];

    // highlight all the text
    [textField setSelectedTextRange:[textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.endOfDocument]];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // unhighlight text
    // note: for some reason, if we don't do this, the text won't select next time the user selects it
    [textField setSelectedTextRange:[textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.beginningOfDocument]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];

	if (textField == self.nameTextField)
	{
		[self dismissPayeeTable];
        if (!self.bOldTransaction)
        {
            [self.pickerTextCategory.textField becomeFirstResponder];
        }
	}
    
	return YES;
}

- (void)textFieldDidChange:(UITextField *)textField
{
    if (textField == self.nameTextField)
    {
        [self updateAutoCompleteArray];
    }
}

#pragma mark - PickerTextView Delegates

- (BOOL)pickerTextViewFieldShouldChange:(PickerTextView *)pickerTextView charactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // create what the new value would look like
    NSString *strNewVal = [pickerTextView.textField.text stringByReplacingCharactersInRange:range withString:string];

    // if it still has a prefix
    if ([self categoryPrefix:strNewVal])
    {
        // allow it
        return YES;
    }

    return NO;
}

- (void)pickerTextViewFieldDidChange:(PickerTextView *)pickerTextView
{
    NSMutableString *strNewVal = [[NSMutableString alloc] init];
    [strNewVal appendString:pickerTextView.textField.text];

    NSString *strPrefix = [self categoryPrefix:pickerTextView.textField.text];

    // if it doesn't start with a prefix, make it
    if (strPrefix == nil)
    {
        [strNewVal insertString:[ARRAY_CATEGORY_PREFIXES objectAtIndex:0] atIndex:0];
    }

    pickerTextView.textField.text = strNewVal;

    NSArray *arrayChoices = [self createNewCategoryChoices:pickerTextView.textField.text];

    [pickerTextView updateChoices:arrayChoices];
}

- (void)pickerTextViewFieldDidBeginEditing:(PickerTextView *)pickerTextView
{
    _activeTextField = pickerTextView.textField;

    [self forceCategoryFieldValue:pickerTextView.textField forPickerView:pickerTextView];

    // highlight all the text after the :
    NSRange range = [pickerTextView.textField.text rangeOfString:@":"];
    UITextPosition *startPosition = [pickerTextView.textField positionFromPosition:pickerTextView.textField.beginningOfDocument offset:range.location + 1];
    [pickerTextView.textField setSelectedTextRange:[pickerTextView.textField textRangeFromPosition:startPosition toPosition:pickerTextView.textField.endOfDocument]];
}

- (BOOL)pickerTextViewShouldEndEditing:(PickerTextView *)pickerTextView
{
    // unhighlight text
    // note: for some reason, if we don't do this, the text won't select next time the user selects it
    [pickerTextView.textField setSelectedTextRange:[pickerTextView.textField textRangeFromPosition:pickerTextView.textField.beginningOfDocument toPosition:pickerTextView.textField.beginningOfDocument]];

    return YES;
}

- (void)pickerTextViewFieldDidEndEditing:(PickerTextView *)pickerTextView
{
    //[self forceCategoryFieldValue:pickerTextView.textField forPickerView:pickerTextView];
}

- (BOOL)pickerTextViewFieldShouldReturn:(PickerTextView *)pickerTextView
{
	[pickerTextView.textField resignFirstResponder];

    if (!self.bOldTransaction)
    {
        [self.notesTextField becomeFirstResponder];
    }

	return YES;
}

- (void)pickerTextViewPopupSelected:(PickerTextView *)pickerTextView onRow:(NSInteger)row
{
    // set the text field to the choice
    pickerTextView.textField.text = [pickerTextView.arrayChoices objectAtIndex:row];

    // check and see if there is more text than just the prefix
    if ([ARRAY_CATEGORY_PREFIXES indexOfObject:pickerTextView.textField.text] == NSNotFound)
    {
        [pickerTextView.textField resignFirstResponder];

        if (!self.bOldTransaction)
        {
            [self.notesTextField becomeFirstResponder];
        }
    }
}

- (void)pickerTextViewFieldDidShowPopup:(PickerTextView *)pickerTextView
{
    // forces the size of the popup picker on the picker text view to a certain size

    // Note: we have to do this because right now the size will start as max needed but as we dynamically
    //       alter the choices, we may end up with more choices than we originally started with
    //       so we want the table to always be as large as it can be

    // first start the popup pickerit right under the control and squished down
    CGRect frame = self.pickerTextCategory.popupPicker.frame;
    frame.size.height = 20;
    //frame.size.height = 220; // magic number to make it as big as possible
    CGPoint pickerLocationScreen = [pickerTextView.superview convertPoint:pickerTextView.frame.origin toView:nil];
    frame.origin.y = pickerLocationScreen.y + pickerTextView.frame.size.height;
    self.pickerTextCategory.popupPicker.frame = frame;

    // now move the window up so that the category field is at the top
    CGRect scrollFrame = self.scrollableContentView.frame;
    scrollFrame.origin.y = -250; // magic number TODO: modify for iPhone4
    [self scrollContentViewToFrame:scrollFrame];

    // bring the picker up with it
    [UIView animateWithDuration:0.35
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^
     {
         CGRect frame = self.pickerTextCategory.popupPicker.frame;
         frame.origin.y = 130;
         frame.size.height = 220; // magic number to make it as big as possible
         self.pickerTextCategory.popupPicker.frame = frame;
     }
                     completion:^(BOOL finished)
     {

     }];

}

#pragma mark - Keyboard callbacks

- (void)keyboardWillShow:(NSNotification *)notification
{
    //NSLog(@"keyboard will show");
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    //NSLog(@"keyboard will hide");

    if (_activeTextField.returnKeyType == UIReturnKeyDone)
    {
        [self scrollContentViewBackToOriginalPosition];
    }

	_activeTextField = nil;
}

@end

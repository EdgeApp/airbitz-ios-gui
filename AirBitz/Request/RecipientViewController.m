//
//  RecipientViewController.m
//  AirBitz
//
//  Created by Adam Harris on 8/14/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "RecipientViewController.h"
#import "CommonTypes.h"
#import "Util.h"
#import "StylizedTextField.h"
#import "InfoView.h"
#import "MontserratLabel.h"
#import "PayeeCell.h"
#import "Contact.h"
#import "MainViewController.h"
#import "Theme.h"

#define KEYBOARD_APPEAR_TIME_SECS   0.3
//#define TABLE_CELL_BACKGROUND_COLOR [UIColor colorWithRed:213.0/255.0 green:237.0/255.0 blue:249.0/255.0 alpha:1.0]



@interface RecipientViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView             *viewDisplay;
@property (weak, nonatomic) IBOutlet MontserratLabel    *labelTitle;
@property (weak, nonatomic) IBOutlet StylizedTextField  *textFieldRecipient;
@property (weak, nonatomic) IBOutlet UITableView        *tableContacts;

@property (nonatomic, copy)   NSString                  *strFullName;
@property (nonatomic, copy)   NSString                  *strTarget;
@property (nonatomic, strong) NSArray                   *arrayAutoComplete; // array of NSNumber's representing indexes to nams, data, etc
@property (nonatomic, strong) NSArray                   *arrayContacts;

@end

@implementation RecipientViewController

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

    self.arrayAutoComplete = @[];
    self.arrayContacts = @[];

    // get keyboard events so we can resize our table based on top of keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    // get a callback when there are changes
    [self.textFieldRecipient addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:self.viewDisplay];

    // set up our edit field
    self.textFieldRecipient.font = [UIFont systemFontOfSize:18];
    self.textFieldRecipient.textAlignment = NSTextAlignmentCenter;
    self.textFieldRecipient.tintColor = [UIColor whiteColor];

    // change visusals on table
    self.tableContacts.backgroundColor = [UIColor clearColor];
    self.tableContacts.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];     // This will remove extra separators from tableview

    // set the title based on why we were brought up
    self.labelTitle.text = (self.mode == RecipientMode_Email ? @"Email Recipient" : @"SMS Recipient");

    [self.textFieldRecipient becomeFirstResponder];

    // load all the names from the address book
    [self generateListOfContactNames];

    // update the autocomplete array
    [self updateAutoCompleteArray];

    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableContacts setContentInset:UIEdgeInsetsMake(0, 0, [MainViewController getFooterHeight], 0)];
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBarTitle:self title:(self.mode == RecipientMode_Email ? @"Email Recipient" : @"SMS Recipient")];

    [MainViewController changeNavBar:self title:[Theme Singleton].backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(buttonBackTouched:) fromObject:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(buttonInfoTouched:) fromObject:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
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
    self.strFullName = @"";
    self.strTarget = @"";
    [self animatedExit];
}

- (IBAction)buttonInfoTouched:(id)sender
{
    [InfoView CreateWithHTML:@"infoRecipient" forView:self.view];
}

#pragma mark - Misc Methods


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
                // add this contact
                [self addContactInfo:person withName:strFullName toArray:arrayContacts];
            }
        }
        CFRelease(people);
    }

    // assign final
    self.arrayContacts = [arrayContacts sortedArrayUsingSelector:@selector(compare:)];
    //NSLog(@"contacts: %@", self.arrayContacts);
}

- (void)addContactInfo:(ABRecordRef)person withName:(NSString *)strName toArray:(NSMutableArray *)arrayContacts
{
    UIImage *imagePhoto = nil;

    // does this contact has an image
    if (ABPersonHasImageData(person))
    {
        NSData *data = (__bridge_transfer NSData*)ABPersonCopyImageData(person);
        imagePhoto = [UIImage imageWithData:data];
    }

    // get the array of phone numbers or e-mail
    ABMultiValueRef arrayData = (__bridge ABMultiValueRef)((__bridge NSString *)ABRecordCopyValue(person,
                                                                                                   self.mode == RecipientMode_SMS ? kABPersonPhoneProperty : kABPersonEmailProperty));

    // go through each element in the array
    for (CFIndex i = 0; i < ABMultiValueGetCount(arrayData); i++)
    {
        Contact *contact = [[Contact alloc] init];

        NSString *tempStrData = (__bridge NSString *)ABMultiValueCopyValueAtIndex(arrayData, i);
        if (tempStrData)
        {
            NSString *strData = [NSString stringWithFormat:@"%@", tempStrData];
            CFRelease((__bridge CFTypeRef)tempStrData);
            contact.strData = strData;
        }
        else
        {
            contact.strData = [NSString stringWithFormat:@""];
        }

        CFStringRef labelStingRef = ABMultiValueCopyLabelAtIndex(arrayData, i);

        if (labelStingRef != nil)
        {
            NSString *tempStrDataLabel = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(labelStingRef);
            NSString *strDataLabel  = [NSString stringWithFormat:@"%@", tempStrDataLabel];
            CFRelease((__bridge CFTypeRef)tempStrDataLabel);
            contact.strDataLabel = strDataLabel;
        }
        else
        {
            contact.strDataLabel = [NSString stringWithFormat:@""];
        }

        contact.strName = strName;
        contact.imagePhoto = imagePhoto;

        [arrayContacts addObject:contact];
    }
    CFRelease(arrayData);
}

- (void)updateAutoCompleteArray
{
    if (self.tableContacts)
    {
        // if there is anything in the text field
        if ([self.textFieldRecipient.text length])
        {
            NSString *strTerm = self.textFieldRecipient.text;

            NSMutableArray *arrayAutoComplete = [[NSMutableArray alloc] init];

            // go through all the contacts
            for (Contact *contact in self.arrayContacts)
            {
                // if it matches what the user has currently typed
                if (([contact.strName rangeOfString:strTerm options:NSCaseInsensitiveSearch].location != NSNotFound) ||
                    ([contact.strData rangeOfString:strTerm options:NSCaseInsensitiveSearch].location != NSNotFound))
                {
                    // add this contact to the auto complete array
                    [arrayAutoComplete addObject:contact];
                }
            }

            self.arrayAutoComplete = [arrayAutoComplete sortedArrayUsingSelector:@selector(compare:)];
        }
        else
        {
            self.arrayAutoComplete = self.arrayContacts;
        }

        // force the table to reload itself
        [self reloadAutoCompleteTable];
    }
}

- (void)reloadAutoCompleteTable
{
    [self.tableContacts reloadData];
}

- (void)installLeftToRightSwipeDetection
{
	UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeftToRight:)];
	gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:gesture];
}

- (BOOL)haveSubViewsShowing
{
    return NO;
}

- (void)animatedExit
{
    [self.textFieldRecipient resignFirstResponder];

//	[UIView animateWithDuration:EXIT_ANIM_TIME_SECS
//						  delay:0.0
//						options:UIViewAnimationOptionCurveEaseInOut
//					 animations:^
//	 {
//		 CGRect frame = self.view.frame;
//		 frame.origin.x = frame.size.width;
//		 self.view.frame = frame;
//	 }
//                     completion:^(BOOL finished)
//	 {
		 [self exit];
//	 }];
}

- (void)exit
{
    [self.delegate RecipientViewControllerDone:self withFullName:self.strFullName andTarget:self.strTarget];
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

    if (cell == nil)
    {
        cell = [[PayeeCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }

    Contact *contact = [self.arrayAutoComplete objectAtIndex:indexPath.row];

    cell.textLabel.text = contact.strName;
    cell.textLabel.textColor = [Theme Singleton].colorTextDark;
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.textColor = [Theme Singleton].colorTextDark;

    // data
    if ([contact.strDataLabel length])
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %@", contact.strDataLabel, contact.strData];
    }
    else
    {
        cell.detailTextLabel.text = contact.strData;
    }

    // image
    UIImage *imageForCell = contact.imagePhoto;
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
    Contact *contact = [self.arrayAutoComplete objectAtIndex:indexPath.row];

    self.strFullName = contact.strName;
    self.strTarget = contact.strData;

    [self animatedExit];
}

#pragma mark - UITextField delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    self.strFullName = self.textFieldRecipient.text;
    self.strTarget = self.textFieldRecipient.text;
    [self animatedExit];

    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField
{
    [self updateAutoCompleteArray];
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardRect;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];

    [UIView animateWithDuration:KEYBOARD_APPEAR_TIME_SECS
						  delay:0.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^
	 {
         [self.tableContacts setContentInset:UIEdgeInsetsMake(0, 0, keyboardRect.size.height, 0)];
	 }
                     completion:^(BOOL finished)
	 {

	 }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    CGRect keyboardRect;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];

    [UIView animateWithDuration:KEYBOARD_APPEAR_TIME_SECS
						  delay:0.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^
	 {
         [self.tableContacts setContentInset:UIEdgeInsetsMake(0, 0, [MainViewController getFooterHeight], 0)];
	 }
                     completion:^(BOOL finished)
	 {

	 }];
}

#pragma mark - GestureReconizer methods

- (void)didSwipeLeftToRight:(UIGestureRecognizer *)gestureRecognizer
{
    if (![self haveSubViewsShowing])
    {
        [self buttonBackTouched:nil];
    }
}

#pragma mark - Custom Notification Handlers

// called when a tab bar button that is already selected, is reselected again
- (void)tabBarButtonReselect:(NSNotification *)notification
{
    if (![self haveSubViewsShowing])
    {
        [self buttonBackTouched:nil];
    }
}

@end

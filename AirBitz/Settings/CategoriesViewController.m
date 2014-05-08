//
//  CategoriesViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "CategoriesViewController.h"
#import "CommonTypes.h"
#import "CategoriesCell.h"
#import "ABC.h"
#import "User.h"

#define BOTTOM_BUTTON_EXTRA_OFFSET_Y 3
#define TABLE_SIZE_EXTRA_HEIGHT      5

@interface CategoriesViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UITextFieldDelegate, CategoriesCellDelegate>
{
    char            **_aszCategories;
    unsigned int    _count;
}

@property (nonatomic, weak) IBOutlet    UITableView     *tableView;
@property (nonatomic, weak) IBOutlet    UIButton        *cancelButton;
@property (nonatomic, weak) IBOutlet    UIButton        *doneButton;
@property (weak, nonatomic) IBOutlet    UIImageView     *imageBottomBar;
@property (weak, nonatomic) IBOutlet    UITextField     *textNew;
@property (weak, nonatomic) IBOutlet    UITextField     *textSearch;

@property (nonatomic, strong)           NSMutableArray  *arrayCategories;
@property (nonatomic, strong)           NSArray         *arrayDisplay;

@end

@implementation CategoriesViewController

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
	[self.cancelButton setTitle:NSLocalizedString(@"Cancel", @"cancel button title") forState:UIControlStateNormal];
	[self.doneButton setTitle:NSLocalizedString(@"Done", @"done button title") forState:UIControlStateNormal];

    CGRect frame;

    // change bottom bar to right above tab bar
    frame = self.imageBottomBar.frame;
    frame.origin.y = SCREEN_HEIGHT - TOOLBAR_HEIGHT - self.imageBottomBar.frame.size.height;
    self.imageBottomBar.frame = frame;

    // change the bottom buttons to center in the bottom bar
    frame = self.cancelButton.frame;
    frame.origin.y = self.imageBottomBar.frame.origin.y + ((self.imageBottomBar.frame.size.height - self.cancelButton.frame.size.height) / 2.0) + BOTTOM_BUTTON_EXTRA_OFFSET_Y;
    self.cancelButton.frame = frame;
    frame = self.doneButton.frame;
    frame.origin.y = self.imageBottomBar.frame.origin.y + ((self.imageBottomBar.frame.size.height - self.doneButton.frame.size.height) / 2.0) + BOTTOM_BUTTON_EXTRA_OFFSET_Y;
    self.doneButton.frame = frame;

    // change the height of the table view
    frame = self.tableView.frame;
    frame.size.height = self.imageBottomBar.frame.origin.y - self.tableView.frame.origin.y + TABLE_SIZE_EXTRA_HEIGHT;
    self.tableView.frame = frame;

    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    // make the seperator go across the entire row
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)])
    {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }

    // load the categories
    [self loadCategories];

    // get a callback when the search changes
    [self.textSearch addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [self freeStringArray:_aszCategories count:_count];
}

#pragma mark - Action Methods

- (IBAction)AddCategory
{
    if (self.textNew.text)
    {
        if ([self.textNew.text length])
        {
            [self.arrayCategories addObject:self.textNew.text];
            [self updateDisplay];
        }
    }
}

- (IBAction)Cancel
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Cancel Changes", nil)
                          message:NSLocalizedString(@"Are you sure you want to cancel any changes you've made?", nil)
                          delegate:self
                          cancelButtonTitle:@"No"
                          otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (IBAction)Done
{
    [self saveCategories];
    [self animatedExit];
}

#pragma mark - Misc Methods

- (CategoriesCell *)getCategoriesCellForTableView:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath
{
	CategoriesCell *cell;
	static NSString *cellIdentifier = @"CategoriesCell";

	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[CategoriesCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}

	cell.delegate = self;

    cell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    cell.textField.spellCheckingType = UITextSpellCheckingTypeNo;

    cell.tag = indexPath.row;

    cell.textField.text = [self.arrayDisplay objectAtIndex:indexPath.row];

	return cell;
}

// load the categories from the core
- (void)loadCategories
{
    _aszCategories = NULL;
    _count = 0;

    // get the categories from the core
    tABC_Error Error;
    ABC_GetCategories([[User Singleton].name UTF8String],
                      &_aszCategories,
                      &_count,
                      &Error);
    [self printABC_Error:&Error];

    // store them in our own array
    self.arrayCategories = [[NSMutableArray alloc] init];
    if (_aszCategories)
    {
        for (int i = 0; i < _count; i++)
        {
            [self.arrayCategories addObject:[NSString stringWithUTF8String:_aszCategories[i]]];
        }
    }

    [self updateDisplay];
}

// saves the categories to the core
- (void)saveCategories
{
    tABC_Error Error;

    // got through the existing categories
    for (int i = 0; i < _count; i++)
    {
        // create an NSString version of the category
        NSString *strCategory = [NSString stringWithUTF8String:_aszCategories[i]];

        // if this category is in our new list
        if ([self.arrayCategories containsObject:strCategory])
        {
            // remove it from our new list since it is already there
            [self.arrayCategories removeObject:strCategory];
        }
        else
        {
            // it doesn't exist in our new list so delete it from the core
            ABC_RemoveCategory([[User Singleton].name UTF8String], _aszCategories[i], &Error);
            [self printABC_Error:&Error];
        }
    }

    // add any categories from our new list that didn't exist in the core list
    for (int i = 0; i < [self.arrayCategories count]; i++)
    {
        NSString *strCategory = [self.arrayCategories objectAtIndex:i];
        ABC_AddCategory([[User Singleton].name UTF8String], (char *)[strCategory UTF8String], &Error);
        [self printABC_Error:&Error];
    }
}

- (void)updateDisplay
{
    NSString *strSearch = self.textSearch.text;

    // if there is a search string
    if ([strSearch length])
    {
        // put those items in the display array that match the search criteria
        NSMutableArray *arrayDisplay = [[NSMutableArray alloc] init];
        for (int i = 0; i < [self.arrayCategories count]; i++)
        {
            NSString *strCategory = [self.arrayCategories objectAtIndex:i];

            // if our search string is in the category
            if ([strCategory rangeOfString:strSearch options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                [arrayDisplay addObject:strCategory];
            }
        }

        self.arrayDisplay = arrayDisplay;
    }
    else
    {
        self.arrayDisplay = [NSArray arrayWithArray:self.arrayCategories];
    }

    [self.tableView reloadData];
}

- (void)freeStringArray:(char **)aszStrings count:(unsigned int) count
{
    if ((aszStrings != NULL) && (count > 0))
    {
        for (int i = 0; i < count; i++)
        {
            free(aszStrings[i]);
        }
        free(aszStrings);
    }
}

- (void)printABC_Error:(const tABC_Error *)pError
{
    if (pError)
    {
        if (pError->code != ABC_CC_Ok)
        {
            printf("Code: %d, Desc: %s, Func: %s, File: %s, Line: %d\n",
                   pError->code,
                   pError->szDescription,
                   pError->szSourceFunc,
                   pError->szSourceFile,
                   pError->nSourceLine
                   );
        }
    }
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
	[self.delegate categoriesViewControllerDidFinish:self];
}

#pragma mark - UITableView Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;

    if (self.arrayDisplay)
    {
        count = [self.arrayDisplay count];
    }

    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 49.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;

    cell = [self getCategoriesCellForTableView:tableView withIndexPath:indexPath];

	//cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	// if they said they wanted to exit without saving changes
	if (buttonIndex == 1)
	{
        [self performSelector:@selector(animatedExit) withObject:nil afterDelay:0.0];
	}
}

#pragma mark - UITextField delegates

- (void)textFieldDidChange:(UITextField *)textField
{
    if (textField == self.textSearch)
    {
        [self updateDisplay];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{

}

- (void)textFieldDidEndEditing:(UITextField *)textField
{

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];

	return YES;
}

#pragma mark - CategoriesCell Delegates

- (void)categoriesCellDeleteTouched:(CategoriesCell *)cell
{
    NSInteger row = cell.tag;

    [self.arrayCategories removeObjectAtIndex:row];
    [self updateDisplay];
}

@end

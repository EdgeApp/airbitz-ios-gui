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

@interface CategoriesViewController () <UITableViewDataSource, UITableViewDelegate, CategoriesCellDelegate>

@property (nonatomic, weak) IBOutlet UITableView    *tableView;
@property (nonatomic, weak) IBOutlet UIButton       *cancelButton;
@property (nonatomic, weak) IBOutlet UIButton       *doneButton;
@property (weak, nonatomic) IBOutlet UIImageView    *imageBottomBar;
@property (weak, nonatomic) IBOutlet UITextField    *textNew;
@property (weak, nonatomic) IBOutlet UITextField    *textSearch;

@property (nonatomic, strong) NSMutableArray    *arrayCategories;

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action Methods

- (IBAction)AddCategory
{
    if (self.textNew.text)
    {
        if ([self.textNew.text length])
        {
            [self.arrayCategories addObject:self.textNew.text];
            [self.tableView reloadData];
        }
    }
}

- (IBAction)Cancel
{
    [self animatedExit];
}

- (IBAction)Done
{
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

    cell.textField.text = [self.arrayCategories objectAtIndex:indexPath.row];

	return cell;
}

- (void)loadCategories
{
    char **aszCategories = NULL;
    unsigned int count = 0;

    // get the categories from the core
    tABC_Error Error;
    ABC_GetCategories([[User Singleton].name UTF8String],
                      &aszCategories,
                      &count,
                      &Error);
    [self printABC_Error:&Error];

    // store them in our own array
    self.arrayCategories = [[NSMutableArray alloc] init];
    if (aszCategories)
    {
        for (int i = 0; i < count; i++)
        {
            [self.arrayCategories addObject:[NSString stringWithUTF8String:aszCategories[i]]];
        }
    }

    // free the ones from the core
    [self freeStringArray:aszCategories count:count];

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

    if (self.arrayCategories)
    {
        count = [self.arrayCategories count];
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

@end

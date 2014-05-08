//
//  CategoriesViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "CategoriesViewController.h"
#import "CommonTypes.h"

#define BOTTOM_BUTTON_EXTRA_OFFSET_Y 3
#define TABLE_SIZE_EXTRA_HEIGHT      5

@interface CategoriesViewController ()

@property (nonatomic, weak) IBOutlet UITableView    *tableView;
@property (nonatomic, weak) IBOutlet UIButton       *cancelButton;
@property (nonatomic, weak) IBOutlet UIButton       *doneButton;
@property (weak, nonatomic) IBOutlet UIImageView    *imageBottomBar;

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

#if 0
	// make the screen the right height
    CGRect frame = self.view.frame;
    frame.size.height = SCREEN_HEIGHT - TOOLBAR_HEIGHT;
    self.view.frame = frame;
#endif
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action Methods

- (IBAction)AddCategory
{
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

@end

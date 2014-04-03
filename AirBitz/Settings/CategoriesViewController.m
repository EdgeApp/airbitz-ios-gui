//
//  CategoriesViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "CategoriesViewController.h"

@interface CategoriesViewController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UIButton *doneButton;

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
	
	//CW NEED TO HIDE THE TAB BAR HERE (SHOW THE TAB BAR WHEN WE LEAVE)
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)AddCategory
{
}

-(IBAction)Back
{
}

-(IBAction)Done
{
}

@end

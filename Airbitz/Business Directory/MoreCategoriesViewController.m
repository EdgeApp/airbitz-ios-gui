//
//  MoreCategoriesViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/10/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "MoreCategoriesViewController.h"
#import "categoryCell.h"
#import "CJSONDeserializer.h"
#import "Server.h"
#import "Theme.h"
#import "MainViewController.h"
#import "Util.h"

#define MODE_NAME	0
#define MODE_LEVEL	1

@interface MoreCategoriesViewController () <UITableViewDataSource, UITableViewDelegate>
{
	BOOL mode;
	NSMutableArray *categoriesArray;
}
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView                *activityView;
@property (nonatomic, weak) IBOutlet UITableView                            *tableView;
@property (nonatomic, weak) IBOutlet UIButton                               *modeButton;
@property (strong, nonatomic)        AFHTTPRequestOperationManager          *afmanager;

@end

@implementation MoreCategoriesViewController

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
	mode = MODE_LEVEL;
	// Do any additional setup after loading the view.
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	categoriesArray = [[NSMutableArray alloc] init];
    self.afmanager = [MainViewController createAFManager];

	[self assignNameCategoryButtonText];
	[self loadCategories];
}

-(void)viewWillAppear:(BOOL)animated
{
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBarTitle:self title:NSLocalizedString(@"More Categories", @"")];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(back) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadCategories
{
	NSString *serverQuery;
	
	[categoriesArray removeAllObjects];
	if(mode == MODE_NAME)
	{
		serverQuery = [NSString stringWithFormat:@"%@/categories/?sort=name", SERVER_API];
	}
	else
	{
		serverQuery = [NSString stringWithFormat:@"%@/categories/?sort=level", SERVER_API];
	}

    [self doNetworkQuery:serverQuery];
}

-(void)doNetworkQuery:(NSString *)query
{
    [self.afmanager GET:query parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *results = (NSDictionary *)responseObject;
        
        [categoriesArray addObjectsFromArray:[results objectForKey:@"results"]];
        
        NSString *nextQuery = [results objectForKey:@"next"];
        if(nextQuery && (nextQuery != (id)[NSNull null]))
        {
            [self doNetworkQuery:nextQuery];
        }
        else
        {
            [self pruneFirstThreeLevelsFromCategories];
            [self.activityView stopAnimating];
            [self.tableView reloadData];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        ABCLog(1, @"*** ERROR Connecting to Network: MoreCategories:doNetworkQuery");
    }];

}


-(void)pruneFirstThreeLevelsFromCategories
{
	NSDictionary *category;
	
	for(int i=0; i<categoriesArray.count; i++)
	{
		category = [categoriesArray objectAtIndex:i];
		NSNumber *num = [category objectForKey:@"level"];
		if(num && num != (id)[NSNull null])
		{
			if([num intValue] < 4)
			{
				[categoriesArray removeObject:category];
				i--;
			}
		}
		else
		{
			//prune null categories
			[categoriesArray removeObject:category];
			i--;
		}
	}
	
	//ABCLog(2,@"New categories: %@", categoriesArray);
}

-(IBAction)back
{
//	[[DL_URLServer controller] cancelAllRequestsForDelegate:self];
	
	[self.delegate moreCategoriesViewControllerDone:self withCategory:nil];
}

-(void)assignNameCategoryButtonText
{
	if(mode == MODE_NAME)
	{
		[self.modeButton setTitle:NSLocalizedString(@"Name", nil) forState:UIControlStateNormal];
	}
	else
	{
		[self.modeButton setTitle:NSLocalizedString(@"Level", nil) forState:UIControlStateNormal];
	}
}

-(IBAction)Mode
{
	[self.activityView startAnimating];
	if(mode == MODE_NAME)
	{
		mode = MODE_LEVEL;
	}
	else
	{
		mode = MODE_NAME;
	}
	[self assignNameCategoryButtonText];
	[self loadCategories];
}

#pragma mark Table View delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return categoriesArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	categoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"categoryCell"];
	if (nil == cell)
	{
		cell = [[categoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"categoryCell"];
	}

	NSDictionary *dict = [categoriesArray objectAtIndex:indexPath.row];
	if(mode == MODE_NAME)
	{
		cell.categoryLabel.text = [dict objectForKey:@"name"];
	}
	else
	{
		cell.categoryLabel.text = [dict objectForKey:@"name"];
	}
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [Theme Singleton].heightSettingsTableCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *dict = [categoriesArray objectAtIndex:indexPath.row];
	[self.delegate moreCategoriesViewControllerDone:self withCategory:[dict objectForKey:@"name"]];
}

@end

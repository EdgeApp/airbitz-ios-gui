//
//  SettingsViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "SettingsViewController.h"
#import "RadioButtonCell.h"
#import "ABC.h"
#import "User.h"
#import "PlainCell.h"
#import "TextFieldCell.h"
#import "BooleanCell.h"
#import "ButtonCell.h"
#import "ButtonOnlyCell.h"
#import "CancelDoneCell.h"

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate, BooleanCellDelegate, ButtonCellDelegate, TextFieldCellDelegate, ButtonOnlyCellDelegate, CancelDoneCellDelegate>
{
	tABC_AccountSettings *pAccountSettings;
	TextFieldCell *activeTextFieldCell;
	UITapGestureRecognizer *tapGesture;
}
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.delaysContentTouches = NO;
	
	tABC_Error Error;
    Error.code = ABC_CC_Ok;

    pAccountSettings = NULL;
    ABC_LoadAccountSettings([[User Singleton].name UTF8String],
                            [[User Singleton].password UTF8String],
                            &pAccountSettings,
                            &Error);
    [self printABC_Error:&Error];
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
}

-(void)dealloc
{
	if(pAccountSettings)
	{
		ABC_FreeAccountSettings(pAccountSettings);
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)Back
{
	[self.delegate SettingsViewControllerDone:self];
}

-(IBAction)Info
{
	NSLog(@"Info button pressed");
}

-(void)booleanCell:(BooleanCell *)cell switchToggled:(UISwitch *)theSwitch
{
	NSLog(@"Switch toggled:%i", theSwitch.on);
}

-(void)buttonCellButtonPressed:(ButtonCell *)cell
{
	NSLog(@"Button was pressed");
}

-(void)buttonOnlyCellButtonPressed:(ButtonOnlyCell *)cell
{
	NSLog(@"Change Categories");
	//log out for now
	[[User Singleton] clear];
	[self.delegate SettingsViewControllerDone:self];
}

-(void)CancelDoneCellCancelPressed
{
	NSLog(@"Cancel button");
}

-(void)CancelDoneCellDonePressed
{
	NSLog(@"Done Button");
}

#pragma mark textFieldCell delegates

-(void)textFieldCellBeganEditing:(TextFieldCell *)cell
{
	//scroll the tableView so that this cell is above the keyboard
	activeTextFieldCell = cell;
	if(!tapGesture)
	{
		tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
		[self.tableView	addGestureRecognizer:tapGesture];
	}
}

- (void) handleTapFrom: (UITapGestureRecognizer *)recognizer
{
    //Code to handle the gesture
	[self.view endEditing:YES];
	[self.tableView removeGestureRecognizer:tapGesture];
	tapGesture = nil;
}

-(void)textFieldCellEndEditing:(TextFieldCell *)cell
{
	[activeTextFieldCell resignFirstResponder];
	activeTextFieldCell = nil;
}

#pragma mark keyboard callbacks

- (void)keyboardWillShow:(NSNotification *)notification
{
	if(activeTextFieldCell)
	{
		//NSDictionary *userInfo = [notification userInfo];
		//CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
		
		//CGRect ownFrame = [self.view.window convertRect:keyboardFrame toView:self.view];
		//NSLog(@"Own frame: %f, %f, %f, %f", ownFrame.origin.x, ownFrame.origin.y, ownFrame.size.width, ownFrame.size.height);
		//NSLog(@"Table frame: %f, %f, %f, %f", self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, self.tableView.frame.size.height);
		CGPoint p = CGPointMake(0, 165.0);
		
		[self.tableView setContentOffset:p animated:YES];
	}
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	if(activeTextFieldCell)
	{
		activeTextFieldCell = nil;
	}
}

#pragma mark Custom Table Cells

-(RadioButtonCell *)getRadioButtonCellForTableView:(UITableView *)tableView withImage:(UIImage *)bkgImage andIndexPath:(NSIndexPath *)indexPath
{
	RadioButtonCell *cell;
	static NSString *cellIdentifier = @"RadioButtonCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[RadioButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	cell.bkgImage.image = bkgImage;
	
	if(indexPath.row == 0)
	{
		cell.name.text = NSLocalizedString(@"Bitcoin", @"settings text");
	}
	if(indexPath.row == 1)
	{
		cell.name.text = NSLocalizedString(@"mBitcoin = (0.001 Bitcoin)", @"settings text");
	}
	if(indexPath.row == 2)
	{
		cell.name.text = NSLocalizedString(@"uBitcoin = (0.000001 Bitcoin)", @"settings text");
	}
	cell.radioButton.image = [UIImage imageNamed:@"btn_unselected"];
	return cell;
}

-(PlainCell *)getPlainCellForTableView:(UITableView *)tableView withImage:(UIImage *)bkgImage andIndexPath:(NSIndexPath *)indexPath
{
	PlainCell *cell;
	static NSString *cellIdentifier = @"PlainCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[PlainCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	cell.bkgImage.image = bkgImage;
	
	if(indexPath.section == 1)
	{
		if(indexPath.row == 0)
		{
			cell.name.text = NSLocalizedString(@"Change password", @"settings text");
		}
		if(indexPath.row == 1)
		{
			cell.name.text = NSLocalizedString(@"Change withdrawal PIN", @"settings text");
		}
		if(indexPath.row == 2)
		{
			cell.name.text = NSLocalizedString(@"Change recovery questions", @"settings text");
		}

	}
	
	return cell;
}

-(TextFieldCell *)getTextFieldCellForTableView:(UITableView *)tableView withImage:(UIImage *)bkgImage andIndexPath:(NSIndexPath *)indexPath
{
	TextFieldCell *cell;
	static NSString *cellIdentifier = @"TextFieldCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[TextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	cell.bkgImage.image = bkgImage;
	cell.delegate = self;
	if(indexPath.section == 1)
	{
		if(indexPath.row == 3)
		{
			cell.name.placeholder = NSLocalizedString(@"First Name (optional)", @"settings text");
		}
		if(indexPath.row == 4)
		{
			cell.name.placeholder = NSLocalizedString(@"Last Name (optional)", @"settings text");
		}
		if(indexPath.row == 5)
		{
			cell.name.placeholder = NSLocalizedString(@"Nickname / handle", @"settings text");
		}
	}
	
	return cell;
}

-(BooleanCell *)getBooleanCellForTableView:(UITableView *)tableView withImage:(UIImage *)bkgImage andIndexPath:(NSIndexPath *)indexPath
{
	BooleanCell *cell;
	static NSString *cellIdentifier = @"BooleanCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[BooleanCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	cell.bkgImage.image = bkgImage;
	cell.delegate = self;
	if(indexPath.section == 2)
	{
		if(indexPath.row == 0)
		{
			cell.name.text = NSLocalizedString(@"Send name on payment", @"settings text");
		}
	}
	
	return cell;
}

-(ButtonCell *)getButtonCellForTableView:(UITableView *)tableView withImage:(UIImage *)bkgImage andIndexPath:(NSIndexPath *)indexPath
{
	ButtonCell *cell;
	static NSString *cellIdentifier = @"ButtonCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	cell.bkgImage.image = bkgImage;
	cell.delegate = self;
	if(indexPath.section == 2)
	{
		if(indexPath.row == 1)
		{
			cell.name.text = NSLocalizedString(@"Auto log off after", @"settings text");
		}
		if(indexPath.row == 2)
		{
			cell.name.text = NSLocalizedString(@"Language", @"settings text");
		}
		if(indexPath.row == 3)
		{
			cell.name.text = NSLocalizedString(@"Default Currency", @"settings text");
		}
	}
	if(indexPath.section == 3)
	{
		if(indexPath.row == 0)
		{
			cell.name.text = NSLocalizedString(@"US dollar", @"settings text");
		}
		if(indexPath.row == 1)
		{
			cell.name.text = NSLocalizedString(@"Canadian dollar", @"settings text");
		}
		if(indexPath.row == 2)
		{
			cell.name.text = NSLocalizedString(@"Euro", @"settings text");
		}
		if(indexPath.row == 3)
		{
			cell.name.text = NSLocalizedString(@"Mexican Peso", @"settings text");
		}
		if(indexPath.row == 4)
		{
			cell.name.text = NSLocalizedString(@"Yuan", @"settings text");
		}
	}
	return cell;
}

-(ButtonOnlyCell *)getButtonOnlyCellForTableView:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath
{
	ButtonOnlyCell *cell;
	static NSString *cellIdentifier = @"ButtonOnlyCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[ButtonOnlyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	cell.delegate = self;
	//[cell.button setTitle:NSLocalizedString(@"Change Categories", @"settings text") forState:UIControlStateNormal]; //cw temp replace this button with log out functionality
	[cell.button setTitle:NSLocalizedString(@"Log Out", @"settings text") forState:UIControlStateNormal];
	
	return cell;
}

-(CancelDoneCell *)getCancelDoneCellForTableView:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath
{
	CancelDoneCell *cell;
	static NSString *cellIdentifier = @"CancelDoneCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[CancelDoneCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	cell.delegate = self;
	
	return cell;
}

#pragma mark UITableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
			case 0:
				return 3;
				break;
			case 1:
				return 6;
				break;
			case 2:
				return 4;
				break;
			case 3:
				return 5;
				break;
			default:
				return 1;
				break;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 2)
	{
		return 47.0;
	}
	return 37.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if((section == 4) || (section == 5))
	{
		return 0.0;
	}

	return 37.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	static NSString *cellIdentifier = @"SettingsSectionHeader";
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		[NSException raise:@"headerView == nil.." format:@"No cells with matching CellIdentifier loaded from your storyboard"];
	}
	UILabel *label = (UILabel *)[cell viewWithTag:1];
	if(section == 0)
	{
		label.text = NSLocalizedString(@"BITCOIN DEMONIMATION", @"section header in settings table");
	}
	if(section == 1)
	{
		label.text = NSLocalizedString(@"USER NAME", @"section header in settings table");
	}
	if(section == 2)
	{
		label.text = @" ";
	}
	if(section == 3)
	{
		label.text = NSLocalizedString(@"DEFAULT EXCHANGE", @"section header in settings table");
	}
	
	return cell;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	if(indexPath.section < 4)
	{
		UIImage *cellImage;
		if((indexPath.section == 2) || ([tableView numberOfRowsInSection:indexPath.section] == 1))
		{
			cellImage = [UIImage imageNamed:@"bd_cell_single"];
		}
		else
		{
			if(indexPath.row == 0)
			{
				cellImage = [UIImage imageNamed:@"bd_cell_top"];
			}
			else
			{
				if(indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1)
				{
					cellImage = [UIImage imageNamed:@"bd_cell_bottom"];
				}
				else
				{
					cellImage = [UIImage imageNamed:@"bd_cell_middle"];
				}
			}
		}
		
		if(indexPath.section == 0)
		{
			cell = [self getRadioButtonCellForTableView:tableView withImage:cellImage andIndexPath:(NSIndexPath *)indexPath];
		}
		if(indexPath.section == 1)
		{
			if(indexPath.row < 3)
			{
				cell = [self getPlainCellForTableView:tableView withImage:cellImage andIndexPath:indexPath];
			}
			else
			{
				cell = [self getTextFieldCellForTableView:tableView withImage:cellImage andIndexPath:(NSIndexPath *)indexPath];
			}
		}
		if(indexPath.section == 2)
		{
			if(indexPath.row == 0)
			{
				cell = [self getBooleanCellForTableView:tableView withImage:cellImage andIndexPath:indexPath];
			}
			else
			{
				cell = [self getButtonCellForTableView:tableView withImage:cellImage andIndexPath:(NSIndexPath *)indexPath];
			}
		}
		if(indexPath.section == 3)
		{
			cell = [self getButtonCellForTableView:tableView withImage:cellImage andIndexPath:(NSIndexPath *)indexPath];
		}
	}
	else if(indexPath.section == 4)
	{
		//show Change Categories button
		cell = [self getButtonOnlyCellForTableView:tableView withIndexPath:indexPath];
	}
	else
	{
		//show Cancel and Done buttons
		cell = [self getCancelDoneCellForTableView:tableView withIndexPath:indexPath];
	}
	
	cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog(@"Selected section:%i, row:%i", indexPath.section, indexPath.row);
}

@end

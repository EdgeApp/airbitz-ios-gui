//
//  TransactionsViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "TransactionsViewController.h"
#import "BalanceView.h"
#import "TransactionCell.h"
#import "Transaction.h"
#import "NSDate+Helper.h"
#import "TransactionDetailsViewController.h"
#import "ABC.h"

#define DOLLAR_CURRENCY_NUM	840

@interface TransactionsViewController () <BalanceViewDelegate, UITableViewDataSource, UITableViewDelegate, TransactionDetailsViewControllerDelegate, UITextFieldDelegate>
{
	BalanceView *balanceView;
	tBalanceViewState balanceState;
	TransactionDetailsViewController *transactionDetailsController;
}
@property (nonatomic, weak) IBOutlet UIView *balanceViewPlaceholder;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UITextField *searchTextField;

@end

@implementation TransactionsViewController

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
	balanceView = [BalanceView CreateWithDelegate:self];
	balanceView.frame = self.balanceViewPlaceholder.frame;
	[self.balanceViewPlaceholder removeFromSuperview];
	[self.view addSubview:balanceView];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	
	self.searchTextField.font = [UIFont fontWithName:@"Montserrat-Regular" size:self.searchTextField.font.pointSize];
	
	//[self.searchTextField addTarget:self action:@selector(searchTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)Done
{
	[self.delegate TransactionsViewControllerDone:self];
}

//note this method duplicated in WalletsViewController
-(NSString *)conversion:(int64_t)satoshi
{
	if(balanceState == BALANCE_VIEW_DOWN)
	{
		//dollars
		double currency;
		tABC_Error error;
		
		ABC_SatoshiToCurrency(satoshi, &currency, DOLLAR_CURRENCY_NUM, &error);
		return [NSString stringWithFormat:@"$ %.2f", currency];
	}
	else
	{
		//bitcoin
		return [NSString stringWithFormat:@"B %.2f", ABC_SatoshiToBitcoin(satoshi)];
	}
}

-(void)launchTransactionDetailsWithTransaction:(Transaction *)transaction
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	transactionDetailsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionDetailsViewController"];
	
	transactionDetailsController.delegate = self;
	transactionDetailsController.transaction = transaction;
	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
	transactionDetailsController.view.frame = frame;
	[self.view addSubview:transactionDetailsController.view];
	
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 transactionDetailsController.view.frame = self.view.bounds;
	 }
					 completion:^(BOOL finished)
	 {
	 }];
	
}

-(void)dismissTransactionDetails
{
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = self.view.bounds;
		 frame.origin.x = frame.size.width;
		 transactionDetailsController.view.frame = frame;
	 }
					 completion:^(BOOL finished)
	 {
		 [transactionDetailsController.view removeFromSuperview];
		 transactionDetailsController = nil;
	 }];
}

#pragma mark TransactionDetailsViewControllerDelegates

-(void)TransactionDetailsViewControllerDone:(TransactionsViewController *)controller
{
	[self dismissTransactionDetails];
}

#pragma mark UITableView delegates



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.wallet.arrayTransactions.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 72.0;
}

-(TransactionCell *)getTransactionCellForTableView:(UITableView *)tableView
{
	TransactionCell *cell;
	static NSString *cellIdentifier = @"TransactionCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[TransactionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	return cell;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = [indexPath row];
	TransactionCell *cell;
	
	//wallet cell
	cell = [self getTransactionCellForTableView:tableView];
	
	
	Transaction* transaction = [self.wallet.arrayTransactions objectAtIndex:indexPath.row];
	//date
	cell.dateLabel.text = [NSDate stringForDisplayFromDate:transaction.date prefixed:NO alwaysDisplayTime:YES];
	
	//address
	cell.addressLabel.text = transaction.strAddress;
	
	//confirmations
	if(transaction.confirmations == 1)
	{
		cell.confirmationLabel.text = [NSString stringWithFormat:@"%i Confirmation", transaction.confirmations];
	}
	else
	{
		cell.confirmationLabel.text = [NSString stringWithFormat:@"%i Confirmations", transaction.confirmations];
	}
	
	//amount
	//cell.amountLabel.text = [NSString stringWithFormat:@"%d"
	cell.amountLabel.text = [self conversion:transaction.amountSatoshi];
	if(transaction.amountSatoshi < 0)
	{
		cell.amountLabel.textColor = [UIColor colorWithRed:0.7490 green:0.1804 blue:0.1922 alpha:1.0];
	}
	else
	{
		cell.amountLabel.textColor = [UIColor colorWithRed:0.3720 green:0.6588 blue:0.1882 alpha:1.0];
	}
	//balance
	cell.balanceLabel.text = [self conversion:transaction.balance];
	
	if((row == 0) && (row == [tableView numberOfRowsInSection:indexPath.section] - 1))
	{
		cell.bkgImage.image = [UIImage imageNamed:@"bd_cell_single"];
	}
	else
	{
		if(row == 0)
		{
			cell.bkgImage.image = [UIImage imageNamed:@"bd_cell_top"];
		}
		else
			if(row == [tableView numberOfRowsInSection:indexPath.section] - 1)
			{
				cell.bkgImage.image = [UIImage imageNamed:@"bd_cell_bottom"];
			}
			else
			{
				cell.bkgImage.image = [UIImage imageNamed:@"bd_cell_middle"];
			}
	}
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"Selected row %li", (long)indexPath.row);
	//[self launchTransactions];
	[self launchTransactionDetailsWithTransaction:[self.wallet.arrayTransactions objectAtIndex:indexPath.row]];
	
}

#pragma mark BalanceViewDelegates

-(void)BalanceView:(BalanceView *)view changedStateTo:(tBalanceViewState)state
{
	balanceState = state;
	[self.tableView reloadData];
}

#pragma mark UITextField delegates

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	//called when user taps on either search textField or location textField
	
}





-(void)searchTextFieldChanged:(UITextField *)textField
{
	/*//http://107.170.22.83:80/api/v1/autocomplete-location/?term=sa
	NSLog( @"location text changed: %@", textField.text);
	NSString *paramDataString = [NSString stringWithFormat:@"%@/autocomplete-location?term=%@", SERVER_API, [textField.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[[DL_URLServer controller] issueRequestURL:paramDataString
									withParams:nil
									withObject:textField
								  withDelegate:self
							acceptableCacheAge:AGE_ACCEPT_CACHE_SECS
								   cacheResult:YES];*/
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

@end

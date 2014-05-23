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
#import "CoreBridge.h"
#import "NSDate+Helper.h"
#import "TransactionDetailsViewController.h"
#import "ABC.h"
#import "Util.h"
#import "User.h"
#import "InfoView.h"
#import "CommonTypes.h"

#define DOLLAR_CURRENCY_NUM	840

@interface TransactionsViewController () <BalanceViewDelegate, UITableViewDataSource, UITableViewDelegate, TransactionDetailsViewControllerDelegate, UITextFieldDelegate, UIAlertViewDelegate>
{
	BalanceView                         *_balanceView;
	tBalanceViewState                   _balanceState;
	TransactionDetailsViewController    *_transactionDetailsController;
    CGRect                              _transactionTableStartFrame;
    BOOL                                _bSearchModeEnabled;
    CGRect                              _searchShowingFrame;
}

@property (weak, nonatomic) IBOutlet UIView         *viewSearch;
@property (weak, nonatomic) IBOutlet UITextField    *textWalletName;
@property (nonatomic, weak) IBOutlet UIView         *balanceViewPlaceholder;
@property (nonatomic, weak) IBOutlet UITableView    *tableView;
@property (nonatomic, weak) IBOutlet UITextField    *searchTextField;
@property (weak, nonatomic) IBOutlet UIButton       *buttonForward;
@property (weak, nonatomic) IBOutlet UIButton       *buttonRequest;
@property (weak, nonatomic) IBOutlet UIButton       *buttonSend;
@property (weak, nonatomic) IBOutlet UIImageView    *imageWalletNameEmboss;
@property (weak, nonatomic) IBOutlet UIButton       *buttonSearch;

@property (nonatomic, strong) UIButton              *buttonBlocker;
@property (nonatomic, strong) NSMutableArray        *arraySearchTransactions;
@property (nonatomic, strong) NSArray               *arrayNonSearchViews;


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

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:nil];

	_balanceView = [BalanceView CreateWithDelegate:self];
	_balanceView.frame = self.balanceViewPlaceholder.frame;
	[self.balanceViewPlaceholder removeFromSuperview];
	[self.view addSubview:_balanceView];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;

    self.arrayNonSearchViews = [NSArray arrayWithObjects:_balanceView, self.textWalletName, self.buttonForward, self.buttonRequest, self.buttonSend, self.imageWalletNameEmboss, self.buttonSearch, nil];

    self.textWalletName.text = self.wallet.strName;
	self.searchTextField.font = [UIFont fontWithName:@"Montserrat-Regular" size:self.searchTextField.font.pointSize];
	[self.searchTextField addTarget:self action:@selector(searchTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.textWalletName addTarget:self action:@selector(searchTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];

    // set up our user blocking button
    self.buttonBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonBlocker.backgroundColor = [UIColor clearColor];
    [self.buttonBlocker addTarget:self action:@selector(buttonBlockerTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonBlocker.frame = self.view.bounds;
    self.buttonBlocker.hidden = YES;
    [self.view addSubview:self.buttonBlocker];
    [self.view bringSubviewToFront:self.textWalletName];

    _searchShowingFrame = self.viewSearch.frame;

    if (IS_IPHONE5)
    {
        self.buttonSearch.hidden = YES;
    }
    else
    {
        // get the search frame out
        CGRect frame = self.viewSearch.frame;
        frame.origin.x = self.viewSearch.frame.size.width;
        self.viewSearch.frame = frame;
        [self.view bringSubviewToFront:self.viewSearch];

        // move up the controls by the search frame amount
        for (UIView *curView in self.arrayNonSearchViews)
        {
            CGRect frame = curView.frame;
            frame.origin.y -= self.viewSearch.frame.size.height;
            curView.frame = frame;
        }

        // change the table to compensate for now search screen
        frame = self.tableView.frame;
        frame.origin.y -= self.viewSearch.frame.size.height;
        frame.size.height += self.viewSearch.frame.size.height;
        self.tableView.frame = frame;

    }

    _transactionTableStartFrame = self.tableView.frame;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [CoreBridge reloadWallet: self.wallet];
    [self.tableView reloadData];
	[self updateBalanceView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action Methods

- (IBAction)Done
{
    if (_bSearchModeEnabled)
    {
        [self resignAllResponders];
        [self transitionToSearch:NO];
    }
    else
    {
        [self.delegate TransactionsViewControllerDone:self];
    }
}

- (IBAction)info
{
    [InfoView CreateWithHTML:@"infoTransactions" forView:self.view];
}

- (IBAction)buttonBlockerTouched:(id)sender
{
    [self blockUser:NO];
    [self resignAllResponders];
}

- (IBAction)buttonSearchTouched:(id)sender
{
    [self transitionToSearch:YES];
}

#pragma mark - Misc Methods

- (void)updateBalanceView
{
	int64_t totalSatoshi = 0.0;
	for(Transaction * tx in self.wallet.arrayTransactions)
	{
		totalSatoshi += tx.amountSatoshi;
	}
	_balanceView.topAmount.text = [CoreBridge formatSatoshi: totalSatoshi];

	double currency;
	tABC_Error error;

	ABC_SatoshiToCurrency(totalSatoshi, &currency, DOLLAR_CURRENCY_NUM, &error);
    _balanceView.botAmount.text = [CoreBridge formatCurrency: currency];
    _balanceView.topDenomination.text = [User Singleton].denominationLabel;

	[_balanceView refresh];
}

// transition two and from search
- (void)transitionToSearch:(BOOL)bGoToSearch
{
    CGRect frameSearch = self.viewSearch.frame;
    CGRect frame = self.tableView.frame;

    if (bGoToSearch)
    {
        [self.view bringSubviewToFront:self.tableView];
        frame.origin.y = _searchShowingFrame.origin.y + _searchShowingFrame.size.height;
        frame.size.height = self.view.frame.size.height - frame.origin.y - 10;

        if (!IS_IPHONE5)
        {
            [self.searchTextField becomeFirstResponder];
            frameSearch.origin.x = _searchShowingFrame.origin.x;
        }

        _bSearchModeEnabled = YES;
    }
    else
    {
        for (UIView *curView in _arrayNonSearchViews)
        {
            curView.hidden = NO;
        }
        if (IS_IPHONE5)
        {
            self.buttonSearch.hidden = YES;
        }
        else
        {
            frameSearch.origin.x = _searchShowingFrame.size.width;
        }
        frame = _transactionTableStartFrame;
        _bSearchModeEnabled = NO;
    }

    [UIView animateWithDuration:0.35
						  delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
					 animations:^
	 {
         self.tableView.frame = frame;

         if (!IS_IPHONE5)
         {
             self.viewSearch.frame = frameSearch;
         }
	 }
                     completion:^(BOOL finished)
	 {
         if (bGoToSearch)
         {
             for (UIView *curView in _arrayNonSearchViews)
             {
                 curView.hidden = YES;
             }
         }
	 }];



    [self.tableView reloadData];
}

- (void)resignAllResponders
{
    [self.textWalletName resignFirstResponder];
    [self.searchTextField resignFirstResponder];
}

- (void)blockUser:(BOOL)bBlock
{
    if (bBlock)
    {
        self.buttonBlocker.hidden = NO;
    }
    else
    {
        self.buttonBlocker.hidden = YES;
    }
}

//note this method duplicated in WalletsViewController
-(NSString *)conversion:(int64_t)satoshi
{
	if (_balanceState == BALANCE_VIEW_DOWN)
	{
		double currency;
		tABC_Error error;
		
		ABC_SatoshiToCurrency(satoshi, &currency, DOLLAR_CURRENCY_NUM, &error);
		return [CoreBridge formatCurrency:currency];
	}
	else
	{
		return [CoreBridge formatSatoshi:satoshi];
	}
}

-(void)launchTransactionDetailsWithTransaction:(Transaction *)transaction
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_transactionDetailsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionDetailsViewController"];
	
	_transactionDetailsController.delegate = self;
	_transactionDetailsController.transaction = transaction;
	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
	_transactionDetailsController.view.frame = frame;
	[self.view addSubview:_transactionDetailsController.view];
	
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 _transactionDetailsController.view.frame = self.view.bounds;
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
		 _transactionDetailsController.view.frame = frame;
	 }
					 completion:^(BOOL finished)
	 {
		 [_transactionDetailsController.view removeFromSuperview];
		 _transactionDetailsController = nil;
	 }];
}


- (void)checkSearchArray
{
    NSString *search = self.searchTextField.text;
    if (search != NULL && search.length > 0)
    {
        if (self.arraySearchTransactions)
        {
            [self.arraySearchTransactions removeAllObjects];
        }
        else
        {
            self.arraySearchTransactions = [[NSMutableArray alloc] init];
        }
        [CoreBridge searchTransactionsIn:self.wallet query:search addTo:self.arraySearchTransactions];
        [self.tableView reloadData];
    }
    else if (![self searchEnabled])
    {
        [self.tableView reloadData];
    }
}

- (BOOL)searchEnabled
{
    return self.searchTextField.text.length > 0;
}

#pragma mark - TransactionDetailsViewControllerDelegates

-(void)TransactionDetailsViewControllerDone:(TransactionsViewController *)controller
{
    [CoreBridge reloadWallet: self.wallet];
    [self.tableView reloadData];
    [self checkSearchArray];
	[self dismissTransactionDetails];
}

#pragma mark - UITableView delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self searchEnabled]) 
    {
        return self.arraySearchTransactions.count;
    }
    else 
    {
        return self.wallet.arrayTransactions.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 72.0;
}

- (TransactionCell *)getTransactionCellForTableView:(UITableView *)tableView
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = [indexPath row];
	TransactionCell *cell;
	
	//wallet cell
	cell = [self getTransactionCellForTableView:tableView];
	
	
	Transaction* transaction = NULL;
    if ([self searchEnabled]) 
    {
        transaction = [self.arraySearchTransactions objectAtIndex:indexPath.row];
    }
    else
    {
        transaction = [self.wallet.arrayTransactions objectAtIndex:indexPath.row];
    }
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
    if ([self searchEnabled]) 
    {
        [self launchTransactionDetailsWithTransaction:[self.arraySearchTransactions objectAtIndex:indexPath.row]];
    }
    else
    {
        [self launchTransactionDetailsWithTransaction:[self.wallet.arrayTransactions objectAtIndex:indexPath.row]];
    }
	
}

#pragma mark - BalanceViewDelegates

-(void)BalanceView:(BalanceView *)view changedStateTo:(tBalanceViewState)state
{
	_balanceState = state;
	[self.tableView reloadData];
}

#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if (textField == self.textWalletName)
    {
        [self blockUser:YES];
    }
    else if (textField == self.searchTextField)
    {
        [self transitionToSearch:YES];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ((textField == self.textWalletName) && ([textField.text length] == 0))
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Invalid Wallet Name", nil)
                              message:NSLocalizedString(@"You must provide a wallet name.", nil)
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        [self blockUser:NO];
    }
}

- (void)searchTextFieldChanged:(UITextField *)textField
{
    if (textField == self.searchTextField)
    {
        [self checkSearchArray];
    }
    else if (textField == self.textWalletName)
    {
        // need at least one character in a wallet name
        if ([textField.text length])
        {
            //NSLog(@"rename wallet to: %@", textField.text);
            tABC_Error error;
            ABC_RenameWallet([[User Singleton].name UTF8String],
                             [[User Singleton].password UTF8String],
                             [self.wallet.strUUID UTF8String],
                             (char *)[textField.text UTF8String],
                             &error);
            [Util printABC_Error:&error];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];

	return YES;
}


#pragma mark - UIAlertView delegates

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	// the only alert we have that uses a delegate is the one that tells them they must provide a wallet name
    [self.textWalletName becomeFirstResponder];
}

@end

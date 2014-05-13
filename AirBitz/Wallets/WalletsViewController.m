//
//  WalletsViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "WalletsViewController.h"
#import "BalanceView.h"
#import "TransactionsViewController.h"
#import "WalletCell.h"
#import "Wallet.h"
#import "Transaction.h"
#import "ABC.h"
#import "User.h"
#import "WalletMakerView.h"

#define DOLLAR_CURRENCY_NUM	840

@interface WalletsViewController () <BalanceViewDelegate, UITableViewDataSource, UITableViewDelegate, TransactionsViewControllerDelegate, WalletMakerViewDelegate>
{
	BalanceView *balanceView;
	TransactionsViewController *transactionsController;
	BOOL archiveCollapsed;
	double currencyConversionFactor;
	tBalanceViewState balanceState;
	UIView *activeWalletsHeaderView;
	UIView *archivedWalletsHeaderView;
	CGRect originalWalletMakerFrame;
	UIButton *blockingButton;
	BOOL walletMakerVisible;
}

@property (nonatomic, strong) NSMutableArray *arrayWallets;
@property (nonatomic, strong) NSMutableArray *arrayArchivedWallets;

@property (nonatomic, weak) IBOutlet WalletMakerView *walletMakerView;
@property (nonatomic, weak) IBOutlet UIView *headerView;
@property (nonatomic, weak) IBOutlet UIView *balanceViewPlaceholder;
@property (nonatomic, weak) IBOutlet UITableView *walletsTable;
@end

@implementation WalletsViewController

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


    // retrieve the wallets from the server and put them in the two member arrays
    [self getWallets];

	// Do any additional setup after loading the view.
	balanceView = [BalanceView CreateWithDelegate:self];
	balanceView.frame = self.balanceViewPlaceholder.frame;
	[self.balanceViewPlaceholder removeFromSuperview];
	[self.view addSubview:balanceView];
	self.walletsTable.dataSource = self;
	self.walletsTable.delegate = self;
	self.walletsTable.editing = YES;
	self.walletsTable.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.walletsTable.allowsSelectionDuringEditing = YES;
	currencyConversionFactor = 1.0;
	
	CGRect frame = self.walletMakerView.frame;
	originalWalletMakerFrame = frame;
	frame.size.height = 0;
	self.walletMakerView.frame = frame;
	self.walletMakerView.hidden = YES;
    self.walletMakerView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
	[self updateBalanceView];
	
	NSString *CellIdentifier = @"WalletsHeader";
	activeWalletsHeaderView = [self.walletsTable dequeueReusableCellWithIdentifier:CellIdentifier];
	((UITableViewCell *)activeWalletsHeaderView).contentView.layer.cornerRadius = 4.0;
	
	CellIdentifier = @"ArchiveHeader";
	archivedWalletsHeaderView = [self.walletsTable dequeueReusableCellWithIdentifier:CellIdentifier];
	((UITableViewCell *)archivedWalletsHeaderView).contentView.layer.cornerRadius = 4.0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Misc Methods

-(void)createBlockingButtonUnderView:(UIView *)view
{
	blockingButton = [UIButton buttonWithType:UIButtonTypeCustom];
	CGRect frame = self.view.bounds;
	frame.origin.y = self.headerView.frame.origin.y + self.headerView.frame.size.height;
	frame.size.height = self.view.bounds.size.height - frame.origin.y;
	blockingButton.frame = frame;
	blockingButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
	[self.view insertSubview:blockingButton belowSubview:self.walletMakerView];
	blockingButton.alpha = 0.0;
	
	[blockingButton addTarget:self
			   action:@selector(blockingButtonHit:)
	 forControlEvents:UIControlEventTouchDown];
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^
	 {
		 blockingButton.alpha = 1.0;
	 }
	 completion:^(BOOL finished)
	 {
		 
	 }];
	
}

- (void)removeBlockingButton
{
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^
	 {
		 blockingButton.alpha = 0.0;
	 }
					 completion:^(BOOL finished)
	 {
		 [blockingButton removeFromSuperview];
		 blockingButton = nil;
	 }];
}

- (void)blockingButtonHit:(UIButton *)button
{
    [self.walletMakerView exit];
}

// retrieves the wallets from the server and put them in the two member arrays
- (void)getWallets
{
    // alloc our version of the wallets
    self.arrayWallets = [[NSMutableArray alloc] init];
    self.arrayArchivedWallets = [[NSMutableArray alloc] init];

    // TODO: get the wallets from the server

    // temp: create mockup wallets
    Wallet *wallet;
    Transaction *transaction;
    NSMutableArray *arrayTransactions;

    //////////// WALLET ///////////////////
    wallet = [[Wallet alloc] init];
    wallet.strUUID = @"EA9A2034-0630-48D2-BA80-A3EEB239429C";
    wallet.strName = @"Baseball Team";
    wallet.attributes = 0;
    wallet.balance = 15.0;
    wallet.currencyNum = 840;
    arrayTransactions = [[NSMutableArray alloc] init];

    // start add transactions
	transaction = [[Transaction alloc] init];
    transaction.strID = @"3";
    transaction.strName = @"kelly@gmail.com";
    transaction.date = [self dateFromString:@"01/15/2014"];
    transaction.confirmations = 2;
    transaction.bConfirmed = NO;
    transaction.amountSatoshi = 25 * 100000000;
    transaction.balance = 32.5;
    transaction.strWalletName = wallet.strName;
    transaction.strWalletUUID = wallet.strUUID;
    transaction.strAddress = @"1zf76dh4TG";
    [arrayTransactions addObject:transaction];

    transaction = [[Transaction alloc] init];
    transaction.strID = @"2";
    transaction.strName = @"John Madden";
    transaction.date = [self dateFromString:@"12/15/2013"];
    transaction.confirmations = 4;
    transaction.bConfirmed = YES;
    transaction.amountSatoshi = -17.5 * 100000000;
    transaction.balance = 7.5;
    transaction.strWalletName = wallet.strName;
    transaction.strWalletUUID = wallet.strUUID;
    transaction.strAddress = @"1zf76dh4TG";
    [arrayTransactions addObject:transaction];
	
	transaction = [[Transaction alloc] init];
    transaction.strID = @"1";
    transaction.strName = @"Matt Kemp";
    transaction.date = [self dateFromString:@"12/10/2013"];
    transaction.confirmations = 3;
    transaction.bConfirmed = NO;
    transaction.amountSatoshi = 5 * 100000000;
    transaction.balance = 20;
    transaction.strWalletName = wallet.strName;
    transaction.strWalletUUID = wallet.strUUID;
    transaction.strAddress = @"1zf76dh4TG";
    [arrayTransactions addObject:transaction];

    
    // end add transactions

    wallet.arrayTransactions = arrayTransactions;
    [self.arrayWallets addObject:wallet];


    //////////// WALLET ///////////////////
    wallet = [[Wallet alloc] init];
    wallet.strUUID = @"3B48EB14-6A59-41A0-9CA3-3AFE9223B18B";
    wallet.strName = @"Fantasy Football";
    wallet.attributes = 0;
    wallet.balance = 10.0;
    wallet.currencyNum = 840;
    arrayTransactions = [[NSMutableArray alloc] init];

    // start add transactions
	
	transaction = [[Transaction alloc] init];
    transaction.strID = @"3";
    transaction.strName = @"kelly@gmail.com";
    transaction.date = [self dateFromString:@"01/15/2014"];
    transaction.confirmations = 2;
    transaction.bConfirmed = NO;
    transaction.amountSatoshi = -.05593 * 100000000;
    transaction.balance = 8.32177;
    transaction.strWalletName = wallet.strName;
    transaction.strWalletUUID = wallet.strUUID;
    transaction.strAddress = @"1zf76dh4TG";
    [arrayTransactions addObject:transaction];
	
	transaction = [[Transaction alloc] init];
    transaction.strID = @"3";
    transaction.strName = @"kelly@gmail.com";
    transaction.date = [self dateFromString:@"01/15/2014"];
    transaction.confirmations = 2;
    transaction.bConfirmed = NO;
    transaction.amountSatoshi = .1377 * 100000000;
    transaction.balance = 8.3777;
    transaction.strWalletName = wallet.strName;
    transaction.strWalletUUID = wallet.strUUID;
    transaction.strAddress = @"1zf76dh4TG";
    [arrayTransactions addObject:transaction];
	
	transaction = [[Transaction alloc] init];
    transaction.strID = @"2";
    transaction.strName = @"John Madden";
    transaction.date = [self dateFromString:@"12/15/2013"];
    transaction.confirmations = 4;
    transaction.bConfirmed = YES;
    transaction.amountSatoshi = -4.12 * 100000000;
    transaction.balance = 8.24;
    transaction.strWalletName = wallet.strName;
    transaction.strWalletUUID = wallet.strUUID;
    transaction.strAddress = @"1zf76dh4TG";
    [arrayTransactions addObject:transaction];
	
	transaction = [[Transaction alloc] init];
    transaction.strID = @"1";
    transaction.strName = @"Matt Kemp";
    transaction.date = [self dateFromString:@"12/10/2013"];
    transaction.confirmations = 3;
    transaction.bConfirmed = NO;
    transaction.amountSatoshi = 2.36 * 100000000;
    transaction.balance = 12.36;
    transaction.strWalletName = wallet.strName;
    transaction.strWalletUUID = wallet.strUUID;
    transaction.strAddress = @"kelly@gmail.com";
    [arrayTransactions addObject:transaction];
    // end add transactions

    wallet.arrayTransactions = arrayTransactions;
    [self.arrayWallets addObject:wallet];

    //////////// WALLET ///////////////////
    wallet = [[Wallet alloc] init];
    wallet.strUUID = @"0DF082BA-1734-4C63-8ECF-026C6AAEC762";
    wallet.strName = @"Shared";
    wallet.attributes = WALLET_ATTRIBUTE_ARCHIVE_BIT;
    wallet.balance = 0.0;
    wallet.currencyNum = 840;
    arrayTransactions = [[NSMutableArray alloc] init];

    // start add transactions
    // end add transactions

    wallet.arrayTransactions = arrayTransactions;
    [self.arrayArchivedWallets addObject:wallet];

    //////////// WALLET ///////////////////
    wallet = [[Wallet alloc] init];
    wallet.strUUID = @"F94D06DF-5A66-4A80-AF5F-9B769FC517AE";
    wallet.strName = @"Mexico";
    wallet.attributes = WALLET_ATTRIBUTE_ARCHIVE_BIT;
    wallet.balance = 0.0;
    wallet.currencyNum = 840;
    arrayTransactions = [[NSMutableArray alloc] init];

    // start add transactions
    // end add transactions

    wallet.arrayTransactions = arrayTransactions;
    [self.arrayArchivedWallets addObject:wallet];

    //////////// WALLET ///////////////////
    wallet = [[Wallet alloc] init];
    wallet.strUUID = @"1386D0B0-99C4-43CF-91D5-841446E84C71";
    wallet.strName = @"Other";
    wallet.attributes = WALLET_ATTRIBUTE_ARCHIVE_BIT;
    wallet.balance = 0.0;
    wallet.currencyNum = 840;
    arrayTransactions = [[NSMutableArray alloc] init];

    // start add transactions
    // end add transactions

    wallet.arrayTransactions = arrayTransactions;
    [self.arrayArchivedWallets addObject:wallet];

    //////////// WALLET ///////////////////
	wallet = [[Wallet alloc] init];
    wallet.strUUID = @"BDCF6578-67C4-43CF-91D5-841446E84C72";
    wallet.strName = @"Vacation";
    wallet.attributes = WALLET_ATTRIBUTE_ARCHIVE_BIT;
    wallet.balance = 0.00046;
    wallet.currencyNum = 840;
    arrayTransactions = [[NSMutableArray alloc] init];

    // start add transactions
    // end add transactions

    wallet.arrayTransactions = arrayTransactions;
    [self.arrayArchivedWallets addObject:wallet];

    //////////// WALLET ///////////////////
	wallet = [[Wallet alloc] init];
    wallet.strUUID = @"1386D0B0-78C4-43CF-9235-841446E84C73";
    wallet.strName = @"House Projects";
    wallet.attributes = WALLET_ATTRIBUTE_ARCHIVE_BIT;
    wallet.balance = 0.32;
    wallet.currencyNum = 840;
    arrayTransactions = [[NSMutableArray alloc] init];

    // start add transactions
    // end add transactions

    wallet.arrayTransactions = arrayTransactions;
    [self.arrayArchivedWallets addObject:wallet];

    //////////// WALLET ///////////////////
	wallet = [[Wallet alloc] init];
    wallet.strUUID = @"1386D0B0-89C4-43CF-3EAD-841446E84C74";
    wallet.strName = @"Rainy Day";
    wallet.attributes = WALLET_ATTRIBUTE_ARCHIVE_BIT;
    wallet.balance = 0.1857;
    wallet.currencyNum = 840;
    arrayTransactions = [[NSMutableArray alloc] init];

    // start add transactions
    // end add transactions

    wallet.arrayTransactions = arrayTransactions;
    [self.arrayArchivedWallets addObject:wallet];

    //////////// WALLET ///////////////////
	wallet = [[Wallet alloc] init];
    wallet.strUUID = @"1386D0B0-90C4-43CF-7889-841446E84C75";
    wallet.strName = @"Car Repair";
    wallet.attributes = WALLET_ATTRIBUTE_ARCHIVE_BIT;
    wallet.balance = 2.35689;
    wallet.currencyNum = 840;
    arrayTransactions = [[NSMutableArray alloc] init];

    // start add transactions
    // end add transactions

    wallet.arrayTransactions = arrayTransactions;
    [self.arrayArchivedWallets addObject:wallet];

    //////////// WALLET ///////////////////
	wallet = [[Wallet alloc] init];
    wallet.strUUID = @"1386D0B0-05C4-44AF-9145-841446E84C76";
    wallet.strName = @"Wal Mart";
    wallet.attributes = WALLET_ATTRIBUTE_ARCHIVE_BIT;
    wallet.balance = 0.28571;
    wallet.currencyNum = 840;
    arrayTransactions = [[NSMutableArray alloc] init];

    // start add transactions
    // end add transactions

    wallet.arrayTransactions = arrayTransactions;
    [self.arrayArchivedWallets addObject:wallet];

	
    //NSLog(@"Wallets: %@", self.arrayWallets);
    //NSLog(@"Archived Wallets: %@", self.arrayArchivedWallets);
}

// creates an NSDate object given a string with mm/dd/yyyy
- (NSDate *)dateFromString:(NSString *)strDate
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *date = [formatter dateFromString:strDate];
    return date;
}

-(void)updateBalanceView
{
	double totalBitcoin = 0;
	
	for(Wallet * wallet in self.arrayWallets)
	{
		totalBitcoin += wallet.balance;
	}
	
	balanceView.topAmount.text = [NSString stringWithFormat:@"B %.2f", totalBitcoin];
	
	double currency;
	tABC_Error error;
	
	ABC_SatoshiToCurrency(ABC_BitcoinToSatoshi(totalBitcoin), &currency, DOLLAR_CURRENCY_NUM, &error);
	balanceView.botAmount.text = [NSString stringWithFormat:@"$ %.2f", currency];
	[balanceView refresh];
}

-(IBAction)addWallet
{
	if (walletMakerVisible == NO)
	{
        [self.walletMakerView reset];
		walletMakerVisible = YES;
		self.walletMakerView.hidden = NO;
		[[self.walletMakerView superview] bringSubviewToFront:self.walletMakerView];
		[self createBlockingButtonUnderView:self.walletMakerView];
		[UIView animateWithDuration:0.35
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseOut
						 animations:^
		 {
			 self.walletMakerView.frame = originalWalletMakerFrame;
		 }
		 completion:^(BOOL finished)
		 {

		 }];
	}
}

-(void)hideWalletMaker
{
	if(walletMakerVisible == YES)
	{
		walletMakerVisible = NO;

		
		CGRect frame = self.walletMakerView.frame;
		frame.size.height = 0;
		[UIView animateWithDuration:0.35
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseOut
						 animations:^
		 {
			 self.walletMakerView.frame = frame;
		 }
						 completion:^(BOOL finished)
		 {
			 self.walletMakerView.hidden = YES;
		 }];
	}
}

- (IBAction)info
{
}

//note this method duplicated in TransactionsViewController
- (NSString *)conversion:(double)bitCoin
{
	if(balanceState == BALANCE_VIEW_DOWN)
	{
		//dollars
		double currency;
		tABC_Error error;
		
		ABC_SatoshiToCurrency(ABC_BitcoinToSatoshi(bitCoin), &currency, DOLLAR_CURRENCY_NUM, &error);
		return [NSString stringWithFormat:@"$ %.2f", currency];
	}
	else
	{
		//bitcoin
		return [NSString stringWithFormat:@"B %.2f", bitCoin];
	}
}

- (IBAction)ExpandCollapseArchive:(UIButton *)sender
{
	if(archiveCollapsed)
	{
		archiveCollapsed = NO;
		[UIView animateWithDuration:0.35
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^
		 {
			 sender.transform = CGAffineTransformRotate(sender.transform, M_PI);
		 }
		 completion:^(BOOL finished)
		 {
			 NSInteger countOfRowsToInsert = self.arrayArchivedWallets.count;
			 NSMutableArray *indexPathsToInsert = [[NSMutableArray alloc] init];
			 for (NSInteger i = 0; i < countOfRowsToInsert; i++)
			 {
				 [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:1]];
			 }
			 
			 UITableViewRowAnimation insertAnimation = UITableViewRowAnimationTop;

			 // apply the updates
			 [self.walletsTable beginUpdates];
			 [self.walletsTable insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:insertAnimation];
			 [self.walletsTable endUpdates];

		 }];
	}
	else
	{
		archiveCollapsed = YES;
		[UIView animateWithDuration:0.35
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^
		 {
			 sender.transform = CGAffineTransformRotate(sender.transform, -M_PI);
		 }
		completion:^(BOOL finished)
		 {
			 NSInteger countOfRowsToDelete = self.arrayArchivedWallets.count;
			 
			 if (countOfRowsToDelete > 0)
			 {
				 NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
				 for (NSInteger i = 0; i < countOfRowsToDelete; i++)
				 {
					 [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:1]];
				 }
				 [self.walletsTable deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];
			 }
		 }];
	}
}

#pragma mark - Segue

- (void)launchTransactionsWithWallet:(Wallet *)wallet
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	transactionsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionsViewController"];
	
	transactionsController.delegate = self;
	transactionsController.wallet = wallet;
	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
	transactionsController.view.frame = frame;
	[self.view addSubview:transactionsController.view];
	
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 transactionsController.view.frame = self.view.bounds;
	 }
					 completion:^(BOOL finished)
	 {
	 }];
	
}

-(void)dismissTransactions
{
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = self.view.bounds;
		 frame.origin.x = frame.size.width;
		 transactionsController.view.frame = frame;
	 }
					 completion:^(BOOL finished)
	 {
		 [transactionsController.view removeFromSuperview];
		 transactionsController = nil;
	 }];
}

#pragma mark - TransactionsViewControllerDelegates

-(void)TransactionsViewControllerDone:(TransactionsViewController *)controller
{
	[self dismissTransactions];
}

#pragma mark - UITableView delegates


- (BOOL)tableView:(UITableView *)tableView
shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	Wallet *wallet;
	if(sourceIndexPath.section == 0)
	{
		wallet = [self.arrayWallets objectAtIndex:sourceIndexPath.row];
		[self.arrayWallets removeObjectAtIndex:sourceIndexPath.row];
	}
	else
	{
		wallet = [self.arrayArchivedWallets objectAtIndex:sourceIndexPath.row];
		[self.arrayArchivedWallets removeObjectAtIndex:sourceIndexPath.row];
	}
	
	if(destinationIndexPath.section == 0)
	{
		wallet.attributes &= ~WALLET_ATTRIBUTE_ARCHIVE_BIT;
		[self.arrayWallets insertObject:wallet atIndex:destinationIndexPath.row];
		
	}
	else
	{
		wallet.attributes |= WALLET_ATTRIBUTE_ARCHIVE_BIT;
		[self.arrayArchivedWallets insertObject:wallet atIndex:destinationIndexPath.row];
	}
	[self updateBalanceView];
	[self.walletsTable reloadData];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44.0;
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	
   // static NSString *CellIdentifier;
	
	if(section == 0)
	{
		 //CellIdentifier = @"WalletsHeader";
		 //NSLog(@"Active wallets header view: %@", activeWalletsHeaderView);
		 return activeWalletsHeaderView;
	}
	else
	{
		//CellIdentifier = @"ArchiveHeader";
		return archivedWalletsHeaderView;
	}
    /*UITableViewCell *headerView = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (headerView == nil)
	{
        [NSException raise:@"headerView == nil.." format:@"No cells with matching CellIdentifier loaded from your storyboard"];
    }
    return headerView;*/
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 0)
	{
		return self.arrayWallets.count;
	}
	else
	{
		if(archiveCollapsed)
		{
			return 0;
		}
		else
		{
			return self.arrayArchivedWallets.count;
		}
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44.0;
}

-(WalletCell *)getWalletCellForTableView:(UITableView *)tableView
{
	WalletCell *cell;
	static NSString *cellIdentifier = @"WalletCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[WalletCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	return cell;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = [indexPath row];
	WalletCell *cell;
	
	//wallet cell
	cell = [self getWalletCellForTableView:tableView];

	if(indexPath.section == 0)
	{
		Wallet *wallet = [self.arrayWallets objectAtIndex:row];
		cell.name.text = wallet.strName;
		cell.amount.text = [self conversion:wallet.balance];
	}
	else
	{
		Wallet *wallet = [self.arrayArchivedWallets objectAtIndex:row];
		cell.name.text = wallet.strName;
		cell.amount.text = [self conversion:wallet.balance];
	}
	
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
	//NSLog(@"Selected row %i", indexPath.row);
	if(indexPath.section == 0)
	{
		[self launchTransactionsWithWallet:[self.arrayWallets objectAtIndex:indexPath.row]];
	}
	else
	{
		[self launchTransactionsWithWallet:[self.arrayArchivedWallets objectAtIndex:indexPath.row]];
	}
}

#pragma mark - BalanceView Delegates

-(void)BalanceView:(BalanceView *)view changedStateTo:(tBalanceViewState)state
{
	balanceState = state;
	[self.walletsTable reloadData];
}

#pragma mark - Wallet Maker View Delegates

- (void)walletMakerViewExit:(WalletMakerView *)walletMakerView
{
	[self hideWalletMaker];
	[self removeBlockingButton];
}

@end

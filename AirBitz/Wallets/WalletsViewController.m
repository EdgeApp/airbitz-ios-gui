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
#import "CoreBridge.h"
#import "OfflineWalletViewController.h"
#import "InfoView.h"
#import "Util.h"
#import "WalletHeaderView.h"

@interface WalletsViewController () <BalanceViewDelegate, UITableViewDataSource, UITableViewDelegate, TransactionsViewControllerDelegate, WalletMakerViewDelegate, OfflineWalletViewControllerDelegate, WalletHeaderViewDelegate>
{
	BalanceView                 *_balanceView;
	TransactionsViewController  *_transactionsController;
	BOOL                        _archiveCollapsed;
	double                      _currencyConversionFactor;
	tBalanceViewState           _balanceState;
	
	CGRect                      _originalWalletMakerFrame;
	UIButton                    *_blockingButton;
	BOOL                        _walletMakerVisible;
    OfflineWalletViewController *_offlineWalletViewController;
}

@property (nonatomic, strong) NSMutableArray *arrayWallets;
@property (nonatomic, strong) NSMutableArray *arrayArchivedWallets;
@property (nonatomic, strong) WalletHeaderView         *activeWalletsHeaderView;
@property (nonatomic, strong) WalletHeaderView         *archivedWalletsHeaderView;
@property (nonatomic, weak) IBOutlet WalletMakerView    *walletMakerView;
@property (nonatomic, weak) IBOutlet UIView             *headerView;
@property (nonatomic, weak) IBOutlet UIView             *balanceViewPlaceholder;
@property (nonatomic, weak) IBOutlet UITableView        *walletsTable;
@end

@implementation WalletsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:nil];

	_balanceView = [BalanceView CreateWithDelegate:self];
	_balanceView.frame = self.balanceViewPlaceholder.frame;
	[self.balanceViewPlaceholder removeFromSuperview];
	[self.view addSubview:_balanceView];
	self.walletsTable.dataSource = self;
	self.walletsTable.delegate = self;
	self.walletsTable.editing = YES;
	self.walletsTable.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.walletsTable.allowsSelectionDuringEditing = YES;
	_currencyConversionFactor = 1.0;
	
	CGRect frame = self.walletMakerView.frame;
	_originalWalletMakerFrame = frame;
	frame.size.height = 0;
	self.walletMakerView.frame = frame;
	self.walletMakerView.hidden = YES;
    self.walletMakerView.delegate = self;
	
	self.activeWalletsHeaderView = [WalletHeaderView CreateWithTitle:NSLocalizedString(@"WALLETS", @"title of active wallets table")];
	self.activeWalletsHeaderView.btn_expandCollapse.hidden = YES;
	
	self.archivedWalletsHeaderView = [WalletHeaderView CreateWithTitle:NSLocalizedString(@"ARCHIVE", @"title of archived wallets table")];
	self.archivedWalletsHeaderView.delegate = self;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    [self reloadWallets];
    [self.walletsTable reloadData];
	[self updateBalanceView];
	
/*	NSString *CellIdentifier = @"WalletsHeader";
	_activeWalletsHeaderView = [self.walletsTable dequeueReusableCellWithIdentifier:CellIdentifier];
	((UITableViewCell *)_activeWalletsHeaderView).contentView.layer.cornerRadius = 4.0;
	
	CellIdentifier = @"ArchiveHeader";
	_archivedWalletsHeaderView = [self.walletsTable dequeueReusableCellWithIdentifier:CellIdentifier];
	((UITableViewCell *)_archivedWalletsHeaderView).contentView.layer.cornerRadius = 4.0;*/
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)resetViews
{
    if (_transactionsController)
    {
		 [_transactionsController.view removeFromSuperview];
		 _transactionsController = nil;
    }
}

#pragma mark - Misc Methods

// select the wallet with the given UUID
- (void)selectWalletWithUUID:(NSString *)strUUID
{
    if (strUUID)
    {
        if ([strUUID length])
        {
            [self resetViews];
            [self reloadWallets];
            // If the transaction view is open, close it

            Wallet *wallet = nil;

            // look for the wallet in our arrays
            for (Wallet *curWallet in self.arrayWallets)
            {
                if ([strUUID isEqualToString:curWallet.strUUID])
                {
                    wallet = curWallet;
                    break;
                }
            }

            // if we haven't found it yet, try the archived wallets
            if (nil == wallet)
            {
                for (Wallet *curWallet in self.arrayArchivedWallets)
                {
                    if ([strUUID isEqualToString:curWallet.strUUID])
                    {
                        wallet = curWallet;
                        break;
                    }
                }
            }
            
            // if we found it
            if (nil != wallet)
            {
                [self launchTransactionsWithWallet:wallet animated:NO];
            }
        }
    }
}

-(void)createBlockingButtonUnderView:(UIView *)view
{
	_blockingButton = [UIButton buttonWithType:UIButtonTypeCustom];
	CGRect frame = self.view.bounds;
	frame.origin.y = self.headerView.frame.origin.y + self.headerView.frame.size.height;
	frame.size.height = self.view.bounds.size.height - frame.origin.y;
	_blockingButton.frame = frame;
	_blockingButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
	[self.view insertSubview:_blockingButton belowSubview:self.walletMakerView];
	_blockingButton.alpha = 0.0;

	[_blockingButton addTarget:self
			   action:@selector(blockingButtonHit:)
	 forControlEvents:UIControlEventTouchDown];
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^
	 {
		 _blockingButton.alpha = 1.0;
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
        _blockingButton.alpha = 0.0;
    }
    completion:^(BOOL finished)
    {
        [_blockingButton removeFromSuperview];
        _blockingButton = nil;
    }];
}

- (void)blockingButtonHit:(UIButton *)button
{
    [self.walletMakerView exit];
}

// retrieves the wallets from disk and put them in the two member arrays
- (void)reloadWallets
{
    if (self.arrayWallets == nil)
    {
        self.arrayWallets = [[NSMutableArray alloc] init];
        self.arrayArchivedWallets = [[NSMutableArray alloc] init];
    }
    else
    {
        [self.arrayWallets removeAllObjects];
        [self.arrayArchivedWallets removeAllObjects];
    }
    [CoreBridge loadWallets: self.arrayWallets archived:self.arrayArchivedWallets];
}

// creates an NSDate object given a string with mm/dd/yyyy
- (NSDate *)dateFromString:(NSString *)strDate
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *date = [formatter dateFromString:strDate];
    return date;
}

- (NSDate *)dateFromTimestamp:(int64_t) intDate
{
    return [NSDate dateWithTimeIntervalSince1970: intDate];
}

- (void)updateBalanceView
{
	int64_t totalSatoshi = 0.0;
	
	for(Wallet * wallet in self.arrayWallets)
	{
		totalSatoshi += wallet.balance;
	}
	_balanceView.topAmount.text = [CoreBridge formatSatoshi: totalSatoshi];
	
	double currency;
	tABC_Error Error;
	ABC_SatoshiToCurrency([[User Singleton].name UTF8String],
                          [[User Singleton].password UTF8String],
                          totalSatoshi, &currency,
                          [[User Singleton] defaultCurrencyNum], &Error);
    [Util printABC_Error:&Error];
    _balanceView.botAmount.text = [CoreBridge formatCurrency:currency 
                                             withCurrencyNum:[[User Singleton] defaultCurrencyNum]];
    _balanceView.topDenomination.text = [User Singleton].denominationLabel;
    _balanceView.botDenomination.text = [CoreBridge currencyAbbrevLookup:[User Singleton].defaultCurrencyNum];
	[_balanceView refresh];
}

- (void)hideWalletMaker
{
	if (_walletMakerVisible == YES)
	{
		_walletMakerVisible = NO;
		
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


//note this method duplicated in TransactionsViewController
- (NSString *)conversion:(int64_t)satoshi
{
	if (_balanceState == BALANCE_VIEW_DOWN)
	{
		double currency;
		tABC_Error error;
		ABC_SatoshiToCurrency([[User Singleton].name UTF8String],
                              [[User Singleton].password UTF8String],
                              satoshi, &currency,
                              [[User Singleton] defaultCurrencyNum], &error);
        [Util printABC_Error:&error];
        return [CoreBridge formatCurrency:currency
                          withCurrencyNum:[[User Singleton] defaultCurrencyNum]];
	}
	else
	{
		return [CoreBridge formatSatoshi:satoshi];
	}
}

- (void)bringUpOfflineWalletView
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    _offlineWalletViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"OfflineWalletViewController"];

    _offlineWalletViewController.delegate = self;

    CGRect frame = self.view.bounds;
    frame.origin.x = frame.size.width;
    _offlineWalletViewController.view.frame = frame;
    [self.view addSubview:_offlineWalletViewController.view];

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         _offlineWalletViewController.view.frame = self.view.bounds;
     }
                     completion:^(BOOL finished)
     {
         [self hideWalletMaker];
         [self removeBlockingButton];
     }];
}

#pragma mark - Action Methods

- (IBAction)addWallet
{
	if (_walletMakerVisible == NO)
	{
        [self.walletMakerView reset];
		_walletMakerVisible = YES;
		self.walletMakerView.hidden = NO;
		[[self.walletMakerView superview] bringSubviewToFront:self.walletMakerView];
		[self createBlockingButtonUnderView:self.walletMakerView];
        [self.walletMakerView.textField becomeFirstResponder];
		[UIView animateWithDuration:0.35
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseOut
						 animations:^
		 {
			 self.walletMakerView.frame = _originalWalletMakerFrame;
		 }
                         completion:^(BOOL finished)
		 {

		 }];
	}
}

- (IBAction)info
{
    [InfoView CreateWithHTML:@"infoWallets" forView:self.view];
}

#pragma mark - WalletHeaderViewDelegates

//- (IBAction)ExpandCollapseArchive:(UIButton *)sender
-(void)walletHeaderView:(WalletHeaderView *)walletHeaderView Expanded:(BOOL)expanded
{
	if(expanded)
	{
		_archiveCollapsed = NO;
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
	}
	else
	{
		_archiveCollapsed = YES;
		NSInteger countOfRowsToDelete = self.arrayArchivedWallets.count;
		//NSLog(@"Rows to collapse: %i", countOfRowsToDelete);
		if (countOfRowsToDelete > 0)
		{
			NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
			for (NSInteger i = 0; i < countOfRowsToDelete; i++)
			{
				[indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:1]];
			}
			[self.walletsTable deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];
		}
	}
}

#pragma mark - Segue

- (void)launchTransactionsWithWallet:(Wallet *)wallet animated:(BOOL)bAnimated
{
    if (_transactionsController) {
        return;
    }
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_transactionsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionsViewController"];
	_transactionsController.delegate = self;
	_transactionsController.wallet = wallet;

	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
	_transactionsController.view.frame = frame;
	[self.view addSubview:_transactionsController.view];
	
	if (bAnimated)
    {
        [UIView animateWithDuration:0.35
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
        {
            _transactionsController.view.frame = self.view.bounds;
        }
        completion:^(BOOL finished)
        {
        }];
    }
    else
    {
        _transactionsController.view.frame = self.view.bounds;
    }
}

- (void)dismissTransactions
{
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = self.view.bounds;
		 frame.origin.x = frame.size.width;
		 _transactionsController.view.frame = frame;
	 }
					 completion:^(BOOL finished)
	 {
		 [_transactionsController.view removeFromSuperview];
		 _transactionsController = nil;
	 }];
}

#pragma mark - TransactionsViewControllerDelegates

- (void)TransactionsViewControllerDone:(TransactionsViewController *)controller
{
    [self reloadWallets];
    [self.walletsTable reloadData];
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
    [CoreBridge setWalletAttributes:wallet];
    [CoreBridge setWalletOrder: self.arrayWallets archived: self.arrayArchivedWallets];
	[self updateBalanceView];
	[self.walletsTable reloadData];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44.0;
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	
    //NSString *CellIdentifier;
	
	if(section == 0)
	{
		 //CellIdentifier = @"WalletsHeader";
		 //NSLog(@"Active wallets header view: %@", activeWalletsHeaderView);
		 return _activeWalletsHeaderView;
	}
	else
	{
		//CellIdentifier = @"ArchiveHeader";
		return _archivedWalletsHeaderView;
	}
    /*UITableViewCell *headerView = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (headerView == nil)
	{
        [NSException raise:@"headerView == nil.." format:@"No cells with matching CellIdentifier loaded from your storyboard"];
    }
	
	((UITableViewCell *)headerView).contentView.layer.cornerRadius = 4.0;
	
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
		//NSLog(@"Section 0 rows: %i", self.arrayWallets.count);
		return self.arrayWallets.count;
	}
	else
	{
		if(_archiveCollapsed)
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
            if (indexPath.section == 0)
            {
                cell.bkgImage.image = [UIImage imageNamed:@"bd_highlighted_cell_top"];
            }
            else
            {
			cell.bkgImage.image = [UIImage imageNamed:@"bd_cell_top"];
            }
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
	if(indexPath.section == 0)
	{
		[self launchTransactionsWithWallet:[self.arrayWallets objectAtIndex:indexPath.row] animated:YES];
	}
	else
	{
		[self launchTransactionsWithWallet:[self.arrayArchivedWallets objectAtIndex:indexPath.row] animated:YES];
	}
}

#pragma mark - BalanceView Delegates

-(void)BalanceView:(BalanceView *)view changedStateTo:(tBalanceViewState)state
{
	_balanceState = state;
	[self.walletsTable reloadData];
}

#pragma mark - Wallet Maker View Delegates

- (void)walletMakerViewExit:(WalletMakerView *)walletMakerView
{
	[self hideWalletMaker];
	[self removeBlockingButton];

    [self reloadWallets];
    [self.walletsTable reloadData];
	[self updateBalanceView];
}

- (void)walletMakerViewExitOffline:(WalletMakerView *)walletMakerView
{
    [self bringUpOfflineWalletView];
}

#pragma mark - Offline Wallet Delegates

- (void)offlineWalletViewControllerDidFinish:(OfflineWalletViewController *)controller
{
	[controller.view removeFromSuperview];
	_offlineWalletViewController = nil;
}

@end

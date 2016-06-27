//
//  TransactionsViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "TransactionsViewController.h"
#import "ExportWalletViewController.h"
#import "BalanceView.h"
#import "TransactionCell.h"
#import "ABCTransaction.h"
#import "AirbitzCore.h"
#import "NSDate+Helper.h"
#import "TransactionDetailsViewController.h"
#import "Util.h"
#import "User.h"
#import "InfoView.h"
#import "CommonTypes.h"
#import "Server.h"
#import "CJSONDeserializer.h"
#import "MainViewController.h"
#import "Theme.h"
#import "WalletHeaderView.h"
#import "WalletCell.h"
#import "WalletMakerView.h"
#import "LocalSettings.h"
#import "Theme.h"
#import "FadingAlertView.h"
#import "TransactionsHeaderView.h"

#define COLOR_POSITIVE [UIColor colorWithRed:0.3720 green:0.6588 blue:0.1882 alpha:1.0]
#define COLOR_NEGATIVE [UIColor colorWithRed:0.7490 green:0.1804 blue:0.1922 alpha:1.0]
#define COLOR_BALANCE  [UIColor colorWithRed:83.0/255.0 green:90.0/255.0 blue:91.0/255.0 alpha:1.0];

#define TABLE_SIZE_HEIGHT_REDUCE_SEARCH_WITH_KEYBOARD 160

#define PHOTO_BORDER_WIDTH          2.0f
#define PHOTO_BORDER_COLOR          [UIColor lightGrayColor]
#define PHOTO_BORDER_CORNER_RADIUS  5.0

#define WALLET_SECTION_BALANCE  0
#define WALLET_SECTION_ACTIVE   1
#define WALLET_SECTION_ARCHIVED 2

#define NO_SEARCHBAR 1

#define CACHE_IMAGE_AGE_SECS (60 * 60) // 60 hour

#define ARCHIVE_COLLAPSED @"archive_collapsed"

const int PromoIndexBuyBitcoin      = 0;
const int PromoIndexImportGiftCard  = 1;
const int PromoIndex20offStarbucks  = 2;
const int PromoIndex10offTarget     = 3;
const int PromoIndex15to20offAmazon = 4;
const int NumPromoRows              = 5;


@interface TransactionsViewController () <BalanceViewDelegate, UITableViewDataSource, UITableViewDelegate, TransactionsViewControllerDelegate, WalletHeaderViewDelegate, WalletMakerViewDelegate,
        TransactionDetailsViewControllerDelegate, UISearchBarDelegate, UIAlertViewDelegate, ExportWalletViewControllerDelegate, UIGestureRecognizerDelegate>
{
    BalanceView                         *_balanceView;
    ABCWallet *longTapWallet;
    UIAlertView                         *longTapAlert;
    UIAlertView                         *renameAlert;
    UIAlertView                         *deleteAlert;
    UIAlertView                         *deleteAlertWarning;

    NSCalendar                          *_cal;
    BOOL                                _archiveCollapsed;
    BOOL                                _showRunningBalance;
    CGRect                              _transactionTableStartFrame;
    BOOL                                _bWalletsShowing;
    BOOL                                _bNewDeviceLogin;
    BOOL                                _bShowingWalletsLoadingAlert;
//    CGRect                              _searchShowingFrame;
    BOOL                                _bWalletNameWarningDisplaying;
    CGRect                              _frameTableWithSearchNoKeyboard;
    BOOL                                _walletMakerVisible;
    UIButton                            *_blockingButton;
    NSOperationQueue                    *txSearchQueue;
    BOOL                                _segmentedControlUSD;
    int64_t                             _totalSatoshi;
    UIImage                             *_blankImage;
    NSDateFormatter                     *_dateFormatterDate;
    NSDateFormatter                     *_dateFormatterTime;
    NSMutableArray                      *_arraySections;
    NSMutableArray                      *_arraySectionsStart;
    NSMutableArray                      *_arraySectionsTitle;
}

@property (nonatomic, weak) IBOutlet WalletMakerView    *walletMakerView;
@property (weak, nonatomic) IBOutlet UITableView        *walletsTable;
@property (weak, nonatomic) IBOutlet UIToolbar          *toolbarBlur;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *walletsViewTop;
@property (weak, nonatomic) IBOutlet UIView             *walletsView;
@property (nonatomic, weak) IBOutlet BalanceView    *balanceViewPlaceholder;
@property (nonatomic, weak) IBOutlet UITableView    *tableView;
@property (nonatomic, weak) IBOutlet UISearchBar    *searchTextField;
//@property (weak, nonatomic) IBOutlet UIButton       *buttonExport;
@property (weak, nonatomic) IBOutlet UIButton       *buttonRequest;
@property (weak, nonatomic) IBOutlet UIButton       *buttonSend;
@property (nonatomic, strong) WalletHeaderView         *balanceHeaderView;
@property (nonatomic, strong) WalletHeaderView         *activeWalletsHeaderView;
@property (nonatomic, strong) WalletHeaderView         *archivedWalletsHeaderView;
@property (nonatomic, strong) UIImage               *imageReceive;
@property (nonatomic, strong) UIImage               *imageSend;
@property (weak, nonatomic) IBOutlet UIView *buttonsShadowView;


@property (weak, nonatomic) IBOutlet UIImageView    *imageWalletNameEmboss;
//@property (weak, nonatomic) IBOutlet UIButton       *buttonSearch;

@property (nonatomic, strong) UIButton              *buttonBlocker;
@property (nonatomic, strong) NSMutableArray        *arraySearchTransactions;

@property (nonatomic, strong) TransactionDetailsViewController      *transactionDetailsController;
@property (nonatomic, strong) ExportWalletViewController            *exportWalletViewController;
@property (nonatomic, strong) NSTimer                               *walletLoadingTimer;
@property (strong, nonatomic) AFHTTPRequestOperationManager         *afmanager;




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

    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];

    // alloc the arrays
    self.arraySearchTransactions = [[NSMutableArray alloc] init];

    // load all the names from the address book
    [MainViewController generateListOfContactNames];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.walletMakerView.hidden = YES;
    self.walletMakerView.delegate = self;
    self.walletLoadingTimer = nil;

    // set up our user blocking button
    self.buttonBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonBlocker.backgroundColor = [UIColor clearColor];
    [self.buttonBlocker addTarget:self action:@selector(buttonBlockerTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonBlocker.frame = self.view.bounds;
    self.buttonBlocker.hidden = YES;
    [self.view addSubview:self.buttonBlocker];

    _bWalletsShowing = NO;
    _bShowingWalletsLoadingAlert = NO;
    _balanceView = [BalanceView CreateWithDelegate:self];
    _showRunningBalance = [LocalSettings controller].showRunningBalance;
    _arraySections = [[NSMutableArray alloc] init];
    _arraySectionsStart = [[NSMutableArray alloc] init];
    _arraySectionsTitle = [[NSMutableArray alloc] init];

    [self.balanceViewPlaceholder addSubview:_balanceView];
    [_balanceView showBalance:NO];
    
    _dateFormatterDate = [[NSDateFormatter alloc] init];
    [_dateFormatterDate setDateStyle:NSDateFormatterMediumStyle];
    [_dateFormatterDate setTimeStyle:NSDateFormatterNoStyle];
    
    _dateFormatterTime = [[NSDateFormatter alloc] init];
    [_dateFormatterTime setDateStyle:NSDateFormatterNoStyle];
    [_dateFormatterTime setTimeStyle:NSDateFormatterShortStyle];
    
    txSearchQueue = [[NSOperationQueue alloc] init];
    [txSearchQueue setMaxConcurrentOperationCount:1];

    self.searchTextField.enablesReturnKeyAutomatically = NO;

    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    tableViewController.refreshControl = [[UIRefreshControl alloc] init];
    [tableViewController.refreshControl addTarget:self
                                           action:@selector(refresh:)
                                 forControlEvents:UIControlEventValueChanged];

    _transactionTableStartFrame = self.tableView.frame;

    [self initializeWalletsTable];
    
    
    self.buttonsShadowView.layer.shadowRadius = 5.0f;
    self.buttonsShadowView.layer.shadowOpacity = 0.6f;
    self.buttonsShadowView.layer.masksToBounds = NO;
    self.buttonsShadowView.layer.shadowColor = [ColorDarkGrey CGColor];
    self.buttonsShadowView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    
    self.afmanager = [MainViewController createAFManager];
    self.imageReceive = [UIImage imageNamed:@"icon_request_padded.png"];
    self.imageSend    = [UIImage imageNamed:@"icon_send_padded.png"];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);
    _blankImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (void) dropdownWallets:(BOOL)bDropdown;
{
    if (bDropdown && !_bWalletsShowing)
    {
        [self toggleWalletDropdown:nil];
    }
    else if (!bDropdown && _bWalletsShowing)
    {
        [self toggleWalletDropdown:nil];
    }
}

- (void) setNewDeviceLogin:(BOOL)bNewDeviceLogin;
{
    _bNewDeviceLogin = bNewDeviceLogin;
}

- (void)toggleWalletDropdown: (UIButton *)sender
{
    ABCLog(2,@"didTapWalletName: Hello world\n");

    CGFloat destination;

    if (_bWalletsShowing)
    {
        destination = -[MainViewController getLargestDimension];
        _bWalletsShowing = false;
    }
    else
    {
        destination = [MainViewController getHeaderHeight];
        _bWalletsShowing = true;
    }
    
    [self updateNavBar];

    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^
    {
        self.walletsViewTop.constant = destination;
        [self.view layoutIfNeeded];
    }
                     completion: ^(BOOL finished)
                     {
                         if (_bWalletsShowing && [[LocalSettings controller] offerWalletHelp]) {
                             [MainViewController fadingAlertHelpPopup:walletsPopupHelpText];
                         }
                     }];
}

- (void)toggleRunningBalance
{
    _showRunningBalance = !_showRunningBalance;
    [LocalSettings controller].showRunningBalance = _showRunningBalance;
    [LocalSettings saveAll];
    [self.tableView reloadData];
    [self updateBalanceView];
}
- (void)forceUpdateNavBar;
{
    [MainViewController changeNavBarOwner:self];
    [self updateNavBar];
}

- (void)updateNavBar
{
    NSString *walletName;
    walletName = [NSString stringWithFormat:@"%@ ▼", abcAccount.currentWallet.name];
    [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(toggleWalletDropdown:) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(info:) fromObject:self];
    
    if (_bWalletsShowing)
    {
        [MainViewController changeNavBar:self title:closeButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(toggleWalletDropdown:) fromObject:self];
    }
    else
    {
        if (!_showRunningBalance && abcAccount.currentWallet)
            [MainViewController changeNavBar:self title:balanceButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(toggleRunningBalance) fromObject:self];
        else
            [MainViewController changeNavBar:self title:abcAccount.currentWallet.currency.code side:NAV_BAR_LEFT button:true enable:true action:@selector(toggleRunningBalance) fromObject:self];
    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MainViewController changeNavBarOwner:self];

    [self performSelector:@selector(resetTableHideSearch) withObject:nil afterDelay:0.0f];

    _bWalletsShowing = false;

    self.buttonRequest.enabled = false;
    self.buttonSend.enabled = false;
    [self.buttonSend setAlpha:0.4];
    [self.buttonRequest setAlpha:0.4];

    self.walletsViewTop.constant = -[MainViewController getLargestDimension];

    self.walletsView.layer.masksToBounds = NO;
    self.walletsView.layer.cornerRadius = 8; // if you like rounded corners
    self.walletsView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.walletsView.layer.shadowRadius = 10;
    self.walletsView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.walletsView.layer.shadowOpacity = 0.2;
    [self.toolbarBlur setTranslucent:[Theme Singleton].bTranslucencyEnable];
    self.walletMakerView.alpha = 0;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews:) name:NOTIFICATION_WALLETS_CHANGED object:nil];

    [self updateViews:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)dismissWalletLoadingTimer
{
    [MainViewController fadingAlertDismiss];
    [self.walletLoadingTimer invalidate];
    self.walletLoadingTimer = nil;
    _bNewDeviceLogin = NO;
    _bShowingWalletsLoadingAlert = NO;
}

- (void)updateViews:(NSNotification *)notification
{
    if (abcAccount.arrayWallets
            && abcAccount.currentWallet
            && abcAccount.currentWallet.loaded)
    {
        [self getBizImagesForWallet:abcAccount.currentWallet];
        [self.tableView reloadData];
        [self updateBalanceView];
        [self updateWalletsView];
        [self updateTransactionSections];

    }

}

- (void)updateTransactionSections
{
    NSArray *array;
    _arraySections = [[NSMutableArray alloc] init];
    _arraySectionsStart = [[NSMutableArray alloc] init];
    _arraySectionsTitle = [[NSMutableArray alloc] init];
    int currentSectionStart = 0;
    
    if ([self searchEnabled])
        array = self.arraySearchTransactions;
    else
        array = abcAccount.currentWallet.arrayTransactions;
    
    if (!array || array.count == 0)
        return;
    
    ABCTransaction *previousTransaction = nil;
    int i;
    
    for (i = 0; i < [array count]; i++)
    {
        if (previousTransaction == nil)
        {
            previousTransaction = array[i];
            continue;
        }
        
        // If the current transaction has the same date as previous, then eliminate header
        NSDate *date = ((ABCTransaction *) array[i]).date;
        NSDateComponents *components = [[NSCalendar currentCalendar]
                                        components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                        fromDate:date];
        NSInteger currentDay = [components day];
        NSInteger currentMonth = [components month];
        
        date = ((ABCTransaction *) array[i - 1]).date;
        components = [[NSCalendar currentCalendar]
                      components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                      fromDate:date];
        NSInteger previousDay = [components day];
        NSInteger previousMonth = [components month];
        
        if (currentDay != previousDay ||
            currentMonth != previousMonth)
        {
            // Create a new section. _arraySections is an array indexed by section number with the
            // number of rows in the section as the array value.
            [_arraySections addObject:[NSNumber numberWithInt:(i - currentSectionStart)]];
            [_arraySectionsStart addObject:[NSNumber numberWithInt:currentSectionStart]];
            
            NSString *formattedDateString = [_dateFormatterDate stringFromDate:date];
            [_arraySectionsTitle addObject:formattedDateString];
            currentSectionStart = i;
        }
    }
    
    // One last section for the remaining transactions
    [_arraySections addObject:[NSNumber numberWithInt:(i - currentSectionStart)]];
    [_arraySectionsStart addObject:[NSNumber numberWithInt:currentSectionStart]];
    NSDate *date = ((ABCTransaction *) array[currentSectionStart]).date;
    NSString *formattedDateString = [_dateFormatterDate stringFromDate:date];
    [_arraySectionsTitle addObject:formattedDateString];
}

-(void)updateWalletsView
{
    [self.walletsTable reloadData];

    [self.balanceHeaderView.segmentedControlBTCUSD setTitle:abcAccount.settings.denomination.label forSegmentAtIndex:0];
    [self.balanceHeaderView.segmentedControlBTCUSD setTitle:abcAccount.settings.defaultCurrency.code
                                          forSegmentAtIndex:1];

    _totalSatoshi = 0;
    //
    // Update balance view in the wallet dropdown.
    //
    for(ABCWallet * wallet in abcAccount.arrayWallets)
    {
        _totalSatoshi += wallet.balance;
    }

    if (_segmentedControlUSD)
    {
        self.balanceHeaderView.segmentedControlBTCUSD.selectedSegmentIndex = 1;
        NSString *strCurrency = [self formatAmount:_totalSatoshi wallet:nil];
        NSString *str = [NSString stringWithFormat:@"%@%@",walletBalanceHeaderText,strCurrency];
        _balanceHeaderView.titleLabel.text = str;
    }
    else
    {
        self.balanceHeaderView.segmentedControlBTCUSD.selectedSegmentIndex = 0;
        NSString *strCurrency = [abcAccount.settings.denomination satoshiToBTCString:_totalSatoshi withSymbol:YES cropDecimals:YES];
        NSString *str = [NSString stringWithFormat:@"%@%@",walletBalanceHeaderText,strCurrency];
        _balanceHeaderView.titleLabel.text = str;
    }
    

}

- (void)resetTableHideSearch
{
     CGPoint pt;
     [self.tableView setContentInset:UIEdgeInsetsMake([MainViewController getHeaderHeight],0,
             [MainViewController getFooterHeight],0)];

     pt.x = 0.0;
     pt.y = -[MainViewController getHeaderHeight] + self.searchTextField.frame.size.height;
     [self.tableView setContentOffset:pt animated:true];

    [self.searchTextField setText:@""];
    [self resignAllResponders];

}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action Methods

- (void)Back: (UIButton *)sender
{
    [self Done];
}

- (void)Done
{
//    if (YES == [self canLeaveWalletNameField])
//    {
//        [self resignAllResponders];
//        if (_bSearchModeEnabled)
//        {
//            self.searchTextField.text = @"";
//            [self transitionToSearch:NO];
//        }
//        else
//        {
//            [self.delegate TransactionsViewControllerDone:self];
//        }
//    }
}

- (void)info: (UIButton *)sender
{
    [self resignAllResponders];
    if (_bWalletsShowing)
    {
        [InfoView CreateWithHTML:@"info_wallets" forView:self.view];
    }
    else
    {
        [InfoView CreateWithHTML:@"info_transactions" forView:self.view];
    }
}

- (IBAction)buttonBlockerTouched:(id)sender
{
    [self blockUser:NO];
    [self resignAllResponders];
}

- (IBAction)buttonRequestTouched:(id)sender
{
    [self resignAllResponders];
    NSDictionary *dictNotification = @{ KEY_TX_DETAILS_EXITED_WALLET_UUID: abcAccount.currentWallet.uuid};
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LAUNCH_REQUEST_FOR_WALLET
                                                        object:self userInfo:dictNotification];
}

- (IBAction)buttonSendTouched:(id)sender
{
    [self resignAllResponders];
    NSDictionary *dictNotification = @{ KEY_TX_DETAILS_EXITED_WALLET_UUID: abcAccount.currentWallet.uuid };
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LAUNCH_SEND_FOR_WALLET
                                                        object:self userInfo:dictNotification];
}

- (void)exportWallet
{
    [self resignAllResponders];

    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    self.exportWalletViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ExportWalletViewController"];
    self.exportWalletViewController.delegate = self;

    [Util addSubviewControllerWithConstraints:self child:self.exportWalletViewController];
    [MainViewController animateSlideIn:self.exportWalletViewController];
}

#pragma mark - Misc Methods

- (void)updateBalanceView //
{
    if (!abcAccount.arrayWallets ||
        !abcAccount.currentWallet ||
        !abcAccount.currentWallet.currency ||
        !abcAccount.currentWallet.currency.code)
        return;

    [_balanceView finishedLoading];
    [_balanceView showBalance:![LocalSettings controller].hideBalance];
    
    _totalSatoshi = abcAccount.currentWallet.balance;
    _balanceView.topAmount.text = [abcAccount.settings.denomination satoshiToBTCString:_totalSatoshi];

    double fCurrency;

    fCurrency = [abcAccount.exchangeCache satoshiToCurrency:_totalSatoshi currencyCode:abcAccount.currentWallet.currency.code error:nil];
    
    NSString *fiatAmount = [abcAccount.currentWallet.currency doubleToPrettyCurrencyString:fCurrency];
    _balanceView.botAmount.text = [NSString stringWithFormat:@"%@ %@", abcAccount.currentWallet.currency.code, fiatAmount];
    
    if (abcAccount.currentWallet.archived)
    {
        self.buttonRequest.enabled = false;
        self.buttonSend.enabled = false;
        [self.buttonSend setAlpha:0.4];
        [self.buttonRequest setAlpha:0.4];
    }
    else
    {
        self.buttonRequest.enabled = true;
        self.buttonSend.enabled = true;
        [self.buttonSend setAlpha:1.0];
        [self.buttonRequest setAlpha:1.0];
    }

    [self updateNavBar];
}


- (void)resignAllResponders
{
    [self.searchTextField resignFirstResponder];
}

- (void)blockUser:(BOOL)bBlock
{
    // Paul doesn't want the 'touch background to dismiss keyboard' so for now we wil ignore this
    return;

//    if (bBlock)
//    {
//        self.buttonBlocker.hidden = NO;
//    }
//    else
//    {
//        self.buttonBlocker.hidden = YES;
//    }
}

// formats the satoshi amount
// if bFiat is YES, then the amount is shown in fiat, otherwise, bitcoin format as specified by user settings
- (NSString *)formatAmount:(int64_t)satoshi wallet:(ABCWallet *)wallet
{
//    BOOL bFiat = !_balanceView.barIsUp;
    if (wallet)
        return [self formatAmount:satoshi useFiat:YES currency:wallet.currency];
    else
        return [self formatAmount:satoshi useFiat:YES currency:abcAccount.settings.defaultCurrency];
}


- (NSString *)formatAmount:(ABCWallet *)wallet
{
//    BOOL bFiat = !_balanceView.barIsUp;
    return [self formatAmount:wallet useFiat:YES];
}


- (NSString *)formatAmount:(ABCWallet *)wallet useFiat:(BOOL)bFiat
{
    return [self formatAmount:wallet.balance useFiat:bFiat currency:wallet.currency];
}


- (NSString *)formatAmount:(int64_t)satoshi useFiat:(BOOL)bFiat currency:(ABCCurrency *)currency;
{
    // if they want it in fiat
    if (bFiat)
    {
        double fCurrency;
        fCurrency = [abcAccount.exchangeCache satoshiToCurrency:satoshi currencyCode:currency.code error:nil];
        return [currency doubleToPrettyCurrencyString:fCurrency];
    }
    else
    {
        return [abcAccount.settings.denomination satoshiToBTCString:satoshi];
    }
}

-(void)launchTransactionDetailsWithTransaction:(ABCTransaction *)transaction cell:(TransactionCell *)cell
{
    if (self.transactionDetailsController) {
        return;
    }
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    self.transactionDetailsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionDetailsViewController"];
    
    self.transactionDetailsController.delegate = self;
    self.transactionDetailsController.transaction = transaction;
    self.transactionDetailsController.wallet = abcAccount.currentWallet;
    self.transactionDetailsController.bOldTransaction = YES;
    self.transactionDetailsController.transactionDetailsMode = (transaction.amountSatoshi < 0 ? TD_MODE_SENT : TD_MODE_RECEIVED);
    if (cell.imagePhoto.image != self.imageSend &&
        cell.imagePhoto.image != self.imageReceive)
    {
        self.transactionDetailsController.photo = cell.imagePhoto.image;
    }
    else
        self.transactionDetailsController.photo = nil;

    [Util addSubviewControllerWithConstraints:self child:self.transactionDetailsController];
    [MainViewController animateSlideIn:self.transactionDetailsController];
}

-(void)dismissTransactionDetails
{
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         self.transactionDetailsController.leftConstraint.constant = [MainViewController getLargestDimension];
         [self.view layoutIfNeeded];
     }
                     completion:^(BOOL finished)
     {
         [self.transactionDetailsController.view removeFromSuperview];
         [self.transactionDetailsController removeFromParentViewController];

         self.transactionDetailsController = nil;
     }];
}

- (void)postToTxSearchQueue:(void(^)(void))cb;
{
    [txSearchQueue addOperationWithBlock:cb];
}

- (void)clearTxSearchQueue;
{
    [txSearchQueue cancelAllOperations];
}

- (void)checkSearchArray
{
    NSString *search = self.searchTextField.text;
    if (search != NULL && search.length > 0)
    {
        [self clearTxSearchQueue];
        [self postToTxSearchQueue:^{
            NSMutableArray *arraySearchTransactions = [[NSMutableArray alloc] init];
            [abcAccount.currentWallet searchTransactionsIn:search addTo:arraySearchTransactions];
            dispatch_async(dispatch_get_main_queue(),^{
                [self.arraySearchTransactions removeAllObjects];
                self.arraySearchTransactions = arraySearchTransactions;
                [self updateTransactionSections];
                [self.tableView reloadData];
            });

        }];
    }
    else if (![self searchEnabled])
    {
        [self updateTransactionSections];
        [self.tableView reloadData];
    }
}

- (BOOL)searchEnabled
{
    return self.searchTextField.text.length > 0;
}

- (UIImage *)contactImageForTransaction:(ABCTransaction *)transaction
{
    UIImage *image = nil;

    if (transaction)
    {
        // find the image from the contacts
        image = [MainViewController Singleton].dictImages[[transaction.metaData.payeeName lowercaseString]];
        ABCLog(2, @"Looking for image for %@. Found image = %lx", transaction.metaData.payeeName, (unsigned long) image);
    }

    return image;
}

- (NSURLRequest *)imageRequestForTransaction:(ABCTransaction *)transaction
{
    if (transaction)
    {
        // if this transaction has a biz id
        if (transaction.metaData.bizId)
        {
            return [self imageRequestForBizID:transaction.metaData.bizId];
        }
    }
    return nil;
}


- (NSURLRequest *)imageRequestForBizID:(unsigned int)bizID;
{
    NSURLRequest *imageRequest = nil;

    // get the image for this bizId
    NSString *requestURL = [MainViewController Singleton].dictImageURLFromBizID[[NSNumber numberWithInt:bizID]];
    imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURL]
                                    cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                timeoutInterval:60];
    return  imageRequest;
}


- (void)getBizImagesForWallet:(ABCWallet *)wallet
{
    for (ABCTransaction *transaction in wallet.arrayTransactions)
    {
        // if this transaction has a biz id
        if (transaction && transaction.metaData.bizId)
        {
            // if we don't have an image for this biz id
            if (nil == [MainViewController Singleton].dictImageURLFromBizID[@(transaction.metaData.bizId)])
            {
                // start by getting the biz details...this will kick of a retreive of the images
                [self getBizDetailsForBizID:transaction.metaData.bizId];
            }
        }
    }
    // Get images for special bizIDs for gift card vendors
    if (nil == [MainViewController Singleton].dictImageURLFromBizID[@(TargetBizID)])
    {
        // start by getting the biz details...this will kick of a retreive of the images
        [self getBizDetailsForBizID:TargetBizID];
    }
    if (nil == [MainViewController Singleton].dictImageURLFromBizID[@(StarbucksBizID)])
    {
        // start by getting the biz details...this will kick of a retreive of the images
        [self getBizDetailsForBizID:StarbucksBizID];
    }
    if (nil == [MainViewController Singleton].dictImageURLFromBizID[@(AmazonBizID)])
    {
        // start by getting the biz details...this will kick of a retreive of the images
        [self getBizDetailsForBizID:AmazonBizID];
    }
    
}

- (void)getBizDetailsForBizID:(unsigned int)bizID;
{
    //get business details
	NSString *requestURL = [NSString stringWithFormat:@"%@/business/%u/", SERVER_API, bizID];
    
    [self.afmanager GET:requestURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *results = (NSDictionary *)responseObject;
        
        NSNumber *numBizId = [results objectForKey:@"bizId"];
        if (numBizId)
        {
            NSDictionary *dictSquareImage = [results objectForKey:@"square_image"];
            if (dictSquareImage)
            {
                NSMutableString *thumbnailString = [dictSquareImage objectForKey:@"thumbnail"];
                NSString *urlString = [NSString stringWithFormat: @"%@%@", SERVER_URL, thumbnailString];

                // at the request to our dictionary and issue code to perform them
                [[MainViewController Singleton].dictImageURLFromBizID setObject:urlString forKey:numBizId];
                [self.tableView reloadData];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        ABCLog(1, @"*** ERROR Connecting to Network: getBizDetailsForBizID bizid=%u", bizID);
    }];
}

- (void)installLeftToRightSwipeDetection
{
	UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeftToRight:)];
	gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:gesture];
}

// used by the guesture recognizer to ignore exit
- (BOOL)haveSubViewsShowing
{
    return (self.transactionDetailsController != nil || self.exportWalletViewController != nil);
}

#pragma mark - TransactionDetailsViewControllerDelegates

-(void)TransactionDetailsViewControllerDone:(TransactionDetailsViewController *)controller
{
    // if we got a new photo
    if (controller.transaction.metaData.bizId && controller.photo && controller.photoUrl)
    {
        [MainViewController Singleton].dictImageURLFromBizID[[NSNumber numberWithInt:controller.transaction.metaData.bizId]] = controller.photoUrl;
    }

    [self dismissTransactionDetails];
    [self forceUpdateNavBar];
    [self updateViews:nil];

}

#pragma mark - UITableView delegates

////

- (BOOL)tableView:(UITableView *)tableView
        shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If there is only 1 wallet left in the active wallts table, prohibit moving
    if (tableView == self.walletsTable)
    {
        if (indexPath.section == WALLET_SECTION_BALANCE)
            return NO;
        if (indexPath.section == WALLET_SECTION_ACTIVE)
        {
            if ([abcAccount.arrayWallets count] == 1)
                return NO;
            else
                return YES;
        }
        if (indexPath.section == WALLET_SECTION_ARCHIVED)
            return YES;

    }
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    // If there is only 1 wallet left in the active wallets table, prohibit moving
    if (tableView == self.walletsTable)
    {
        if (sourceIndexPath.section == WALLET_SECTION_ACTIVE && sourceIndexPath.row == 0 && [abcAccount.arrayWallets count] == 1)
        {
            return sourceIndexPath;
        }

        if (proposedDestinationIndexPath.section == WALLET_SECTION_BALANCE)
        {
            return sourceIndexPath;
        }

        return proposedDestinationIndexPath;
    }
    else
    {
        NSAssert(0, @"Wrong table to move");
        return sourceIndexPath;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{

    NSIndexPath *srcIndexPath = [[NSIndexPath alloc]init];
    NSIndexPath *dstIndexPath = [[NSIndexPath alloc]init];
    srcIndexPath = [NSIndexPath indexPathForItem:sourceIndexPath.row inSection:sourceIndexPath.section - WALLET_SECTION_ACTIVE];
    dstIndexPath = [NSIndexPath indexPathForItem:destinationIndexPath.row inSection:destinationIndexPath.section - WALLET_SECTION_ACTIVE];

    [abcAccount reorderWallets:srcIndexPath toIndexPath:dstIndexPath];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.walletsTable)
    {
        if (section == WALLET_SECTION_BALANCE || section == WALLET_SECTION_ACTIVE)
        {
            return [Theme Singleton].heightWalletHeader;
        }
        else if (section == WALLET_SECTION_ARCHIVED)
        {
            if (([abcAccount.arrayArchivedWallets count] >= 1) || ([abcAccount.arrayWallets count] > 1))
                return [Theme Singleton].heightWalletHeader;
        }

    }
    else if (tableView == self.tableView)
    {
        return 20;
    }
    return 0;
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{

    if (tableView == self.walletsTable)
    {
        switch (section) {
            case WALLET_SECTION_BALANCE:
                return _balanceHeaderView;
            case WALLET_SECTION_ACTIVE:

                //CellIdentifier = @"WalletsHeader";
                //ABCLog(2,@"Active wallets header view: %@", activeWalletsHeaderView);
                return _activeWalletsHeaderView;

            case WALLET_SECTION_ARCHIVED:
                return _archivedWalletsHeaderView;

        }
    }
    else if (tableView == self.tableView)
    {
        TransactionsHeaderView *view;
        
        view = [self getHeaderViewForTableView:self.tableView];
        
        if (section == _arraySectionsTitle.count)
            return nil;
        else
            view.titleLabel.text = _arraySectionsTitle[section];
        
        return view;
    }
    return nil;
}


////

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView)
    {
        if ([self searchEnabled])
        {
            return [_arraySections count];
        }
        else
        {
            // Add one extra section for the Promo rows
            return [_arraySections count] + 1;
        }
    }
    else
        return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView)
    {
        if ([self searchEnabled])
        {
            NSNumber *num = _arraySections[section];
            return [num integerValue];
        }
        else
        {
            if (_arraySections.count == section)
            {
                return NumPromoRows;
            }
            else
            {
                NSNumber *num = _arraySections[section];
                return [num integerValue];
            }
            
        }
    }
    else // self.walletsTable
    {
        switch (section)
        {

            case WALLET_SECTION_BALANCE:
                return 0;
            case WALLET_SECTION_ACTIVE:
                return abcAccount.arrayWallets.count;

            case WALLET_SECTION_ARCHIVED:
                if(_archiveCollapsed)
                {
                    return 0;
                }
                else
                {
                    return abcAccount.arrayArchivedWallets.count;
                }
        }

    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView)
    {
        return [Theme Singleton].heightTransactionCell;
    }
    else
    {
        return [Theme Singleton].heightWalletCell;
    }
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

- (TransactionsHeaderView *)getHeaderViewForTableView:(UITableView *)tableView
{
    UITableViewHeaderFooterView *hfv = nil;
    static NSString *cellIdentifier = @"HeaderView";
    TransactionsHeaderView *view = nil;
    
    hfv = [tableView dequeueReusableHeaderFooterViewWithIdentifier:cellIdentifier];
    if (nil == hfv)
    {
        view = [TransactionsHeaderView CreateWithTitle:loadingBalanceDotDotDot];
        hfv = (UITableViewHeaderFooterView *) view;
    }
    return (TransactionsHeaderView *)hfv;
}

//- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
//{
//    if (tableView == self.tableView)
//    {
//        // Set the text color of our header/footer text.
////        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
//        
//        // Set the background color of our header/footer.
////        [header.contentView setBackgroundColor:[Theme Singleton].colorTransactionsHeader];
////        header.tintColor = [Theme Singleton].colorTransactionsHeader;
////        header.contentView.tintColor = [Theme Singleton].colorTransactionsHeader;
////        
////        header.backgroundView.backgroundColor = [Theme Singleton].colorTransactionsHeader;
//        
//        // You can also do this to set the background color of our header/footer,
//        //    but the gradients/other effects will be retained.
//        // view.tintColor = [UIColor blackColor];
//    }
//}
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.walletsTable)
    {
        return [self tableViewWallets:tableView cellForRowAtIndexPath:indexPath];
    }
    
    UITableViewCell *finalCell;
    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    {
        TransactionCell *cell;
        ABCWallet *wallet = abcAccount.currentWallet;
        UIColor *backgroundColor;
        
        // wallet cell
        cell = [self getTransactionCellForTableView:tableView];
        
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        ABCTransaction *transaction = NULL;
        BOOL bBlankCell = NO;
        
        if (section == _arraySections.count)
        {
            // This is the Promo section
            cell.dateLabel.text = @"";
            
            if (row == PromoIndexBuyBitcoin)
            {
                cell.promoLabel.text = buyBitcoinButton;
                cell.imagePhoto.image = self.imageReceive;
                backgroundColor = [Theme Singleton].colorRequestButton;
                
                bBlankCell = YES;
            }
            else if (row == PromoIndexImportGiftCard)
            {
                if (AIRBITZ)
                {
                    cell.promoLabel.text = importAirbitzGiftCardButton;
                    cell.imagePhoto.image = [UIImage imageNamed:@"logo_icon_full.png"];
                    backgroundColor = [UIColor clearColor];
                }
                else
                {
                    cell.promoLabel.text = importPrivateKeyButton;
                    cell.imagePhoto.image = self.imageReceive;
                    backgroundColor = [Theme Singleton].colorRequestButton;
                }
                bBlankCell = YES;
            }
            else if (row == PromoIndex20offStarbucks)
            {
                cell.promoLabel.text = upTo20OffStarbucksButton;
                NSURLRequest *urlRequest = [self imageRequestForBizID:StarbucksBizID];
                [cell.imagePhoto setImageWithURLRequest:urlRequest placeholderImage:_blankImage success:nil failure:nil];
                backgroundColor = [UIColor clearColor];
                bBlankCell = YES;
            }
            else if (row == PromoIndex10offTarget)
            {
                cell.promoLabel.text = upTo10OffTargetButton;
                NSURLRequest *urlRequest = [self imageRequestForBizID:TargetBizID];
                [cell.imagePhoto setImageWithURLRequest:urlRequest placeholderImage:_blankImage success:nil failure:nil];
                backgroundColor = [UIColor clearColor];
                
                bBlankCell = YES;
            }
            else if (row == PromoIndex15to20offAmazon)
            {
                cell.promoLabel.text = upTo15to20OffAmazonButton;
                NSURLRequest *urlRequest = [self imageRequestForBizID:AmazonBizID];
                [cell.imagePhoto setImageWithURLRequest:urlRequest placeholderImage:_blankImage success:nil failure:nil];
                backgroundColor = [UIColor clearColor];
                
                bBlankCell = YES;
            }
        }
        else if ([self searchEnabled])
        {
            if ([self.arraySearchTransactions count] == 0)
            {
                bBlankCell = YES;
                cell.dateLabel.text = transactionCellNoTransactionsFoundText;
            }
            else
            {
                if (section >= _arraySectionsStart.count)
                {
                    ABCLog(1, @"Error. TransactionsViewController section out of bounds of _arraySectionsStart %lu %lu", section, _arraySectionsStart.count);
                    bBlankCell = YES;
                    cell.dateLabel.text = errorDescriptionText;
                }
                else
                {
                    NSNumber *num = _arraySectionsStart[section];
                    long index = num.integerValue + row;
                    
                    if (index >= self.arraySearchTransactions.count)
                    {
                        bBlankCell = YES;
                        cell.dateLabel.text = errorDescriptionText;
                    }
                    else
                    {
                        ABCLog(1, @"Error. TransactionsViewController num+row out of bounds of arraySearchTransactions %lu %lu %lu", num.integerValue, row, self.arraySearchTransactions.count);
                        transaction = self.arraySearchTransactions[index];
                        cell.transactionIndex = index;
                    }
                }
            }
        }
        else
        {
            if ([abcAccount.currentWallet.arrayTransactions count] == 0)
            {
                bBlankCell = YES;
                cell.dateLabel.text = transactionCellNoTransactionsText;
            }
            else
            {
                if (section >= _arraySectionsStart.count)
                {
                    ABCLog(1, @"Error. TransactionsViewController section out of bounds of _arraySectionsStart %lu %lu", section, _arraySectionsStart.count);
                    bBlankCell = YES;
                    cell.dateLabel.text = errorDescriptionText;
                }
                else
                {
                    NSNumber *num = _arraySectionsStart[section];
                    long index = num.integerValue + row;
                    if (index >= abcAccount.currentWallet.arrayTransactions.count)
                    {
                        ABCLog(1, @"Error. TransactionsViewController num+row out of bounds of arrayTransactions %lu %lu %lu", num.integerValue, row, abcAccount.currentWallet.arrayTransactions.count);
                        bBlankCell = YES;
                        cell.dateLabel.text = errorDescriptionText;
                    }
                    else
                    {
                        transaction = abcAccount.currentWallet.arrayTransactions[index];
                        cell.transactionIndex = index;
                    }
                }
            }
        }
        
        cell.confirmationLabel.text = @"";

        //
        // if this is an empty table, generate a blank cell
        //
        if (bBlankCell)
        {
            cell.promoLabel.textColor = [Theme Singleton].colorTextDark;
            cell.promoLabel.font = [UIFont fontWithName:AppFont size:[Theme Singleton].fontSizeTxListBuyBitcoin];
            cell.addressLabel.text = @"";
//            cell.dateLabel.text = @"";
            cell.dateLabel.textColor = [Theme Singleton].colorTextDarkGrey;

            cell.amountLabel.text = @"";
            cell.balanceLabel.text = @"";
//            cell.imagePhoto.image = nil;
//            cell.imagePhoto.backgroundColor = [UIColor clearColor];
            cell.promoLabel.textAlignment = NSTextAlignmentLeft;
            cell.buttonRight.hidden = NO;
            
            [cell.imagePhoto.layer setBackgroundColor:[backgroundColor CGColor]];
            cell.imagePhoto.layer.cornerRadius = 5;
            cell.imagePhoto.layer.masksToBounds = YES;
            
            CGFloat borderWidth = PHOTO_BORDER_WIDTH;
            cell.viewPhoto.layer.borderColor = [PHOTO_BORDER_COLOR CGColor];
            cell.viewPhoto.layer.borderWidth = borderWidth;
            cell.viewPhoto.layer.cornerRadius = PHOTO_BORDER_CORNER_RADIUS;


            return cell;
        }

        cell.buttonRight.hidden = YES;
        cell.promoLabel.text = @"";
        cell.addressLabel.textAlignment = NSTextAlignmentLeft;
        cell.confirmationLabel.textAlignment = NSTextAlignmentLeft;
        
        NSString *formattedDateString = [_dateFormatterTime stringFromDate:transaction.date];
        
        // date
        cell.dateLabel.text = formattedDateString;
        cell.dateLabel.textColor = [Theme Singleton].colorTextDarkGrey;
        
        // address
        if (transaction.metaData.payeeName && [transaction.metaData.payeeName length] > 0)
        {
            cell.addressLabel.font = [UIFont fontWithName:AppFont size:[Theme Singleton].fontSizeTxListName];
            cell.addressLabel.textColor = [Theme Singleton].colorTransactionName;
            cell.addressLabel.text = transaction.metaData.payeeName;
        }
        else
        {
            cell.addressLabel.font = [UIFont fontWithName:AppFontItalic size:[Theme Singleton].fontSizeTxListName];
            cell.addressLabel.textColor = [Theme Singleton].colorTransactionNameLight;
            if (transaction.amountSatoshi < 0)
                cell.addressLabel.text = sentBitcoinText;
            else
                cell.addressLabel.text = receivedBitcoinText;
        }
        
        // if we are in search  mode
        if ([self searchEnabled])
        {
            // confirmation becomes category
            cell.dateLabel.text = transaction.metaData.category;
            cell.dateLabel.textColor = [Theme Singleton].colorTextDarkGrey;
        }
        else
        {
            unsigned long blockHeight = transaction.wallet.blockHeight;
            unsigned long confirmations;
            
            if (transaction.height == 0)
                confirmations = 0;
            else
                confirmations = blockHeight - transaction.height + 1;
            
            if (blockHeight <= 0)
            {
                cell.dateLabel.text = synchronizingText;
                cell.dateLabel.textColor = [Theme Singleton].colorTextDarkGrey;
            }
            else if (confirmations <= 0)
            {
                if (transaction.isReplaceByFee)
                {
                    cell.dateLabel.text = warningRBFText;
                    cell.dateLabel.textColor = COLOR_NEGATIVE;
                }
                else if (transaction.isDoubleSpend)
                {
                    cell.dateLabel.text = doubleSpendText;
                    cell.dateLabel.textColor = COLOR_NEGATIVE;
                }
                else
                {
                    cell.dateLabel.text = pendingText;
                    cell.dateLabel.textColor = COLOR_NEGATIVE;
                }
            }
//            else if (confirmations == 1)
//            {
//                cell.confirmationLabel.text = [NSString stringWithFormat:@"%lu %@", confirmations, confirmationText];
//                cell.confirmationLabel.textColor = COLOR_POSITIVE;
//            }
//            else if (confirmations >= ABCConfirmedConfirmationCount)
//            {
//                cell.confirmationLabel.textColor = COLOR_POSITIVE;
//                cell.confirmationLabel.text = @"";
//            }
//            else
//            {
//                cell.confirmationLabel.text = [NSString stringWithFormat:@"%lu %@", confirmations, confirmationsText];
//                cell.confirmationLabel.textColor = COLOR_POSITIVE;
//            }
            
        }
        
        // amount - always bitcoin
        cell.amountLabel.text = [self formatAmount:transaction.amountSatoshi useFiat:NO currency:wallet.currency];
        cell.amountLabel.textColor = (transaction.amountSatoshi < 0) ? COLOR_NEGATIVE : COLOR_POSITIVE;
        
        if (_showRunningBalance)
        {
            // balance
            cell.balanceLabel.text = [abcAccount.settings.denomination satoshiToBTCString:transaction.balance withSymbol:YES cropDecimals:NO];
            cell.balanceLabel.textColor = COLOR_BALANCE;
        }
        else
        {
            // balance becomes fiat
            double fCurrency = [abcAccount.exchangeCache satoshiToCurrency:transaction.amountSatoshi currencyCode:wallet.currency.code error:nil];
            cell.balanceLabel.text = [wallet.currency doubleToPrettyCurrencyString:fCurrency];
            cell.balanceLabel.textColor = (transaction.amountSatoshi < 0) ? COLOR_NEGATIVE : COLOR_POSITIVE;
        }
        
        // set the photo
        
        UIImage *placeHolderImage;
        if (transaction.amountSatoshi < 0)
        {
            backgroundColor = [Theme Singleton].colorSendButton;
            placeHolderImage = self.imageSend;
        }
        else
        {
            backgroundColor = [Theme Singleton].colorRequestButton;
            placeHolderImage = self.imageReceive;
        }
        
        NSURLRequest *urlRequest = [self imageRequestForTransaction:transaction];
        if (urlRequest)
            [cell.imagePhoto setImageWithURLRequest:urlRequest placeholderImage:placeHolderImage success:nil failure:nil];
        else
        {
            cell.imagePhoto.image = [self contactImageForTransaction:transaction];
            if (nil == cell.imagePhoto.image)
                cell.imagePhoto.image = placeHolderImage;
        }
        
        [cell.imagePhoto.layer setBackgroundColor:[backgroundColor CGColor]];
        cell.imagePhoto.layer.cornerRadius = 5;
        cell.imagePhoto.layer.masksToBounds = YES;
        
        CGFloat borderWidth = PHOTO_BORDER_WIDTH;
        cell.viewPhoto.layer.borderColor = [PHOTO_BORDER_COLOR CGColor];
        cell.viewPhoto.layer.borderWidth = borderWidth;
        cell.viewPhoto.layer.cornerRadius = PHOTO_BORDER_CORNER_RADIUS;
        finalCell = cell;
    }
    return finalCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (tableView == self.tableView)
    {
        TransactionCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        [self resignAllResponders];
        
        if (indexPath.section == _arraySections.count)
        {
            if (indexPath.row == PromoIndexBuyBitcoin)
            {
                // Buy bitcoin button
                NSString *deviceCurrency = [ABCCurrency getCurrencyCodeOfLocale];
                
                NSString *overrideURL = [MainViewController Singleton].dictBuyBitcoinOverrideURLs[deviceCurrency];
                
                if (overrideURL && [overrideURL length] > 7)
                {
                    NSURL *url = [[NSURL alloc] initWithString:overrideURL];
                    [[UIApplication sharedApplication] openURL:url];
                }
                else if (SHOW_BUY_SELL &&
                         ([deviceCurrency isEqualToString:@"USD"] ||
                          [deviceCurrency isEqualToString:@"CAD"] ||
                          [deviceCurrency isEqualToString:@"EUR"]))
                {
                    [MainViewController launchBuySell];
                }
                else
                {
                    [MainViewController launchDirectoryATM];
                }
            }
            else if (indexPath.row == PromoIndexImportGiftCard)
            {
                // Import Gift Card
                [MainViewController launchSend];
            }
            else if (indexPath.row == PromoIndex20offStarbucks)
            {
                // 20% off button
                [MainViewController launchGiftCard];
            }
            else if (indexPath.row == PromoIndex10offTarget)
            {
                // 10% off button
                [MainViewController launchGiftCard];
            }
            else if (indexPath.row == PromoIndex15to20offAmazon)
            {
                // Amazon button
                NSURL *url = [[NSURL alloc] initWithString:@"http://bit.ly/AirbitzPurse"];
                [[UIApplication sharedApplication] openURL:url];
            }
            
        }
        else if ([self searchEnabled])
        {
            if ([self.arraySearchTransactions count] > 0)
                [self launchTransactionDetailsWithTransaction:[self.arraySearchTransactions objectAtIndex:cell.transactionIndex] cell:cell];
        }
        else
        {
            if ([abcAccount.currentWallet.arrayTransactions count] > 0)
                [self launchTransactionDetailsWithTransaction:[abcAccount.currentWallet.arrayTransactions objectAtIndex:cell.transactionIndex] cell:cell];
        }
    }
    else
    {
        NSIndexPath *setIndexPath = [[NSIndexPath alloc]init];
        setIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:indexPath.section - WALLET_SECTION_ACTIVE];

        [abcAccount makeCurrentWalletWithIndex:setIndexPath];
        [self toggleWalletDropdown:nil];

    }
}

#pragma mark - BalanceViewDelegates

- (void)BalanceViewChanged:(BalanceView *)view show:(BOOL)show;
{
    [LocalSettings controller].hideBalance = !show;
    [LocalSettings saveAll];

    [self updateViews:nil];
}

#pragma mark - UISearchBar delegates

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    //XXX
    // Need to lock table header & shrink toggle bar
    ABCLog(2,@"TransactionsView: searchBarTextDidBeginEditing");
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar;
{
    //XXX
    // Need to unlock table header & grow toggle bar
    ABCLog(2,@"TransactionsView: searchBarTextDidEndEditing");
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text
{

    [self checkSearchArray];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar;                     // called when keyboard search button pressed
{
    [searchBar resignFirstResponder];
}

#pragma mark - UIAlertView delegates

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView == longTapAlert)
    {
        if (buttonIndex == 1)
        {
            // Do Rename popup
            renameAlert =[[UIAlertView alloc ] initWithTitle:renameWalletText
                                                     message:longTapWallet.name
                                                    delegate:self
                                           cancelButtonTitle:cancelButtonText
                                           otherButtonTitles:doneButtonText, nil];
            renameAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
            UITextField *textField = [renameAlert textFieldAtIndex:0];
            textField.text = longTapWallet.name;
            textField.placeholder = longTapWallet.name;

            [renameAlert show];
        }
        else if (buttonIndex == 2)
        {
            if (longTapWallet.balance > 0)
            {
                [MainViewController fadingAlert:deleteWalletHasFunds];
            }
            else
            {
                // Do Delete popup
                deleteAlert =[[UIAlertView alloc ] initWithTitle:deleteWalletText
                                                         message:longTapWallet.name
                                                        delegate:self
                                               cancelButtonTitle:cancelButtonText
                                               otherButtonTitles:okButtonText, nil];
                deleteAlert.alertViewStyle = UIAlertViewStyleDefault;

                [deleteAlert show];
            }
        }
    }
    else if (alertView == deleteAlert)
    {
        if (buttonIndex == 1) {
            // Do Delete popup
            deleteAlertWarning =[[UIAlertView alloc ] initWithTitle:[NSString stringWithFormat:@"%@: %@", deleteWalletText, longTapWallet.name]
                                                     message:deleteWalletWarningText
                                                    delegate:self
                                           cancelButtonTitle:cancelButtonText
                                           otherButtonTitles:okButtonText, nil];
            deleteAlertWarning.alertViewStyle = UIAlertViewStyleDefault;

            [deleteAlertWarning show];
        }
    }
    else if (alertView == deleteAlertWarning)
    {
        if (buttonIndex == 1) {
            [MainViewController fadingAlert:deletingWalletText holdTime:FADING_ALERT_HOLD_TIME_FOREVER_WITH_SPINNER];

            [longTapWallet removeWallet:^
            {
                [MainViewController fadingAlert:deleteWalletDeletedText];

            } error:^(NSError *error)
            {
                [MainViewController fadingAlert:deleteWalletErrorText];
            }];
        }
    }
    else if (alertView == renameAlert)
    {
        if (buttonIndex == 1) {
            UITextField *textField = [alertView textFieldAtIndex:0];
            //        // need at least one character in a wallet name
            if ([textField.text length])
            {
                [longTapWallet renameWallet:textField.text];
            }
            else
            {
                [MainViewController fadingAlert:renameWalletWarningText];
            }

        }
    }
}

#pragma mark - Export Wallet Delegates

- (void)exportWalletViewControllerDidFinish:(ExportWalletViewController *)controller
{
    [MainViewController animateOut:controller withBlur:NO complete:^(void)
    {
        self.exportWalletViewController = nil;
        [self forceUpdateNavBar];
        [self updateViews:nil];
    }];
}


#pragma mark - GestureRecognizer methods

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.walletsTable];

    NSIndexPath *indexPath = [self.walletsTable indexPathForRowAtPoint:p];
    if (indexPath == nil) {
        ABCLog(2,@"long press on table view but not on a row");
    } else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        ABCLog(2,@"long press on table view at section %d, row %d", (int) indexPath.section, (int) indexPath.row);
        if (indexPath.section == WALLET_SECTION_ACTIVE)
        {
            longTapWallet = [abcAccount.arrayWallets objectAtIndex:indexPath.row];
        }
        else if (indexPath.section == WALLET_SECTION_ARCHIVED)
        {
            longTapWallet = [abcAccount.arrayArchivedWallets objectAtIndex:indexPath.row];
        }
        NSString *deleteText = nil;

        // Only allow wallet delete if this wallet is archived or if there is another non-archived wallet
        if ([abcAccount.arrayWallets count] > 1 ||
                longTapWallet.archived)
        {
            deleteText = deleteWalletText;
        }
        
        longTapAlert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@%@",walletNameHeaderText, longTapWallet.name]
                                                  message:@""
                                                 delegate:self
                                        cancelButtonTitle:cancelButtonText
                                        otherButtonTitles:renameButtonText,deleteText,nil];
        [longTapAlert show];
    } else {
        ABCLog(2,@"gestureRecognizer.state = %d", (int)gestureRecognizer.state);
    }
}


- (void)didSwipeLeftToRight:(UIGestureRecognizer *)gestureRecognizer
{
    if (![self haveSubViewsShowing])
    {
        [self Done];
    }
}

#pragma mark - Custom Notification Handlers

// called when a tab bar button that is already selected, is reselected again
- (void)tabBarButtonReselect:(NSNotification *)notification
{
    if (![self haveSubViewsShowing])
    {
        [self Done];
    }
}

#pragma mark - Refresh control

- (void)refresh:(id)sender
{
    [abcAccount.currentWallet refreshServer:NO notify:^
    {
        [(UIRefreshControl *) sender endRefreshing];
    }];
}


//
// Wallet Dropdown functionality
//   taken from WalletsViewController.c
//
- (void)initializeWalletsTable
{
    self.walletsTable.dataSource = self;
    self.walletsTable.delegate = self;
    self.walletsTable.editing = YES;
    self.walletsTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.walletsTable.allowsSelectionDuringEditing = YES;

    self.balanceHeaderView = [WalletHeaderView CreateWithTitle:loadingBalanceDotDotDot
                                                            collapse:NO];
    self.balanceHeaderView.btn_expandCollapse.hidden = YES;
    self.balanceHeaderView.btn_expandCollapse.enabled = NO;
    self.balanceHeaderView.btn_addWallet.hidden = YES;
    self.balanceHeaderView.btn_addWallet.enabled = NO;
    self.balanceHeaderView.segmentedControlBTCUSD.hidden = NO;
    self.balanceHeaderView.segmentedControlBTCUSD.enabled = YES;
    self.balanceHeaderView.delegate = self;

    self.activeWalletsHeaderView = [WalletHeaderView CreateWithTitle:walletsTableHeaderText
                                                            collapse:NO];
    self.activeWalletsHeaderView.btn_expandCollapse.hidden = YES;
    self.activeWalletsHeaderView.btn_expandCollapse.enabled = NO;
    self.activeWalletsHeaderView.segmentedControlBTCUSD.hidden = YES;
    self.activeWalletsHeaderView.segmentedControlBTCUSD.enabled = NO;
    self.activeWalletsHeaderView.btn_exportWallet.hidden = NO;
    self.activeWalletsHeaderView.btn_exportWallet.enabled = YES;
    self.activeWalletsHeaderView.delegate = self;

    _archiveCollapsed = [[NSUserDefaults standardUserDefaults] boolForKey:ARCHIVE_COLLAPSED];
    self.archivedWalletsHeaderView = [WalletHeaderView CreateWithTitle:archiveTableHeaderText
                                                              collapse:_archiveCollapsed];
    self.archivedWalletsHeaderView.btn_addWallet.hidden = YES;
    self.archivedWalletsHeaderView.btn_addWallet.enabled = NO;
    self.archivedWalletsHeaderView.segmentedControlBTCUSD.hidden = YES;
    self.archivedWalletsHeaderView.segmentedControlBTCUSD.enabled = NO;
    self.archivedWalletsHeaderView.delegate = self;

    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
            initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 2.0; //seconds
    lpgr.delegate = self;
    [self.walletsTable addGestureRecognizer:lpgr];


}

-(UITableViewCell *)tableViewWallets:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    WalletCell *cell;

    //wallet cell
    cell = [self getWalletCellForTableView:tableView];

    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

    if (nil == abcAccount.arrayWallets)
        return cell;

    ABCWallet *wallet;

    switch (indexPath.section)
    {
        case WALLET_SECTION_BALANCE:
            NSAssert(0, @"No wallets in balance section");
            break;
        case WALLET_SECTION_ACTIVE:
            if (![abcAccount.arrayWallets count])
                return cell;
            wallet = [abcAccount.arrayWallets objectAtIndex:row];
            break;
        case WALLET_SECTION_ARCHIVED:
            if (nil == abcAccount.arrayArchivedWallets || ![abcAccount.arrayArchivedWallets count])
                return cell;
            wallet = [abcAccount.arrayArchivedWallets objectAtIndex:row];
            break;
    }

    cell.name.backgroundColor = [UIColor clearColor];
    cell.amount.backgroundColor = [UIColor clearColor];

    if (wallet.loaded) {
        cell.userInteractionEnabled = YES;
        cell.name.text = wallet.name;
    } else {
        cell.userInteractionEnabled = NO;
        cell.name.text = loadingText;
    }

    cell.amount.text = [self formatAmount:wallet useFiat:_segmentedControlUSD];

    // If there is only 1 wallet left in the active wallets table, prohibit moving
    if (indexPath.section == WALLET_SECTION_ACTIVE && [abcAccount.arrayWallets count] == 1)
    {
        [cell setEditing:NO];
    }
    else
    {
        [cell setEditing:YES];
    }

    return cell;
}

#pragma mark - WalletHeaderViewDelegates

-(void)segmentedControlHeader
{

    if (self.balanceHeaderView.segmentedControlBTCUSD.selectedSegmentIndex == 0)
    {
        // Choose BTC
        _segmentedControlUSD = NO;
    }
    else
    {
        // Choose Fiat
        _segmentedControlUSD = YES;
    }

    [self updateViews:nil];

}

-(void)walletHeaderView:(WalletHeaderView *)walletHeaderView Expanded:(BOOL)expanded
{
    if(expanded)
    {
        _archiveCollapsed = NO;

        NSInteger countOfRowsToInsert = abcAccount.arrayArchivedWallets.count;
        NSMutableArray *indexPathsToInsert = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < countOfRowsToInsert; i++)
        {
            [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:WALLET_SECTION_ARCHIVED]];
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
        NSInteger countOfRowsToDelete = abcAccount.arrayArchivedWallets.count;
        //ABCLog(2,@"Rows to collapse: %i", countOfRowsToDelete);
        if (countOfRowsToDelete > 0)
        {
            NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
            for (NSInteger i = 0; i < countOfRowsToDelete; i++)
            {
                [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:WALLET_SECTION_ARCHIVED]];
            }
            if ([indexPathsToDelete count] > 0)
            {
                [self.walletsTable deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];
            }
        }
    }
    // persist _archiveCollapsed
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [[NSUserDefaults standardUserDefaults] setBool:_archiveCollapsed forKey:ARCHIVE_COLLAPSED];
    [userDefaults synchronize];
}

- (void)headerButton
{
    [MainViewController fadingAlertHelpPopup:walletHeaderButtonHelpText];
}

- (void)hideWalletMaker
{
    if (_walletMakerVisible == YES)
    {
        _walletMakerVisible = NO;

        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                              delay:[Theme Singleton].animationDelayTimeDefault
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^
                         {
                             self.walletMakerView.alpha = 0;
                             [self.view layoutIfNeeded];

                         }
                         completion:^(BOOL finished)
                         {
                             self.walletMakerView.hidden = YES;
                         }];
    }
}



- (void)addWallet
{

    if (_walletMakerVisible == NO)
    {
        [self.walletMakerView reset];
        _walletMakerVisible = YES;
        self.walletMakerView.hidden = NO;
        [[self.walletMakerView superview] bringSubviewToFront:self.walletMakerView];
        [self createBlockingButton:self.walletMakerView];
        [self.walletMakerView.textField becomeFirstResponder];
        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                              delay:[Theme Singleton].animationDelayTimeDefault
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^
                         {
                             self.walletMakerView.alpha = 1;
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished)
                         {

                         }];
    }
}

-(void)createBlockingButton:(UIView *)view
{
    _blockingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect frame = self.view.bounds;
//    frame.origin.y = self.headerView.frame.origin.y + self.headerView.frame.size.height;
//    frame.size.height = self.view.bounds.size.height - frame.origin.y;
    _blockingButton.frame = frame;
    _blockingButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    [self.view insertSubview:_blockingButton belowSubview:view];
    _blockingButton.alpha = 0.0;

    [_blockingButton addTarget:self
                        action:@selector(blockingButtonHit:)
              forControlEvents:UIControlEventTouchDown];

    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
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
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
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

#pragma mark - Wallet Maker View Delegates

- (void)walletMakerViewExit:(WalletMakerView *)walletMakerView
{
    [self hideWalletMaker];
    [self removeBlockingButton];

    [self updateViews:nil];
}



@end

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


@interface TransactionsViewController () <BalanceViewDelegate, UITableViewDataSource, UITableViewDelegate, TransactionsViewControllerDelegate, WalletHeaderViewDelegate, WalletMakerViewDelegate,
        TransactionDetailsViewControllerDelegate, UISearchBarDelegate, UIAlertViewDelegate, ExportWalletViewControllerDelegate, UIGestureRecognizerDelegate>
{
    BalanceView                         *_balanceView;
    ABCWallet *longTapWallet;
    UIAlertView                         *longTapAlert;
    UIAlertView                         *renameAlert;
    UIAlertView                         *deleteAlert;
    UIAlertView                         *deleteAlertWarning;

    BOOL                                _archiveCollapsed;

    CGRect                              _transactionTableStartFrame;
    BOOL                                _bWalletsShowing;
    BOOL                                _bNewDeviceLogin;
    BOOL                                _bShowingWalletsLoadingAlert;
//    CGRect                              _searchShowingFrame;
    BOOL                                _bWalletNameWarningDisplaying;
    CGRect                              _frameTableWithSearchNoKeyboard;
    BOOL                        _walletMakerVisible;
    UIButton                    *_blockingButton;
    NSOperationQueue                                *txSearchQueue;


}

@property (nonatomic, weak) IBOutlet WalletMakerView    *walletMakerView;
@property (weak, nonatomic) IBOutlet UITableView *walletsTable;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbarBlur;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *walletsViewTop;
@property (weak, nonatomic) IBOutlet UIView *walletsView;
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
    [self.balanceViewPlaceholder addSubview:_balanceView];
    
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
    
    self.afmanager = [MainViewController createAFManager];
    self.imageReceive = [UIImage imageNamed:@"icon_request_padded.png"];
    self.imageSend    = [UIImage imageNamed:@"icon_send_padded.png"];
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

    [MainViewController changeNavBar:self title:closeButtonText side:NAV_BAR_LEFT button:true enable:_bWalletsShowing action:@selector(toggleWalletDropdown:) fromObject:self];

    [UIView animateWithDuration: 0.35
                          delay: 0.0
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self performSelector:@selector(resetTableHideSearch) withObject:nil afterDelay:0.0f];

    _bWalletsShowing = false;

    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:closeButtonText side:NAV_BAR_LEFT button:true enable:_bWalletsShowing action:@selector(toggleWalletDropdown:) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(info:) fromObject:self];

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews) name:NOTIFICATION_WALLETS_CHANGED object:nil];

    [self updateViews];
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

- (void)updateViews
{
    if (abcUser.arrayWallets
            && abcUser.currentWallet
            && abcUser.currentWallet.loaded)
    {
        [self getBizImagesForWallet:abcUser.currentWallet];
        [self.tableView reloadData];
        [self updateBalanceView];
        [self updateWalletsView];

    }

}

-(void)updateWalletsView
{
    [self.walletsTable reloadData];

    [self.balanceHeaderView.segmentedControlBTCUSD setTitle:abcUser.settings.denominationLabel forSegmentAtIndex:0];
    [self.balanceHeaderView.segmentedControlBTCUSD setTitle:[abc currencyAbbrevLookup:abcUser.settings.defaultCurrencyNum]
                                          forSegmentAtIndex:1];

    if (_balanceView.barIsUp)
        self.balanceHeaderView.segmentedControlBTCUSD.selectedSegmentIndex = 0;
    else
        self.balanceHeaderView.segmentedControlBTCUSD.selectedSegmentIndex = 1;

    int64_t totalSatoshi = 0;
    //
    // Update balance view in the wallet dropdown.
    //
    for(ABCWallet * wallet in abcUser.arrayWallets)
    {
        totalSatoshi += wallet.balance;
    }

    NSString *strCurrency = [self formatAmount:totalSatoshi wallet:nil];
    NSString *str = [NSString stringWithFormat:@"%@%@",walletBalanceHeaderText,strCurrency];
    _balanceHeaderView.titleLabel.text = str;

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
        [InfoView CreateWithHTML:@"infoWallets" forView:self.view];
    }
    else
    {
        [InfoView CreateWithHTML:@"infoTransactions" forView:self.view];
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
    NSDictionary *dictNotification = @{ KEY_TX_DETAILS_EXITED_WALLET_UUID: abcUser.currentWallet.strUUID};
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LAUNCH_REQUEST_FOR_WALLET
                                                        object:self userInfo:dictNotification];
}

- (IBAction)buttonSendTouched:(id)sender
{
    [self resignAllResponders];
    NSDictionary *dictNotification = @{ KEY_TX_DETAILS_EXITED_WALLET_UUID: abcUser.currentWallet.strUUID };
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
    if (nil == abcUser.arrayWallets ||
            nil == abcUser.currentWallet)
        return;

    int64_t totalSatoshi = 0.0;
    for(ABCTransaction * tx in abcUser.currentWallet.arrayTransactions)
    {
        totalSatoshi += tx.amountSatoshi;
    }
    _balanceView.topAmount.text = [abcUser formatSatoshi: totalSatoshi];

    double currency;

    [abcUser satoshiToCurrency:totalSatoshi currencyNum:abcUser.currentWallet.currencyNum currency:&currency];
    _balanceView.botAmount.text = [abcUser formatCurrency:currency
                                             withCurrencyNum:abcUser.currentWallet.currencyNum];
    _balanceView.topDenomination.text = abcUser.settings.denominationLabel;
    NSAssert(abcUser.currentWallet.currencyAbbrev.length > 0, @"currencyAbbrev not set");
    _balanceView.botDenomination.text = abcUser.currentWallet.currencyAbbrev;

    [_balanceView refresh];

    if (abcUser.currentWallet.archived)
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

    NSString *walletName;

    walletName = [NSString stringWithFormat:@"%@ ▼", abcUser.currentWallet.strName];

    [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(toggleWalletDropdown:) fromObject:self];


}


- (void)resignAllResponders
{
    [self.searchTextField resignFirstResponder];
}

- (void)blockUser:(BOOL)bBlock
{
    // Paul doesn't want the 'touch background to dismiss keyboard' so for now we wil ignore this
    return;

    if (bBlock)
    {
        self.buttonBlocker.hidden = NO;
    }
    else
    {
        self.buttonBlocker.hidden = YES;
    }
}

// formats the satoshi amount
// if bFiat is YES, then the amount is shown in fiat, otherwise, bitcoin format as specified by user settings
- (NSString *)formatAmount:(int64_t)satoshi wallet:(ABCWallet *)wallet
{
    BOOL bFiat = !_balanceView.barIsUp;
    if (wallet)
        return [self formatAmount:satoshi useFiat:bFiat currencyNum:wallet.currencyNum];
    else
        return [self formatAmount:satoshi useFiat:bFiat currencyNum:abcUser.settings.defaultCurrencyNum];
}


- (NSString *)formatAmount:(ABCWallet *)wallet
{
    BOOL bFiat = !_balanceView.barIsUp;
    return [self formatAmount:wallet useFiat:bFiat];
}


- (NSString *)formatAmount:(ABCWallet *)wallet useFiat:(BOOL)bFiat
{
    return [self formatAmount:wallet.balance useFiat:bFiat currencyNum:wallet.currencyNum];
}


- (NSString *)formatAmount:(int64_t)satoshi useFiat:(BOOL)bFiat currencyNum:(int)currencyNum
{
    // if they want it in fiat
    if (bFiat)
    {
        double currency;
        [abcUser satoshiToCurrency:satoshi currencyNum:currencyNum currency:&currency];
        return [abcUser formatCurrency:currency
                          withCurrencyNum:currencyNum];
    }
    else
    {
        return [abcUser formatSatoshi:satoshi];
    }
}


//note this method duplicated in WalletsViewController
//- (NSString *)conversion:(int64_t)satoshi
//{
//    return [self formatSatoshi:satoshi useFiat:!_balanceView.barIsUp];
//}
//
-(void)launchTransactionDetailsWithTransaction:(ABCTransaction *)transaction cell:(TransactionCell *)cell
{
    if (self.transactionDetailsController) {
        return;
    }
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    self.transactionDetailsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionDetailsViewController"];
    
    self.transactionDetailsController.delegate = self;
    self.transactionDetailsController.transaction = transaction;
    self.transactionDetailsController.wallet = abcUser.currentWallet;
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
    [UIView animateWithDuration:0.35
                          delay:0.0
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
            [abcUser.currentWallet searchTransactionsIn:search addTo:arraySearchTransactions];
            dispatch_async(dispatch_get_main_queue(),^{
                [self.arraySearchTransactions removeAllObjects];
                self.arraySearchTransactions = arraySearchTransactions;
                [self.tableView reloadData];
            });

        }];
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

- (UIImage *)contactImageForTransaction:(ABCTransaction *)transaction
{
    UIImage *image = nil;

    if (transaction)
    {
        // find the image from the contacts
        image = [MainViewController Singleton].dictImages[[transaction.strName lowercaseString]];
        ABCLog(2, @"Looking for image for %@. Found image = %lx", transaction.strName, (unsigned long) image);
    }

    return image;
}

- (NSURLRequest *)imageRequestForTransaction:(ABCTransaction *)transaction
{
    NSURLRequest *imageRequest = nil;
    if (transaction)
    {
        // if this transaction has a biz id
        if (transaction.bizId)
        {
            // get the image for this bizId
            NSString *requestURL = [MainViewController Singleton].dictImageURLFromBizID[[NSNumber numberWithInt:transaction.bizId]];
            imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURL]
                                                          cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                      timeoutInterval:60];
        }
    }
    
    return imageRequest;
}


- (void)getBizImagesForWallet:(ABCWallet *)wallet
{
    for (ABCTransaction *transaction in wallet.arrayTransactions)
    {
        // if this transaction has a biz id
        if (transaction && transaction.bizId)
        {
            // if we don't have an image for this biz id
            if (nil == [MainViewController Singleton].dictImageURLFromBizID[@(transaction.bizId)])
            {
                // start by getting the biz details...this will kick of a retreive of the images
                [self getBizDetailsForTransaction:transaction];
            }
        }
    }
}

- (void)getBizDetailsForTransaction:(ABCTransaction *)transaction
{
    //get business details
	NSString *requestURL = [NSString stringWithFormat:@"%@/business/%u/", SERVER_API, transaction.bizId];
    
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
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        ABCLog(1, @"*** ERROR Connecting to Network");
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
    if (controller.transaction.bizId && controller.photo && controller.photoUrl)
    {
        [MainViewController Singleton].dictImageURLFromBizID[[NSNumber numberWithInt:controller.transaction.bizId]] = controller.photoUrl;
    }

    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:closeButtonText side:NAV_BAR_LEFT button:true enable:_bWalletsShowing action:@selector(toggleWalletDropdown:) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(info:) fromObject:self];

    [self dismissTransactionDetails];
    [self updateViews];

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
            if ([abcUser.arrayWallets count] == 1)
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
        if (sourceIndexPath.section == WALLET_SECTION_ACTIVE && sourceIndexPath.row == 0 && [abcUser.arrayWallets count] == 1)
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

    [abcUser reorderWallets:srcIndexPath toIndexPath:dstIndexPath];
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
            if (([abcUser.arrayArchivedWallets count] >= 1) || ([abcUser.arrayWallets count] > 1))
                return [Theme Singleton].heightWalletHeader;
        }

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
    return nil;
}


////

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView)
        return 1;
    else
        return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView)
    {
        if ([self searchEnabled])
        {
            if (self.arraySearchTransactions.count == 0)
                return 1;
            else
                return self.arraySearchTransactions.count;
        }
        else
        {
            if (0 == abcUser.currentWallet.arrayTransactions.count)
                return 1;
            else
                return abcUser.currentWallet.arrayTransactions.count;
        }
    }
    else // self.walletsTable
    {
        switch (section)
        {

            case WALLET_SECTION_BALANCE:
                return 0;
            case WALLET_SECTION_ACTIVE:
                return abcUser.arrayWallets.count;

            case WALLET_SECTION_ARCHIVED:
                if(_archiveCollapsed)
                {
                    return 0;
                }
                else
                {
                    return abcUser.arrayArchivedWallets.count;
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


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.walletsTable)
    {
        return [self tableViewWallets:tableView cellForRowAtIndexPath:indexPath];
    }

    UITableViewCell *finalCell;
    NSInteger row = [indexPath row];
    {
        TransactionCell *cell;
        ABCWallet *wallet = abcUser.currentWallet;

        // wallet cell
        cell = [self getTransactionCellForTableView:tableView];
        [cell setInfo:row tableHeight:[tableView numberOfRowsInSection:indexPath.section]];

        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        ABCTransaction *transaction = NULL;
        BOOL bBlankCell = NO;
        if ([self searchEnabled])
        {
            if ([self.arraySearchTransactions count] == 0)
            {
                bBlankCell = YES;
                cell.addressLabel.text = transactionCellNoTransactionsFoundText;
            }
            else
            {
                transaction = [self.arraySearchTransactions objectAtIndex:indexPath.row];
            }
        }
        else
        {
            if ([abcUser.currentWallet.arrayTransactions count] == 0)
            {
                bBlankCell = YES;
                cell.addressLabel.text = transactionCellNoTransactionsText;

            }
            else
            {
                transaction = [abcUser.currentWallet.arrayTransactions objectAtIndex:indexPath.row];
            }
        }

        //
        // if this is an empty table, generate a blank cell
        //
        if (bBlankCell)
        {
//            cell.addressLabel.textColor = [Theme Singleton].colorTextDark;
            cell.dateLabel.text = @"";
            cell.confirmationLabel.text = @"";
            cell.amountLabel.text = @"";
            cell.balanceLabel.text = @"";
            cell.imagePhoto.image = nil;
            return cell;
        }

        // date
        cell.dateLabel.text = [NSDate stringForDisplayFromDate:transaction.date prefixed:NO alwaysDisplayTime:YES];

        // address
        cell.addressLabel.text = transaction.strName;

        // if we are in search  mode
        if ([self searchEnabled])
        {
            // confirmation becomes category
            cell.confirmationLabel.text = transaction.strCategory;
            cell.confirmationLabel.textColor = COLOR_BALANCE;

            // amount - always bitcoin
            cell.amountLabel.text = [self formatAmount:transaction.amountSatoshi useFiat:NO currencyNum:wallet.currencyNum];

            // balance becomes fiat
            cell.balanceLabel.text = [self formatAmount:transaction.amountSatoshi useFiat:YES currencyNum:wallet.currencyNum];
            cell.balanceLabel.textColor = (transaction.amountSatoshi < 0) ? COLOR_NEGATIVE : COLOR_POSITIVE;
        }
        else
        {
            if (transaction.bSyncing)
            {
                cell.confirmationLabel.text = synchronizingText;
                cell.confirmationLabel.textColor = COLOR_BALANCE;
            }
            else if (transaction.confirmations < 0)
            {
                cell.confirmationLabel.text = doubleSpendText;
                cell.confirmationLabel.textColor = COLOR_NEGATIVE;
            }
            else if (transaction.confirmations == 0)
            {
                cell.confirmationLabel.text = pendingText;
                cell.confirmationLabel.textColor = COLOR_NEGATIVE;
            }
            else if (transaction.confirmations == 1)
            {
                cell.confirmationLabel.text = [NSString stringWithFormat:@"%i %@", transaction.confirmations, confirmationText];
                cell.confirmationLabel.textColor = COLOR_POSITIVE;
            }
            else if (transaction.confirmations >= CONFIRMED_CONFIRMATION_COUNT)
            {
                cell.confirmationLabel.textColor = COLOR_POSITIVE;
                cell.confirmationLabel.text = confirmedText;
            }
            else
            {
                cell.confirmationLabel.text = [NSString stringWithFormat:@"%i %@", transaction.confirmations, confirmationsText];
                cell.confirmationLabel.textColor = COLOR_POSITIVE;
            }

            //amount
            cell.amountLabel.text = [self formatAmount:transaction.amountSatoshi wallet:abcUser.currentWallet];

            // balance
            cell.balanceLabel.text = [self formatAmount:transaction.balance wallet:abcUser.currentWallet];
            cell.balanceLabel.textColor = COLOR_BALANCE;
        }

        // color amount
        cell.amountLabel.textColor = (transaction.amountSatoshi < 0) ? COLOR_NEGATIVE : COLOR_POSITIVE;
        // set the photo

        UIImage *placeHolderImage;
        UIColor *backgroundColor;
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
        if ([self searchEnabled])
        {
            if ([self.arraySearchTransactions count] > 0)
                [self launchTransactionDetailsWithTransaction:[self.arraySearchTransactions objectAtIndex:indexPath.row] cell:cell];
        }
        else
        {
            if ([abcUser.currentWallet.arrayTransactions count] > 0)
                [self launchTransactionDetailsWithTransaction:[abcUser.currentWallet.arrayTransactions objectAtIndex:indexPath.row] cell:cell];
        }
    }
    else
    {
        NSIndexPath *setIndexPath = [[NSIndexPath alloc]init];
        setIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:indexPath.section - WALLET_SECTION_ACTIVE];

        [abcUser makeCurrentWalletWithIndex:setIndexPath];
        [self toggleWalletDropdown:nil];

    }
}

#pragma mark - BalanceViewDelegates

- (void)BalanceView:(BalanceView *)view changedStateTo:(tBalanceViewState)state
{
    [self updateViews];
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
                                                     message:longTapWallet.strName
                                                    delegate:self
                                           cancelButtonTitle:cancelButtonText
                                           otherButtonTitles:doneButtonText, nil];
            renameAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
            UITextField *textField = [renameAlert textFieldAtIndex:0];
            textField.text = longTapWallet.strName;
            textField.placeholder = longTapWallet.strName;

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
                                                         message:longTapWallet.strName
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
            deleteAlertWarning =[[UIAlertView alloc ] initWithTitle:[NSString stringWithFormat:@"%@: %@", deleteWalletText, longTapWallet.strName]
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

            [abcUser walletRemove:longTapWallet complete:^
            {
                [MainViewController fadingAlert:deleteWalletDeletedText];

            } error:^(ABCConditionCode ccode, NSString *errorString)
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
                [abcUser renameWallet:longTapWallet.strUUID newName:textField.text];
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
    }];
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:closeButtonText side:NAV_BAR_LEFT button:true enable:false action:@selector(Back:) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(info:) fromObject:self];

    [self updateViews];

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
            longTapWallet = [abcUser.arrayWallets objectAtIndex:indexPath.row];
        }
        else if (indexPath.section == WALLET_SECTION_ARCHIVED)
        {
            longTapWallet = [abcUser.arrayArchivedWallets objectAtIndex:indexPath.row];
        }
        NSString *deleteText = nil;

        // Only allow wallet delete if this wallet is archived or if there is another non-archived wallet
        if ([abcUser.arrayWallets count] > 1 ||
                longTapWallet.archived)
        {
            deleteText = deleteWalletText;
        }
        
        longTapAlert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@%@",walletNameHeaderText, longTapWallet.strName]
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
    [abcUser.currentWallet refreshServer:NO notify:^
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

    self.balanceHeaderView = [WalletHeaderView CreateWithTitle:NSLocalizedString(@"Loading Balance...", @"title of wallets table balance header")
                                                            collapse:NO];
    self.balanceHeaderView.btn_expandCollapse.hidden = YES;
    self.balanceHeaderView.btn_expandCollapse.enabled = NO;
    self.balanceHeaderView.btn_addWallet.hidden = YES;
    self.balanceHeaderView.btn_addWallet.enabled = NO;
    self.balanceHeaderView.segmentedControlBTCUSD.hidden = NO;
    self.balanceHeaderView.segmentedControlBTCUSD.enabled = YES;
    self.balanceHeaderView.delegate = self;

    self.activeWalletsHeaderView = [WalletHeaderView CreateWithTitle:NSLocalizedString(@"WALLETS", @"title of active wallets table")
                                                            collapse:NO];
    self.activeWalletsHeaderView.btn_expandCollapse.hidden = YES;
    self.activeWalletsHeaderView.btn_expandCollapse.enabled = NO;
    self.activeWalletsHeaderView.segmentedControlBTCUSD.hidden = YES;
    self.activeWalletsHeaderView.segmentedControlBTCUSD.enabled = NO;
    self.activeWalletsHeaderView.btn_exportWallet.hidden = NO;
    self.activeWalletsHeaderView.btn_exportWallet.enabled = YES;
    self.activeWalletsHeaderView.delegate = self;

    _archiveCollapsed = [[NSUserDefaults standardUserDefaults] boolForKey:ARCHIVE_COLLAPSED];
    self.archivedWalletsHeaderView = [WalletHeaderView CreateWithTitle:NSLocalizedString(@"ARCHIVE", @"title of archived wallets table")
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
    [cell setInfo:row tableHeight:[tableView numberOfRowsInSection:indexPath.section]];

    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

    if (nil == abcUser.arrayWallets)
        return cell;

    ABCWallet *wallet;

    switch (indexPath.section)
    {
        case WALLET_SECTION_BALANCE:
            NSAssert(0, @"No wallets in balance section");
            break;
        case WALLET_SECTION_ACTIVE:
            wallet = [abcUser.arrayWallets objectAtIndex:row];
            break;
        case WALLET_SECTION_ARCHIVED:
            wallet = [abcUser.arrayArchivedWallets objectAtIndex:row];
            break;
    }

    cell.name.backgroundColor = [UIColor clearColor];
    cell.amount.backgroundColor = [UIColor clearColor];

    if (wallet.loaded) {
        cell.userInteractionEnabled = YES;
        cell.name.text = wallet.strName;
    } else {
        cell.userInteractionEnabled = NO;
        cell.name.text = NSLocalizedString(@"Loading...", @"");
    }

    cell.amount.text = [self formatAmount:wallet];

    // If there is only 1 wallet left in the active wallets table, prohibit moving
    if (indexPath.section == WALLET_SECTION_ACTIVE && [abcUser.arrayWallets count] == 1)
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
        [_balanceView balanceViewSetBTC];

    }
    else
    {
        // Choose Fiat
        [_balanceView balanceViewSetFiat];
    }

    [self updateViews];

}

-(void)walletHeaderView:(WalletHeaderView *)walletHeaderView Expanded:(BOOL)expanded
{
    if(expanded)
    {
        _archiveCollapsed = NO;

        NSInteger countOfRowsToInsert = abcUser.arrayArchivedWallets.count;
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
        NSInteger countOfRowsToDelete = abcUser.arrayArchivedWallets.count;
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

        [UIView animateWithDuration:0.35
                              delay:0.0
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
        [UIView animateWithDuration:0.35
                              delay:0.0
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

#pragma mark - Wallet Maker View Delegates

- (void)walletMakerViewExit:(WalletMakerView *)walletMakerView
{
    [self hideWalletMaker];
    [self removeBlockingButton];

    [self updateViews];
}



@end

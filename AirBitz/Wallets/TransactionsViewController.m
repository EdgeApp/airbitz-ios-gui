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
#import "Transaction.h"
#import "CoreBridge.h"
#import "NSDate+Helper.h"
#import "TransactionDetailsViewController.h"
#import "ABC.h"
#import "Util.h"
#import "User.h"
#import "InfoView.h"
#import "CommonTypes.h"
#import "DL_URLServer.h"
#import "Server.h"
#import "CJSONDeserializer.h"
#import "MainViewController.h"
#import "Theme.h"
#import "WalletHeaderView.h"
#import "WalletCell.h"
#import "FadingAlertView2.h"

#define COLOR_POSITIVE [UIColor colorWithRed:0.3720 green:0.6588 blue:0.1882 alpha:1.0]
#define COLOR_NEGATIVE [UIColor colorWithRed:0.7490 green:0.1804 blue:0.1922 alpha:1.0]
#define COLOR_BALANCE  [UIColor colorWithRed:83.0/255.0 green:90.0/255.0 blue:91.0/255.0 alpha:1.0];

#define TABLE_SIZE_HEIGHT_REDUCE_SEARCH_WITH_KEYBOARD 160

#define PHOTO_BORDER_WIDTH          2.0f
#define PHOTO_BORDER_COLOR          [UIColor lightGrayColor]
#define PHOTO_BORDER_CORNER_RADIUS  5.0

#define TABLE_HEADER_HEIGHT 46.0
#define TABLE_CELL_HEIGHT   72.0

#define WALLETS_TABLE_CELL_HEIGHT 60
#define WALLETS_TABLE_HEADER_HEIGHT 44

#define NO_SEARCHBAR 1

#define CACHE_IMAGE_AGE_SECS (60 * 60) // 60 hour

#define ARCHIVE_COLLAPSED @"archive_collapsed"


@interface TransactionsViewController () <BalanceViewDelegate, UITableViewDataSource, UITableViewDelegate, TransactionsViewControllerDelegate, WalletHeaderViewDelegate,
        TransactionDetailsViewControllerDelegate, UISearchBarDelegate, UIAlertViewDelegate, ExportWalletViewControllerDelegate, DL_URLRequestDelegate, UIGestureRecognizerDelegate>
{
    BalanceView                         *_balanceView;
    FadingAlertView2                    *_fadingAlert2;

    BOOL                        _archiveCollapsed;

    CGRect                              _transactionTableStartFrame;
    BOOL                                _bSearchModeEnabled;
    BOOL                                _bWalletsShowing;
//    CGRect                              _searchShowingFrame;
    BOOL                                _bWalletNameWarningDisplaying;
    CGRect                              _frameTableWithSearchNoKeyboard;
}

//@property (weak, nonatomic) IBOutlet UIView         *viewSearch; // Moves search bar in and out
//@property (weak, nonatomic) IBOutlet UITextField    *textWalletName;
@property (nonatomic, strong) NSMutableArray *arrayWallets;
@property (nonatomic, strong) NSMutableArray *arrayArchivedWallets;

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
@property (nonatomic, strong) WalletHeaderView         *activeWalletsHeaderView;
@property (nonatomic, strong) WalletHeaderView         *archivedWalletsHeaderView;

@property (weak, nonatomic) IBOutlet UIImageView    *imageWalletNameEmboss;
//@property (weak, nonatomic) IBOutlet UIButton       *buttonSearch;

@property (nonatomic, strong) UIButton              *buttonBlocker;
@property (nonatomic, strong) NSMutableArray        *arraySearchTransactions;
//@property (nonatomic, strong) NSArray               *arrayNonSearchViews;
@property (nonatomic, strong) NSMutableDictionary   *dictContactImages; // images for the contacts
@property (nonatomic, strong) NSMutableDictionary   *dictBizImages; // images for businesses
@property (nonatomic, strong) NSMutableDictionary   *dictImageRequests;

@property (nonatomic, strong) TransactionDetailsViewController    *transactionDetailsController;
@property (nonatomic, strong) ExportWalletViewController          *exportWalletViewController;


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
    self.dictContactImages = [[NSMutableDictionary alloc] init];
    self.dictBizImages = [[NSMutableDictionary alloc] init];
    self.dictImageRequests = [[NSMutableDictionary alloc] init];

    // load all the names from the address book
    [self loadContactImages];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.wallet = nil;

//    self.textWalletName.text = self.wallet.strName;
//    self.textWalletName.font = [UIFont systemFontOfSize:18];
//    self.textWalletName.autocapitalizationType = UITextAutocapitalizationTypeWords;
//    self.searchTextField.font = [UIFont fontWithName:@"Montserrat-Regular" size:self.searchTextField.font.pointSize];
//    [self.searchTextField addTarget:self action:@selector(searchTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
//    [self.textWalletName addTarget:self action:@selector(searchTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];

    // set up our user blocking button
    self.buttonBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonBlocker.backgroundColor = [UIColor clearColor];
    [self.buttonBlocker addTarget:self action:@selector(buttonBlockerTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonBlocker.frame = self.view.bounds;
    self.buttonBlocker.hidden = YES;
    //self.buttonBlocker.backgroundColor = [UIColor greenColor];
    [self.view addSubview:self.buttonBlocker];
//    [self.view bringSubviewToFront:self.textWalletName];
//    [self.view bringSubviewToFront:self.viewSearch];

//    _searchShowingFrame = self.viewSearch.frame;

    _bWalletsShowing = false;
    _balanceView = [BalanceView CreateWithDelegate:self];
    [self.balanceViewPlaceholder addSubview:_balanceView];

    self.searchTextField.enablesReturnKeyAutomatically = NO;

    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    tableViewController.refreshControl = [[UIRefreshControl alloc] init];
    [tableViewController.refreshControl addTarget:self
                                           action:@selector(refresh:)
                                 forControlEvents:UIControlEventValueChanged];

    _transactionTableStartFrame = self.tableView.frame;

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(dataUpdated:)
                                                 name:NOTIFICATION_BLOCK_HEIGHT_CHANGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(dataUpdated:)
                                                 name:NOTIFICATION_DATA_SYNC_UPDATE object:nil];

    [self initializeWalletsTable];

    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];

}

- (void)toggleWalletDropdown: (UIButton *)sender
{
    NSLog(@"didTapWalletName: Hello world\n");

    CGFloat destination;

    if (_bWalletsShowing)
    {
        destination = -self.walletsView.frame.size.height;
        _bWalletsShowing = false;

    }
    else
    {
        destination = [MainViewController getHeaderHeight];
        _bWalletsShowing = true;
    }

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
                     }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self performSelector:@selector(resetTableHideSearch) withObject:nil afterDelay:0.0f];
//    [self resetTableHideSearch];

    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].backButtonText side:NAV_BAR_LEFT button:true enable:false action:@selector(Back:) fromObject:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(info:) fromObject:self];

    self.buttonRequest.enabled = false;
    self.buttonSend.enabled = false;
    [self.buttonSend setAlpha:0.4];
    [self.buttonRequest setAlpha:0.4];

    _bWalletsShowing = false;
    self.walletsViewTop.constant = -self.walletsView.layer.frame.size.height;

    self.walletsView.layer.masksToBounds = NO;
    self.walletsView.layer.cornerRadius = 8; // if you like rounded corners
    self.walletsView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.walletsView.layer.shadowRadius = 10;
    self.walletsView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.walletsView.layer.shadowOpacity = 0.2;
    [self.toolbarBlur setTranslucent:[Theme Singleton].bTranslucencyEnable];

    [self.balanceViewPlaceholder refresh];

    if (self.arrayWallets == nil)
    {
        self.arrayWallets = [[NSMutableArray alloc] init];
        self.arrayArchivedWallets = [[NSMutableArray alloc] init];
    }
    [CoreBridge postToWalletsQueue:^(void) {
        [self reloadWallets:self.arrayWallets archived:self.arrayArchivedWallets];

        dispatch_async(dispatch_get_main_queue(),^{
            [self getBizImagesForWallet:self.wallet];
            [self.tableView reloadData];
            [self.walletsTable reloadData];
            [self updateBalanceView];

        });
    }];

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
    [DL_URLServer.controller cancelAllRequestsForDelegate:self];
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
    [InfoView CreateWithHTML:@"infoTransactions" forView:self.view];
}

- (IBAction)buttonBlockerTouched:(id)sender
{
    [self blockUser:NO];
    [self resignAllResponders];
}

//- (IBAction)buttonSearchTouched:(id)sender
//{
//    if (YES == [self canLeaveWalletNameField])
//    {
//        [self resignAllResponders];
//        [self transitionToSearch:YES];
//    }
//}

- (IBAction)buttonRequestTouched:(id)sender
{
//    if (YES == [self canLeaveWalletNameField])
    {
        [self resignAllResponders];
        NSDictionary *dictNotification = @{ KEY_TX_DETAILS_EXITED_WALLET_UUID: self.wallet.strUUID };
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LAUNCH_REQUEST_FOR_WALLET
                                                            object:self userInfo:dictNotification];
    }
}

- (IBAction)buttonSendTouched:(id)sender
{
//    if (YES == [self canLeaveWalletNameField])
    {
        [self resignAllResponders];
        NSDictionary *dictNotification = @{ KEY_TX_DETAILS_EXITED_WALLET_UUID: self.wallet.strUUID };
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LAUNCH_SEND_FOR_WALLET
                                                            object:self userInfo:dictNotification];
    }
}

- (IBAction)buttonExportTouched:(id)sender
{
//    if (YES == [self canLeaveWalletNameField])
    {
        [self resignAllResponders];

        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
        self.exportWalletViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"ExportWalletViewController"];

        self.exportWalletViewController.delegate = self;
        self.exportWalletViewController.wallet = self.wallet;

        CGRect frame = self.view.bounds;
        frame.origin.x = frame.size.width;
        self.exportWalletViewController.view.frame = frame;
        [self.view addSubview:self.exportWalletViewController.view];

        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [UIView animateWithDuration:0.35
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
         {
             self.exportWalletViewController.view.frame = self.view.bounds;
         }
                         completion:^(BOOL finished)
         {
             [[UIApplication sharedApplication] endIgnoringInteractionEvents];
         }];
    }
}

#pragma mark - Misc Methods

- (void)updateBalanceView //
{
    int64_t totalSatoshi = 0.0;
    for(Transaction * tx in self.wallet.arrayTransactions)
    {
        totalSatoshi += tx.amountSatoshi;
    }
    _balanceView.topAmount.text = [CoreBridge formatSatoshi: totalSatoshi];

    double currency;
    tABC_Error error;

    ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], 
                          totalSatoshi, &currency, self.wallet.currencyNum, &error);
    _balanceView.botAmount.text = [CoreBridge formatCurrency:currency
                                             withCurrencyNum:self.wallet.currencyNum];
    _balanceView.topDenomination.text = [User Singleton].denominationLabel;
    _balanceView.botDenomination.text = self.wallet.currencyAbbrev;

    [_balanceView refresh];

    if ([self.wallet isArchived])
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

    walletName = [NSString stringWithFormat:@"%@ ↓", self.wallet.strName];

    [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(toggleWalletDropdown:) fromObject:self];


}

// transition two and from search
//- (void)transitionToSearch:(BOOL)bGoToSearch
//{
//    CGRect frameSearch = self.viewSearch.frame;
//    CGRect frame = self.tableView.frame;
//
//    if (bGoToSearch)
//    {
//        [self.view bringSubviewToFront:self.tableView];
//        frame.origin.y = _searchShowingFrame.origin.y + _searchShowingFrame.size.height;
//        frame.size.height = self.view.frame.size.height - frame.origin.y - 10;
//        _frameTableWithSearchNoKeyboard = frame;
//        frame.size.height -= TABLE_SIZE_HEIGHT_REDUCE_SEARCH_WITH_KEYBOARD; // compensate for keyboard
//
//        if (IS_IPHONE4  || NO_SEARCHBAR)
//        {
//            [self.searchTextField becomeFirstResponder];
//            frameSearch.origin.x = _searchShowingFrame.origin.x;
//        }
//
//        _bSearchModeEnabled = YES;
//    }
//    else
//    {
//        for (UIView *curView in _arrayNonSearchViews)
//        {
//            curView.hidden = NO;
//        }
//        if (!IS_IPHONE4 && !NO_SEARCHBAR)
//        {
//            self.buttonSearch.hidden = YES;
//        }
//        else
//        {
//            frameSearch.origin.x = _searchShowingFrame.size.width;
//        }
//        frame = _transactionTableStartFrame;
//        _bSearchModeEnabled = NO;
//    }
//
//    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
//    [UIView animateWithDuration:0.35
//                          delay:0.0
//                        options:UIViewAnimationOptionCurveEaseOut
//                     animations:^
//     {
//         self.tableView.frame = frame;
//
//         if (IS_IPHONE4  || NO_SEARCHBAR)
//         {
//             self.viewSearch.frame = frameSearch;
//         }
//     }
//                     completion:^(BOOL finished)
//     {
//         if (bGoToSearch)
//         {
//             for (UIView *curView in _arrayNonSearchViews)
//             {
//                 curView.hidden = YES;
//             }
//         }
//        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
//     }];
//
//    [self.tableView reloadData];
//}

- (void)resignAllResponders
{
//    [self.textWalletName resignFirstResponder];
    [self.searchTextField resignFirstResponder];
}

- (void)blockUser:(BOOL)bBlock
{
    // Paul doesn't want the 'touch background to dismiss keyboard' so for now we wil ignore this
    return;

    if (bBlock)
    {
//        [self.view bringSubviewToFront:self.buttonBlocker];
//        if (!_bSearchModeEnabled)
//        {
//            [self.view bringSubviewToFront:self.textWalletName];
//        }
//        [self.view bringSubviewToFront:self.viewSearch];
        self.buttonBlocker.hidden = NO;
    }
    else
    {
        self.buttonBlocker.hidden = YES;
    }
}

// formats the satoshi amount based upon user's settings
// if bFiat is YES, then the amount is shown in fiat, otherwise, bitcoin format as specified by user settings
- (NSString *)formatSatoshi:(int64_t)satoshi useFiat:(BOOL)bFiat
{
    // if they want it in fiat
    if (bFiat)
    {
        double currency;
        tABC_Error error;
        ABC_SatoshiToCurrency([[User Singleton].name UTF8String],[[User Singleton].password UTF8String],
                              satoshi, &currency, self.wallet.currencyNum, &error);
        return [CoreBridge formatCurrency:currency
                          withCurrencyNum:self.wallet.currencyNum];
    }
    else
    {
        return [CoreBridge formatSatoshi:satoshi];
    }
}

//note this method duplicated in WalletsViewController
- (NSString *)conversion:(int64_t)satoshi
{
    return [self formatSatoshi:satoshi useFiat:!_balanceView.barIsUp];
}

-(void)launchTransactionDetailsWithTransaction:(Transaction *)transaction
{
    if (self.transactionDetailsController) {
        return;
    }
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    self.transactionDetailsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionDetailsViewController"];
    
    self.transactionDetailsController.delegate = self;
    self.transactionDetailsController.transaction = transaction;
    self.transactionDetailsController.wallet = self.wallet;
    self.transactionDetailsController.bOldTransaction = YES;
    self.transactionDetailsController.transactionDetailsMode = (transaction.amountSatoshi < 0 ? TD_MODE_SENT : TD_MODE_RECEIVED);
    self.transactionDetailsController.photo = [self imageForTransaction:transaction];

    CGRect frame = self.view.bounds;
    frame.origin.x = frame.size.width;
    self.transactionDetailsController.view.frame = frame;
    [self.view addSubview:self.transactionDetailsController.view];
    
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         self.transactionDetailsController.view.frame = self.view.bounds;
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
         self.transactionDetailsController.view.frame = frame;
     }
                     completion:^(BOOL finished)
     {
         [self.transactionDetailsController.view removeFromSuperview];
         self.transactionDetailsController = nil;
     }];
}

- (void)checkSearchArray
{
    NSString *search = self.searchTextField.text;
    if (search != NULL && search.length > 0)
    {
        [self.arraySearchTransactions removeAllObjects];
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

// returns YES if the user can leave the wallet name field
// otherwise, user is warned
//- (BOOL)canLeaveWalletNameField
//{
//    if ([self.textWalletName.text length] == 0)
//    {
//        [self.textWalletName becomeFirstResponder];
//        if (!_bWalletNameWarningDisplaying)
//        {
//            _bWalletNameWarningDisplaying = YES;
//
//            UIAlertView *alert = [[UIAlertView alloc]
//                                  initWithTitle:NSLocalizedString(@"Invalid Wallet Name", nil)
//                                  message:NSLocalizedString(@"You must provide a wallet name.", nil)
//                                  delegate:self
//                                  cancelButtonTitle:@"OK"
//                                  otherButtonTitles:nil];
//            [alert show];
//        }
//
//        return NO;
//    }
//    else
//    {
//        return YES;
//    }
//}

- (void)loadContactImages
{
    CFErrorRef error;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);

    __block BOOL accessGranted = NO;

    if (ABAddressBookRequestAccessWithCompletion != NULL)
    {
        // we're on iOS 6
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);

        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     accessGranted = granted;
                                                     dispatch_semaphore_signal(sema);
                                                 });

        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        //dispatch_release(sema);
    }
    else
    {
        // we're on iOS 5 or older
        accessGranted = YES;
    }

    if (accessGranted)
    {
        CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
        for (CFIndex i = 0; i < CFArrayGetCount(people); i++)
        {
            ABRecordRef person = CFArrayGetValueAtIndex(people, i);

            NSString *strFullName = [Util getNameFromAddressRecord:person];
            if ([strFullName length])
            {
                // if this contact has an image and we don't have one yet
                if ((ABPersonHasImageData(person)) && (nil == [self.dictContactImages objectForKey:strFullName]))
                {
                    NSData *data = (__bridge_transfer NSData*)ABPersonCopyImageData(person);
					if(data)
					{
						[self.dictContactImages setObject:[UIImage imageWithData:data] forKey:strFullName];
					}
                }
            }
        }
        CFRelease(people);
    }
}

- (UIImage *)imageForTransaction:(Transaction *)transaction
{
    UIImage *image = nil;

    if (transaction)
    {
        // if this transaction has a biz id
        if (transaction.bizId)
        {
            // get the image for this bizId
            image = [self.dictBizImages objectForKey:[NSNumber numberWithInt:transaction.bizId]];
        }

        if (image == nil)
        {
            // find the image from the contacts
            image = [self.dictContactImages objectForKey:transaction.strName];
        }
    }

    return image;
}

- (void)getBizImagesForWallet:(Wallet *)wallet
{
    for (Transaction *transaction in wallet.arrayTransactions)
    {
        // if this transaction has a biz id
        if (transaction.bizId)
        {
            // if we don't have an image for this biz id
            if (nil == [self.dictBizImages objectForKey:[NSNumber numberWithInt:transaction.bizId]])
            {
                // start by getting the biz details...this will kick of a retreive of the images
                [self getBizDetailsForTransaction:transaction];
            }
        }
    }
}

- (void)getBizDetailsForTransaction:(Transaction *)transaction
{
    //get business details
	NSString *requestURL = [NSString stringWithFormat:@"%@/business/%u/", SERVER_API, transaction.bizId];
	//NSLog(@"Requesting: %@", requestURL);
	[[DL_URLServer controller] issueRequestURL:requestURL
									withParams:nil
									withObject:nil
								  withDelegate:self
							acceptableCacheAge:CACHE_24_HOURS
								   cacheResult:YES];
}

// issue any image requests we have
- (void)performImageRequests
{

    for (NSNumber *numBizId in [self.dictImageRequests allKeys])
    {
        NSString *strThumbnailURL = [self.dictImageRequests objectForKey:numBizId];

        // remove this request
        [self.dictImageRequests removeObjectForKey:numBizId];

        // create the url string
        NSString *strURL = [NSString stringWithFormat:@"%@%@", SERVER_URL, strThumbnailURL];

        // run the qurey
        [[DL_URLServer controller] issueRequestURL:[strURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                        withParams:nil
                                        withObject:numBizId
                                      withDelegate:self
                                acceptableCacheAge:CACHE_IMAGE_AGE_SECS
                                       cacheResult:YES];
    }
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
    if (controller.transaction.bizId && controller.photo)
    {
        [self.dictBizImages setObject:controller.photo forKey:[NSNumber numberWithInt:controller.transaction.bizId]];
    }

    [CoreBridge postToWalletsQueue:^(void) {
        [CoreBridge reloadWallet:self.wallet];
        [self getBizImagesForWallet:self.wallet];

        dispatch_async(dispatch_get_main_queue(),^{
            [self.tableView reloadData];
            [self checkSearchArray];
        });
    }];
    [self dismissTransactionDetails];

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
        return !(indexPath.section == 0 && indexPath.row == 0 && [_arrayWallets count] == 1);
    else
        return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    // If there is only 1 wallet left in the active wallets table, prohibit moving
    if (tableView == self.walletsTable)
    {
        if (sourceIndexPath.section == 0 && sourceIndexPath.row == 0 && [_arrayWallets count] == 1)
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
        wallet.archived = NO;
        [self.arrayWallets insertObject:wallet atIndex:destinationIndexPath.row];

    }
    else
    {
        wallet.archived = YES;
        [self.arrayArchivedWallets insertObject:wallet atIndex:destinationIndexPath.row];
    }
    [CoreBridge setWalletAttributes:wallet];
    [CoreBridge setWalletOrder: self.arrayWallets archived:self.arrayArchivedWallets];
    [self updateBalanceView];
    NSLog(@"Wallet Table %f %f %f %f\n", self.walletsTable.frame.origin.x, self.walletsTable.frame.origin.y, self.walletsTable.frame.size.width, self.walletsTable.frame.size.height);

    [self.walletsTable reloadData];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.walletsTable)
    {
        if (section == 0 || [_arrayWallets count] > 1)
        {
            return 44.0;
        }
    }
    return 0;
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{

    if (tableView == self.walletsTable)
    {
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
    }
    else
    {
//        NSAssert(0, @"Wrong table for header");
        return nil;
    }
}


////

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView)
        return 1;
    else
        return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView)
    {
        if ([self searchEnabled]) {
            return self.arraySearchTransactions.count;
        }
        else {
            return self.wallet.arrayTransactions.count;
        }
    }
    else // self.walletsTable
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
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView)
    {
        return TABLE_CELL_HEIGHT;
    }
    else
    {
        return WALLETS_TABLE_CELL_HEIGHT;
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
    NSInteger section = [indexPath section];
    {
        TransactionCell *cell;

        // wallet cell
        cell = [self getTransactionCellForTableView:tableView];
        [cell setInfo:row tableHeight:[tableView numberOfRowsInSection:indexPath.section]];

        Transaction *transaction = NULL;
        if ([self searchEnabled])
        {
            transaction = [self.arraySearchTransactions objectAtIndex:indexPath.row];
        }
        else
        {
            transaction = [self.wallet.arrayTransactions objectAtIndex:indexPath.row];
        }

        // date
        cell.dateLabel.text = [NSDate stringForDisplayFromDate:transaction.date prefixed:NO alwaysDisplayTime:YES];

        // address
        cell.addressLabel.text = transaction.strAddress;

        // if we are in search  mode
        if (_bSearchModeEnabled)
        {
            // confirmation becomes category
            cell.confirmationLabel.text = transaction.strCategory;
            cell.confirmationLabel.textColor = COLOR_BALANCE;

            // amount - always bitcoin
            cell.amountLabel.text = [self formatSatoshi:transaction.amountSatoshi useFiat:NO];

            // balance becomes fiat
            cell.balanceLabel.text = [self formatSatoshi:transaction.amountSatoshi useFiat:YES];
            cell.balanceLabel.textColor = (transaction.amountSatoshi < 0) ? COLOR_NEGATIVE : COLOR_POSITIVE;
        }
        else
        {
            if (transaction.bSyncing)
            {
                cell.confirmationLabel.text = NSLocalizedString(@"Synchronizing", nil);
                cell.confirmationLabel.textColor = COLOR_BALANCE;
            }
            else if (transaction.confirmations == 0)
            {
                cell.confirmationLabel.text = [NSString stringWithFormat:@"Pending"];
                cell.confirmationLabel.textColor = COLOR_NEGATIVE;
            }
            else if (transaction.confirmations == 1)
            {
                cell.confirmationLabel.text = [NSString stringWithFormat:@"%i Confirmation", transaction.confirmations];
                cell.confirmationLabel.textColor = COLOR_POSITIVE;
            }
            else if (transaction.confirmations >= CONFIRMED_CONFIRMATION_COUNT)
            {
                cell.confirmationLabel.textColor = COLOR_POSITIVE;
                cell.confirmationLabel.text = NSLocalizedString(@"Confirmed", nil);
            }
            else
            {
                cell.confirmationLabel.text = [NSString stringWithFormat:@"%i Confirmations", transaction.confirmations];
                cell.confirmationLabel.textColor = COLOR_POSITIVE;
            }

            //amount
            cell.amountLabel.text = [self conversion:transaction.amountSatoshi];

            // balance
            cell.balanceLabel.text = [self conversion:transaction.balance];
            cell.balanceLabel.textColor = COLOR_BALANCE;
        }

        // color amount
        cell.amountLabel.textColor = (transaction.amountSatoshi < 0) ? COLOR_NEGATIVE : COLOR_POSITIVE;
        // set the photo
        cell.imagePhoto.image = [self imageForTransaction:transaction];
        cell.imagePhoto.hidden = (cell.imagePhoto.image == nil);
        cell.imagePhoto.layer.cornerRadius = 5;
        cell.imagePhoto.layer.masksToBounds = YES;
    
//        CGRect dateFrame = cell.dateLabel.frame;
//        CGRect addressFrame = cell.addressLabel.frame;
//        CGRect confirmationFrame = cell.confirmationLabel.frame;
        
//        if (cell.imagePhoto.image == nil)
//        {
//            dateFrame.origin.x = addressFrame.origin.x = confirmationFrame.origin.x = 10;
//        }
//        else
//        {
//            dateFrame.origin.x = addressFrame.origin.x = confirmationFrame.origin.x = 63;
//        }
        
//        cell.dateLabel.frame = dateFrame;
//        cell.addressLabel.frame = addressFrame;
//        cell.confirmationLabel.frame = confirmationFrame;
        
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
    if (tableView == self.tableView)
    {

        {
            [self resignAllResponders];
            if ([self searchEnabled])
            {
                [self launchTransactionDetailsWithTransaction:[self.arraySearchTransactions objectAtIndex:indexPath.row]];
            }
            else
            {
                [self launchTransactionDetailsWithTransaction:[self.wallet.arrayTransactions objectAtIndex:indexPath.row]];
            }
        }
    }
    else
    {
        //
        // Set new wallet. Hide the dropdown. Then reload the TransactionsView table
        //
        if(indexPath.section == 0)
        {
            self.wallet = [self.arrayWallets objectAtIndex:indexPath.row];
        }
        else
        {
            self.wallet = [self.arrayArchivedWallets objectAtIndex:indexPath.row];
        }
        [self viewWillAppear:YES];

    }
}

#pragma mark - BalanceViewDelegates

- (void)BalanceView:(BalanceView *)view changedStateTo:(tBalanceViewState)state
{
    [self.tableView reloadData];
}

#pragma mark - UISearchBar delegates

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    //XXX
    // Need to lock table header & shrink toggle bar
    NSLog(@"TransactionsView: searchBarTextDidBeginEditing");
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar;
{
    //XXX
    // Need to unlock table header & grow toggle bar
    NSLog(@"TransactionsView: searchBarTextDidEndEditing");
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text
{

    [self checkSearchArray];
//    }
//    else if (textField == self.textWalletName)
//    {
//        // need at least one character in a wallet name
//        if ([textField.text length])
//        {
//            //NSLog(@"rename wallet to: %@", textField.text);
//            tABC_Error error;
//            ABC_RenameWallet([[User Singleton].name UTF8String],
//                             [[User Singleton].password UTF8String],
//                             [self.wallet.strUUID UTF8String],
//                             (char *)[textField.text UTF8String],
//                             &error);
//            [Util printABC_Error:&error];
//        }
//    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar;                     // called when keyboard search button pressed
{
    [searchBar resignFirstResponder];
}

//- (BOOL)textFieldShouldReturn:(UITextField *)textField
//{
//    if ((textField != self.textWalletName) || ([self canLeaveWalletNameField]))
//    {
//        [textField resignFirstResponder];
//    }
//
//    return YES;
//}
//
//- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
//{
//    if (textField == self.textWalletName)
//    {
//        if (NO == [self canLeaveWalletNameField])
//        {
//            [self blockUser:YES];
//            return NO;
//        }
//        else
//        {
//            // unhighlight wallet name text
//            // note: for some reason, if we don't do this, the text won't select next time the user selects it
//            [textField setSelectedTextRange:[textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.beginningOfDocument]];
//        }
//    }
//
//    return YES;
//}

#pragma mark - DLURLServer Callbacks

- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
	if (data)
	{
        if (DL_URLRequestStatus_Success == status)
        {
            // if this is a business details query
            if (nil == object)
            {
                NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];

				//NSLog(@"Results download returned: %@", jsonString );

                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
                NSError *myError;
                NSDictionary *dictFromServer = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:&myError];

                NSNumber *numBizId = [dictFromServer objectForKey:@"bizId"];
                if (numBizId)
                {
                    NSDictionary *dictSquareImage = [dictFromServer objectForKey:@"square_image"];
                    if (dictSquareImage)
                    {
                        NSString *strImageURL = [dictSquareImage objectForKey:@"thumbnail"];
                        if (strImageURL)
                        {
                            // at the request to our dictionary and issue code to perform them
                            [self.dictImageRequests setObject:strImageURL forKey:numBizId];
                            [self performSelector:@selector(performImageRequests) withObject:nil afterDelay:0.0];
                        }
                    }
                }
            }
            else
            {
                NSNumber *numBizId = (NSNumber *) object;
                UIImage *srcImage = [UIImage imageWithData:data];
                [self.dictBizImages setObject:srcImage forKey:numBizId];
                [self.tableView reloadData];
            }
        }
    }
}

#pragma mark - UIAlertView delegates

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
//    // the only alert we have that uses a delegate is the one that tells them they must provide a wallet name
//    [self.textWalletName becomeFirstResponder];
//    _bWalletNameWarningDisplaying = NO;
}

#pragma mark - Export Wallet Delegates

- (void)exportWalletViewControllerDidFinish:(ExportWalletViewController *)controller
{
    [controller.view removeFromSuperview];
    self.exportWalletViewController = nil;
}

#pragma mark - Block Height Change

- (void)dataUpdated:(NSNotification *)notification
{
    [CoreBridge postToWalletsQueue:^(void) {
        NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
        NSMutableArray *arrayArchivedWallets = [[NSMutableArray alloc] init];

        [self reloadWallets:arrayWallets archived:arrayArchivedWallets];

        dispatch_async(dispatch_get_main_queue(),^{
            self.arrayWallets = arrayWallets;
            self.arrayArchivedWallets = arrayArchivedWallets;

            if(self.arrayWallets.count > 0) {
                [self.walletsTable reloadData];
                [self.tableView reloadData];
            }
            NSLog(@"TransactionsView: dataUpdated: Calling updateBalanceView");

            // Since these actions are all queued. We may not be the current viewcontroller
            // If not, then don't update the display. Especially the Navbar which is likely owned by
            // someone else.
            [self updateBalanceView];
            [self.view setNeedsDisplay];
        });
    }];
}

#pragma mark - GestureReconizer methods

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
    [CoreBridge refreshWallet:_wallet.strUUID refreshData:NO notify:^{
        [(UIRefreshControl *)sender endRefreshing];
    }];
}


//
// Wallet Dropdown functionality
//   taken from WalletsViewController.c
//


- (NSString *)walletAmounttoString:(Wallet *)wallet inFiat:(BOOL)inFiat
{
    if (inFiat)
    {
        double currency;
        tABC_Error error;
        ABC_SatoshiToCurrency([[User Singleton].name UTF8String],
                [[User Singleton].password UTF8String],
                wallet.balance, &currency,
                wallet.currencyNum, &error);
        [Util printABC_Error:&error];
        return [CoreBridge formatCurrency:currency
                          withCurrencyNum:wallet.currencyNum];
    }
    else
    {
        return [CoreBridge formatSatoshi:wallet.balance];
    }
}


- (void)initializeWalletsTable
{
    self.walletsTable.dataSource = self;
    self.walletsTable.delegate = self;
    self.walletsTable.editing = YES;
    self.walletsTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.walletsTable.allowsSelectionDuringEditing = YES;
//    _currencyConversionFactor = 1.0;

//    self.walletMakerView.hidden = YES;
//    self.walletMakerView.delegate = self;
//    self.walletMakerTop.constant = -self.walletMakerView.layer.frame.size.height;

    self.activeWalletsHeaderView = [WalletHeaderView CreateWithTitle:NSLocalizedString(@"WALLETS", @"title of active wallets table")
                                                            collapse:NO];
    self.activeWalletsHeaderView.btn_expandCollapse.hidden = YES;
    self.activeWalletsHeaderView.delegate = self;

    _archiveCollapsed = [[NSUserDefaults standardUserDefaults] boolForKey:ARCHIVE_COLLAPSED];
    self.archivedWalletsHeaderView = [WalletHeaderView CreateWithTitle:NSLocalizedString(@"ARCHIVE", @"title of archived wallets table")
                                                              collapse:_archiveCollapsed];
    self.archivedWalletsHeaderView.btn_addWallet.hidden = YES;
    self.archivedWalletsHeaderView.delegate = self;
}

// retrieves the wallets from disk and put them in the two member arrays
- (void)reloadWallets: (NSMutableArray *)arrayWallets archived:(NSMutableArray *)arrayArchivedWallets
{
    if (arrayWallets == nil || arrayArchivedWallets == nil)
    {
        NSLog(@"ERROR reloadWallets arrayWallets or arrayArchivedWallets = nil.");
        return;
    }
    else
    {
        [arrayWallets removeAllObjects];
        [arrayArchivedWallets removeAllObjects];
    }
    [CoreBridge loadWallets:arrayWallets
                   archived:arrayArchivedWallets
                    withTxs:NO];

    if (self.wallet == nil)
    {
        if ([arrayWallets count] > 0)
        {
            self.wallet = [arrayWallets objectAtIndex:0];
        }
    }

    if (self.wallet != nil)
    {
        [CoreBridge reloadWallet:self.wallet];
    }
    [self lockIfLoading];
}

- (void)lockIfLoading
{
    // Still loading?
    int loadingCount = 0;
    for (Wallet *w in self.arrayWallets) {
        if (!w.loaded) {
            loadingCount++;
        }
    }
    if (loadingCount > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LOCK_TABBAR object:self];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UNLOCK_TABBAR object:self];
    }
}

// select the wallet with the given UUID
- (void)selectWalletWithUUID:(NSString *)strUUID
{
    if (strUUID)
    {
        if ([strUUID length])
        {
            [self reloadWallets:self.arrayWallets archived:self.arrayArchivedWallets];

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
                //XXX
//                [self launchTransactionsWithWallet:wallet animated:NO];
            }
        }
    }
}

-(UITableViewCell *)tableViewWallets:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    WalletCell *cell;

    //wallet cell
    cell = [self getWalletCellForTableView:tableView];
    [cell setInfo:row tableHeight:[tableView numberOfRowsInSection:indexPath.section]];

    Wallet *wallet = (indexPath.section == 0 ?
            [self.arrayWallets objectAtIndex:row] :
            [self.arrayArchivedWallets objectAtIndex:row]);

    cell.name.backgroundColor = [UIColor clearColor];
    cell.amount.backgroundColor = [UIColor clearColor];

    if (wallet.loaded) {
        cell.userInteractionEnabled = YES;
        cell.name.text = wallet.strName;
    } else {
        cell.userInteractionEnabled = NO;
        cell.name.text = NSLocalizedString(@"Loading...", @"");
    }

    cell.amount.text = [self walletAmounttoString:wallet inFiat:NO];
    cell.amountFiat.text = [self walletAmounttoString:wallet inFiat:YES];

    // If there is only 1 wallet left in the active wallets table, prohibit moving
    if (indexPath.section == 0 && [_arrayWallets count] == 1)
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
    _fadingAlert2 = [FadingAlertView2 CreateInsideView:self.view withDelegate:self];
    _fadingAlert2.fadeDelay = FADING_HELP_DELAY;
    _fadingAlert2.fadeDuration = FADING_HELP_DURATION;
    [_fadingAlert2 messageTextSet:@"To archive a wallet, tap and hold the 3 bars to the right of a wallet and drag it below the [ARCHIVE] header"];
    [_fadingAlert2 blockModal:NO];
    [_fadingAlert2 showFading];
}

- (void)fadingAlertDismissed:(FadingAlertView *)view
{
    _fadingAlert2 = nil;
}

- (void)addWallet
{

//    if (_walletMakerVisible == NO)
//    {
//        [self.walletMakerView reset];
//        _walletMakerVisible = YES;
//        self.walletMakerView.hidden = NO;
//        [[self.walletMakerView superview] bringSubviewToFront:self.walletMakerView];
//        [self createBlockingButton:self.walletMakerView];
//        [self.walletMakerView.textField becomeFirstResponder];
//        [UIView animateWithDuration:0.35
//                              delay:0.0
//                            options:UIViewAnimationOptionCurveEaseOut
//                         animations:^
//                         {
//                             self.walletMakerTop.constant = [MainViewController getHeaderHeight];
//                             [self.view layoutIfNeeded];
//                         }
//                         completion:^(BOOL finished)
//                         {
//
//                         }];
//    }
}


@end

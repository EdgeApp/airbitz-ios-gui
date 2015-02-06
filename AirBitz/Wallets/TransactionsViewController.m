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

#define COLOR_POSITIVE [UIColor colorWithRed:0.3720 green:0.6588 blue:0.1882 alpha:1.0]
#define COLOR_NEGATIVE [UIColor colorWithRed:0.7490 green:0.1804 blue:0.1922 alpha:1.0]
#define COLOR_BALANCE  [UIColor colorWithRed:83.0/255.0 green:90.0/255.0 blue:91.0/255.0 alpha:1.0];

#define TABLE_SIZE_HEIGHT_REDUCE_SEARCH_WITH_KEYBOARD 160

#define PHOTO_BORDER_WIDTH          2.0f
#define PHOTO_BORDER_COLOR          [UIColor lightGrayColor]
#define PHOTO_BORDER_CORNER_RADIUS  5.0

#define TABLE_HEADER_HEIGHT 46.0
#define TABLE_CELL_HEIGHT   72.0
#define NO_SEARCHBAR 1

#define CACHE_IMAGE_AGE_SECS (60 * 60) // 60 hour

@interface TransactionsViewController () <BalanceViewDelegate, UITableViewDataSource, UITableViewDelegate, TransactionDetailsViewControllerDelegate, UITextFieldDelegate, UIAlertViewDelegate, ExportWalletViewControllerDelegate, DL_URLRequestDelegate, UIGestureRecognizerDelegate>
{
    BalanceView                         *_balanceView;
    CGRect                              _transactionTableStartFrame;
    BOOL                                _bSearchModeEnabled;
    CGRect                              _searchShowingFrame;
    BOOL                                _bWalletNameWarningDisplaying;
    CGRect                              _frameTableWithSearchNoKeyboard;
}

@property (weak, nonatomic) IBOutlet UIView         *viewSearch;
@property (weak, nonatomic) IBOutlet UITextField    *textWalletName;
@property (nonatomic, weak) IBOutlet UIView         *balanceViewPlaceholder;
@property (nonatomic, weak) IBOutlet UITableView    *tableView;
@property (nonatomic, weak) IBOutlet UITextField    *searchTextField;
@property (weak, nonatomic) IBOutlet UIButton       *buttonExport;
@property (weak, nonatomic) IBOutlet UIButton       *buttonRequest;
@property (weak, nonatomic) IBOutlet UIButton       *buttonSend;
@property (weak, nonatomic) IBOutlet UIImageView    *imageWalletNameEmboss;
@property (weak, nonatomic) IBOutlet UIButton       *buttonSearch;

@property (nonatomic, strong) UIButton              *buttonBlocker;
@property (nonatomic, strong) NSMutableArray        *arraySearchTransactions;
@property (nonatomic, strong) NSArray               *arrayNonSearchViews;
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

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:nil];

    // alloc the arrays
    self.arraySearchTransactions = [[NSMutableArray alloc] init];
    self.dictContactImages = [[NSMutableDictionary alloc] init];
    self.dictBizImages = [[NSMutableDictionary alloc] init];
    self.dictImageRequests = [[NSMutableDictionary alloc] init];

    // load all the names from the address book
    [self loadContactImages];

    _balanceView = [BalanceView CreateWithDelegate:self];
    _balanceView.frame = self.balanceViewPlaceholder.frame;
    _balanceView.botDenomination.text = self.wallet.currencyAbbrev;

    [self.balanceViewPlaceholder removeFromSuperview];
    [self.view addSubview:_balanceView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.arrayNonSearchViews = [NSArray arrayWithObjects:_balanceView, self.textWalletName, self.buttonExport, self.imageWalletNameEmboss, self.buttonSearch, nil];

    self.textWalletName.text = self.wallet.strName;
    self.textWalletName.font = [UIFont systemFontOfSize:18];
    self.textWalletName.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.searchTextField.font = [UIFont fontWithName:@"Montserrat-Regular" size:self.searchTextField.font.pointSize];
    [self.searchTextField addTarget:self action:@selector(searchTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.textWalletName addTarget:self action:@selector(searchTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];

    // set up our user blocking button
    self.buttonBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonBlocker.backgroundColor = [UIColor clearColor];
    [self.buttonBlocker addTarget:self action:@selector(buttonBlockerTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonBlocker.frame = self.view.bounds;
    self.buttonBlocker.hidden = YES;
    //self.buttonBlocker.backgroundColor = [UIColor greenColor];
    [self.view addSubview:self.buttonBlocker];
    [self.view bringSubviewToFront:self.textWalletName];
    [self.view bringSubviewToFront:self.viewSearch];

    _searchShowingFrame = self.viewSearch.frame;

    if (!IS_IPHONE4 && !NO_SEARCHBAR)
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

    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    tableViewController.refreshControl = [[UIRefreshControl alloc] init];
    [tableViewController.refreshControl addTarget:self
                                           action:@selector(refresh:)
                                 forControlEvents:UIControlEventValueChanged];

    [_balanceView refresh];
    _transactionTableStartFrame = self.tableView.frame;

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(dataUpdated:)
                                                 name:NOTIFICATION_BLOCK_HEIGHT_CHANGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(dataUpdated:)
                                                 name:NOTIFICATION_DATA_SYNC_UPDATE object:nil];

    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [CoreBridge reloadWallet:self.wallet];
    [self getBizImagesForWallet:self.wallet];
    [self.tableView reloadData];
    [self updateBalanceView];
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

- (IBAction)Done
{
    if (YES == [self canLeaveWalletNameField])
    {
        [self resignAllResponders];
        if (_bSearchModeEnabled)
        {
            self.searchTextField.text = @"";
            [self transitionToSearch:NO];
        }
        else
        {
            [self.delegate TransactionsViewControllerDone:self];
        }
    }
}

- (IBAction)info
{
    if (YES == [self canLeaveWalletNameField])
    {
        [self resignAllResponders];
        [InfoView CreateWithHTML:@"infoTransactions" forView:self.view];
    }
}

- (IBAction)buttonBlockerTouched:(id)sender
{
    [self blockUser:NO];
    [self resignAllResponders];
}

- (IBAction)buttonSearchTouched:(id)sender
{
    if (YES == [self canLeaveWalletNameField])
    {
        [self resignAllResponders];
        [self transitionToSearch:YES];
    }
}

- (IBAction)buttonRequestTouched:(id)sender
{
    if (YES == [self canLeaveWalletNameField])
    {
        [self resignAllResponders];
        NSDictionary *dictNotification = @{ KEY_TX_DETAILS_EXITED_WALLET_UUID: self.wallet.strUUID };
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LAUNCH_REQUEST_FOR_WALLET
                                                            object:self userInfo:dictNotification];
    }
}

- (IBAction)buttonSendTouched:(id)sender
{
    if (YES == [self canLeaveWalletNameField])
    {
        [self resignAllResponders];
        NSDictionary *dictNotification = @{ KEY_TX_DETAILS_EXITED_WALLET_UUID: self.wallet.strUUID };
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LAUNCH_SEND_FOR_WALLET
                                                            object:self userInfo:dictNotification];
    }
}

- (IBAction)buttonExportTouched:(id)sender
{
    if (YES == [self canLeaveWalletNameField])
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

    ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], 
                          totalSatoshi, &currency, self.wallet.currencyNum, &error);
    _balanceView.botAmount.text = [CoreBridge formatCurrency:currency 
                                             withCurrencyNum:self.wallet.currencyNum];
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
        _frameTableWithSearchNoKeyboard = frame;
        frame.size.height -= TABLE_SIZE_HEIGHT_REDUCE_SEARCH_WITH_KEYBOARD; // compensate for keyboard

        if (IS_IPHONE4  || NO_SEARCHBAR)
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
        if (!IS_IPHONE4 && !NO_SEARCHBAR)
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

    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^
     {
         self.tableView.frame = frame;

         if (IS_IPHONE4  || NO_SEARCHBAR)
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
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
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
    // Paul doesn't want the 'touch background to dismiss keyboard' so for now we wil ignore this
    return;

    if (bBlock)
    {
        [self.view bringSubviewToFront:self.buttonBlocker];
        if (!_bSearchModeEnabled)
        {
            [self.view bringSubviewToFront:self.textWalletName];
        }
        [self.view bringSubviewToFront:self.viewSearch];
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
- (BOOL)canLeaveWalletNameField
{
    if ([self.textWalletName.text length] == 0)
    {
        [self.textWalletName becomeFirstResponder];
        if (!_bWalletNameWarningDisplaying)
        {
            _bWalletNameWarningDisplaying = YES;

            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Invalid Wallet Name", nil)
                                  message:NSLocalizedString(@"You must provide a wallet name.", nil)
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }

        return NO;
    }
    else
    {
        return YES;
    }
}

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
    
    [CoreBridge reloadWallet: self.wallet];
    [self getBizImagesForWallet:self.wallet];
    [self.tableView reloadData];
    [self checkSearchArray];
    [self dismissTransactionDetails];
}

#pragma mark - UITableView delegates

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1)
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
    else
    {

        return _bSearchModeEnabled ? 0 : 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;

    if (indexPath.section == 0)
    {
        if (_bSearchModeEnabled)
        {
            height = 0.0;
        }
        else
        {
            height = TABLE_HEADER_HEIGHT;
        }
    }
    else
    {
        height = TABLE_CELL_HEIGHT;
    }

    return height;
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
    UITableViewCell *finalCell;
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];

    if (section == 0)
    {
        static NSString *cellIdentifier = @"TransactionHeaderCell";

        finalCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (nil == finalCell)
        {
            finalCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            finalCell.selectionStyle = UITableViewCellSelectionStyleNone;
            finalCell.backgroundColor = [UIColor clearColor];
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(15, 0, 143.0, 41.0);
            [button setBackgroundImage:[UIImage imageNamed:@"btn_request.png"] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(buttonRequestTouched:) forControlEvents:UIControlEventTouchUpInside];
            [finalCell addSubview:button];
            [button setTitle:@"      Request" forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:15.0];
            self.buttonRequest = button;

            button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(163.0, 0, 143.0, 41.0);
            [button setBackgroundImage:[UIImage imageNamed:@"btn_send.png"] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(buttonSendTouched:) forControlEvents:UIControlEventTouchUpInside];
            [finalCell addSubview:button];
            [button setTitle:@"      Send" forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:15.0];
            self.buttonSend = button;
        }
    }
    else
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
                cell.confirmationLabel.text = [NSString stringWithFormat:@"Unconfirmed"];
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
    
        CGRect dateFrame = cell.dateLabel.frame;
        CGRect addressFrame = cell.addressLabel.frame;
        CGRect confirmationFrame = cell.confirmationLabel.frame;
        
        if (cell.imagePhoto.image == nil)
        {
            dateFrame.origin.x = addressFrame.origin.x = confirmationFrame.origin.x = 10;
        }
        else
        {
            dateFrame.origin.x = addressFrame.origin.x = confirmationFrame.origin.x = 63;
        }
        
        cell.dateLabel.frame = dateFrame;
        cell.addressLabel.frame = addressFrame;
        cell.confirmationLabel.frame = confirmationFrame;
        
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
    if (indexPath.section == 1)
    {
        if (YES == [self canLeaveWalletNameField])
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
}

#pragma mark - BalanceViewDelegates

- (void)BalanceView:(BalanceView *)view changedStateTo:(tBalanceViewState)state
{
    [self.tableView reloadData];
}

#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == self.textWalletName)
    {
        [self blockUser:YES];

        // highlight all the text
        [textField setSelectedTextRange:[textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.endOfDocument]];
    }
    else if (textField == self.searchTextField)
    {
        if ([self canLeaveWalletNameField])
        {
            [self transitionToSearch:YES];
            [self blockUser:YES];
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.textWalletName)
    {
        if (NO == [self canLeaveWalletNameField])
        {
            [self.textWalletName becomeFirstResponder];
        }
    }
    else if (textField == self.searchTextField)
    {
        if (_bSearchModeEnabled)
        {
            self.tableView.frame = _frameTableWithSearchNoKeyboard;
        }

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
    if ((textField != self.textWalletName) || ([self canLeaveWalletNameField]))
    {
        [textField resignFirstResponder];
    }

    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (textField == self.textWalletName)
    {
        if (NO == [self canLeaveWalletNameField])
        {
            [self blockUser:YES];
            return NO;
        }
        else
        {
            // unhighlight wallet name text
            // note: for some reason, if we don't do this, the text won't select next time the user selects it
            [textField setSelectedTextRange:[textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.beginningOfDocument]];
        }
    }

    return YES;
}

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
    // the only alert we have that uses a delegate is the one that tells them they must provide a wallet name
    [self.textWalletName becomeFirstResponder];
    _bWalletNameWarningDisplaying = NO;
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
    [CoreBridge reloadWallet: self.wallet];
    [self.tableView reloadData];
    [self updateBalanceView];
    [self.view setNeedsDisplay];
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

@end

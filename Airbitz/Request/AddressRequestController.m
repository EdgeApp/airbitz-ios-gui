//
//  AddressRequestController.m
//  AirBitz
//

#import "AddressRequestController.h"
#import "CommonTypes.h"
#import "ButtonSelectorView.h"
#import "Util.h"
#import "User.h"
#import "ABC.h"
#import "MainViewController.h"
#import "Theme.h"

#define X_SOURCE @"Airbitz"

@interface AddressRequestController () <UITextFieldDelegate,  ButtonSelectorDelegate>
{
//	int _selectedWalletIndex;
    NSString *strName;
    NSString *strCategory;
    NSString *strNotes;
    NSNumber *maxNumberAddresses;
//    Wallet   *wallet;
}

@property (nonatomic, weak) IBOutlet ButtonSelectorView *walletSelector;
@property (nonatomic, weak) IBOutlet UILabel *message;
//@property (nonatomic, strong) NSArray  *arrayWallets;

@end

@implementation AddressRequestController

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
	// Do any additional setup after loading the view.
	_walletSelector.delegate = self;
    _walletSelector.textLabel.text = NSLocalizedString(@"Wallet:", nil);
    [_walletSelector setButtonWidth:200];
//    [self loadWalletInfo];
    [self validateUri];

    NSMutableString *msg = [[NSMutableString alloc] init];
    if ([strName length] > 0) {
        [msg appendFormat:NSLocalizedString(@"%@ has requested a bitcoin address to send money to.", nil), strName];
    } else {
        [msg appendString:NSLocalizedString(@"An app has requested a bitcoin address to send money to.", nil)];
    }
    [msg appendString:NSLocalizedString(@" Please choose a wallet to receive funds.", nil)];
    _message.text = msg;



}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews:) name:NOTIFICATION_WALLETS_CHANGED object:nil];

    [self updateViews:nil];
}

- (void)updateViews:(NSNotification *)notification
{
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBarTitle:self title:@"Airbitz"];
    [MainViewController changeNavBar:self title:[Theme Singleton].backButtonText side:NAV_BAR_LEFT button:true enable:false action:nil fromObject:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].helpButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];

    _walletSelector.arrayItemsToSelect = [CoreBridge Singleton].arrayWalletNames;
    [_walletSelector.button setTitle:[CoreBridge Singleton].currentWallet.strName forState:UIControlStateNormal];
    _walletSelector.selectedItemIndex = [CoreBridge Singleton].currentWalletID;
}

- (void)validateUri
{
    if (_url) {
        NSDictionary *dict = [Util getUrlParameters:_url];
        strName = [dict objectForKey:@"x-source"] ? [dict objectForKey:@"x-source"] : @"";
        strNotes = [dict objectForKey:@"notes"] ? [dict objectForKey:@"notes"] : @"";
        strCategory = [dict objectForKey:@"category"] ? [dict objectForKey:@"category"] : @"";
        maxNumberAddresses = [dict objectForKey:@"max-number"] ? [dict objectForKey:@"max-number"] : [NSNumber numberWithInt:1];
        _successUrl = [[NSURL alloc] initWithString:[dict objectForKey:@"x-success"]];
        _errorUrl = [[NSURL alloc] initWithString:[dict objectForKey:@"x-error"]];
        _cancelUrl = [[NSURL alloc] initWithString:[dict objectForKey:@"x-cancel"]];
    } else {
        strName = @"";
        strCategory = @"";
        strNotes = @"";
    }
}

//- (void)loadWalletInfo
//{
//    // load all the non-archive wallets
//    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
//    [CoreBridge loadWallets:arrayWallets archived:nil withTxs:NO];
//
//    // create the array of wallet names
//    _selectedWalletIndex = 0;
//
//    NSMutableArray *arrayWalletNames =
//        [[NSMutableArray alloc] initWithCapacity:[arrayWallets count]];
//    for (int i = 0; i < [arrayWallets count]; i++) {
//        Wallet *w = [arrayWallets objectAtIndex:i];
//        [arrayWalletNames addObject:[NSString stringWithFormat:@"%@ (%@)",
//            w.strName, [CoreBridge formatSatoshi:w.balance]]];
//    }
//    if (_selectedWalletIndex < [arrayWallets count]) {
//        wallet = [arrayWallets objectAtIndex:_selectedWalletIndex];
//        _walletSelector.arrayItemsToSelect = [arrayWalletNames copy];
//        [_walletSelector.button setTitle:wallet.strName forState:UIControlStateNormal];
//        _walletSelector.selectedItemIndex = (int) _selectedWalletIndex;
//    }
//    self.arrayWallets = arrayWallets;
//}
//
#pragma mark - Action Methods

- (IBAction)okay
{
    [self.view endEditing:YES];

    NSMutableString *strRequestID = [[NSMutableString alloc] init];
    NSMutableString *strRequestAddress = [[NSMutableString alloc] init];
    NSMutableString *strRequestURI = [[NSMutableString alloc] init];
    [self createRequest:strRequestID storeRequestURI:strRequestURI
        storeRequestAddressIn:strRequestAddress withAmount:0 withRequestState:kRequest];
    if (_successUrl) {
        NSString *url = [_successUrl absoluteString];
        NSMutableString *query;
        if ([url rangeOfString:@"?"].location == NSNotFound) {
            query = [[NSMutableString alloc] initWithFormat: @"%@?address=%@", url, [Util urlencode:strRequestURI]];
        } else {
            query = [[NSMutableString alloc] initWithFormat: @"%@&address=%@", url, [Util urlencode:strRequestURI]];
        }
        [query appendFormat:@"&x-source=%@", X_SOURCE];
        if ([[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:query]]) {
            // If the URL was successfully opened, finalize the request
            [self finalizeRequest:strRequestID];
        } else {
            // If that failed to open, try error url
            [[UIApplication sharedApplication] openURL:_errorUrl];
        }
    }
    // finish
    [self.delegate AddressRequestControllerDone:self];
}

- (IBAction)cancel
{
    if (_cancelUrl == nil) {
        _cancelUrl = _errorUrl;
    }
    if (_cancelUrl) {
        NSString *url = [_cancelUrl absoluteString];
        NSMutableString *query;
        NSString *cancelMessage = [Util urlencode:NSLocalizedString(@"User cancelled the request.", nil)];
        if ([url rangeOfString:@"?"].location == NSNotFound) {
            query = [[NSMutableString alloc] initWithFormat: @"%@?addr=&cancelMessage=%@", url, cancelMessage];
        } else {
            query = [[NSMutableString alloc] initWithFormat: @"%@&addr=&cancelMessage=%@", url, cancelMessage];
        }
        [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:query]];
    }
    // finish
    [self.delegate AddressRequestControllerDone:self];
}

- (void)createRequest:(NSMutableString *)strRequestID
    storeRequestURI:(NSMutableString *)strRequestURI
    storeRequestAddressIn:(NSMutableString *)strRequestAddress
    withAmount:(SInt64)amountSatoshi withRequestState:(RequestState)state
{
    [strRequestID setString:@""];
    [strRequestAddress setString:@""];
    [strRequestURI setString:@""];

    unsigned int width = 0;
    unsigned char *pData = NULL;
    char *pszURI = NULL;
    tABC_Error error;

    char *szRequestID = [self createReceiveRequestFor:amountSatoshi withRequestState:state];
    if (szRequestID) {
        ABC_GenerateRequestQRCode([[User Singleton].name UTF8String],
            [[User Singleton].password UTF8String], [[CoreBridge Singleton].currentWallet.strUUID UTF8String],
            szRequestID, &pszURI, &pData, &width, &error);
        if (error.code == ABC_CC_Ok) {
            if (pszURI && strRequestURI) {
                [strRequestURI appendFormat:@"%s", pszURI];
                free(pszURI);
            }
        } else {
            [Util printABC_Error:&error];
        }
    }
    if (szRequestID) {
        if (strRequestID) {
            [strRequestID appendFormat:@"%s", szRequestID];
        }
        char *szRequestAddress = NULL;
        tABC_CC result = ABC_GetRequestAddress([[User Singleton].name UTF8String],
            [[User Singleton].password UTF8String], [[CoreBridge Singleton].currentWallet.strUUID UTF8String],
            szRequestID, &szRequestAddress, &error);
        [Util printABC_Error:&error];
        if (result == ABC_CC_Ok) {
            if (szRequestAddress && strRequestAddress) {
                [strRequestAddress appendFormat:@"%s", szRequestAddress];
            }
        }
        if (szRequestAddress) {
            free(szRequestAddress);
        }
    }
    if (szRequestID) {
        free(szRequestID);
    }
    if (pData) {
        free(pData);
    }
}

- (char *)createReceiveRequestFor: (SInt64)amountSatoshi withRequestState:(RequestState)state
{
	tABC_Error error;
    tABC_TxDetails details;

    memset(&details, 0, sizeof(tABC_TxDetails));
    details.amountSatoshi = 0;
	details.amountFeesAirbitzSatoshi = 0;
	details.amountFeesMinersSatoshi = 0;
    details.amountCurrency = 0;
    details.szName = (char *) [strName UTF8String];
    details.szNotes = (char *) [strNotes UTF8String];
	details.szCategory = (char *) [strCategory UTF8String];
	details.attributes = 0x0; //for our own use (not used by the core)
    details.bizId = 0;

	char *pRequestID;
    // create the request
	ABC_CreateReceiveRequest([[User Singleton].name UTF8String],
        [[User Singleton].password UTF8String], [[CoreBridge Singleton].currentWallet.strUUID UTF8String],
        &details, &pRequestID, &error);
	if (error.code == ABC_CC_Ok) {
		return pRequestID;
	} else {
		return 0;
	}
}

- (BOOL)finalizeRequest:(NSString *)requestId
{
    tABC_Error error;
    // Finalize this request so it isn't used elsewhere
    ABC_FinalizeReceiveRequest([[User Singleton].name UTF8String],
        [[User Singleton].password UTF8String], [[CoreBridge Singleton].currentWallet.strUUID UTF8String],
        [requestId UTF8String], &error);
    [Util printABC_Error:&error];
    return error.code == ABC_CC_Ok ? YES : NO;
}

#pragma mark - ButtonSelectorView delegates

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
    NSIndexPath *indexPath = [[NSIndexPath alloc]init];
    indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [CoreBridge makeCurrentWalletWithIndex:indexPath];
}

@end

//
//  PluginViewController.m
//  AirBitz
//

#import "PluginViewController.h"
#import "ButtonSelectorView2.h"
#import "ABC.h"
#import "Config.h"
#import "User.h"
#import "FadingAlertView.h"
#import "CoreBridge.h"
#import "SendConfirmationViewController.h"
#import "MainViewController.h"
#import "Theme.h"
#import "Util.h"
#import "Notifications.h"
#import "CommonTypes.h"
#import "SpendTarget.h"
#import "MainViewController.h"

static const NSString *PROTOCOL = @"bridge://";

@interface PluginViewController () <UIWebViewDelegate, SendConfirmationViewControllerDelegate>
{
    FadingAlertView                *_fadingAlert;
    SendConfirmationViewController *_sendConfirmationViewController;
    NSString                       *_sendCbid;
    Wallet                         *_sendWallet;
    NSMutableArray                 *_navStack;
    NSDictionary                   *_functions;
    BOOL                           bWalletListDropped;
}

@property (nonatomic, retain) IBOutlet UILabel            *titleLabel;
@property (nonatomic, retain) IBOutlet UIButton           *backButton;
@property (nonatomic, retain) IBOutlet UIWebView          *webView;
@property (nonatomic, weak)   IBOutlet ButtonSelectorView2 *buttonSelector; //wallet dropdown

@end

@implementation PluginViewController

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

    bWalletListDropped = false;
    _navStack = [[NSMutableArray alloc] init];
    _functions = @{
                     @"bitidAddress":NSStringFromSelector(@selector(bitidAddress:)),
                     @"bitidSignature":NSStringFromSelector(@selector(bitidSignature:)),
                     @"selectedWallet":NSStringFromSelector(@selector(selectedWallet:)),
                     @"wallets":NSStringFromSelector(@selector(wallets:)),
        @"createReceiveRequest":NSStringFromSelector(@selector(createReceiveRequest:)),
                @"requestSpend":NSStringFromSelector(@selector(launchSpendConfirmation:)),
             @"finalizeRequest":NSStringFromSelector(@selector(finalizeRequest:)),
                   @"writeData":NSStringFromSelector(@selector(writeData:)),
                   @"clearData":NSStringFromSelector(@selector(clearData:)),
                    @"readData":NSStringFromSelector(@selector(readData:)),
          @"getBtcDenomination":NSStringFromSelector(@selector(getBtcDenomination:)),
           @"satoshiToCurrency":NSStringFromSelector(@selector(satoshiToCurrency:)),
           @"currencyToSatoshi":NSStringFromSelector(@selector(currencyToSatoshi:)),
               @"formatSatoshi":NSStringFromSelector(@selector(formatSatoshi:)),
              @"formatCurrency":NSStringFromSelector(@selector(formatCurrency:)),
                   @"getConfig":NSStringFromSelector(@selector(getConfig:)),
                   @"showAlert":NSStringFromSelector(@selector(showAlert:)),
                       @"title":NSStringFromSelector(@selector(title:)),
                  @"showNavBar":NSStringFromSelector(@selector(showNavBar:)),
                  @"hideNavBar":NSStringFromSelector(@selector(hideNavBar:)),
                        @"exit":NSStringFromSelector(@selector(uiExit:)),
               @"navStackClear":NSStringFromSelector(@selector(navStackClear:)),
                @"navStackPush":NSStringFromSelector(@selector(navStackPush:)),
                 @"navStackPop":NSStringFromSelector(@selector(navStackPop:))
    };

    NSString *localFilePath = [[NSBundle mainBundle] pathForResource:_plugin.sourceFile ofType:_plugin.sourceExtension];
    NSURLRequest *localRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:localFilePath]];
    _webView.delegate = self;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.opaque = NO;
    [_webView loadRequest:localRequest];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews:) name:NOTIFICATION_WALLETS_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self resizeFrame:YES];
    [super viewWillAppear:animated];

	self.buttonSelector.delegate = self;
    [self.buttonSelector disableButton];

    [self updateViews:nil];
    [self notifyDenominationChange];
}

- (void)updateViews:(NSNotification *)notification
{
    [MainViewController changeNavBarOwner:self];
    if ([CoreBridge Singleton].arrayWallets && [CoreBridge Singleton].currentWallet)
    {
        self.buttonSelector.arrayItemsToSelect = [CoreBridge Singleton].arrayWalletNames;
        [self.buttonSelector.button setTitle:[CoreBridge Singleton].currentWallet.strName forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = [CoreBridge Singleton].currentWalletID;

        NSString *walletName = [NSString stringWithFormat:@"%@ ▼", [CoreBridge Singleton].currentWallet.strName];
        [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle:) fromObject:self];

        if (notification == nil || ![notification.name isEqualToString:@"Skip"]) {
            [self notifyWalletChanged];
        }
    }
    if (bWalletListDropped) {
        [MainViewController changeNavBar:self title:[Theme Singleton].closeButtonText side:NAV_BAR_LEFT button:true enable:bWalletListDropped action:@selector(didTapTitle:) fromObject:self];
    } else {
        [MainViewController changeNavBar:self title:[Theme Singleton].backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Back:) fromObject:self];
    }
    [MainViewController changeNavBar:self title:[Theme Singleton].helpButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
}

#pragma mark - ButtonSelectorView2 delegates

- (void)ButtonSelector2:(ButtonSelectorView2 *)view selectedItem:(int)itemIndex
{
    NSIndexPath *indexPath = [[NSIndexPath alloc]init];
    indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [CoreBridge makeCurrentWalletWithIndex:indexPath];

    bWalletListDropped = false;
    [MainViewController changeNavBar:self title:[Theme Singleton].backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Back:) fromObject:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didTapTitle: (UIButton *)sender
{
    if (bWalletListDropped)
    {
        [self.buttonSelector close];
        bWalletListDropped = false;
        [MainViewController changeNavBar:self title:[Theme Singleton].backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Back:) fromObject:self];
    }
    else
    {
        [self.buttonSelector open];
        bWalletListDropped = true;
        [MainViewController changeNavBar:self title:[Theme Singleton].closeButtonText side:NAV_BAR_LEFT button:true enable:bWalletListDropped action:@selector(didTapTitle:) fromObject:self];
    }
}

- (void)resizeFrame:(BOOL)withTabBar
{
    CGRect webFrame = _webView.frame;
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    webFrame.size.height = screenFrame.size.height - HEADER_HEIGHT;
    if (withTabBar) {
        webFrame.size.height -= TOOLBAR_HEIGHT;
    }

    _webView.frame = webFrame;
    [_webView setNeedsLayout];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - WebView Methods

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *padding = @"document.body.style.margin='0';document.body.style.padding = '0'";
    [_webView stringByEvaluatingJavaScriptFromString:padding];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *url = [request URL].absoluteString;
    NSLog(@("url: %@"), url);
    if ([[url lowercaseString] hasPrefix:PROTOCOL]) {
        url = [url substringFromIndex:PROTOCOL.length];
        url = [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        NSError *jsonError;
        NSDictionary *callInfo = [NSJSONSerialization
                                  JSONObjectWithData:[url dataUsingEncoding:NSUTF8StringEncoding]
                                  options:kNilOptions
                                  error:&jsonError];
        if (jsonError != nil) {
            ABLog(2,@"Error parsing JSON for the url %@",url);
            return NO;
        }

        NSString *functionName = [callInfo objectForKey:@"functionName"];
        if (functionName == nil) {
            ABLog(2,@"Missing function name");
            return NO;
        }

        NSString *cbid = [callInfo objectForKey:@"cbid"];
        NSDictionary *args = [callInfo objectForKey:@"args"];
        [self execFunction:functionName withCbid:cbid withArgs:args];
        return NO;
    } else if ([[url lowercaseString] hasPrefix:@"airbitz://plugin"]) {
        NSURL *base = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:_plugin.sourceFile
                                                                             ofType:_plugin.sourceExtension]];
        NSString *newUrlString = [NSString stringWithFormat:@"%@?%@", [base absoluteString], [request URL].query];
        NSURL *newUrl = [NSURL URLWithString:newUrlString];
        [_webView loadRequest:[NSURLRequest requestWithURL:newUrl]];
        return NO;
    }
    return YES;
}

- (NSDictionary *)jsonResponse:(BOOL)success
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [d setObject:[NSNumber numberWithBool:success] forKey:@"success"];
    return d;
}

- (NSDictionary *)jsonSuccess
{
    return [self jsonResponse:YES];
}

- (NSDictionary *)jsonError
{
    return [self jsonResponse:NO];
}

- (NSDictionary *)jsonResult:(id)val
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    if (val) {
        [d setObject:val forKey:@"result"];
    }
    [d setObject:[NSNumber numberWithBool:YES] forKey:@"success"];
    return d;
}

- (void)execFunction:(NSString *)name withCbid:cbid withArgs:(NSDictionary *)args
{
    ABLog(2,@("execFunction %@"), name);

    NSDictionary *params = @{@"cbid": cbid, @"args": args};
    if ([_functions objectForKey:name] != nil) {
        [self performSelector:NSSelectorFromString([_functions objectForKey:name]) withObject:params];
    } else {
        // We run both here in case the JS implementation is blocking or uses callbacks
        [self setJsResults:cbid withArgs:[self jsonError]];
        [self callJsFunction:cbid withArgs:[self jsonError]];
    }
}

- (void)setJsResults:(NSString *)cbid withArgs:(NSDictionary *)args
{
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:args options:0 error:&jsonError];
    if (jsonError != nil) {
        ABLog(2,@"Error creating JSON from the response  : %@", [jsonError localizedDescription]);
        return;
    }

    NSString *resp = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    ABLog(2,@"resp = %@", resp);
    if (resp == nil) {
        ABLog(2,@"resp is null. count = %d", (unsigned int)[args count]);
    }
    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Airbitz._results[%@]=%@", cbid, resp]];
}

- (void)callJsFunction:(NSString *)cbid withArgs:(NSDictionary *)args
{
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:args options:0 error:&jsonError];
    if (jsonError != nil) {
        ABLog(2,@"Error creating JSON from the response  : %@", [jsonError localizedDescription]);
        return;
    }

    NSString *resp = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    ABLog(2,@"resp = %@", resp);
    if (resp == nil) {
        ABLog(2,@"resp is null. count = %d", (int)[args count]);
    }
    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Airbitz._callbacks[%@]('%@');", cbid, resp]];
}

#pragma mark - Action Methods

- (IBAction)Back:(id)sender
{
    if (_sendConfirmationViewController != nil) {
        [self sendConfirmationViewControllerDidFinish:_sendConfirmationViewController
                                             withBack:YES
                                            withError:NO
                                            withTxId:nil];
    } else if ([_navStack count] == 0) {
        self.view.alpha = 1.0;
        [UIView animateWithDuration:0.35
                            delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                        animations:^{
            self.view.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.delegate PluginViewControllerDone:self];
        }];
    } else {
        // Press back button
        [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Airbitz.ui.back();"]];
    }
}

#pragma mark - Core Functions

- (void)bitidAddress:(NSDictionary *)params
{
    NSDictionary *args = [params objectForKey:@"args"];
    NSString *uri = [args objectForKey:@"uri"];
    NSString *msg = [args objectForKey:@"message"];
    BitidSignature *bitid = [CoreBridge bitidSign:uri msg:msg];

    [self setJsResults:[params objectForKey:@"cbid"] withArgs:[self jsonResult:bitid.address]];
}

- (void)bitidSignature:(NSDictionary *)params
{
    NSDictionary *args = [params objectForKey:@"args"];
    NSString *uri = [args objectForKey:@"uri"];
    NSString *msg = [args objectForKey:@"message"];
    BitidSignature *bitid = [CoreBridge bitidSign:uri msg:msg];

    [self setJsResults:[params objectForKey:@"cbid"] withArgs:[self jsonResult:bitid.signature]];
}

- (NSMutableDictionary *)walletToDict:(Wallet *)w
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [d setObject:w.strUUID forKey:@"id"];
    [d setObject:w.strName forKey:@"name"];
    [d setObject:[NSNumber numberWithInt:w.currencyNum] forKey:@"currencyNum"];
    [d setObject:[NSNumber numberWithLong:w.balance] forKey:@"balance"];
    return d;
}

- (void)notifyWalletChanged
{
    NSMutableDictionary *d = [self walletToDict:[CoreBridge Singleton].currentWallet];
    NSDictionary *data = [self jsonResult:d];

    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&jsonError];
    if (jsonError != nil) {
        ABLog(2,@"Error creating JSON from the response  : %@", [jsonError localizedDescription]);
        return;
    }

    NSString *resp = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    ABLog(2,@"resp = %@", resp);
    if (resp == nil) {
        ABLog(2,@"resp is null. count = %d", (unsigned int)[data count]);
    }
    if (_webView) {
        [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Airbitz._bridge.walletChanged('%@');", resp]];
        [self notifyDenominationChange];
    }
}

- (void)notifyDenominationChange
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [d setObject:[User Singleton].denominationLabel forKey:@"value"];
    NSDictionary *data = [self jsonResult:d];

    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&jsonError];
    if (jsonError != nil) {
        ABLog(2,@"Error creating JSON from the response  : %@", [jsonError localizedDescription]);
        return;
    }

    NSString *resp = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    ABLog(2,@"resp = %@", resp);
    if (resp == nil) {
        ABLog(2,@"resp is null. count = %d", (unsigned int)[data count]);
    }
    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Airbitz._bridge.denominationUpdate('%@');", resp]];
}

- (void)selectedWallet:(NSDictionary *)params
{
    NSMutableDictionary *d = [self walletToDict:[CoreBridge Singleton].currentWallet];
    [self callJsFunction:[params objectForKey:@"cbid"] withArgs:[self jsonResult:d]];
}

- (void)wallets:(NSDictionary *)params
{
    // TODO: move to queue
    NSMutableArray *results = [[NSMutableArray alloc] init];
    for (Wallet *w in [CoreBridge Singleton].arrayWallets) {
        NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
        [d setObject:w.strUUID forKey:@"id"];
        [d setObject:w.strName forKey:@"name"];
        [d setObject:[NSNumber numberWithInt:w.currencyNum] forKey:@"currencyNum"];
        [d setObject:[NSNumber numberWithLong:w.balance] forKey:@"balance"];
        [results addObject:d];
    }
    [self callJsFunction:[params objectForKey:@"cbid"] withArgs:[self jsonResult:results]];
}

- (void)launchSpendConfirmation:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    if (_sendCbid != nil || _sendConfirmationViewController != nil) {
        return;
    }
    _sendCbid = cbid;
    _sendWallet = [CoreBridge getWallet:[args objectForKey:@"id"]];

    tABC_Error error;
    SpendTarget *spendTarget = [[SpendTarget alloc] init];
    if ([spendTarget spendNewInternal:[args objectForKey:@"toAddress"]
                                label:[args objectForKey:@"label"]
                             category:[args objectForKey:@"category"]
                                notes:[args objectForKey:@"notes"] 
                        amountSatoshi:[[args objectForKey:@"amountSatoshi"] longValue]
                                error:&error]) {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
        _sendConfirmationViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendConfirmationViewController"];
        _sendConfirmationViewController.delegate = self;
        _sendConfirmationViewController.spendTarget = spendTarget;

        [CoreBridge makeCurrentWallet:_sendWallet];
        _sendConfirmationViewController.overrideCurrency = [[args objectForKey:@"amountFiat"] doubleValue];
        _sendConfirmationViewController.bAdvanceToTx = NO;
        [Util animateController:_sendConfirmationViewController parentController:self];
    }
}

- (void)createReceiveRequest:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

	tABC_Error error;
    NSDictionary *results = nil;

    Wallet *wallet = [CoreBridge getWallet:[args objectForKey:@"id"]];

    tABC_TxDetails details;
    memset(&details, 0, sizeof(tABC_TxDetails));
    details.amountSatoshi = [[args objectForKey:@"amountSatoshi"] longValue];
    details.amountCurrency = [[args objectForKey:@"amountFiat"] doubleValue];
	details.amountFeesAirbitzSatoshi = 0;
	details.amountFeesMinersSatoshi = 0;
    details.szName = (char *)[[args objectForKey:@"label"] UTF8String];
    details.szNotes = (char *)[[args objectForKey:@"notes"] UTF8String];
    details.szCategory = (char *)[[args objectForKey:@"category"] UTF8String];
	details.attributes = 0x0;
    details.bizId = 0;

	char *pRequestID;

    // create the request
	ABC_CreateReceiveRequest([[User Singleton].name UTF8String],
                             [[User Singleton].password UTF8String],
                             [wallet.strUUID UTF8String],
                             &details, &pRequestID, &error);
	if (error.code == ABC_CC_Ok) {
        NSString *requestId = [NSString stringWithUTF8String:pRequestID];
        NSString *address = [self getRequestAddress:pRequestID withWallet:wallet];
        NSDictionary *d = @{@"requestId": requestId, @"address": address};
        results = [self jsonResult:d];
        if (pRequestID) {
            free(pRequestID);
        }
	} else {
        results = [self jsonError];
	}
    [self callJsFunction:cbid withArgs:results];
}

- (void)finalizeRequest:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    tABC_Error error;
    ABC_FinalizeReceiveRequest([[User Singleton].name UTF8String],
                               [[User Singleton].password UTF8String],
                               [[args objectForKey:@"id"] UTF8String],
                               [[args objectForKey:@"requestId"] UTF8String],
                               &error);
    if (error.code == ABC_CC_Ok) {
        [self setJsResults:cbid withArgs:[self jsonSuccess]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)writeData:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];
    if ([self pluginDataSet:_plugin.pluginId withKey:[args objectForKey:@"key"] 
                                    withValue:[args objectForKey:@"value"]]) {
        [self setJsResults:cbid withArgs:[self jsonSuccess]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)clearData:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    if ([self pluginDataClear:_plugin.pluginId]) {
        [self setJsResults:cbid withArgs:[self jsonSuccess]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)readData:(NSDictionary *)params
{
    NSDictionary *args = [params objectForKey:@"args"];
    NSString *value = [self pluginDataGet:_plugin.pluginId withKey:[args objectForKey:@"key"]];
    [self setJsResults:[params objectForKey:@"cbid"] withArgs:[self jsonResult:value]];
}

- (void)getBtcDenomination:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];
    [self setJsResults:cbid withArgs:[self jsonResult:[User Singleton].denominationLabel]];
}

- (void)satoshiToCurrency:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];
            
    tABC_Error error;
    double currency;
    ABC_SatoshiToCurrency([[User Singleton].name UTF8String],
                          [[User Singleton].password UTF8String],
                          [[args objectForKey:@"satoshi"] longValue],
                          &currency,
                          [[args objectForKey:@"currencyNum"] intValue],
                          &error);
    if (error.code == ABC_CC_Ok) {
        [self setJsResults:cbid withArgs:[self jsonResult:[NSNumber numberWithDouble:currency]]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)currencyToSatoshi:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    tABC_Error error;
    int64_t satoshis;
    ABC_CurrencyToSatoshi([[User Singleton].name UTF8String],
                          [[User Singleton].password UTF8String],
                          [[args objectForKey:@"currency"] doubleValue],
                          [[args objectForKey:@"currencyNum"] intValue],
                          &satoshis, &error);
    if (error.code == ABC_CC_Ok) {
        [self setJsResults:cbid withArgs:[self jsonResult:[NSNumber numberWithLongLong:satoshis]]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)formatSatoshi:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    NSString *res = [CoreBridge formatSatoshi:[[args objectForKey:@"satoshi"] longValue]];
    [self setJsResults:cbid withArgs:[self jsonResult:res]];
}

- (void)formatCurrency:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    NSString *res = [CoreBridge formatCurrency:[[args objectForKey:@"currency"] doubleValue]
                                withCurrencyNum:[[args objectForKey:@"currencyNum"] intValue]
                                    withSymbol:[[args objectForKey:@"withSymbol"] boolValue]];
    res = [res stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self setJsResults:cbid withArgs:[self jsonResult:res]];
}

- (void)getConfig:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    NSString *key = [args objectForKey:@"key"];
    NSString *value = [_plugin.env valueForKey:key];
    if (value) {
        [self setJsResults:cbid withArgs:[self jsonResult:value]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonResult:@""]];
    }
}

- (void)showAlert:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];
    BOOL showSpinner = [[args objectForKey:@"showSpinner"] boolValue];

    [self showFadingAlert:[args objectForKey:@"message"] showSpinner:showSpinner];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

- (void)title:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    _titleLabel.text = [args objectForKey:@"title"];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

- (void)showNavBar:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:YES]];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

- (void)hideNavBar:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:NO]];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

- (void)uiExit:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];

    if ([self.delegate respondsToSelector:@selector(PluginViewControllerDone:)]) {
        [self.delegate PluginViewControllerDone:self];
    }
    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

- (void)navStackClear:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];

    _navStack = [[NSMutableArray alloc] init];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

- (void)navStackPush:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    [_navStack addObject:[args objectForKey:@"path"]];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

- (void)navStackPop:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];

    [_navStack removeLastObject];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

#pragma - Helper Functions

- (NSString *)getRawTransaction:(NSString *)walletUUID withTxId:(NSString *)txId
{
    char *szHex = NULL;
    NSString *hex = nil;
    tABC_Error error;
    ABC_GetRawTransaction([[User Singleton].name UTF8String],
        [[User Singleton].password UTF8String], [walletUUID UTF8String], [txId UTF8String], &szHex, &error);
    if (error.code == ABC_CC_Ok) {
        hex = [NSString stringWithUTF8String:szHex];
    }
    if (szHex) {
        free(szHex);
    }
    return hex;
}

- (NSString *)getRequestAddress:(char *)szRequestID withWallet:(Wallet *)wallet
{
    char *szRequestAddress = NULL;
    NSString *address;
    tABC_Error error;
    ABC_GetRequestAddress([[User Singleton].name UTF8String],
                          [[User Singleton].password UTF8String],
                          [wallet.strUUID UTF8String],
                          szRequestID, &szRequestAddress, &error);
    if (error.code == ABC_CC_Ok) {
        address = [NSString stringWithUTF8String:szRequestAddress];
    }
    if (szRequestAddress) {
        free(szRequestAddress);
    }
    return address;
}

- (NSString *)pluginDataGet:(NSString *)pluginId withKey:(NSString *)key
{
    tABC_Error error;
    NSString *result = nil;
    char *szData = NULL;
    ABC_PluginDataGet([[User Singleton].name UTF8String],
                      [[User Singleton].password UTF8String],
                      [pluginId UTF8String], [key UTF8String],
                      &szData, &error);
    if (error.code == ABC_CC_Ok) {
        result = [NSString stringWithUTF8String:szData];
    }
    if (szData != NULL) {
        free(szData);
    }
    return result;
}

- (BOOL)pluginDataSet:(NSString *)pluginId withKey:(NSString *)key withValue:(NSString *)value
{
    tABC_Error error;
    ABC_PluginDataSet([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
        [pluginId UTF8String], [key UTF8String], [value UTF8String], &error);
    return error.code == ABC_CC_Ok;
}

- (BOOL)pluginDataRemove:(NSString *)pluginId withKey:(NSString *)key
{
    tABC_Error error;
    ABC_PluginDataRemove([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
        [pluginId UTF8String], [key UTF8String], &error);
    return error.code == ABC_CC_Ok;
}

- (BOOL)pluginDataClear:(NSString *)pluginId
{
    tABC_Error error;
    ABC_PluginDataClear([[User Singleton].name UTF8String],
        [[User Singleton].password UTF8String], [pluginId UTF8String], &error);
    return error.code == ABC_CC_Ok;
}

#pragma - SendConfirmationViewControllerDelegate

- (void)sendConfirmationViewControllerDidFinish:(SendConfirmationViewController *)controller
{
    [self sendConfirmationViewControllerDidFinish:controller withBack:NO withError:YES withTxId:nil];
}

- (void)sendConfirmationViewControllerDidFinish:(SendConfirmationViewController *)controller
                                       withBack:(BOOL)bBack
                                      withError:(BOOL)bError
                                       withTxId:(NSString *)txId
{
    [self updateViews:[NSNotification notificationWithName:@"Skip" object:nil]];
    [Util animateOut:_sendConfirmationViewController parentController:self complete:^(void) {
        // hide calculator
        if (bBack) {
            [self callJsFunction:_sendCbid withArgs:[self jsonResult:@{@"back": @"true"}]];
        } else if (bError) {
            [self callJsFunction:_sendCbid withArgs:[self jsonError]];
        } else {
            if (txId) {
                NSString *hex = [self getRawTransaction:_sendWallet.strUUID withTxId:txId];
                [self callJsFunction:_sendCbid withArgs:[self jsonResult:hex]];
            } else {
                [self callJsFunction:_sendCbid withArgs:[self jsonError]];
            }
        }
        // clean up
        _sendConfirmationViewController = nil;
        _sendCbid = nil;
    }];
}


#pragma - Fading Alert

- (void)showFadingAlert:(NSString *)message showSpinner:(BOOL)showSpinner
{
    CGFloat duration = FADING_ALERT_HOLD_TIME_DEFAULT;
    if (showSpinner) {
        duration = FADING_ALERT_HOLD_TIME_FOREVER_WITH_SPINNER; 
    }
    [MainViewController fadingAlert:message holdTime:duration];
}

#pragma mark - Keyboard Hack

// Snagged from https://github.com/apache/cordova-plugins

- (void)keyboardWillShow:(NSNotification *)notification
{
    [self performSelector:@selector(stylizeKeyboard) withObject:nil afterDelay:0];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
}

- (void)stylizeKeyboard
{
    UIWindow *keyboardWindow = nil;
    for (UIWindow *windows in [[UIApplication sharedApplication] windows]) {
        if (![[windows class] isEqual:[UIWindow class]]) {
            keyboardWindow = windows;
            break;
        }
    }

    BOOL picker = NO;
    for (UIView* peripheralView in [self getKeyboardViews:keyboardWindow]) {
        if ([[peripheralView description] hasPrefix:@"<UIWebSelectSinglePicker"]
                || [[peripheralView description] hasPrefix:@"<UIDatePicker"]) {
            picker = YES;
            break;
        }
    }
    if (picker) {
        [self modPicker:keyboardWindow];
    } else {
        [self modKeyboard:keyboardWindow];
    }
    [self resizeFrame:YES];
}

- (void)modPicker:(UIWindow *)keyboardWindow {
    for (UIView* peripheralView in [self getKeyboardViews:keyboardWindow]) {
        if ([[peripheralView description] hasPrefix:@"<UIKBInputBackdropView"]) {
            [[peripheralView layer] setOpacity:1.0];
        }
        if ([[peripheralView description] hasPrefix:@"<UIImageView"]) {
            [[peripheralView layer] setOpacity:1.0];
        }
        if ([[peripheralView description] hasPrefix:@"<UIWebFormAccessory"]) {
            [[peripheralView layer] setOpacity:1.0];

            UIView *view = [peripheralView.subviews objectAtIndex:0];
            if (view == nil) {
                continue;
            }
            UIView *toolbar = [view.subviews objectAtIndex:0];
            if (toolbar == nil) {
                continue;
            }
            for (UIView *subview in toolbar.subviews) {
                if ([[subview description] hasPrefix:@"<UIToolbarButton"]) {
                    subview.hidden = YES;
                }
            }
        }
    }
}

- (void)modKeyboard:(UIWindow *)keyboardWindow {
    for (UIView* peripheralView in [self getKeyboardViews:keyboardWindow]) {
        // hides the backdrop (iOS 7)
        if ([[peripheralView description] hasPrefix:@"<UIKBInputBackdropView"]) {
            // sparing the backdrop behind the main keyboard
            CGRect rect = peripheralView.frame;
            if (rect.origin.y == 0) {
                [[peripheralView layer] setOpacity:0.0];
            }
        }
        
        // hides the accessory bar
        if ([[peripheralView description] hasPrefix:@"<UIWebFormAccessory"]) {
            //remove the extra scroll space for the form accessory bar
            CGRect newFrame = self.webView.scrollView.frame;
            newFrame.size.height += peripheralView.frame.size.height;
            self.webView.scrollView.frame = newFrame;
            
            // remove the form accessory bar
            if ([self IsAtLeastiOSVersion8]) {
                [[peripheralView layer] setOpacity:0.0];
            } else {
                [peripheralView removeFromSuperview];
            }
        }
        // hides the thin grey line used to adorn the bar (iOS 6)
        if ([[peripheralView description] hasPrefix:@"<UIImageView"]) {
            [[peripheralView layer] setOpacity:0.0];
        }
    }
}

- (NSArray*)getKeyboardViews:(UIView*)viewToSearch{
    NSArray *subViews = [[NSArray alloc] init];
    for (UIView *possibleFormView in viewToSearch.subviews) {
        if ([[possibleFormView description] hasPrefix: self.getKeyboardFirstLevelIdentifier]) {
            if([self IsAtLeastiOSVersion8]){
                for (UIView* subView in possibleFormView.subviews) {
                    return subView.subviews;
                }
            }else{
                return possibleFormView.subviews;
            }
        }
        
    }
    return subViews;
}

- (NSString*)getKeyboardFirstLevelIdentifier{
    if(![self IsAtLeastiOSVersion8]){
        return @"<UIPeripheralHostView";
    }else{
        return @"<UIInputSetContainerView";
    }
}

- (BOOL)IsAtLeastiOSVersion8
{
#ifdef __IPHONE_8_0
    return YES;
#else
    return NO;
#endif

}


@end

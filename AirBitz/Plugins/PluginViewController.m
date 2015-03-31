//
//  PluginViewController.m
//  AirBitz
//

#import "PluginViewController.h"
#import "ABC.h"
#import "Config.h"
#import "User.h"
#import "FadingAlertView.h"
#import "CoreBridge.h"
#import "SendConfirmationViewController.h"
#import "Util.h"
#import "Notifications.h"
#import "CommonTypes.h"

static const NSString *PROTOCOL = @"bridge://";
static NSString *pluginId = @"com.glidera";

@interface PluginViewController () <UIWebViewDelegate, SendConfirmationViewControllerDelegate>
{
    FadingAlertView                *_fadingAlert;
    SendConfirmationViewController *_sendConfirmationViewController;
    NSString                       *_sendCbid;
    Wallet                         *_sendWallet;
    NSMutableArray                 *_navStack;
    NSDictionary                   *_functions;
}

@property (nonatomic, retain) IBOutlet UILabel            *titleLabel;
@property (nonatomic, retain) IBOutlet UIButton           *backButton;
@property (nonatomic, retain) IBOutlet UIWebView          *webView;

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

    _navStack = [[NSMutableArray alloc] init];
    _functions = @{
                     @"wallets":NSStringFromSelector(@selector(wallets:)),
        @"createReceiveRequest":NSStringFromSelector(@selector(createReceiveRequest:)),
                @"requestSpend":NSStringFromSelector(@selector(launchSpendConfirmation:)),
             @"finalizeRequest":NSStringFromSelector(@selector(finalizeRequest:)),
                   @"writeData":NSStringFromSelector(@selector(writeData:)),
                   @"clearData":NSStringFromSelector(@selector(clearData:)),
                    @"readData":NSStringFromSelector(@selector(readData:)),
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

    NSString *localFilePath = [[NSBundle mainBundle] pathForResource:@"glidera" ofType:@"html" inDirectory:@"plugins"];
    NSURLRequest *localRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:localFilePath]];
    _webView.delegate = self;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.opaque = NO;
    [_webView loadRequest:localRequest];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self resizeFrame:YES];

    [super viewWillAppear:animated];
}

- (void)resizeFrame:(BOOL)withTabBar
{
    CGRect frame = _webView.frame;
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    frame.size.height = screenFrame.size.height - HEADER_HEIGHT;
    if (withTabBar) {
        frame.size.height -= TOOLBAR_HEIGHT;
    }

    _webView.frame = frame;
    _webView.scrollView.bounces = NO;
    [_webView setNeedsLayout];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - WebView Methods

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
            NSLog(@"Error parsing JSON for the url %@",url);
            return NO;
        }

        NSString *functionName = [callInfo objectForKey:@"functionName"];
        if (functionName == nil) {
            NSLog(@"Missing function name");
            return NO;
        }

        NSString *cbid = [callInfo objectForKey:@"cbid"];
        NSDictionary *args = [callInfo objectForKey:@"args"];
        [self execFunction:functionName withCbid:cbid withArgs:args];
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
    [d setObject:val forKey:@"result"];
    [d setObject:[NSNumber numberWithBool:YES] forKey:@"success"];
    return d;
}

- (void)execFunction:(NSString *)name withCbid:cbid withArgs:(NSDictionary *)args
{
    NSLog(@("execFunction %@"), name);

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
        NSLog(@"Error creating JSON from the response  : %@", [jsonError localizedDescription]);
        return;
    }

    NSString *resp = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"resp = %@", resp);
    if (resp == nil) {
        NSLog(@"resp is null. count = %d", [args count]);
    }
    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Airbitz._results[%@]=%@", cbid, resp]];
}

- (void)callJsFunction:(NSString *)cbid withArgs:(NSDictionary *)args
{
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:args options:0 error:&jsonError];
    if (jsonError != nil) {
        NSLog(@"Error creating JSON from the response  : %@", [jsonError localizedDescription]);
        return;
    }

    NSString *resp = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"resp = %@", resp);
    if (resp == nil) {
        NSLog(@"resp is null. count = %d", [args count]);
    }
    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Airbitz._callbacks[%@]('%@');", cbid, resp]];
}

#pragma mark - Action Methods

- (IBAction)Back
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

- (void)wallets:(NSDictionary *)params
{
    // TODO: move to queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
        NSMutableArray *arrayArchivedWallets = [[NSMutableArray alloc] init];
        [CoreBridge loadWallets:arrayWallets archived:arrayArchivedWallets withTxs:NO];
        NSMutableArray *results = [[NSMutableArray alloc] init];
        for (Wallet *w in arrayWallets) {
            NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
            [d setObject:w.strUUID forKey:@"id"];
            [d setObject:w.strName forKey:@"name"];
            [d setObject:[NSNumber numberWithInt:w.currencyNum] forKey:@"currencyNum"];
            [d setObject:[NSNumber numberWithLong:w.balance] forKey:@"balance"];
            [results addObject:d];
        }
        dispatch_async(dispatch_get_main_queue(),^{
            [self callJsFunction:[params objectForKey:@"cbid"] withArgs:[self jsonResult:results]];
        });
    });
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

    NSString *toAddress = [args objectForKey:@"toAddress"];
    uint64_t amountSatoshi = [[args objectForKey:@"amountSatoshi"] longValue];
    double amountFiat = [[args objectForKey:@"amountFiat"] doubleValue];
    NSString *label = [args objectForKey:@"label"];
    NSString *category = [args objectForKey:@"category"];
    NSString *notes = [args objectForKey:@"notes"];

	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_sendConfirmationViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendConfirmationViewController"];
	_sendConfirmationViewController.delegate = self;
	_sendConfirmationViewController.sendToAddress = toAddress;
    _sendConfirmationViewController.bAddressIsWalletUUID = NO;
    _sendConfirmationViewController.wallet = _sendWallet;
	_sendConfirmationViewController.amountToSendSatoshi = amountSatoshi;
	_sendConfirmationViewController.overrideCurrency = amountFiat;
	_sendConfirmationViewController.nameLabel = label;
	_sendConfirmationViewController.category = category;
	_sendConfirmationViewController.notes = notes;
    _sendConfirmationViewController.bAdvanceToTx = NO;
    [Util animateController:_sendConfirmationViewController parentController:self];
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
    if ([self pluginDataSet:pluginId withKey:[args objectForKey:@"key"] 
                                    withValue:[args objectForKey:@"value"]]) {
        [self setJsResults:cbid withArgs:[self jsonSuccess]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)clearData:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];
    if ([self pluginDataClear:pluginId]) {
        [self setJsResults:cbid withArgs:[self jsonSuccess]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)readData:(NSDictionary *)params
{
    NSDictionary *args = [params objectForKey:@"args"];
    NSString *value = [self pluginDataGet:pluginId withKey:[args objectForKey:@"key"]];
    [self setJsResults:[params objectForKey:@"cbid"] withArgs:[self jsonResult:value]];
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
        [self setJsResults:cbid withArgs:[self jsonResult:[NSNumber numberWithLong:satoshis]]];
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
    if ([@"GLIDERA_PARTNER_TOKEN" compare:key]  == NSOrderedSame) {
        [self setJsResults:cbid withArgs:[self jsonResult:GLIDERA_API_KEY]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonResult:@""]];
    }
}

- (void)showAlert:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    [self showFadingAlert:[args objectForKey:@"message"]];
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
    NSDictionary *args = [params objectForKey:@"args"];

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:YES]];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

- (void)hideNavBar:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:NO]];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

- (void)uiExit:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    if ([self.delegate respondsToSelector:@selector(PluginViewControllerDone:)]) {
        [self.delegate PluginViewControllerDone:self];
    }
    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

- (void)navStackClear:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    _navStack = [[NSMutableArray alloc] init];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];

    _backButton.hidden = YES;
}

- (void)navStackPush:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    [_navStack addObject:[args objectForKey:@"path"]];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];

    _backButton.hidden = NO;
}

- (void)navStackPop:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    [_navStack removeLastObject];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];

    _backButton.hidden = [_navStack count] == 0;
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
    [Util animateOut:_sendConfirmationViewController parentController:self complete:^(void) {
        // hide calculator
        if (bBack) {
            [self callJsFunction:_sendCbid withArgs:[self jsonError]];
        } else if (bError) {
            [self callJsFunction:_sendCbid withArgs:[self jsonError]];
        } else {
            NSString *hex = [self getRawTransaction:_sendWallet.strUUID withTxId:txId];
            [self callJsFunction:_sendCbid withArgs:[self jsonResult:hex]];
        }
        // clean up
        _sendConfirmationViewController = nil;
        _sendCbid = nil;
    }];
}


#pragma - Fading Alert

- (void)showFadingAlert:(NSString *)message
{
    _fadingAlert = [FadingAlertView CreateInsideView:self.view withDelegate:nil];
    _fadingAlert.message = NSLocalizedString(message, nil);
    _fadingAlert.fadeDuration = 1;
    _fadingAlert.fadeDelay = 5;
    [_fadingAlert blockModal:NO];
    [_fadingAlert showFading];
}

#pragma mark - Keyboard Hack

// Snagged from https://github.com/apache/cordova-plugins

- (void)keyboardWillShow:(NSNotification *)notification
{
    [self performSelector:@selector(removeBar) withObject:nil afterDelay:0];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [self resizeFrame:YES];
}

- (void)removeBar
{
    UIWindow *keyboardWindow = nil;
    for (UIWindow *windows in [[UIApplication sharedApplication] windows]) {
        if (![[windows class] isEqual:[UIWindow class]]) {
            keyboardWindow = windows;
            break;
        }
    }
    
    for (UIView* peripheralView in [self getKeyboardViews:keyboardWindow]) {
        
        // hides the backdrop (iOS 7)
        if ([[peripheralView description] hasPrefix:@"<UIKBInputBackdropView"]) {
            // check that this backdrop is for the accessory bar (at the top),
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
    NSArray *subViews;
    
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

//
//  PluginViewController.m
//  AirBitz
//

#import "PluginViewController.h"
#import "ButtonSelectorView2.h"
#import "Config.h"
#import "User.h"
#import "FadingAlertView.h"
#import "AirbitzCore.h"
#import "SendConfirmationViewController.h"
#import "MainViewController.h"
#import "Theme.h"
#import "Util.h"
#import "Notifications.h"
#import "CommonTypes.h"
#import "ABCSpend.h"
#import "MainViewController.h"

static const NSString *PROTOCOL = @"bridge://";

@interface PluginViewController () <UIWebViewDelegate, SendConfirmationViewControllerDelegate, UINavigationControllerDelegate,UIImagePickerControllerDelegate, UIAlertViewDelegate>
{
    FadingAlertView                *_fadingAlert;
    SendConfirmationViewController *_sendConfirmationViewController;
    NSString                       *_sendCbid;
    Wallet                         *_sendWallet;
    NSMutableArray                 *_navStack;
    NSDictionary                   *_functions;
    NSString                       *_tempCbidForImagePicker;
    NSDictionary                   *_tempArgsForImagePicker;
    ABCSpend                       *_abcSpend;
    UIAlertView                    *_imagePickerAlert;
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
                     @"debugLevel":NSStringFromSelector(@selector(debugLevel:)),
                     @"bitidAddress":NSStringFromSelector(@selector(bitidAddress:)),
                     @"bitidSignature":NSStringFromSelector(@selector(bitidSignature:)),
                     @"selectedWallet":NSStringFromSelector(@selector(selectedWallet:)),
                     @"wallets":NSStringFromSelector(@selector(wallets:)),
        @"createReceiveRequest":NSStringFromSelector(@selector(createReceiveRequest:)),
                @"requestSpend":NSStringFromSelector(@selector(requestSpend:)),
                 @"requestSign":NSStringFromSelector(@selector(requestSign:)),
                 @"broadcastTx":NSStringFromSelector(@selector(broadcastTx:)),
                      @"saveTx":NSStringFromSelector(@selector(saveTx:)),
                 @"requestFile":NSStringFromSelector(@selector(launchFilePicker:)),
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
                   @"hideAlert":NSStringFromSelector(@selector(hideAlert:)),
                       @"title":NSStringFromSelector(@selector(title:)),
                  @"showNavBar":NSStringFromSelector(@selector(showNavBar:)),
                  @"hideNavBar":NSStringFromSelector(@selector(hideNavBar:)),
                        @"exit":NSStringFromSelector(@selector(uiExit:)),
               @"navStackClear":NSStringFromSelector(@selector(navStackClear:)),
                @"navStackPush":NSStringFromSelector(@selector(navStackPush:)),
                 @"navStackPop":NSStringFromSelector(@selector(navStackPop:)),
              @"launchExternal":NSStringFromSelector(@selector(launchExternal:))
    };

    [NSHTTPCookieStorage sharedHTTPCookieStorage].cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
    _webView.delegate = self;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.opaque = NO;

    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:_plugin.sourceFile ofType:_plugin.sourceExtension]];
    NSString *localFilePath = [url absoluteString];  

    if (_uri != nil) {
        localFilePath = [NSString stringWithFormat:@"%@?%@", localFilePath, _uri.query];
    }

    NSURLRequest *localRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:localFilePath]];
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

    [self notifyDenominationChange];
}

- (void)updateViews:(NSNotification *)notification
{
    [MainViewController changeNavBarOwner:self];
    if (abc.arrayWallets && abc.currentWallet)
    {
        self.buttonSelector.arrayItemsToSelect = abc.arrayWalletNames;
        [self.buttonSelector.button setTitle:abc.currentWallet.strName forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = abc.currentWalletID;

        NSString *walletName = [NSString stringWithFormat:@"%@ ▼", abc.currentWallet.strName];
        [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle:) fromObject:self];

        if (notification == nil || ![notification.name isEqualToString:@"Skip"]) {
            [self notifyWalletChanged];
        }
    }
    if (bWalletListDropped) {
        [MainViewController changeNavBar:self title:closeButtonText side:NAV_BAR_LEFT button:true enable:bWalletListDropped action:@selector(didTapTitle:) fromObject:self];
    } else {
        [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Back:) fromObject:self];
    }
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
}

#pragma mark - ButtonSelectorView2 delegates

- (void)ButtonSelector2:(ButtonSelectorView2 *)view selectedItem:(int)itemIndex
{
    NSIndexPath *indexPath = [[NSIndexPath alloc]init];
    indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [abc makeCurrentWalletWithIndex:indexPath];

    bWalletListDropped = false;
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Back:) fromObject:self];
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
        [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Back:) fromObject:self];
    }
    else
    {
        [self.buttonSelector open];
        bWalletListDropped = true;
        [MainViewController changeNavBar:self title:closeButtonText side:NAV_BAR_LEFT button:true enable:bWalletListDropped action:@selector(didTapTitle:) fromObject:self];
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
    [self updateViews:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *url = [request URL].absoluteString;
    if (![url containsString:@"debugLevel"])
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
            ABCLog(2,@"Error parsing JSON for the url %@",url);
            return NO;
        }

        NSString *functionName = [callInfo objectForKey:@"functionName"];
        if (functionName == nil) {
            ABCLog(2,@"Missing function name");
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
    ABCLog(2,@("execFunction %@"), name);

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
        ABCLog(2,@"Error creating JSON from the response  : %@", [jsonError localizedDescription]);
        return;
    }

    NSString *resp = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    ABCLog(2,@"resp = %@", resp);
    if (resp == nil) {
        ABCLog(2,@"resp is null. count = %d", (unsigned int)[args count]);
    }
    dispatch_async(dispatch_get_main_queue(), ^ {
        [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Airbitz._results[%@]=%@", cbid, resp]];
    });
}

- (void)callJsFunction:(NSString *)cbid withArgs:(NSDictionary *)args
{
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:args options:0 error:&jsonError];
    if (jsonError != nil) {
        ABCLog(2,@"Error creating JSON from the response  : %@", [jsonError localizedDescription]);
        return;
    }

    NSString *resp = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    ABCLog(2,@"resp = %@", resp);
    if (resp == nil) {
        ABCLog(2,@"resp is null. count = %d", (int)[args count]);
    }
    dispatch_async(dispatch_get_main_queue(), ^ {
        [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Airbitz._callbacks[%@]('%@');", cbid, resp]];
    });
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
    BitidSignature *bitid = [abc bitidSign:uri msg:msg];

    [self setJsResults:[params objectForKey:@"cbid"] withArgs:[self jsonResult:bitid.address]];
}

- (void)bitidSignature:(NSDictionary *)params
{
    NSDictionary *args = [params objectForKey:@"args"];
    NSString *uri = [args objectForKey:@"uri"];
    NSString *msg = [args objectForKey:@"message"];
    BitidSignature *bitid = [abc bitidSign:uri msg:msg];

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
    NSMutableDictionary *d = [self walletToDict:abc.currentWallet];
    NSDictionary *data = [self jsonResult:d];

    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&jsonError];
    if (jsonError != nil) {
        ABCLog(2,@"Error creating JSON from the response  : %@", [jsonError localizedDescription]);
        return;
    }

    NSString *resp = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    ABCLog(2,@"resp = %@", resp);
    if (resp == nil) {
        ABCLog(2,@"resp is null. count = %d", (unsigned int)[data count]);
    }
    if (_webView) {
        [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Airbitz._bridge.walletChanged('%@');", resp]];
        [self notifyDenominationChange];
    }
}

- (void)notifyDenominationChange
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [d setObject:abc.settings.denominationLabel forKey:@"value"];
    NSDictionary *data = [self jsonResult:d];

    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&jsonError];
    if (jsonError != nil) {
        ABCLog(2,@"Error creating JSON from the response  : %@", [jsonError localizedDescription]);
        return;
    }

    NSString *resp = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    ABCLog(2,@"resp = %@", resp);
    if (resp == nil) {
        ABCLog(2,@"resp is null. count = %d", (unsigned int)[data count]);
    }
    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Airbitz._bridge.denominationUpdate('%@');", resp]];
}

- (void)selectedWallet:(NSDictionary *)params
{
    NSMutableDictionary *d = [self walletToDict:abc.currentWallet];
    [self callJsFunction:[params objectForKey:@"cbid"] withArgs:[self jsonResult:d]];
}

- (void)wallets:(NSDictionary *)params
{
    // TODO: move to queue
    NSMutableArray *results = [[NSMutableArray alloc] init];
    for (Wallet *w in abc.arrayWallets) {
        NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
        [d setObject:w.strUUID forKey:@"id"];
        [d setObject:w.strName forKey:@"name"];
        [d setObject:[NSNumber numberWithInt:w.currencyNum] forKey:@"currencyNum"];
        [d setObject:[NSNumber numberWithLong:w.balance] forKey:@"balance"];
        [results addObject:d];
    }
    [self callJsFunction:[params objectForKey:@"cbid"] withArgs:[self jsonResult:results]];
}

- (void)launchSpendConfirmation:(NSDictionary *)params signOnly:(BOOL)signOnly
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    if (_sendCbid != nil || _sendConfirmationViewController != nil) {
        return;
    }
    _sendCbid = cbid;
    _sendWallet = [abc getWallet:[args objectForKey:@"id"]];

    ABCSpend *pSpend;
    ABCConditionCode ccode = 
            [abc newSpendInternal:[args objectForKey:@"toAddress"]
                                          label:[args objectForKey:@"label"]
                                       category:[args objectForKey:@"category"]
                                          notes:[args objectForKey:@"notes"]
                                  amountSatoshi:[[args objectForKey:@"amountSatoshi"] longValue]
                                    abcSpend:&pSpend];
    if (ABCConditionCodeOk == ccode)
    {
        _abcSpend = pSpend;
        if (0 < [[args objectForKey:@"bizId"] longValue]) {
            _abcSpend.bizId = [[args objectForKey:@"bizId"] longValue];
        }
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
        _sendConfirmationViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendConfirmationViewController"];
        _sendConfirmationViewController.delegate = self;
        _sendConfirmationViewController.abcSpend = _abcSpend;

        [abc makeCurrentWallet:_sendWallet];
        _abcSpend.srcWallet = abc.currentWallet;
        _sendConfirmationViewController.overrideCurrency = [[args objectForKey:@"amountFiat"] doubleValue];
        _sendConfirmationViewController.bAdvanceToTx = NO;
        _sendConfirmationViewController.bSignOnly = signOnly;
        [Util animateController:_sendConfirmationViewController parentController:self];
    }
}

- (void)requestSpend:(NSDictionary *)params
{
    [self launchSpendConfirmation:params signOnly:NO];
}

- (void)requestSign:(NSDictionary *)params
{
    [self launchSpendConfirmation:params signOnly:YES];
}

- (void)broadcastTx:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];
    
    if (_abcSpend != nil &&
        (ABCConditionCodeOk == [_abcSpend broadcastTx:[args objectForKey:@"rawTx"]])) {
        [self setJsResults:cbid withArgs:[self jsonSuccess]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)saveTx:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    if (_abcSpend != nil) {
        NSString *txid;
        [_abcSpend saveTx:[args objectForKey:@"rawTx"] txId:&txid];
        _abcSpend = nil;
        [self setJsResults:_sendCbid withArgs:[self jsonResult:txid]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)launchFilePicker:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    _tempArgsForImagePicker = args;
    _tempCbidForImagePicker = cbid;
    
    _imagePickerAlert = [[UIAlertView alloc] initWithTitle:imagePickerAlertTitle
                                                   message:nil
                                                  delegate:self
                                         cancelButtonTitle:nil
                                         otherButtonTitles:imagePickerAlertUseCamera,imagePickerAlertUsePhotos,nil];
    [_imagePickerAlert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView == _imagePickerAlert)
    {
        UIImagePickerController * imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        if (0 == buttonIndex)
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        else if (1 == buttonIndex)
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}


- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#define MAX_WIDTH_HEIGHT 1024

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    float oldWidth = image.size.width;
    float oldHeight = image.size.height;
    float newWidth;
    float newHeight;
    
    if (oldWidth > MAX_WIDTH_HEIGHT ||
        oldHeight > MAX_WIDTH_HEIGHT)
    {
        if (oldHeight > oldWidth)
        {
            newHeight = MAX_WIDTH_HEIGHT;
            newWidth = MAX_WIDTH_HEIGHT * (oldWidth / oldHeight);
        }
        else
        {
            newWidth = MAX_WIDTH_HEIGHT;
            newHeight = MAX_WIDTH_HEIGHT * (oldHeight / oldWidth);
        }
    }
    else
    {
        newWidth = oldWidth;
        newHeight = oldHeight;
    }
    
    UIImage *scaledImage = [self imageWithImage:image scaledToSize:CGSizeMake(newWidth, newHeight)];
    
    NSData *imgData = [NSData dataWithData:UIImageJPEGRepresentation(scaledImage, 0.5)];
    NSString *encodedString = [imgData base64Encoding];
    
    int SLICE_SIZE = 500;
    size_t len = [encodedString length];
    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Airbitz.bufferClear();"]];
    for (int i = 0; i < len / SLICE_SIZE; ++i) {
        size_t start = i * SLICE_SIZE;
        size_t size = start + SLICE_SIZE > len ? len - start : SLICE_SIZE;

        NSString *chunk = [encodedString substringWithRange:NSMakeRange(start, size)];
        [_webView stringByEvaluatingJavaScriptFromString:
            [NSString stringWithFormat:@"Airbitz.bufferAdd('%@');", chunk]];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
    
    // NSDictionary *results = [self jsonResult:@"useBuffer"];
    NSDictionary *results = [self jsonResult:encodedString];
    [self callJsFunction:_tempCbidForImagePicker withArgs:results];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)createReceiveRequest:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    ABCConditionCode ccode;
    NSDictionary *results = nil;

    Wallet *wallet = [abc getWallet:[args objectForKey:@"id"]];

    ABCRequest *request = [[ABCRequest alloc] init];
    request.walletUUID = wallet.strUUID;
    request.amountSatoshi = [[args objectForKey:@"amountSatoshi"] longValue];
//    details.amountCurrency = [[args objectForKey:@"amountFiat"] doubleValue];
    request.payeeName   = [args objectForKey:@"label"];
    request.category    = [args objectForKey:@"category"];
    request.notes       = [args objectForKey:@"notes"];
    
    if (0 < [[args objectForKey:@"bizId"] longValue]) {
        request.bizId = (unsigned int)[[args objectForKey:@"bizId"] longValue];
    }

    ccode = [abc createReceiveRequestWithDetails:request];
    if (ABCConditionCodeOk == ccode)
    {
        NSString *requestId = request.requestID;
        NSString *address = request.address;
        NSDictionary *d = @{@"requestId": requestId, @"address": address};
        results = [self jsonResult:d];
    }
    else
    {
        results = [self jsonError];
    }

    [self callJsFunction:cbid withArgs:results];
}

- (void)finalizeRequest:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    ABCConditionCode ccode;
    ccode = [abc finalizeRequestWithID:[args objectForKey:@"id"]
                                           requestID:[args objectForKey:@"requestId"]];
    if (ABCConditionCodeOk == ccode) {
        [self setJsResults:cbid withArgs:[self jsonSuccess]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)writeData:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];
    if (ABCConditionCodeOk == [abc pluginDataSet:_plugin.pluginId
                                                       withKey:[args objectForKey:@"key"]
                                                     withValue:[args objectForKey:@"value"]]) {
        [self setJsResults:cbid withArgs:[self jsonSuccess]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)clearData:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    if (ABCConditionCodeOk == [abc pluginDataClear:_plugin.pluginId]) {
        [self setJsResults:cbid withArgs:[self jsonSuccess]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)readData:(NSDictionary *)params
{
    NSDictionary *args = [params objectForKey:@"args"];
    NSMutableString *value = [[NSMutableString alloc] init];
    [abc pluginDataGet:_plugin.pluginId withKey:[args objectForKey:@"key"] data:value];
    [self setJsResults:[params objectForKey:@"cbid"] withArgs:[self jsonResult:value]];
}

- (void)getBtcDenomination:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    [self setJsResults:cbid withArgs:[self jsonResult:abc.settings.denominationLabel]];
}

- (void)satoshiToCurrency:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];
            
    double currency;
    ABCConditionCode ccode;
    
    ccode = [abc satoshiToCurrency:[[args objectForKey:@"satoshi"] longValue]
                                     currencyNum:[[args objectForKey:@"currencyNum"] intValue]
                                        currency:&currency];
    if (ABCConditionCodeOk == ccode) {
        [self setJsResults:cbid withArgs:[self jsonResult:[NSNumber numberWithDouble:currency]]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)currencyToSatoshi:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    int64_t satoshis;
    ABCConditionCode ccode;
    ccode = [abc currencyToSatoshi:[[args objectForKey:@"currency"] doubleValue]
                                     currencyNum:[[args objectForKey:@"currencyNum"] intValue]
                                         satoshi:&satoshis];
    if (ABCConditionCodeOk == ccode) {
        [self setJsResults:cbid withArgs:[self jsonResult:[NSNumber numberWithLongLong:satoshis]]];
    } else {
        [self setJsResults:cbid withArgs:[self jsonError]];
    }
}

- (void)formatSatoshi:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    NSString *res = [abc formatSatoshi:[[args objectForKey:@"satoshi"] longValue]];
    [self setJsResults:cbid withArgs:[self jsonResult:res]];
}

- (void)formatCurrency:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    NSString *res = [abc formatCurrency:[[args objectForKey:@"currency"] doubleValue]
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

- (void)hideAlert:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];

    [MainViewController fadingAlertDismiss];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

- (void)title:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    _titleLabel.text = [args objectForKey:@"title"];
    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

- (void)debugLevel:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];
    
    NSString *text = [args objectForKey:@"text"];
    NSString *level = [args objectForKey:@"level"];
    
    ABCLog((int) [level integerValue], @"%@", text);
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

- (void)launchExternal:(NSDictionary *)params
{
    NSString *cbid = [params objectForKey:@"cbid"];
    NSDictionary *args = [params objectForKey:@"args"];

    NSURL* url = [[NSURL alloc] initWithString:[args objectForKey:@"uri"]];
    [[UIApplication sharedApplication] openURL:url];

    [self setJsResults:cbid withArgs:[self jsonSuccess]];
}

#pragma - SendConfirmationViewControllerDelegate

- (void)sendConfirmationViewControllerDidFinish:(SendConfirmationViewController *)controller
{
    [self sendConfirmationViewControllerDidFinish:controller withBack:NO withError:YES withTxId:nil];
}

- (void)sendConfirmationViewControllerDidFinish:(SendConfirmationViewController *)controller
                                       withBack:(BOOL)bBack
                                      withError:(BOOL)bError
                                       withTxId:(NSString *)data
{
    [self updateViews:[NSNotification notificationWithName:@"Skip" object:nil]];
    [Util animateOut:_sendConfirmationViewController parentController:self complete:^(void) {
        // hide calculator
        if (bBack) {
            [self callJsFunction:_sendCbid withArgs:[self jsonResult:@{@"back": @"true"}]];
        } else if (bError) {
            [self callJsFunction:_sendCbid withArgs:[self jsonError]];
        } else {
            if (data) {
                [self callJsFunction:_sendCbid withArgs:[self jsonResult:data]];
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
    // [self performSelector:@selector(stylizeKeyboard) withObject:nil afterDelay:0];
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

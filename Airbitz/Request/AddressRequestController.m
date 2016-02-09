//
//  AddressRequestController.m
//  AirBitz
//

#import "AddressRequestController.h"
#import "CommonTypes.h"
#import "ButtonSelectorView2.h"
#import "Util.h"
#import "User.h"
#import "MainViewController.h"
#import "Theme.h"
#import "FadingAlertView.h"

#define X_SOURCE @"Airbitz"

@interface AddressRequestController () <UITextFieldDelegate,  ButtonSelector2Delegate>
{
    NSString *strName;
    NSString *strCategory;
    NSString *strNotes;
    NSNumber *maxNumberAddresses;
    BOOL      bWalletListDropped;

}

@property (nonatomic, weak) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet ButtonSelectorView2 *buttonSelector;

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
    bWalletListDropped = NO;

	self.buttonSelector.delegate = self;
    [self.buttonSelector disableButton];
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
    
    if (abcUser.arrayWallets && abcUser.currentWallet)
    {
        self.buttonSelector.arrayItemsToSelect = abcUser.arrayWalletNames;
        [self.buttonSelector.button setTitle:abcUser.currentWallet.strName forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = abcUser.currentWalletID;
        
        NSString *walletName = [NSString stringWithFormat:navbarToWalletPrefixText, abcUser.currentWallet.strName];
        [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle:) fromObject:self];
        
        if (!([abcUser.arrayWallets containsObject:abcUser.currentWallet]))
        {
            [FadingAlertView create:self.view
                            message:walletHasBeenArchivedText
                           holdTime:FADING_ALERT_HOLD_TIME_FOREVER];
        }
    }
    
    [MainViewController changeNavBar:self title:closeButtonText side:NAV_BAR_LEFT button:true enable:NO action:nil fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:NO action:nil fromObject:self];
    
//    [MainViewController changeNavBarOwner:self];
//    [MainViewController changeNavBarTitle:self title:@"Airbitz"];
//    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:false action:nil fromObject:self];
//    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
//
//    _walletSelector.arrayItemsToSelect = abcUser.arrayWalletNames;
//    [_walletSelector.button setTitle:abcUser.currentWallet.strName forState:UIControlStateNormal];
//    _walletSelector.selectedItemIndex = abcUser.currentWalletID;
}

- (void)didTapTitle: (UIButton *)sender
{
    if (bWalletListDropped)
    {
        [self.buttonSelector close];
        bWalletListDropped = false;
    }
    else
    {
        [self.buttonSelector open];
        bWalletListDropped = true;
    }
    [MainViewController changeNavBar:self title:closeButtonText side:NAV_BAR_LEFT button:true enable:bWalletListDropped action:@selector(didTapTitle:) fromObject:self];
}

- (void)validateUri
{
    if (_url) {
        NSDictionary *dict = [Util getUrlParameters:_url];
        strName = [dict objectForKey:@"x-source"] ? [dict objectForKey:@"x-source"] : @"";
        strNotes = [dict objectForKey:@"notes"] ? [dict objectForKey:@"notes"] : @"";
        strCategory = [dict objectForKey:@"category"] ? [dict objectForKey:@"category"] : @"";
        maxNumberAddresses = [dict objectForKey:@"max-number"] ? [dict objectForKey:@"max-number"] : [NSNumber numberWithInt:1];
        NSString *strSuccess = [dict objectForKey:@"x-success"] ? [dict objectForKey:@"x-success"] : @"";
        NSString *strError = [dict objectForKey:@"x-error"] ? [dict objectForKey:@"x-error"] : @"";
        NSString *strCancel = [dict objectForKey:@"x-cancel"] ? [dict objectForKey:@"x-cancel"] : @"";
        
        _successUrl = _errorUrl = _cancelUrl = nil;
        
        if ([strSuccess length])
            _successUrl = [[NSURL alloc] initWithString:[dict objectForKey:@"x-success"]];
        if ([strError length])
            _errorUrl = [[NSURL alloc] initWithString:[dict objectForKey:@"x-error"]];
        if ([strCancel length])
            _cancelUrl = [[NSURL alloc] initWithString:[dict objectForKey:@"x-cancel"]];
        
    } else {
        strName = @"";
        strCategory = @"";
        strNotes = @"";
    }
}

#pragma mark - Action Methods

- (IBAction)okay
{
    [self.view endEditing:YES];

    ABCRequest *request  = [ABCRequest alloc];
    
    if (_successUrl) {
        
        request.payeeName = strName;
        request.category = strCategory;
        request.notes = strNotes;

        [abcUser.currentWallet createReceiveRequestWithDetails:request];
        
        NSString *url = [_successUrl absoluteString];
        NSMutableString *query;
        if ([url rangeOfString:@"?"].location == NSNotFound) {
            query = [[NSMutableString alloc] initWithFormat: @"%@?address=%@", url, [Util urlencode:request.uri]];
        } else {
            query = [[NSMutableString alloc] initWithFormat: @"%@&address=%@", url, [Util urlencode:request.uri]];
        }
        [query appendFormat:@"&x-source=%@", X_SOURCE];
        if ([[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:query]]) {
            // If the URL was successfully opened, finalize the request
            [request finalizeRequest];
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
    // finish
    [self.delegate AddressRequestControllerDone:self];
}

#pragma mark - ButtonSelectorView delegates

- (void)ButtonSelector2:(ButtonSelectorView2 *)view selectedItem:(int)itemIndex
{
    NSIndexPath *indexPath = [[NSIndexPath alloc]init];
    indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [abcUser makeCurrentWalletWithIndex:indexPath];
    
    bWalletListDropped = false;
}

@end

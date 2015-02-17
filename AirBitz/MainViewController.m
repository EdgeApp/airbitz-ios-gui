//
//  MainViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "ABC.h"
#import "MainViewController.h"
#import "TabBarView.h"
#import "DirectoryViewController.h"
#import "RequestViewController.h"
#import "SendViewController.h"
#import "WalletsViewController.h"
#import "LoginViewController.h"
#import "PINReLoginViewController.h"
#import "Notifications.h"
#import "SettingsViewController.h"
#import "SendStatusViewController.h"
#import "TransactionDetailsViewController.h"
#import "TwoFactorScanViewController.h"
#import "User.h"
#import "Config.h"
#import "Util.h"
#import "CoreBridge.h"
#import "CommonTypes.h"
#import "LocalSettings.h"
#import "AudioController.h"
#import "FadingAlertView.h"
#import "InfoView.h"
#import "DL_URLServer.h"
#import "NotificationChecker.h"
#import "LocalSettings.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

typedef enum eAppMode
{
	APP_MODE_DIRECTORY = TAB_BAR_BUTTON_DIRECTORY,
	APP_MODE_REQUEST = TAB_BAR_BUTTON_APP_MODE_REQUEST,
	APP_MODE_SEND = TAB_BAR_BUTTON_APP_MODE_SEND,
	APP_MODE_WALLETS = TAB_BAR_BUTTON_APP_MODE_WALLETS,
	APP_MODE_SETTINGS = TAB_BAR_BUTTON_APP_MODE_SETTINGS
} tAppMode;

@interface MainViewController () <TabBarViewDelegate, RequestViewControllerDelegate, SettingsViewControllerDelegate,
                                  LoginViewControllerDelegate, PINReLoginViewControllerDelegate,
                                  TransactionDetailsViewControllerDelegate, UIAlertViewDelegate, FadingAlertViewDelegate,
                                  TwoFactorScanViewControllerDelegate, InfoViewDelegate,
                                  MFMailComposeViewControllerDelegate>
{
	UIViewController            *_selectedViewController;
	DirectoryViewController     *_directoryViewController;
	RequestViewController       *_requestViewController;
	SendViewController          *_sendViewController;
	WalletsViewController       *_walletsViewController;
	LoginViewController         *_loginViewController;
    PINReLoginViewController    *_PINReLoginViewController;
	SettingsViewController      *_settingsViewController;
	SendStatusViewController    *_sendStatusController;
    TransactionDetailsViewController *_txDetailsController;
    TwoFactorScanViewController      *_tfaScanViewController;
    UIAlertView                 *_receivedAlert;
    UIAlertView                 *_passwordChangeAlert;
    UIAlertView                 *_otpRequiredAlert;
    UIAlertView                 *_userReviewAlert;
    UIAlertView                 *_userReviewOKAlert;
    UIAlertView                 *_userReviewNOAlert;
    FadingAlertView             *_fadingAlert;
	CGRect                      _originalTabBarFrame;
	CGRect                      _originalViewFrame;
	tAppMode                    _appMode;
    NSURL                       *_uri;
    InfoView                    *_notificationInfoView;
    BOOL                        firstLaunch;
}

@property (nonatomic, weak) IBOutlet TabBarView *tabBar;

@property (nonatomic, copy) NSString *strWalletUUID; // used when bringing up wallet screen for a specific wallet
@property (nonatomic, copy) NSString *strTxID;       // used when bringing up wallet screen for a specific wallet

@end

@implementation MainViewController

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

    [User initAll];

    NSMutableData *seedData = [[NSMutableData alloc] init];
    [self fillSeedData:seedData];
#if !DIRECTORY_ONLY
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs_dir = [paths objectAtIndex:0];
    NSString *ca_path = [[NSBundle mainBundle] pathForResource:@"ca-certificates" ofType:@"crt"];

    tABC_Error Error;
    Error.code = ABC_CC_Ok;
    ABC_Initialize([docs_dir UTF8String],
                   [ca_path UTF8String],
                   (unsigned char *)[seedData bytes],
                   (unsigned int)[seedData length],
                   &Error);
    [Util printABC_Error:&Error];
#endif

	_originalTabBarFrame = self.tabBar.frame;
	_originalViewFrame = self.view.frame;
	// Do any additional setup after loading the view.
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_directoryViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"DirectoryViewController"];
	_loginViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
	_loginViewController.delegate = self;
	_PINReLoginViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"PINReLoginViewController"];
	_PINReLoginViewController.delegate = self;

    [self loadUserViews];

    // resgister for transaction details screen complete notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionDetailsExit:) name:NOTIFICATION_TRANSACTION_DETAILS_EXITED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchSend:) name:NOTIFICATION_LAUNCH_SEND_FOR_WALLET object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchRequest:) name:NOTIFICATION_LAUNCH_REQUEST_FOR_WALLET object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchRecoveryQuestions:) name:NOTIFICATION_LAUNCH_RECOVERY_QUESTIONS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBitcoinUri:) name:NOTIFICATION_HANDLE_BITCOIN_URI object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loggedOffRedirect:) name:NOTIFICATION_MAIN_RESET object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyRemotePasswordChange:) name:NOTIFICATION_REMOTE_PASSWORD_CHANGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyOtpRequired:) name:NOTIFICATION_OTP_REQUIRED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchReceiving:) name:NOTIFICATION_TX_RECEIVED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchViewSweep:) name:NOTIFICATION_VIEW_SWEEP_TX object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayNextNotification) name:NOTIFICATION_NOTIFICATION_RECEIVED object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lockTabbar) name:NOTIFICATION_LOCK_TABBAR object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unlockTabbar) name:NOTIFICATION_UNLOCK_TABBAR object:nil];

    // init and set API key
    [DL_URLServer initAll];
    NSString *token = [NSString stringWithFormat:@"Token %@", AUTH_TOKEN];
    [[DL_URLServer controller] setHeaderRequestValue:token forKey: @"Authorization"];
    [[DL_URLServer controller] setHeaderRequestValue:[LocalSettings controller].clientID forKey:@"X-Client-ID"];
    [[DL_URLServer controller] verbose: SERVER_MESSAGES_TO_SHOW];
    
    [NotificationChecker initAll];
}

/**
 * These views need to be cleaned out after a login
 */
- (void)loadUserViews
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_requestViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"RequestViewController"];
	_requestViewController.delegate = self;
	_sendViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendViewController"];
	_walletsViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"WalletsViewController"];
	_settingsViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
	_settingsViewController.delegate = self;

    _otpRequiredAlert = nil;
    firstLaunch = YES;
}


- (void)viewWillAppear:(BOOL)animated
{
	self.tabBar.delegate = self;

	//originalTabBarPosition = self.tabBar.frame.origin;
#if DIRECTORY_ONLY
	[self hideTabBarAnimated:NO];
#else
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHideTabBar:) name:NOTIFICATION_SHOW_TAB_BAR object:nil];
#endif
    // Setup Business Directory
    [self.tabBar selectButtonAtIndex:APP_MODE_DIRECTORY];

    // Switch to Wallets Business Directory
    [self.tabBar selectButtonAtIndex:APP_MODE_WALLETS];
    // Start on the Wallets tab
    _appMode = APP_MODE_WALLETS;
    [self launchViewControllerBasedOnAppMode];
    firstLaunch = NO;
}

- (void)dealloc
{
    //remove all notifications associated with self
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Misc Methods


- (void)fillSeedData:(NSMutableData *)data
{
    NSMutableString *strSeed = [[NSMutableString alloc] init];

    // add the advertiser identifier
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)])
    {
        [strSeed appendString:[[[UIDevice currentDevice] identifierForVendor] UUIDString]];
    }

    // add the UUID
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    [strSeed appendString:[[NSString alloc] initWithString:(__bridge NSString *)string]];
    CFRelease(string);

    // add the device name
    [strSeed appendString:[[UIDevice currentDevice] name]];

    // add the string to the data
    [data appendData:[strSeed dataUsingEncoding:NSUTF8StringEncoding]];

    double time = CACurrentMediaTime();

    [data appendBytes:&time length:sizeof(double)];

    u_int32_t rand = arc4random();

    [data appendBytes:&rand length:sizeof(u_int32_t)];
}

-(void)showFastestLogin
{
    if (firstLaunch) {
        bool exists = [CoreBridge PINLoginExists];
        if (exists) {
            [self showPINLogin:NO];
        } else {
            [self showLogin:NO];
        }
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
            bool exists = [CoreBridge PINLoginExists];
            dispatch_async(dispatch_get_main_queue(), ^ {
                if (exists) {
                    [self showPINLogin:YES];
                } else {
                    [self showLogin:YES];
                }
            });
        });
    }
}

-(void)showLogin:(BOOL)animated
{
    _loginViewController.view.frame = self.view.bounds;
    [self.view insertSubview:_loginViewController.view belowSubview:self.tabBar];
    [self hideTabBarAnimated:animated];
    if (animated) {
        _loginViewController.view.alpha = 0.0;
        [UIView animateWithDuration:0.25
                            delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                        animations:^
        {
            _loginViewController.view.alpha = 1.0;
        }
                        completion:^(BOOL finished)
        {
        }];
    }
}

-(void)showPINLogin:(BOOL)animated
{
    _PINReLoginViewController.view.frame = self.view.bounds;
    [self.view insertSubview:_PINReLoginViewController.view belowSubview:self.tabBar];
    [self hideTabBarAnimated:animated];
    if (animated) {
        _PINReLoginViewController.view.alpha = 0.0;
        [UIView animateWithDuration:0.25
                            delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                        animations:^
        {
            _PINReLoginViewController.view.alpha = 1.0;
        }
                        completion:^(BOOL finished)
        {
        }];
    }
}

-(void)updateChildViewSizeForTabBar
{
	if([_selectedViewController respondsToSelector:@selector(viewBottom:)])
	{
		[(id)_selectedViewController viewBottom:self.tabBar.frame.origin.y + 5.0];	/* 5.0 covers transparent area at top of tab bar */
	}
}

-(void)showHideTabBar:(NSNotification *)notification
{
	BOOL showTabBar = ((NSNumber *)notification.object).boolValue;
	if(showTabBar)
	{
		[self showTabBarAnimated:YES];
	}
	else
	{
		[self hideTabBarAnimated:YES];
	}
}

-(void)hideTabBarAnimated:(BOOL)animated
{
	if(animated)
	{
		[UIView animateWithDuration:0.25
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState
						 animations:^
		 {
			 CGRect frame = self.tabBar.frame;
			 frame.origin.y = _originalTabBarFrame.origin.y + frame.size.height;
			 self.tabBar.frame = frame;
			 
			 _selectedViewController.view.frame = self.view.bounds;
		 }
		completion:^(BOOL finished)
		 {
			//NSLog(@"view: %f, %f, tab bar origin: %f", self.view.frame.origin.y, self.view.frame.size.height, self.tabBar.frame.origin.y);
		 }];
	}
	else
	{
		CGRect frame = self.tabBar.frame;
		frame.origin.y = _originalTabBarFrame.origin.y + frame.size.height;
		self.tabBar.frame = frame;
		
		_selectedViewController.view.frame = self.view.bounds;
	}
}

-(void)launchViewControllerBasedOnAppMode
{
	switch(_appMode)
	{
		case APP_MODE_DIRECTORY:
		{
			if (_selectedViewController != _directoryViewController)
			{
				[_selectedViewController.view removeFromSuperview];
				_selectedViewController = _directoryViewController;
				[self.view insertSubview:_selectedViewController.view belowSubview:self.tabBar];
			}
			break;
		}
		case APP_MODE_REQUEST:
		{
			if (_selectedViewController != _requestViewController)
			{
				if([User isLoggedIn] || (DIRECTORY_ONLY == 1))
				{
                    _requestViewController.walletUUID = self.strWalletUUID;
					[_selectedViewController.view removeFromSuperview];
					_selectedViewController = _requestViewController;
					[self.view insertSubview:_selectedViewController.view belowSubview:self.tabBar];
				}
				else
				{
                    [self showFastestLogin];
				}
			}
			break;
		}
		case APP_MODE_SEND:
		{
			if (_selectedViewController != _sendViewController)
			{
				if([User isLoggedIn] || (DIRECTORY_ONLY == 1))
				{
					tABC_CC result;
					tABC_WalletInfo **walletInfo;
					unsigned int numWallets = 0;
					tABC_Error error;
					
					result = ABC_GetWallets([[User Singleton].name UTF8String],
										   [[User Singleton].password UTF8String],
										   &walletInfo,
										   &numWallets,
										   &error);
					
					if(1) //numWallets)
					{
                        _sendViewController.walletUUID = self.strWalletUUID;
						[_selectedViewController.view removeFromSuperview];
						_selectedViewController = _sendViewController;
						[self.view insertSubview:_selectedViewController.view belowSubview:self.tabBar];
					}
					else
					{
						[Util printABC_Error:&error];
						UIAlertView *alert = [[UIAlertView alloc]
											  initWithTitle:NSLocalizedString(@"No Wallets", @"Alert title that warns user they have no wallets to send from")
											  message:NSLocalizedString(@"You have no wallets from which to send funds.  First create a wallet by tapping on the Wallets tab and hitting the '+' button", nil)
											  delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
						[alert show];
					}
					
				}
				else
				{
                    [self showFastestLogin];
				}
			}
			break;
		}
		case APP_MODE_WALLETS:
		{
			if (_selectedViewController != _walletsViewController)
			{
				if ([User isLoggedIn] || (DIRECTORY_ONLY == 1))
				{
					[_selectedViewController.view removeFromSuperview];
					_selectedViewController = _walletsViewController;
					[self.view insertSubview:_selectedViewController.view belowSubview:self.tabBar];
                    [_walletsViewController selectWalletWithUUID:_strWalletUUID];
				}
				else
				{
                    [self showFastestLogin];
				}
			}
			break;
		}
		case APP_MODE_SETTINGS:
			if (_selectedViewController != _settingsViewController)
			{
				if ([User isLoggedIn] || (DIRECTORY_ONLY == 1))
				{
					[_selectedViewController.view removeFromSuperview];
					_selectedViewController = _settingsViewController;
					[self.view insertSubview:_selectedViewController.view belowSubview:self.tabBar];
				}
				else
				{
                    [self showFastestLogin];
				}
			}
			break;
	}
}

-(void)showTabBarAnimated:(BOOL)animated
{
	if(animated)
	{
		[UIView animateWithDuration:0.25
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
						 animations:^
		 {
			 self.tabBar.frame = _originalTabBarFrame;
			 CGRect frame = self.view.bounds;
			 frame.size.height -= (_originalTabBarFrame.size.height - 5.0);
			 _selectedViewController.view.frame = frame;
		 }
		 completion:^(BOOL finished)
		 {
			// NSLog(@"view: %f, %f, tab bar origin: %f", self.view.frame.origin.y, self.view.frame.size.height, self.tabBar.frame.origin.y);

		 }];
	}
	else
	{
		self.tabBar.frame = _originalTabBarFrame;
		
		CGRect frame = self.view.bounds;
		frame.size.height -= (_originalTabBarFrame.size.height - 5.0);
		_selectedViewController.view.frame = frame;
	}
}

- (void)displayNextNotification
{
    if (!_notificationInfoView && [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        NSDictionary *notif = [NotificationChecker firstNotification];
        if (notif)
        {
            // Hide the keyboard if a notification is shown
            [self.view endEditing:NO];
            NSString *notifHTML = [NSString stringWithFormat:@"<!DOCTYPE html>\
            <html>\
                <body>\
                    <div><strong><center>%@</center></strong><BR />\
                    %@\
                    </div>\
                </body>\
            </html>",
                                   [notif objectForKey:@"title"],
                                   [notif objectForKey:@"message"]];
            _notificationInfoView = [InfoView CreateWithDelegate:self];
            [_notificationInfoView enableScrolling:YES];
            CGRect frame = self.view.bounds;
            frame.size.height = frame.size.height - self.tabBar.frame.size.height;
            [_notificationInfoView setFrame:frame];
            [_notificationInfoView setHtmlInfoToDisplay:notifHTML];
            [self.view addSubview:_notificationInfoView];
        }
    }
}

- (void)lockTabbar
{
    [_tabBar lockButton:TAB_BAR_BUTTON_APP_MODE_SEND];
    [_tabBar lockButton:TAB_BAR_BUTTON_APP_MODE_REQUEST];
}

- (void)unlockTabbar
{
    [_tabBar unlockButton:TAB_BAR_BUTTON_APP_MODE_SEND];
    [_tabBar unlockButton:TAB_BAR_BUTTON_APP_MODE_REQUEST];
}

#pragma mark - TabBarView delegates

-(void)tabVarView:(TabBarView *)view selectedSubview:(UIView *)subview reselected:(BOOL)bReselected
{
    tTabBarButton tabBarButton = (tTabBarButton) (subview.tag);
	_appMode = (tAppMode)(subview.tag);

    if (bReselected)
    {
        NSDictionary *dictNotification = @{ KEY_TAB_BAR_BUTTON_RESELECT_ID : [NSNumber numberWithInt:tabBarButton] };
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:self userInfo:dictNotification];
    }
    else
    {
        [self launchViewControllerBasedOnAppMode]; //will show login if necessary
        [self updateChildViewSizeForTabBar];

        // reset any data designed to drive the selection
        _strWalletUUID = nil;
        _strTxID = nil;
    }
}

#pragma mark - RequestViewControllerDelegates

-(void)RequestViewControllerDone:(RequestViewController *)vc
{
	//cw this method currently not used
	
	//pop back to directory
	//[self.tabBar selectButtonAtIndex:0];
}

#pragma mark - SettingsViewControllerDelegates

-(void)SettingsViewControllerDone:(SettingsViewController *)controller
{
    [self loadUserViews];

	_appMode = APP_MODE_DIRECTORY;
	[self.tabBar selectButtonAtIndex:APP_MODE_DIRECTORY];
}

#pragma mark - LoginViewControllerDelegates

- (void)loginViewControllerDidAbort
{
	_appMode = APP_MODE_DIRECTORY;
	[self.tabBar selectButtonAtIndex:APP_MODE_DIRECTORY];
	[self showTabBarAnimated:YES];
	[_loginViewController.view removeFromSuperview];
}

- (void)loginViewControllerDidLogin:(BOOL)bNewAccount
{
    NSMutableArray *wallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWalletUUIDs:wallets];
    if (bNewAccount || [wallets count] == 0) {
        _fadingAlert = [FadingAlertView CreateInsideView:self.view withDelegate:self];
        _fadingAlert.message = NSLocalizedString(@"Creating and securing wallet", nil);
        _fadingAlert.fadeDuration = 2;
        _fadingAlert.fadeDelay = 0;
        [_fadingAlert blockModal:YES];
        [_fadingAlert showSpinner:YES];
        [_fadingAlert show];
        [CoreBridge setupNewAccount:_fadingAlert];
    }

    // After login, reset all the main views
    [self loadUserViews];

    _appMode = APP_MODE_WALLETS;
    [self.tabBar selectButtonAtIndex:_appMode];
	[_loginViewController.view removeFromSuperview];
	[self showTabBarAnimated:YES];
	[self launchViewControllerBasedOnAppMode];

    if (_uri)
    {
        [self processBitcoinURI:_uri];
        _uri = nil;
    }
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        if([User offerUserReview]) {
            _userReviewAlert = [[UIAlertView alloc]
                                    initWithTitle:NSLocalizedString(@"Airbitz", nil)
                                    message:NSLocalizedString(@"How are you liking Airbitz?", nil)
                                    delegate:self
                                    cancelButtonTitle:NSLocalizedString(@"Not so good", nil)
                                    otherButtonTitles:NSLocalizedString(@"It's great", nil), nil];
            [_userReviewAlert show];
        }
    });
}

- (void)fadingAlertDismissed:(FadingAlertView *)view
{
    _fadingAlert = nil;
}


- (void)launchReceiving:(NSNotification *)notification
{
    NSDictionary *data = [notification userInfo];
    _strWalletUUID = [data objectForKey:KEY_TX_DETAILS_EXITED_WALLET_UUID];
    _strTxID = [data objectForKey:KEY_TX_DETAILS_EXITED_TX_ID];

    Transaction *transaction = [CoreBridge getTransaction:_strWalletUUID withTx:_strTxID];

    /* If showing QR code, launch receiving screen*/
    if (_selectedViewController == _requestViewController 
            && [_requestViewController showingQRCode:_strWalletUUID withTx:_strTxID])
    {
        if ([_requestViewController transactionWasDonation])
        {
            // launch the next QR view with the donation amount
            [_requestViewController LaunchQRCodeScreen:transaction.amountSatoshi withRequestState:kDonation];
            return;
        }

        SInt64 txDiff = [_requestViewController transactionDifference:_strWalletUUID withTx:_strTxID];
        if (txDiff >= 0)
        {
            // Sender paid exact amount or too much
            [self handleReceiveFromQR:_strWalletUUID withTx:_strTxID];
            [[AudioController controller] playReceived];
        }
        else if (txDiff < 0)
        {
            // Sender didn't pay enough
            txDiff = fabs(txDiff);
            [_requestViewController LaunchQRCodeScreen:txDiff withRequestState:kPartial];
            [[AudioController controller] playPartialReceived];
        }
    }
    // Prevent displaying multiple alerts
    else if (_receivedAlert == nil)
    {
        NSString *title = NSLocalizedString(@"Received Funds", nil);
        NSString *msg = NSLocalizedString(@"Bitcoin received. Tap for details.", nil);
        if (transaction && transaction.amountSatoshi < 0) {
            title = NSLocalizedString(@"Sent Funds", nil);
            msg = NSLocalizedString(@"Bitcoin sent. Tap for details.", nil);
        }
        [[AudioController controller] playReceived];
        _receivedAlert = [[UIAlertView alloc]
                                initWithTitle:title
                                message:msg
                                delegate:self
                                cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        [_receivedAlert show];
        // Wait 5 seconds and dimiss
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            if (_receivedAlert)
            {
                [_receivedAlert dismissWithClickedButtonIndex:0 animated:YES];
            }
        });
    }
}

- (void)handleReceiveFromQR:(NSString *)walletUUID withTx:(NSString *)txId
{
    NSString *message;
    
    NSInteger receiveCount = LocalSettings.controller.receiveBitcoinCount + 1; //TODO find RECEIVES_COUNT
    [LocalSettings controller].receiveBitcoinCount = receiveCount;
    [LocalSettings saveAll];
    
    NSString *coin;
    NSString *fiat;
    
    tABC_Error error;
    Wallet *wallet = [CoreBridge getWallet:walletUUID];
    Transaction *transaction = [CoreBridge getTransaction:walletUUID withTx:txId];
    
    double currency;
    int64_t satoshi = transaction.amountSatoshi;
    if (ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                              satoshi, &currency, wallet.currencyNum, &error) == ABC_CC_Ok)
        fiat = [CoreBridge formatCurrency:currency withCurrencyNum:wallet.currencyNum withSymbol:true];
    
    currency = fabs(transaction.amountFiat);
    if (ABC_CurrencyToSatoshi([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                  currency, wallet.currencyNum, &satoshi, &error) == ABC_CC_Ok)
        coin = [CoreBridge formatSatoshi:satoshi withSymbol:false cropDecimals:[CoreBridge currencyDecimalPlaces]];
    
    if([LocalSettings controller].bMerchantMode == YES || receiveCount > 2)
    {
        message = [NSString stringWithFormat:@"You Received Bitcoin!\n%@ (~%@)", coin, fiat];
        [self launchTransactionDetails:_strWalletUUID withTx:_strTxID];
    }
    else
    {
        message = [NSString stringWithFormat:@"You received Bitcoin!\n%@ (~%@)\nUse the Payee, Category, and Notes field to optionally tag your transaction", coin, fiat];
        [_requestViewController resetViews];
        [self showTabBarAnimated:NO];
    }

    _fadingAlert = [FadingAlertView CreateInsideView:self.view withDelegate:self];
    _fadingAlert.message = message;
    _fadingAlert.fadeDuration = 2;
    _fadingAlert.fadeDelay = 5;
    [_fadingAlert blockModal:NO];
    [_fadingAlert showSpinner:NO];
    [_fadingAlert showFading];
}

- (void)launchViewSweep:(NSNotification *)notification
{
    NSDictionary *data = [notification userInfo];
    _strWalletUUID = [data objectForKey:KEY_TX_DETAILS_EXITED_WALLET_UUID];
    _strTxID = [data objectForKey:KEY_TX_DETAILS_EXITED_TX_ID];
    [self launchTransactionDetails:_strWalletUUID withTx:_strTxID];
}

- (void)launchTransactionDetails:(NSString *)walletUUID withTx:(NSString *)txId
{
    Wallet *wallet = [CoreBridge getWallet:walletUUID];
    Transaction *transaction = [CoreBridge getTransaction:walletUUID withTx:txId];

    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    _txDetailsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionDetailsViewController"];
    _txDetailsController.wallet = wallet;
    _txDetailsController.transaction = transaction;
    _txDetailsController.delegate = self;
    _txDetailsController.bOldTransaction = NO;
    _txDetailsController.transactionDetailsMode = TD_MODE_RECEIVED;

    CGRect frame = self.view.bounds;
    frame.origin.x = frame.size.width;
    _txDetailsController.view.frame = frame;
    [self.view insertSubview:_txDetailsController.view belowSubview:self.tabBar];
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
    {
        _txDetailsController.view.frame = self.view.bounds;
    }
    completion:^(BOOL finished)
    {
        [self showTabBarAnimated:YES];
    }];
}

-(void)TransactionDetailsViewControllerDone:(TransactionDetailsViewController *)controller
{
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
    {
        CGRect frame = self.view.bounds;
        frame.origin.x = frame.size.width;
        _txDetailsController.view.frame = frame;
    }
    completion:^(BOOL finished)
    {
        [_txDetailsController.view removeFromSuperview];
        _txDetailsController = nil;
    }];
}

#pragma mark - PINReLoginViewControllerDelegates

- (void)PINReLoginViewControllerDidSwitchUserWithMessage:(NSString *)message
{
    [self PINReLoginViewControllerDidAbort];
    [self showLogin:YES];
    if (message)
    {
        _fadingAlert = [FadingAlertView CreateInsideView:self.view withDelegate:self];
        _fadingAlert.message = message;
        _fadingAlert.fadeDuration = 2;
        _fadingAlert.fadeDelay = 0;
        [_fadingAlert showFading];
    }
}

- (void)PINReLoginViewControllerDidAbort
{
	_appMode = APP_MODE_DIRECTORY;
	[self.tabBar selectButtonAtIndex:APP_MODE_DIRECTORY];
	[self showTabBarAnimated:YES];
	[_PINReLoginViewController.view removeFromSuperview];
}

- (void)PINReLoginViewControllerDidLogin
{
    // After login, reset all the main views
    [self loadUserViews];
    
	[_PINReLoginViewController.view removeFromSuperview];
	[self showTabBarAnimated:YES];
	[self launchViewControllerBasedOnAppMode];
    
    if (_uri)
    {
        [self processBitcoinURI:_uri];
        _uri = nil;
    }
}

#pragma mark - ABC Alert delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (_receivedAlert == alertView && buttonIndex == 1)
	{
        [self launchTransactionDetails:_strWalletUUID withTx:_strTxID];
        _receivedAlert = nil;
	}
    else if (_passwordChangeAlert == alertView)
    {
        _passwordChangeAlert = nil;
    }
    else if (_otpRequiredAlert == alertView && buttonIndex == 1)
    {
        [self launchTwoFactorScan];
    }
    else if (_userReviewAlert == alertView)
    {
        if(buttonIndex == 0) // No, send an email to support
        {
            _userReviewNOAlert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Airbitz", nil)
                                  message:NSLocalizedString(@"Would you like to send us some feedback?", nil)
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"No thanks", nil)
                                  otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
            [_userReviewNOAlert show];
        }
        else if (buttonIndex == 1) // Yes, launch userReviewOKAlert
        {
            _userReviewOKAlert = [[UIAlertView alloc]
                                initWithTitle:NSLocalizedString(@"Airbitz", nil)
                                message:NSLocalizedString(@"Would you like to write a review in the App store?", nil)
                                delegate:self
                                cancelButtonTitle:NSLocalizedString(@"No thanks", nil)
                                otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
            [_userReviewOKAlert show];
        }
    }
    else if (_userReviewNOAlert == alertView)
    {
        if(buttonIndex == 1)
        {
            [self sendSupportEmail];
        }
    }
    else if (_userReviewOKAlert == alertView)
    {
        if(buttonIndex == 1)
        {
            NSString *iTunesLink = @"https://itunes.apple.com/us/app/bitcoin-wallet-map-directory/id843536046?mt=8";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
        }
    }
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
    if (_receivedAlert == alertView)
    {
        _strWalletUUID = @"";
        _strTxID = @"";
        _receivedAlert = nil;
    }
}

- (void)sendSupportEmail
{
    // if mail is available
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
        [mailComposer setToRecipients:[NSArray arrayWithObjects:@"support@airbitz.co", nil]];
        NSString *subject = [NSString stringWithFormat:@"Airbitz Feedback"];
        [mailComposer setSubject:NSLocalizedString(subject, nil)];
        mailComposer.mailComposeDelegate = self;
        [self presentViewController:mailComposer animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Can't send e-mail"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Mail Compose Delegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    NSString *strTitle = NSLocalizedString(@"AirBitz", nil);
    NSString *strMsg = nil;
    
    switch (result)
    {
        case MFMailComposeResultCancelled:
            strMsg = NSLocalizedString(@"Email cancelled", nil);
            break;
            
        case MFMailComposeResultSaved:
            strMsg = NSLocalizedString(@"Email saved to send later", nil);
            break;
            
        case MFMailComposeResultSent:
            strMsg = NSLocalizedString(@"Email sent", nil);
            break;
            
        case MFMailComposeResultFailed:
        {
            strTitle = NSLocalizedString(@"Error sending Email", nil);
            strMsg = [error localizedDescription];
            break;
        }
        default:
            break;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle
                                                    message:strMsg
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
    
    [[controller presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Custom Notification Handlers

- (void)notifyRemotePasswordChange:(NSArray *)params
{
    if (_passwordChangeAlert == nil && [User isLoggedIn])
    {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [[User Singleton] clear];
        [self resetViews:nil];
        _passwordChangeAlert = [[UIAlertView alloc]
                                initWithTitle:NSLocalizedString(@"Password Change", nil)
                                message:NSLocalizedString(@"The password to this account was changed by another device. Please login using the new credentials.", nil)
                                delegate:self
                    cancelButtonTitle:nil
                    otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        [_passwordChangeAlert show];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
}

- (void)notifyOtpRequired:(NSArray *)params
{
    if (_otpRequiredAlert == nil) {
        _otpRequiredAlert = [[UIAlertView alloc]
                                initWithTitle:NSLocalizedString(@"Two Factor Authentication On", nil)
                                message:NSLocalizedString(@"Two Factor Authentication (enchanced security) has been enabled from a different device for this account. Please enable 2 Factor Authentication for full access from this device.", nil)
                                delegate:self
                                cancelButtonTitle:NSLocalizedString(@"Remind Me Later", nil)
                                otherButtonTitles:NSLocalizedString(@"Enable", nil), nil];
        [_otpRequiredAlert show];
    }
}

// called when the stats have been updated
- (void)transactionDetailsExit:(NSNotification *)notification
{
    // if the wallet tab is not already open, bring it up with this wallet
    if (APP_MODE_WALLETS != _appMode)
    {
        NSDictionary *dictData = [notification userInfo];
        _strWalletUUID = [dictData objectForKey:KEY_TX_DETAILS_EXITED_WALLET_UUID];
        [_walletsViewController resetViews];
        [self.tabBar selectButtonAtIndex:APP_MODE_WALLETS];
    }
}

- (void)launchSend:(NSNotification *)notification
{
    if (APP_MODE_SEND != _appMode)
    {
        NSDictionary *dictData = [notification userInfo];
        _strWalletUUID = [dictData objectForKey:KEY_TX_DETAILS_EXITED_WALLET_UUID];
        [_sendViewController resetViews];
        [self.tabBar selectButtonAtIndex:APP_MODE_SEND];
    }
}

- (void)launchRequest:(NSNotification *)notification
{
    if (APP_MODE_REQUEST != _appMode)
    {
        NSDictionary *dictData = [notification userInfo];
        _strWalletUUID = [dictData objectForKey:KEY_TX_DETAILS_EXITED_WALLET_UUID];
        [_requestViewController resetViews];
        [self.tabBar selectButtonAtIndex:APP_MODE_REQUEST];
    }
}

- (void)launchRecoveryQuestions:(NSNotification *)notification
{
    if (APP_MODE_SETTINGS != _appMode) {
        [self.tabBar selectButtonAtIndex:APP_MODE_SETTINGS];
    }
    [_settingsViewController bringUpRecoveryQuestionsView];
}

- (void)launchTwoFactorScan
{
    _tfaScanViewController = (TwoFactorScanViewController *)[Util animateIn:@"TwoFactorScanViewController" parentController:self];
    _tfaScanViewController.delegate = self;
    _tfaScanViewController.bStoreSecret = YES;
    _tfaScanViewController.bTestSecret = YES;
}

- (void)twoFactorScanViewControllerDone:(TwoFactorScanViewController *)controller withBackButton:(BOOL)bBack
{
    BOOL success = controller.bSuccess;
    [Util animateOut:controller parentController:self complete:^(void) {
        _tfaScanViewController = nil;
    }];
}

- (void)handleBitcoinUri:(NSNotification *)notification
{
    NSDictionary *dictData = [notification userInfo];
    NSURL *uri = [dictData objectForKey:KEY_URL];
    [self processBitcoinURI:uri];
}

- (void)processBitcoinURI:(NSURL *)uri
{
    if ([User isLoggedIn]) {
        [_sendViewController resetViews];
        
        _sendViewController.pickerTextSendTo.textField.text = [uri absoluteString];
        [_sendViewController processURI];
    }
    else {
        _uri = uri;
    }
    
    [self.tabBar selectButtonAtIndex:APP_MODE_SEND];
}

- (void)loggedOffRedirect:(NSNotification *)notification
{
    [self.tabBar selectButtonAtIndex:APP_MODE_DIRECTORY];
    [self.tabBar selectButtonAtIndex:APP_MODE_WALLETS];
    _appMode = APP_MODE_WALLETS;
    [self resetViews:notification];
    [self showTabBarAnimated:NO];
}

- (void)resetViews:(NSNotification *)notification
{
    // Hide the keyboard
    [self.view endEditing:NO];

    // Force the tabs to redraw the selected view
    _selectedViewController = nil;
    [self launchViewControllerBasedOnAppMode];
}

#pragma mark infoView Delegates

- (void)InfoViewFinished:(InfoView *)infoView
{
    [_notificationInfoView removeFromSuperview];
    _notificationInfoView = nil;
    [self displayNextNotification];
}

@end

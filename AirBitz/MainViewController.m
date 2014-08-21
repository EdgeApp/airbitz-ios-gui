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
#import "Notifications.h"
#import "SettingsViewController.h"
#import "SendStatusViewController.h"
#import "TransactionDetailsViewController.h"
#import "User.h"
#import "Config.h"
#import "Util.h"
#import "CoreBridge.h"
#import "CommonTypes.h"

typedef enum eAppMode
{
	APP_MODE_DIRECTORY = TAB_BAR_BUTTON_DIRECTORY,
	APP_MODE_REQUEST = TAB_BAR_BUTTON_APP_MODE_REQUEST,
	APP_MODE_SEND = TAB_BAR_BUTTON_APP_MODE_SEND,
	APP_MODE_WALLETS = TAB_BAR_BUTTON_APP_MODE_WALLETS,
	APP_MODE_SETTINGS = TAB_BAR_BUTTON_APP_MODE_SETTINGS
} tAppMode;

@interface MainViewController () <TabBarViewDelegate, RequestViewControllerDelegate, SettingsViewControllerDelegate,
                                  LoginViewControllerDelegate, TransactionDetailsViewControllerDelegate,
                                  UIAlertViewDelegate>
{
	UIViewController            *_selectedViewController;
	DirectoryViewController     *_directoryViewController;
	RequestViewController       *_requestViewController;
	SendViewController          *_sendViewController;
	WalletsViewController       *_walletsViewController;
	LoginViewController         *_loginViewController;
	SettingsViewController      *_settingsViewController;
	SendStatusViewController    *_sendStatusController;
    TransactionDetailsViewController *_txDetailsController;
    UIAlertView                 *_receivedAlert;
    UIAlertView                 *_passwordChangeAlert;
	CGRect                      _originalTabBarFrame;
	CGRect                      _originalViewFrame;
	tAppMode                    _appMode;
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

    [self loadUserViews];

    // resgister for transaction details screen complete notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionDetailsExit:) name:NOTIFICATION_TRANSACTION_DETAILS_EXITED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchSend:) name:NOTIFICATION_LAUNCH_SEND_FOR_WALLET object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchRequest:) name:NOTIFICATION_LAUNCH_REQUEST_FOR_WALLET object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBitcoinUri:) name:NOTIFICATION_HANDLE_BITCOIN_URI object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loggedOffRedirect:) name:NOTIFICATION_MAIN_RESET object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyRemotePasswordChange:) name:NOTIFICATION_REMOTE_PASSWORD_CHANGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchReceiving:) name:NOTIFICATION_TX_RECEIVED object:nil];
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
	[self.tabBar selectButtonAtIndex:0];
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
    //NSLog(@"seed string: %@", strSeed);
    [data appendData:[strSeed dataUsingEncoding:NSUTF8StringEncoding]];

    double time = CACurrentMediaTime();

    [data appendBytes:&time length:sizeof(double)];

    u_int32_t rand = arc4random();

    [data appendBytes:&rand length:sizeof(u_int32_t)];
}

-(void)showLogin
{
	_loginViewController.view.frame = self.view.bounds;
	[self.view insertSubview:_loginViewController.view belowSubview:self.tabBar];
	_loginViewController.view.alpha = 0.0;
	[self hideTabBarAnimated:YES];
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
					[self showLogin];
				}
			}
			break;
		}
			break;
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
					[self showLogin];
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
					[self showLogin];
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
					[self showLogin];
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

#pragma mark - TabBarView delegates

-(void)tabVarView:(TabBarView *)view selectedSubview:(UIView *)subview reselected:(BOOL)bReselected
{
	//NSLog(@"Selecting view %i", (int) subview.tag);
    tTabBarButton tabBarButton = (tTabBarButton) (subview.tag);
	_appMode = (tAppMode)(subview.tag);

    if (bReselected)
    {
        NSDictionary *dictNotification = @{ KEY_TAB_BAR_BUTTON_RESELECT_ID : [NSNumber numberWithInt:tabBarButton] };
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:self userInfo:dictNotification];
        //NSLog(@"\n❎❎❎❎❎❎❎❎❎❎❎❎❎❎❎❎\Tab Bar Button tapped while already selected\n❎❎❎❎❎❎❎❎❎❎❎❎❎❎❎❎");
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

- (void)loginViewControllerDidLogin
{
    // After login, reset all the main views
    [self loadUserViews];

	[_loginViewController.view removeFromSuperview];
	[self showTabBarAnimated:YES];
	[self launchViewControllerBasedOnAppMode];
}

- (void)launchReceiving:(NSNotification *)notification
{
    NSDictionary *data = [notification userInfo];
    _strWalletUUID = [data objectForKey:KEY_TX_DETAILS_EXITED_WALLET_UUID];
    _strTxID = [data objectForKey:KEY_TX_DETAILS_EXITED_TX_ID];

    /* If showing QR code, launch receiving screen*/
    if (_selectedViewController == _requestViewController 
            && [_requestViewController showingQRCode:_strWalletUUID withTx:_strTxID])
    {
        [self launchSendStatus:_strWalletUUID withTx:_strTxID];
    }
    else
    {
        _receivedAlert = [[UIAlertView alloc]
                                initWithTitle:NSLocalizedString(@"Received Funds", nil)
                                message:NSLocalizedString(@"Bitcoin received. Tap for details.", nil)
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

- (void)launchSendStatus:(NSString *)walletUUID withTx:(NSString *)txId
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    _sendStatusController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendStatusViewController"];

    CGRect frame = self.view.bounds;
    _sendStatusController.view.frame = frame;
    [self.view insertSubview:_sendStatusController.view belowSubview:self.tabBar];
    _sendStatusController.view.alpha = 0.0;
    _sendStatusController.messageLabel.text = NSLocalizedString(@"Receiving...", nil);
    _sendStatusController.titleLabel.text = NSLocalizedString(@"Receive Status", nil);
    [UIView animateWithDuration:0.35
                        delay:0.0
                    options:UIViewAnimationOptionCurveEaseInOut
                    animations:^
    {
        _sendStatusController.view.alpha = 1.0;
    }
    completion:^(BOOL finished)
    {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self launchTransactionDetails:_strWalletUUID withTx:_strTxID];
            [_sendStatusController.view removeFromSuperview];
            _sendStatusController = nil;
            [_requestViewController resetViews];
        });
    }];
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

#pragma mark - Custom Notification Handlers

- (void)notifyRemotePasswordChange:(NSArray *)params
{
    if (_passwordChangeAlert == nil)
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

- (void)handleBitcoinUri:(NSNotification *)notification
{
    [_sendViewController resetViews];
    [self.tabBar selectButtonAtIndex:APP_MODE_SEND];

    NSDictionary *dictData = [notification userInfo];
    NSURL *uri = [dictData objectForKey:KEY_URL];
    _sendViewController.pickerTextSendTo.textField.text = [uri absoluteString];
    [_sendViewController processURI];
}

- (void)loggedOffRedirect:(NSNotification *)notification
{
	[self.tabBar selectButtonAtIndex:APP_MODE_DIRECTORY];
    [self resetViews:notification];
}

- (void)resetViews:(NSNotification *)notification
{
    // Hide the keyboard
    [self.view endEditing:NO];

    // Force the tabs to redraw the selected view
    _selectedViewController = nil;
    [self launchViewControllerBasedOnAppMode];
}

@end

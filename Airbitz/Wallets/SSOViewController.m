//
//  SSOViewController.m
//  Airbitz
//
//  Created by Paul Puey 2016-08-09.
//  Copyright (c) 2016 AirBitz. All rights reserved.
//

#import "SSOViewController.h"
#import "MainViewController.h"
#import "StylizedButton.h"
#import "Theme.h"
#import "FadingAlertView.h"

@interface SSOViewController ()
{
    BOOL                            _bitidSParam;
    BOOL                            _bitidProvidingKYCToken;
    NSMutableArray                  *_kycTokenKeys;

}
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView    *spinnerView;
@property (weak, nonatomic) IBOutlet UILabel                    *headerLabel;
@property (weak, nonatomic) IBOutlet UILabel                    *appNameLabel;
@property (weak, nonatomic) IBOutlet UITextView                 *descriptionTextView;
@property (weak, nonatomic) IBOutlet UIButton                   *loginButton;
@property (weak, nonatomic) IBOutlet UIButton                   *cancelButton;
@property (weak, nonatomic) IBOutlet UITableView                *ssoTableView;

@end

@implementation SSOViewController

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
    [self.spinnerView startAnimating];


}

- (void)viewDidUnload
{
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    [MainViewController changeNavBarOwner:self];

    self.spinnerView.hidden = YES;
    self.headerLabel.textColor = [Theme Singleton].colorTextDarkGrey;
    self.descriptionTextView.textColor = [Theme Singleton].colorTextDarkGrey;
    self.appNameLabel.textColor = [Theme Singleton].colorTextDark;
    
    [self setupNavBar];

    [self generateViewText];
}

- (void) generateViewText;
{
    NSString *bitidRequestString = @"";
    _bitidSParam = NO;
    
    if (_parsedURI.bitIDURI)
    {
        self.headerLabel.text = bitIDLogin;
        self.appNameLabel.text = [_parsedURI.bitIDDomain stringByReplacingOccurrencesOfString:@"https://" withString:@""];
        [self.loginButton.layer setName:loginButtonText];
        [self.cancelButton.layer setName:cancelButtonText];
        
        if (_parsedURI.bitidKYCProvider)
        {
            bitidRequestString = [NSString stringWithFormat:@"%@%@", bitidRequestString, provideIdentityTokenText];
            _bitidSParam = YES;
            _bitidProvidingKYCToken = YES;
        }
        else
        {
            _bitidProvidingKYCToken = NO;
        }
        
        if (_parsedURI.bitidKYCRequest)
        {
            _bitidSParam = YES;
            
            _kycTokenKeys = [[NSMutableArray alloc] init];
            [abcAccount.dataStore dataListKeys:@"Identities" keys:_kycTokenKeys];
            if ([_kycTokenKeys count] > 0)
            {
                bitidRequestString = [NSString stringWithFormat:@"%@%@", bitidRequestString, requestYourIdentityToken];
            }
            else
            {
                bitidRequestString = [NSString stringWithFormat:@"%@%@", bitidRequestString, requestYourIdentityTokenButNone];
                _kycTokenKeys = nil;
            }
        }
        else
        {
            _kycTokenKeys = nil;
            if (!_bitidProvidingKYCToken)
            {
                // Standard BitID Login
                bitidRequestString = NSLocalizedString(@"Please verify the domain above and tap LOGIN to authenticate with this site", nil);
            }
        }
        
        if (_bitidSParam)
        {
            bitidRequestString = [NSString stringWithFormat:@"\n\n%@\n\n%@", wouldLikeToColon, bitidRequestString];
        }
        
        if (_parsedURI.bitidPaymentAddress)
        {
            bitidRequestString = [NSString stringWithFormat:@"%@%@", bitidRequestString, requestPaymentAddress];
            _bitidSParam = YES;
        }
        
        self.descriptionTextView.text = bitidRequestString;
        
//        if (_parsedURI.bitidKYCRequest)
//        {
//            if (_kycTokenKeys)
//            {
//                int count = (int)[_kycTokenKeys count];
//                
//                if (count == 1)
//                {
//                    
//                    _bitidAlert = [[UIAlertView alloc]
//                                   initWithTitle:bitIDLogin
//                                   message:message
//                                   delegate:self
//                                   cancelButtonTitle:noButtonText
//                                   otherButtonTitles:[NSString stringWithFormat:@"Use ID token [%@]",  _kycTokenKeys[0]],nil];
//                }
//                else if (count == 2)
//                {
//                    _bitidAlert = [[UIAlertView alloc]
//                                   initWithTitle:bitIDLogin
//                                   message:message
//                                   delegate:self
//                                   cancelButtonTitle:noButtonText
//                                   otherButtonTitles:[NSString stringWithFormat:@"Use ID token [%@]", _kycTokenKeys[0]],
//                                   [NSString stringWithFormat:@"Use ID token [%@]", _kycTokenKeys[1]],
//                                   nil];
//                    
//                }
//                else
//                {
//                    // Only support a max of 3 tokens for now
//                    _bitidAlert = [[UIAlertView alloc]
//                                   initWithTitle:bitIDLogin
//                                   message:message
//                                   delegate:self
//                                   cancelButtonTitle:noButtonText
//                                   otherButtonTitles:[NSString stringWithFormat:@"Use ID token [%@]", _kycTokenKeys[0]],
//                                   [NSString stringWithFormat:@"Use ID token [%@]", _kycTokenKeys[1]],
//                                   [NSString stringWithFormat:@"Use ID token [%@]", _kycTokenKeys[2]],
//                                   nil];
//                }
//                
//            }
//            else
//            {
//                
//                _bitidAlert = [[UIAlertView alloc]
//                               initWithTitle:bitIDLogin
//                               message:message
//                               delegate:self
//                               cancelButtonTitle:cancelButtonText
//                               otherButtonTitles:nil];
//            }
//            
//        }
//        else
//        {
//            _bitidAlert = [[UIAlertView alloc]
//                           initWithTitle:bitIDLogin
//                           message:message
//                           delegate:self
//                           cancelButtonTitle:noButtonText
//                           otherButtonTitles:yesButtonText,nil];
//            
//        }
    }

}

- (void)setupNavBar
{
    [MainViewController changeNavBarTitle:self title:transactionDetailsHeaderText];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Exit:) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (void)viewDidDisappear:(BOOL)animated
{
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Custom Notification Handlers

// called when a tab bar button that is already selected, is reselected again
- (void)tabBarButtonReselect:(NSNotification *)notification
{
    [self Done];
}


#pragma mark - Action Methods
- (IBAction)Login:(id)sender
{
    self.spinnerView.hidden = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        ABCError *error = nil;
        if (!_bitidSParam)
            error = [abcAccount bitidLogin:_parsedURI.bitIDURI];
        else
        {
//            if (_kycTokenKeys)
//            {
//                NSMutableString *callbackURL = [[NSMutableString alloc] init];
//                
//                [abcAccount.dataStore dataRead:@"Identities" withKey:_kycTokenKeys[buttonIndex-1] data:callbackURL];
//                error = [abcAccount bitidLoginMeta:_parsedURI.bitIDURI kycURI:[NSString stringWithString:callbackURL]];
//            }
//            else
            {
                error = [abcAccount bitidLoginMeta:_parsedURI.bitIDURI kycURI:@""];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (!error)
            {
//                if (_bitidProvidingKYCToken)
//                {
//                    NSString *message = [NSString stringWithFormat:provideIdentityTokenText, _parsedURI.bitIDDomain];
//                    
//                    [MainViewController fadingAlert:message holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
//                }
//                else if(_kycTokenKeys)
//                {
//                    NSString *message = [NSString stringWithFormat:@"%@ %@", successfully_verified_identity, _kycTokenKeys[buttonIndex-1]];
//                    [MainViewController fadingAlert:message holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
//                }
//                else
                {
                    [MainViewController fadingAlert:successfullyLoggedIn holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
                    [self Done];
                }
            }
            else
            {
                [MainViewController fadingAlert:errorLoggingIn holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
                [self Done];
            }
            
        });
    });
    
//    if (self.returnUrl && [self.returnUrl length] > 0) {
//        [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:self.returnUrl]];
//    }
}

- (IBAction)Deny:(id)sender {
    [self Done];
}

-(void)Exit:(id)sender
{
    [self Done];
}

- (IBAction)Done
{
    self.spinnerView.hidden = NO;
    [self exit:YES];
}

- (void)exit:(BOOL)bNotifyExit
{
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(SSOViewControllerDone:)])
        {
            [self.delegate SSOViewControllerDone:self];
        }
    }
}

@end

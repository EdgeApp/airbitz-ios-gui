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
#import "PluginCell.h"
#import "UtilityTableViewController.h"

@interface SSOViewController () <UITableViewDelegate, UITableViewDataSource>
{
    BOOL                            _bitidSParam;
    BOOL                            _bitidProvidingKYCToken;
    NSMutableArray                  *_kycTokenKeys;
    UIImage                         *_blankImage;
    int                             _selectedTableIndex;
    int                             _tableNumRows;
    NSMutableArray                  *_reposToUseIndex;
    
    // 2 dim array. 1st are repoTypes index. 2nd dim are list of repos for that type
    NSMutableArray                  *_reposIndexed;

}
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView    *spinnerView;
@property (weak, nonatomic) IBOutlet UILabel                    *headerLabel;
@property (weak, nonatomic) IBOutlet UILabel                    *appNameLabel;
@property (weak, nonatomic) IBOutlet UITextView                 *descriptionTextView;
@property (weak, nonatomic) IBOutlet UIButton                   *loginButton;
@property (weak, nonatomic) IBOutlet UIButton                   *cancelButton;
@property (weak, nonatomic) IBOutlet UITableView                *ssoTableView;
@property (weak, nonatomic) IBOutlet UIImageView                *topImageLogo;



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
    self.ssoTableView.delegate = self;
    self.ssoTableView.dataSource = self;
    
    _reposToUseIndex = [[NSMutableArray alloc] init];
    _reposIndexed = [[NSMutableArray alloc] init];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);
    _blankImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
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
    NSString *descriptionText = @"";
    _bitidSParam = NO;
    
    if (_edgeLoginInfo)
    {
        if (_edgeLoginInfo.requestorImageUrl)
        {
            self.headerLabel.hidden = YES;
                NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:_edgeLoginInfo.requestorImageUrl]
                                                              cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                          timeoutInterval:60];
            
            [self.topImageLogo setImageWithURLRequest:imageRequest placeholderImage:_blankImage success:nil failure:nil];
            
            self.topImageLogo.layer.shadowColor = [UIColor blackColor].CGColor;
            self.topImageLogo.layer.shadowOpacity = 0.5;
            self.topImageLogo.layer.shadowRadius = 10;
            self.topImageLogo.layer.shadowOffset = CGSizeMake(5.0f, 5.0f);
        }
        else
        {
            self.topImageLogo.hidden = YES;
            self.headerLabel.text = edge_login;
        }
        self.appNameLabel.text = _edgeLoginInfo.requestor;
        [self.cancelButton setTitle:cancelButtonText forState:UIControlStateNormal];
        [self.loginButton setTitle:accept_button_text forState:UIControlStateNormal];
        
        self.descriptionTextView.text = NSLocalizedString(@"This application would like to access the following repositories linked to your Airbitz account. It will not have access to any other accounts or wallets.", nil);
        _tableNumRows = (int) _edgeLoginInfo.repoTypes.count;
        
        for (int i = 0; i < _edgeLoginInfo.repoTypes.count; i++)
        {
            NSString *s = _edgeLoginInfo.repoTypes[i];
            NSArray *array = [abcAccount getEdgeLoginRepos:s];
            
            if (array)
            {
                [_reposIndexed addObject:array];
                [_reposToUseIndex addObject: [NSNumber numberWithInt:0]];
            }
            else
            {
                [_reposToUseIndex addObject: [NSNumber numberWithInt:-1]];
                [_reposIndexed addObject:@[]];
            }
        }

    }
    else if (_parsedURI.bitIDURI)
    {
        self.appNameLabel.text = [_parsedURI.bitIDDomain stringByReplacingOccurrencesOfString:@"https://" withString:@""];
        self.appNameLabel.text = [self.appNameLabel.text stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        [self.cancelButton setTitle:cancelButtonText forState:UIControlStateNormal];
        
        if (_parsedURI.bitidKYCProvider)
        {
            self.headerLabel.text = bitIDIdentity;
            descriptionText = [NSString stringWithFormat:@"• %@", provideIdentityTokenText];
            _bitidSParam = YES;
            _bitidProvidingKYCToken = YES;
            [self.loginButton setTitle:accept_button_text forState:UIControlStateNormal];
        }
        else if (_parsedURI.bitidKYCRequest)
        {
            self.headerLabel.text = bitIDIdentity;
            _bitidProvidingKYCToken = NO;
            _bitidSParam = YES;
            
            _kycTokenKeys = [[NSMutableArray alloc] init];
//            [abcAccount.dataStore dataListKeys:@"Identities" keys:_kycTokenKeys];
            // XXX testing only
            [_kycTokenKeys addObject:@"bitpos.me"];
            [_kycTokenKeys addObject:@"optus.com.au"];
            [_kycTokenKeys addObject:@"airbitz.co"];
            if ([_kycTokenKeys count] > 0)
            {
                descriptionText = [NSString stringWithFormat:@"• %@", requestYourIdentityToken];
                [self.loginButton setTitle:approve_button_text forState:UIControlStateNormal];
            }
            else
            {
                descriptionText = [NSString stringWithFormat:@"• %@", requestYourIdentityTokenButNone];
                _kycTokenKeys = nil;
                self.loginButton.hidden = YES;
                [self.cancelButton setTitle:backButtonText forState:UIControlStateNormal];
            }
        }
        else
        {
            _kycTokenKeys = nil;
            // Standard BitID Login
            self.headerLabel.text = bitIDLogin;
            descriptionText = NSLocalizedString(@"Please verify the domain above and tap LOGIN to authenticate with this site", nil);
            [self.loginButton setTitle:loginButtonText forState:UIControlStateNormal];
        }
        
        _tableNumRows = (int) _kycTokenKeys.count;
        
        if (_parsedURI.bitidPaymentAddress)
        {
            descriptionText = [NSString stringWithFormat:@"%@\n• %@", descriptionText, requestPaymentAddress];
            _bitidSParam = YES;
        }
        
        if (_bitidSParam)
        {
            descriptionText = [NSString stringWithFormat:@"%@\n\n%@", wouldLikeToColon, descriptionText];
        }
        
        self.descriptionTextView.text = descriptionText;
        [self.ssoTableView reloadData];
        
    }

}

- (void)setupNavBar
{
    [MainViewController changeNavBarTitle:self title:airbitzEdgeLogin];
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
    if (_edgeLoginInfo)
    {
        [abcAccount approveEdgeLoginRequest:_edgeLoginInfo.token callback:^(ABCError *error) {
            if (error)
            {
                
            }
            else
            {
                [MainViewController fadingAlert:successfullyLoggedIn holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
                [self Done];
            }

        }];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        ABCError *error = nil;
        if (!_bitidSParam)
            error = [abcAccount bitidLogin:_parsedURI.bitIDURI];
        else
        {
            if (_kycTokenKeys)
            {
                NSMutableString *callbackURL = [[NSMutableString alloc] init];
                
                [abcAccount.dataStore dataRead:@"Identities" withKey:_kycTokenKeys[_selectedTableIndex] data:callbackURL];
                error = [abcAccount bitidLoginMeta:_parsedURI.bitIDURI kycURI:[NSString stringWithString:callbackURL]];
            }
            else
            {
                error = [abcAccount bitidLoginMeta:_parsedURI.bitIDURI kycURI:@""];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (!error)
            {
                if (_bitidProvidingKYCToken)
                {
                    NSString *message = [NSString stringWithFormat:identity_token_created_and_saved, _parsedURI.bitIDDomain];
                    
                    [MainViewController fadingAlert:message holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
                }
                else if(_kycTokenKeys)
                {
                    NSString *message = [NSString stringWithFormat:@"%@ %@", successfully_verified_identity, _kycTokenKeys[_selectedTableIndex]];
                    [MainViewController fadingAlert:message holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
                }
                else
                {
                    [MainViewController fadingAlert:successfullyLoggedIn holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
                }
            }
            else
            {
                [MainViewController fadingAlert:errorLoggingIn holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
            }
            [self Done];
            
        });
    });
    
//    if (self.returnUrl && [self.returnUrl length] > 0) {
//        [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:self.returnUrl]];
//    }
}

- (IBAction)Deny:(id)sender {
    if (_edgeLoginInfo)
    {
        [abcAccount deleteEdgeLoginRequest:_edgeLoginInfo.token];
    }
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

#pragma mark - UITableView delegates
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tableNumRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PluginCell";
    int row = (int) indexPath.row;
    
    PluginCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PluginCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    if (_edgeLoginInfo)
    {
        cell.topLabel.text = _edgeLoginInfo.repoNames[row];
        cell.topLabel.textColor = [Theme Singleton].colorTextDark;

        NSArray *repos = _reposIndexed[row];
        
        if (repos && repos.count)
        {
            NSNumber *index = _reposToUseIndex[row];
            if (index && index.intValue >= 0)
            {
                cell.bottomLabel.text = [NSString stringWithFormat:@"\"%@\" or choose", ((ABCWallet *)repos[index.intValue]).name];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            }
            else
            {
                cell.bottomLabel.text = create_new_text;
                cell.rightImage.hidden = YES;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
        }
        else
        {
            cell.bottomLabel.text = create_new_text;
            cell.rightImage.hidden = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.image.image = _blankImage;
        
        NSString *imageUrl = nil;
        
        NSString *s = _edgeLoginInfo.repoTypes[indexPath.row];
        
        if ([s isEqualToString:@"account:repo:com.augur"])
            imageUrl = @"https://airbitz.co/go/wp-content/uploads/2016/08/augur_logo_100.png";
        else if ([s isEqualToString:@"account:repo:city.arcade"])
            imageUrl = @"https://airbitz.co/go/wp-content/uploads/2016/08/ACLOGOnt-1.png";
        else if ([s isEqualToString:@"wallet:repo:ethereum"])
            imageUrl = @"https://airbitz.co/go/wp-content/uploads/2016/08/EthereumIcon-100w.png";
        else if ([s isEqualToString:@"wallet:repo:bitcoin"])
            imageUrl = @"https://airbitz.co/go/wp-content/uploads/2016/08/bitcoin-logo-02.png";
        
        if (imageUrl)
        {
            NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:imageUrl]
                                                          cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                      timeoutInterval:60];
            
            [cell.image setImageWithURLRequest:imageRequest placeholderImage:_blankImage success:nil failure:nil];
        }
        
        cell.image.layer.shadowColor = [UIColor blackColor].CGColor;
        cell.image.layer.shadowOpacity = 0.5;
        cell.image.layer.shadowRadius = 10;
        cell.image.layer.shadowOffset = CGSizeMake(5.0f, 5.0f);
    }
    else if (_kycTokenKeys)
    {
        cell.topLabel.text = _kycTokenKeys[indexPath.row];
        cell.topLabel.textColor = [Theme Singleton].colorTextDark;
        
        cell.bottomLabel.text = @"";
        cell.image.image = _blankImage;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [Theme Singleton].colorBackgroundHighlight;
    bgColorView.layer.masksToBounds = YES;
    cell.selectedBackgroundView = bgColorView;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = (int) indexPath.row;
    if (_kycTokenKeys)
    {
        _selectedTableIndex = (int) indexPath.row;
        [self Login:nil];
    }
    else
    {
        NSArray *repos = _reposIndexed[row];
        NSMutableArray *arrayText = [[NSMutableArray alloc] init];
        
        if (repos && repos.count)
        {
            for (ABCWallet *w in repos)
            {
                [arrayText addObject:w.name];
            }
            [arrayText addObject:create_new_text];
            
            // Popup alert to choose one of the repos
            [UtilityTableViewController launchUtilityTableViewController:self
                                                              cellHeight:55.0
                                                            arrayTopText:[arrayText copy]
                                                         arrayBottomText:nil
                                                          arrayImageUrls:nil
                                                              arrayImage:nil
                                                                callback:^(int selectedIndex)
            {
                if (selectedIndex <= arrayText.count)
                    _reposToUseIndex[row] = [NSNumber numberWithInt:-1];
                else
                    _reposToUseIndex[row] = [NSNumber numberWithInt:selectedIndex];
            }];
        }
    }
}

@end

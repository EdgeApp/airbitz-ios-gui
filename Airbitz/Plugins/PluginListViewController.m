//
//  BuySellViewController.m
//  AirBitz
//

#import "PluginListViewController.h"
#import "MainViewController.h"
#import "Theme.h"
#import "PluginCell.h"
#import "PluginViewController.h"
#import "WalletHeaderView.h"
#import "Plugin.h"
#import "Util.h"
#import "LocalSettings.h"
#import "Mixpanel.h"

@interface PluginListViewController () <UIWebViewDelegate, UITableViewDataSource, UITableViewDelegate, PluginViewControllerDelegate>
{
    PluginViewController *_pluginViewController;
    UIImage                 *_blankImage;
}

@property (nonatomic, strong) WalletHeaderView    *buySellHeaderView;
@property (nonatomic, strong) WalletHeaderView    *giftCardHeaderView;
@property (nonatomic, weak) IBOutlet UILabel      *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton     *backButton;
@property (nonatomic, weak) IBOutlet UITableView  *pluginTable;


@end

@implementation PluginListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    _pluginTable.dataSource = self;
    _pluginTable.delegate = self;
    _pluginTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_pluginTable setContentInset:UIEdgeInsetsMake(0,0,
                                                   [MainViewController getFooterHeight],0)];

    _backButton.hidden = YES;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);
    _blankImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [Plugin initAll];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[Mixpanel sharedInstance] track:@"PLG-Enter"];
    [super viewWillAppear:animated];
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:false action:nil fromObject:self];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
    [MainViewController changeNavBarTitle:self title:spend_bitcoin_plugin_text];
    _pluginTable.editing = NO;
    
    if ([[LocalSettings controller] offerPluginsHelp])
    {
        NSString *txt = [NSString stringWithFormat:plugin_popup_notice, appTitle];
        [MainViewController fadingAlertHelpPopup:txt];
    }
    

}

#pragma mark - UITableView

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[Plugin getGeneralPlugins] count];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    return [Theme Singleton].heightBLETableCells;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PluginCell";
    NSInteger row = [indexPath row];
    Plugin *plugin;
 
    PluginCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PluginCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    plugin = [[Plugin getGeneralPlugins] objectAtIndex:row];

    cell.topLabel.text = plugin.name;
    cell.bottomLabel.text = plugin.provider;
    
    if (plugin.imageUrl)
    {
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:plugin.imageUrl]
                                                      cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                  timeoutInterval:60];
        
        [cell.image setImageWithURLRequest:imageRequest placeholderImage:_blankImage success:nil failure:nil];
    }
    else
    {
        cell.image.image = [UIImage imageNamed:plugin.imageFile];
    }

    cell.image.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.image.layer.shadowOpacity = 0.5;
    cell.image.layer.shadowRadius = 10;
    cell.image.layer.shadowOffset = CGSizeMake(5.0f, 5.0f);
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryNone;
 
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [Theme Singleton].colorLightPrimary;
    bgColorView.layer.masksToBounds = YES;
    cell.selectedBackgroundView = bgColorView;
    cell.backgroundColor = plugin.backgroundColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    Plugin *plugin;
    
    plugin = [[Plugin getGeneralPlugins] objectAtIndex:row];
    [[Mixpanel sharedInstance] track:[NSString stringWithFormat:@"PLG-%@ %@", plugin.provider, plugin.name]];

    [self launchPlugin:plugin uri:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)launchPluginByCountry:(NSString *)country provider:(NSString *)provider uri:(NSURL *)uri
{
    Plugin *plugin = nil;
    for (Plugin *p in [Plugin getBuySellPlugins]) {
        if ([provider isEqualToString:p.provider]
          && [country isEqualToString:p.country]) {
            plugin = p;
        }
    }
    if (nil == plugin)
    {
        for (Plugin *p in [Plugin getGeneralPlugins]) {
            if ([provider isEqualToString:p.provider]
                && [country isEqualToString:p.country]) {
                plugin = p;
            }
        }
    }
    if (plugin != nil) {
        [self launchPlugin:plugin uri:uri];
        return YES;
    }
    return NO;
}

- (void)launchPlugin:(Plugin *)plugin uri:(NSURL *)uri
{
    [self resetViews];

    UIStoryboard *pluginStoryboard = [UIStoryboard storyboardWithName:@"Plugins" bundle: nil];
    _pluginViewController = [pluginStoryboard instantiateViewControllerWithIdentifier:@"PluginViewController"];
    _pluginViewController.delegate = self;
    _pluginViewController.plugin = plugin;
    _pluginViewController.uri = uri;
    [Util animateController:_pluginViewController parentController:self];
}

- (void)resetViews
{
    if (_pluginViewController)
    {
        [_pluginViewController.view removeFromSuperview];
        [_pluginViewController removeFromParentViewController];
        _pluginViewController = nil;
    }
}

#pragma mark - PluginViewControllerDelegate

- (void)PluginViewControllerDone:(PluginViewController *)controller
{
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:false action:nil fromObject:self];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
    [MainViewController changeNavBarTitle:self title:spend_bitcoin_plugin_text];
    [Util animateOut:controller parentController:self complete:^(void) {
        [self resetViews];
        _pluginViewController = nil;
    }];
}

@end

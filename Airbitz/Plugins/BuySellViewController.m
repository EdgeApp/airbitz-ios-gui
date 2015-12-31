//
//  BuySellViewController.m
//  AirBitz
//

#import "BuySellViewController.h"
#import "MainViewController.h"
#import "Theme.h"
#import "BuySellCell.h"
#import "PluginViewController.h"
#import "WalletHeaderView.h"
#import "Plugin.h"
#import "Util.h"

#define SECTION_GIFT_CARDS      0
#define SECTION_BUY_SELL        1
#define SECTIONS_TOTAL          2

@interface BuySellViewController () <UIWebViewDelegate, UITableViewDataSource, UITableViewDelegate, PluginViewControllerDelegate>
{
    PluginViewController *_pluginViewController;
}

@property (nonatomic, strong) WalletHeaderView    *buySellHeaderView;
@property (nonatomic, strong) WalletHeaderView    *giftCardHeaderView;
@property (nonatomic, weak) IBOutlet UILabel      *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton     *backButton;
@property (nonatomic, weak) IBOutlet UITableView  *pluginTable;

@end

@implementation BuySellViewController

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

    _buySellHeaderView = [WalletHeaderView CreateWithTitle:NSLocalizedString(@"Buy / Sell Bitcoin", nil) collapse:NO];
    _buySellHeaderView.btn_expandCollapse.hidden = YES;
    _buySellHeaderView.btn_addWallet.hidden = YES;
    _buySellHeaderView.btn_exportWallet.hidden = YES;
    _buySellHeaderView.btn_header.hidden = YES;
    _giftCardHeaderView = [WalletHeaderView CreateWithTitle:NSLocalizedString(@"Discounted Gift Cards", nil) collapse:NO];
    _giftCardHeaderView.btn_expandCollapse.hidden = YES;
    _giftCardHeaderView.btn_addWallet.hidden = YES;
    _giftCardHeaderView.btn_exportWallet.hidden = YES;
    _giftCardHeaderView.btn_header.hidden = YES;
    
    [Plugin initAll];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:false action:nil fromObject:self];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
    [MainViewController changeNavBarTitle:self title:buySellText];
    _pluginTable.editing = NO;
}

#pragma mark - UITableView

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [Theme Singleton].heightBLETableCells;
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (SECTION_BUY_SELL == section)
        return  _buySellHeaderView;
    else
        return  _giftCardHeaderView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SECTIONS_TOTAL;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (SECTION_BUY_SELL == section)
        return [[Plugin getBuySellPlugins] count];
    else
        return [[Plugin getGiftCardPlugins] count];
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
    static NSString *CellIdentifier = @"BuySellCell";
    NSInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    Plugin *plugin;
 
    BuySellCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[BuySellCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    if (SECTION_BUY_SELL == section)
        plugin = [[Plugin getBuySellPlugins] objectAtIndex:row];
    else if (SECTION_GIFT_CARDS == section)
        plugin = [[Plugin getGiftCardPlugins] objectAtIndex:row];

    [cell setInfo:row tableHeight:[tableView numberOfRowsInSection:indexPath.section]];
    cell.text.text = plugin.name;
    cell.text.textColor = plugin.textColor;
    cell.imageView.image = [UIImage imageNamed:plugin.imageFile];
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryNone;
 
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [Theme Singleton].colorBackgroundHighlight;
    bgColorView.layer.masksToBounds = YES;
    cell.selectedBackgroundView = bgColorView;
    cell.backgroundColor = plugin.backgroundColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    Plugin *plugin;
    
    if (SECTION_BUY_SELL == section)
        plugin = [[Plugin getBuySellPlugins] objectAtIndex:row];
    else if (SECTION_GIFT_CARDS == section)
        plugin = [[Plugin getGiftCardPlugins] objectAtIndex:row];
    
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
        for (Plugin *p in [Plugin getGiftCardPlugins]) {
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
    [MainViewController changeNavBarTitle:self title:buySellText];
    [Util animateOut:controller parentController:self complete:^(void) {
        [self resetViews];
        _pluginViewController = nil;
    }];
}

@end

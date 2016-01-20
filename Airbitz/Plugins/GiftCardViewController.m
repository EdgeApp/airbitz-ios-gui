//
//  BuySellViewController.m
//  AirBitz
//

#import "GiftCardViewController.h"
#import "MainViewController.h"
#import "Theme.h"
#import "BuySellCell.h"
#import "PluginViewController.h"
#import "WalletHeaderView.h"
#import "Plugin.h"
#import "Util.h"

@interface GiftCardViewController () <UIWebViewDelegate, UITableViewDataSource, UITableViewDelegate, PluginViewControllerDelegate>
{
    PluginViewController *_pluginViewController;
}

@property (nonatomic, strong) WalletHeaderView    *buySellHeaderView;
@property (nonatomic, strong) WalletHeaderView    *giftCardHeaderView;
@property (nonatomic, weak) IBOutlet UILabel      *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton     *backButton;
@property (nonatomic, weak) IBOutlet UITableView  *pluginTable;

@end

@implementation GiftCardViewController

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

    [Plugin initAll];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:false action:nil fromObject:self];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
    [MainViewController changeNavBarTitle:self title:discountedGiftCardsText];
    _pluginTable.editing = NO;
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

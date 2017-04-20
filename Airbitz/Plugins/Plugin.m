//
//  Plugin.m
//  AirBitz
//

#import "Plugin.h"
#import "Config.h"
#import "MainViewController.h"
#import "CommonTypes.h"
#import "Strings.h"
#import "BrandStrings.h"

@interface Plugin ()
@end

@implementation Plugin

static BOOL bInitialized = NO;
static NSMutableArray *buySellPlugins;
static NSMutableArray *generalPlugins;

+ (void)initAll
{
    if (NO == bInitialized)
    {
        bool isTestnet = [abc isTestNet];

        buySellPlugins = [[NSMutableArray alloc] init];
        generalPlugins = [[NSMutableArray alloc] init];

        Plugin *plugin;
        {
            plugin = [[Plugin alloc] init];
            plugin.pluginId = @"com.bitrefill.widget";
            plugin.provider = @"Bitrefill";
            plugin.sourceFile = @"bitrefill";
            plugin.sourceExtension = @"html";
            plugin.imageUrl = @"https://airbitz.co/go/wp-content/uploads/2016/08/Bitrefill-logo-300x300.png";
            plugin.name = mobile_phone_topups;
            plugin.env = @{
                           @"SANDBOX": (isTestnet ? @"true" : @"false"),
                           @"API_KEY": BITREFILL_API_KEY
                           };
            [generalPlugins addObject:plugin];
        }
        
        {
            plugin = [[Plugin alloc] init];
            plugin.pluginId = @"com.foldapp";
            plugin.provider = @"Fold";
            plugin.country = @"US";
            plugin.sourceFile = @"foldapp";
            plugin.sourceExtension = @"html";
            plugin.imageUrl = @"https://airbitz.co/go/wp-content/uploads/2016/08/starbucks_logo2.png";
            plugin.name = starbucks_20_percent_off;
            plugin.env = @{
                           @"API-TOKEN": FOLD_API_KEY,
                           @"AIRBITZ_STATS_KEY": AIRBITZ_DIRECTORY_API_KEY,
                           @"BRAND": @"Starbucks",
                           @"LOGO_URL": @"https://airbitz.co/go/wp-content/uploads/2015/12/green-coffee-mug-128px.png",
                           @"BIZID": [NSString stringWithFormat:@"%d",StarbucksBizID],
                           @"CATEGORY": [NSString stringWithFormat:@"%@%@%@",
                                         expense_category_en, @"%3A", category_coffee_shops],
                           };
            [generalPlugins addObject:plugin];
        }
        
        {
            plugin = [[Plugin alloc] init];
            plugin.pluginId = @"com.foldapp";
            plugin.provider = @"Fold";
            plugin.country = @"US";
            plugin.sourceFile = @"foldapp";
            plugin.sourceExtension = @"html";
            plugin.imageUrl = @"https://airbitz.co/go/wp-content/uploads/2016/08/target_logo.png";
            plugin.name = target_10_percent_off;
            plugin.env = @{
                           @"API-TOKEN": FOLD_API_KEY,
                           @"AIRBITZ_STATS_KEY": AIRBITZ_DIRECTORY_API_KEY,
                           @"BRAND": @"Target",
                           @"LOGO_URL": @"https://airbitz.co/go/wp-content/uploads/2015/12/red-bulls-eye-128px.png",
                           @"BIZID": [NSString stringWithFormat:@"%d",TargetBizID],
                           @"CATEGORY": [NSString stringWithFormat:@"%@%@%@",
                                         expense_category_en, @"%3A", category_shopping],
                           };
            [generalPlugins addObject:plugin];
        }
        
        if ([MainViewController Singleton].developBuild ||
            [[MainViewController Singleton].arrayPluginBizIDs containsObject:[NSNumber numberWithInt:11139]])
        {
            plugin = [[Plugin alloc] init];
            plugin.pluginId = @"com.foldapp";
            plugin.provider = @"Fold";
            plugin.country = @"US";
            plugin.sourceFile = @"foldapp";
            plugin.sourceExtension = @"html";
            plugin.imageUrl = @"https://airbitz.co/go/wp-content/uploads/2015/12/Whole-Foods-Market-128px.png";
            plugin.name = wholefoods_10_percent_off;
            plugin.env = @{
                           @"API-TOKEN": FOLD_API_KEY,
                           @"AIRBITZ_STATS_KEY": AIRBITZ_DIRECTORY_API_KEY,
                           @"BRAND": @"Whole Foods",
                           @"LOGO_URL": @"https://airbitz.co/go/wp-content/uploads/2015/12/Whole-Foods-Market-128px.png",
                           @"BIZID": [NSString stringWithFormat:@"%d",WholeFoodsBizID],
                           @"CATEGORY": [NSString stringWithFormat:@"%@%@%@",
                                         expense_category_en, @"%3A", category_groceries],
                           };
            [generalPlugins addObject:plugin];
        }

        if ([MainViewController Singleton].developBuild ||
            [[MainViewController Singleton].arrayPluginBizIDs containsObject:[NSNumber numberWithInt:11140]])
        {
            plugin = [[Plugin alloc] init];
            plugin.pluginId = @"com.foldapp";
            plugin.provider = @"Fold";
            plugin.country = @"US";
            plugin.sourceFile = @"foldapp";
            plugin.sourceExtension = @"html";
            plugin.imageUrl = @"https://airbitz.co/go/wp-content/uploads/2016/08/walmart-logo0.jpg";
            plugin.name = walmart_10_percent_off;
            plugin.env = @{
                           @"API-TOKEN": FOLD_API_KEY,
                           @"AIRBITZ_STATS_KEY": AIRBITZ_DIRECTORY_API_KEY,
                           @"BRAND": @"Walmart",
                           @"LOGO_URL": @"https://airbitz.co/go/wp-content/uploads/2015/12/WalMart-128px.png",
                           @"BIZID": [NSString stringWithFormat:@"%d",WalmartBizID],
                           @"CATEGORY": [NSString stringWithFormat:@"%@%@%@",
                                         expense_category_en, @"%3A", category_shopping],
                           };
            [generalPlugins addObject:plugin];
        }
        
        if ([MainViewController Singleton].developBuild ||
            [[MainViewController Singleton].arrayPluginBizIDs containsObject:[NSNumber numberWithInt:11141]])
        {
            plugin = [[Plugin alloc] init];
            plugin.pluginId = @"com.foldapp";
            plugin.provider = @"Fold";
            plugin.country = @"US";
            plugin.sourceFile = @"foldapp";
            plugin.sourceExtension = @"html";
            plugin.imageUrl = @"https://airbitz.co/go/wp-content/uploads/2015/12/Home-Depot-square-128px.png";
            plugin.name = homedepot_15_percent_off;
            plugin.env = @{
                           @"API-TOKEN": FOLD_API_KEY,
                           @"AIRBITZ_STATS_KEY": AIRBITZ_DIRECTORY_API_KEY,
                           @"BRAND": @"Home Depot",
                           @"LOGO_URL": @"https://airbitz.co/go/wp-content/uploads/2015/12/Home-Depot-square-128px.png",
                           @"BIZID": [NSString stringWithFormat:@"%d",HomeDepotBizID],
                           @"CATEGORY": [NSString stringWithFormat:@"%@%@%@",
                                         expense_category_en, @"%3A", category_home_improvement],
                           };
            [generalPlugins addObject:plugin];
        }
        
        plugin = [[Plugin alloc] init];
        plugin.pluginId = @"com.glidera.us";
        plugin.provider = @"Glidera";
        plugin.country = @"US";
        plugin.sourceFile = @"glidera";
        plugin.sourceExtension = @"html";
        plugin.imageUrl = @"https://airbitz.co/go/wp-content/uploads/2016/08/Screen-Shot-2016-08-18-at-1.36.56-AM.png";
        plugin.name = buy_sell_bank_usa;
        plugin.env = @{
                       @"SANDBOX": (isTestnet ? @"true" : @"false"),
                       @"GLIDERA_CLIENT_ID": (isTestnet ? GLIDERA_API_SANDBOX_KEY : GLIDERA_API_KEY),
                       @"REDIRECT_URI": [NSString stringWithFormat:@"%@://plugin/glidera/%@/", [MainViewController Singleton].appUrlPrefix, plugin.country],
                       @"AIRBITZ_STATS_KEY": AIRBITZ_DIRECTORY_API_KEY,
                       };
        [buySellPlugins addObject:plugin];

        plugin = [[Plugin alloc] init];
        plugin.pluginId = @"com.bity.ch";
        plugin.provider = @"Bity";
        plugin.country = @"CH";
        plugin.sourceFile = @"bity";
        plugin.sourceExtension = @"html";
        plugin.imageUrl = @"https://airbitz.co/go/wp-content/uploads/2017/04/Bity-square.png";
        plugin.name = buy_sell_bank_europe;
        plugin.env = @{
                       @"SANDBOX": (isTestnet ? @"true" : @"false"),
                       @"AFFILIATE_CODE": BITY_AFFILIATE_CODE,
                       @"AIRBITZ_STATS_KEY": AIRBITZ_DIRECTORY_API_KEY,
                       };
        [buySellPlugins addObject:plugin];
        
        plugin = [[Plugin alloc] init];
        plugin.pluginId = @"com.libertyx.app";
        plugin.provider = @"LibertyX";
        plugin.country = @"US";
        plugin.sourceFile = @"libertyx";
        plugin.sourceExtension = @"html";
        plugin.imageUrl = @"https://airbitz.co/go/wp-content/uploads/2017/02/libertyx-icon.png";
        plugin.name = buy_sell_cash_usa;
        plugin.env = @{
                       @"TESTNET": (isTestnet ? @"true" : @"false"),
                       @"LIBERTYX_API_KEY": (isTestnet ? @"" : LIBERTYX_API_KEY),
                       @"AIRBITZ_STATS_KEY": AIRBITZ_DIRECTORY_API_KEY,
                       @"LIBERTYX_LABEL": @"LibertyX",
                       @"LIBERTYX_CATEGORY": @"Exchange:Buy Bitcoin",
                       @"BIZID": [NSString stringWithFormat:@"%d",LibertyXBizID],
                       };
        [buySellPlugins addObject:plugin];
        
        bInitialized = YES;
    }
}

+ (void)freeAll
{
}

+ (NSArray *)getGeneralPlugins
{
    return generalPlugins;
}

+ (NSArray *)getBuySellPlugins
{
    return buySellPlugins;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.pluginId = @"";
        self.name = @"";
        self.sourceFile = @"";
        self.sourceExtension = @"html";
    }
    return self;
}

- (void)dealloc 
{
}

@end

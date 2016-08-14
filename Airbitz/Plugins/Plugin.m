//
//  Plugin.m
//  AirBitz
//

#import "Plugin.h"
#import "Config.h"
#import "MainViewController.h"
#import "CommonTypes.h"
#import "Strings.h"

@interface Plugin ()
@end

@implementation Plugin

static BOOL bInitialized = NO;
static NSMutableArray *buySellPlugins;
static NSMutableArray *giftCardPlugins;

+ (void)initAll
{
    if (NO == bInitialized)
    {
        bool isTestnet = [abc isTestNet];

        buySellPlugins = [[NSMutableArray alloc] init];
        giftCardPlugins = [[NSMutableArray alloc] init];

        Plugin *plugin;

        {
            plugin = [[Plugin alloc] init];
            plugin.pluginId = @"com.foldapp";
            plugin.provider = @"foldapp";
            plugin.country = @"US";
            plugin.sourceFile = @"foldapp";
            plugin.sourceExtension = @"html";
            plugin.imageFile = @"plugin_icon_coffee";
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
            [giftCardPlugins addObject:plugin];
        }
        
        {
            plugin = [[Plugin alloc] init];
            plugin.pluginId = @"com.foldapp";
            plugin.provider = @"foldapp";
            plugin.country = @"US";
            plugin.sourceFile = @"foldapp";
            plugin.sourceExtension = @"html";
            plugin.imageFile = @"plugin_icon_target";
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
            [giftCardPlugins addObject:plugin];
        }
        
        if (AIRBITZ_DEVELOP ||
            [[MainViewController Singleton].arrayPluginBizIDs containsObject:[NSNumber numberWithInt:11139]])
        {
            plugin = [[Plugin alloc] init];
            plugin.pluginId = @"com.foldapp";
            plugin.provider = @"foldapp";
            plugin.country = @"US";
            plugin.sourceFile = @"foldapp";
            plugin.sourceExtension = @"html";
            plugin.imageFile = @"plugin_icon_wholefoods";
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
            [giftCardPlugins addObject:plugin];
        }

        if (AIRBITZ_DEVELOP ||
            [[MainViewController Singleton].arrayPluginBizIDs containsObject:[NSNumber numberWithInt:11140]])
        {
            plugin = [[Plugin alloc] init];
            plugin.pluginId = @"com.foldapp";
            plugin.provider = @"foldapp";
            plugin.country = @"US";
            plugin.sourceFile = @"foldapp";
            plugin.sourceExtension = @"html";
            plugin.imageFile = @"plugin_icon_walmart";
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
            [giftCardPlugins addObject:plugin];
        }
        
        if (AIRBITZ_DEVELOP ||
            [[MainViewController Singleton].arrayPluginBizIDs containsObject:[NSNumber numberWithInt:11141]])
        {
            plugin = [[Plugin alloc] init];
            plugin.pluginId = @"com.foldapp";
            plugin.provider = @"foldapp";
            plugin.country = @"US";
            plugin.sourceFile = @"foldapp";
            plugin.sourceExtension = @"html";
            plugin.imageFile = @"plugin_icon_homedepot";
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
            [giftCardPlugins addObject:plugin];
        }
        
        plugin = [[Plugin alloc] init];
        plugin.pluginId = @"com.glidera.us";
        plugin.provider = @"glidera";
        plugin.country = @"US";
        plugin.sourceFile = @"glidera";
        plugin.sourceExtension = @"html";
        plugin.imageFile = @"plugin_icon_usd";
        plugin.name = usa_text;
        plugin.env = @{
                       @"SANDBOX": (isTestnet ? @"true" : @"false"),
                       @"GLIDERA_CLIENT_ID": (isTestnet ? GLIDERA_API_SANDBOX_KEY : GLIDERA_API_KEY),
                       @"REDIRECT_URI": [NSString stringWithFormat:@"%@://plugin/glidera/%@/", AIRBITZ_URI_PREFIX, plugin.country],
                       @"AIRBITZ_STATS_KEY": AIRBITZ_DIRECTORY_API_KEY,
                       };
        [buySellPlugins addObject:plugin];

//        plugin = [[Plugin alloc] init];
//        plugin.pluginId = @"com.clevercoin";
//        plugin.provider = @"clevercoin";
//        plugin.country = @"EUR";
//        plugin.sourceFile = @"clevercoin";
//        plugin.sourceExtension = @"html";
//        plugin.imageFile = @"plugin_icon_euro";
//        plugin.name = @"Europe (EUR)";
//        plugin.env = @{
//                    @"SANDBOX": (isTestnet ? @"true" : @"false"),
//                    @"REDIRECT_URI": [NSString stringWithFormat:@"%@://plugin/clevercoin/%@/", AIRBITZ_URI_PREFIX, plugin.country],
//                    @"CLEVERCOIN_API_KEY": CLEVERCOIN_API_KEY,
//                    @"CLEVERCOIN_API_LABEL": CLEVERCOIN_API_LABEL,
//                    @"CLEVERCOIN_API_SECRET": CLEVERCOIN_API_SECRET,
//                    @"AIRBITZ_STATS_KEY": AIRBITZ_DIRECTORY_API_KEY,
//                    };
//        [buySellPlugins addObject:plugin];
        
        bInitialized = YES;
    }
}

+ (void)freeAll
{
}

+ (NSArray *)getGiftCardPlugins
{
    return giftCardPlugins;
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

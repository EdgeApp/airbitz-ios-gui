//
//  Plugin.m
//  AirBitz
//

#import "Plugin.h"
#import "Config.h"
#import "ABC.h"
#import "CommonTypes.h"

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
        tABC_Error error;
        bool isTestnet = false;
        ABC_IsTestNet(&isTestnet, &error);

        buySellPlugins = [[NSMutableArray alloc] init];
        giftCardPlugins = [[NSMutableArray alloc] init];

        Plugin *plugin;
        plugin = [[Plugin alloc] init];
        plugin.pluginId = @"com.foldapp";
        plugin.provider = @"foldapp";
        plugin.country = @"US";
        plugin.sourceFile = @"foldapp";
        plugin.sourceExtension = @"html";
        plugin.imageFile = @"plugin_icon_coffee";
        plugin.name = @"Up to 20% Off on Starbucks";
        plugin.env = @{
                       @"API-TOKEN": FOLD_API_KEY,
                       @"AIRBITZ_STATS_KEY": AUTH_TOKEN,
                       @"BRAND": @"Starbucks",
                       };
        [giftCardPlugins addObject:plugin];

        plugin = [[Plugin alloc] init];
        plugin.pluginId = @"com.foldapp";
        plugin.provider = @"foldapp";
        plugin.country = @"US";
        plugin.sourceFile = @"foldapp";
        plugin.sourceExtension = @"html";
        plugin.imageFile = @"plugin_icon_target";
        plugin.name = @"Up to 10% Off on Target";
        plugin.env = @{
                       @"API-TOKEN": FOLD_API_KEY,
                       @"AIRBITZ_STATS_KEY": AUTH_TOKEN,
                       @"BRAND": @"Target",
                       };
        [giftCardPlugins addObject:plugin];

        plugin = [[Plugin alloc] init];
        plugin.pluginId = @"com.glidera.us";
        plugin.provider = @"glidera";
        plugin.country = @"US";
        plugin.sourceFile = @"glidera";
        plugin.sourceExtension = @"html";
        plugin.imageFile = @"plugin_icon_usd";
        plugin.name = @"USA and Canada";
        plugin.env = @{
                       @"SANDBOX": (isTestnet ? @"true" : @"false"),
                       @"GLIDERA_CLIENT_ID": (isTestnet ? GLIDERA_API_SANDBOX_KEY : GLIDERA_API_KEY),
                       @"REDIRECT_URI": [NSString stringWithFormat:@"%@://plugin/glidera/%@/", AIRBITZ_URI_PREFIX, plugin.country],
                       @"AIRBITZ_STATS_KEY": AUTH_TOKEN,
                       };
        [buySellPlugins addObject:plugin];

        plugin = [[Plugin alloc] init];
        plugin.pluginId = @"com.clevercoin";
        plugin.provider = @"clevercoin";
        plugin.country = @"EUR";
        plugin.sourceFile = @"clevercoin";
        plugin.sourceExtension = @"html";
        plugin.imageFile = @"plugin_icon_euro";
        plugin.name = @"Europe (EUR)";
        plugin.env = @{
                    @"SANDBOX": (isTestnet ? @"true" : @"false"),
                    @"REDIRECT_URI": [NSString stringWithFormat:@"%@://plugin/clevercoin/%@/", AIRBITZ_URI_PREFIX, plugin.country],
                    @"CLEVERCOIN_API_KEY": CLEVERCOIN_API_KEY,
                    @"CLEVERCOIN_API_LABEL": CLEVERCOIN_API_LABEL,
                    @"CLEVERCOIN_API_SECRET": CLEVERCOIN_API_SECRET,
                    @"AIRBITZ_STATS_KEY": AUTH_TOKEN,
                    };
        [buySellPlugins addObject:plugin];
        
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

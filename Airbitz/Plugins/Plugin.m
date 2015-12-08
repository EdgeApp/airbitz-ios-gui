//
//  Plugin.m
//  AirBitz
//

#import "Plugin.h"
#import "Config.h"
#import "ABC.h"

@interface Plugin ()
@end

@implementation Plugin

static BOOL bInitialized = NO;
static NSMutableArray *plugins;

+ (void)initAll
{
    if (NO == bInitialized)
    {
        tABC_Error error;
        bool isTestnet = false;
        ABC_IsTestNet(&isTestnet, &error);

        plugins = [[NSMutableArray alloc] init];

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
        [plugins addObject:plugin];

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
        [plugins addObject:plugin];

        plugin = [[Plugin alloc] init];
        plugin.pluginId = @"com.glidera.us";
        plugin.provider = @"glidera";
        plugin.country = @"US";
        plugin.sourceFile = @"glidera";
        plugin.sourceExtension = @"html";
        plugin.imageFile = @"plugin_icon_usd";
        plugin.name = @"Buy/Sell Bitcoin (US/Canada)";
        plugin.env = @{
                       @"SANDBOX": (isTestnet ? @"true" : @"false"),
                       @"GLIDERA_CLIENT_ID": (isTestnet ? GLIDERA_API_SANDBOX_KEY : GLIDERA_API_KEY),
                       @"REDIRECT_URI": [NSString stringWithFormat:@"airbitz://plugin/glidera/%@/", plugin.country],
                       @"AIRBITZ_STATS_KEY": AUTH_TOKEN,
                       };
        [plugins addObject:plugin];

        if (isTestnet) {
            plugin = [[Plugin alloc] init];
            plugin.pluginId = @"com.clevercoin";
            plugin.provider = @"clevercoin";
            plugin.country = @"EUR";
            plugin.sourceFile = @"clevercoin";
            plugin.sourceExtension = @"html";
            plugin.imageFile = @"plugin_icon_euro";
            plugin.name = @"Buy Bitcoin (Euro)";
            plugin.env = @{
                        @"SANDBOX": (isTestnet ? @"true" : @"false"),
                        @"REDIRECT_URI": [NSString stringWithFormat:@"airbitz://plugin/clevercoin/%@/", plugin.country],
                        @"CLEVERCOIN_API_KEY": CLEVERCOIN_API_KEY,
                        @"CLEVERCOIN_API_LABEL": CLEVERCOIN_API_LABEL,
                        @"CLEVERCOIN_API_SECRET": CLEVERCOIN_API_SECRET,
                        @"AIRBITZ_STATS_KEY": AUTH_TOKEN,
                        };
            [plugins addObject:plugin];
            
        }
        
        bInitialized = YES;
    }
}

+ (void)freeAll
{
}

+ (Plugin *)getPlugins
{
    return plugins;
}

+ (NSArray *)getPlugin:(NSString *)pluginId
{
    return nil;
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

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
        plugin.pluginId = @"com.glidera.us";
        plugin.provider = @"glidera";
        plugin.country = @"US";
        plugin.sourceFile = @"glidera";
        plugin.sourceExtension = @"html";
        plugin.name = @"Glidera US/Canada (beta)";
        plugin.env = @{
            @"SANDBOX": (isTestnet ? @"true" : @"false"),
            @"GLIDERA_CLIENT_ID": (isTestnet ? GLIDERA_API_SANDBOX_KEY : GLIDERA_API_KEY),
            @"REDIRECT_URI": [NSString stringWithFormat:@"airbitz://plugin/glidera/%@/", plugin.country]
        };
        [plugins addObject:plugin];

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

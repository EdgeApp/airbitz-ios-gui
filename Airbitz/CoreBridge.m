
#import "ABC.h"
#import "Wallet.h"
#import "Transaction.h"
#import "TxOutput.h"
#import "Config.h"
#import "User.h"
#import "Util.h"
#import "LocalSettings.h"
#import "Keychain.h"
#import "SpendTarget.h"

#import "CoreBridge.h"
#import "AppGroupConstants.h"

#import <pthread.h>

#define CURRENCY_NUM_AUD                 36
#define CURRENCY_NUM_CAD                124
#define CURRENCY_NUM_CNY                156
#define CURRENCY_NUM_CUP                192
#define CURRENCY_NUM_HKD                344
#define CURRENCY_NUM_MXN                484
#define CURRENCY_NUM_NZD                554
#define CURRENCY_NUM_PHP                608
#define CURRENCY_NUM_GBP                826
#define CURRENCY_NUM_USD                840
#define CURRENCY_NUM_EUR                978

#define FILE_SYNC_FREQUENCY_SECONDS     30
#define NOTIFY_DATA_SYNC_DELAY          1

#define DEFAULT_CURRENCY_NUM CURRENCY_NUM_USD // USD


const int64_t RECOVERY_REMINDER_AMOUNT = 10000000;
const int RECOVERY_REMINDER_COUNT = 2;

@implementation BitidSignature
- (id)init
{
   self = [super init];
   return self;
}
@end

@implementation ABCSettings
- (id)init
{
    self = [super init];
    return self;
}
@end

@interface CoreBridge ()
{
    NSDictionary                                    *localeAsCurrencyNum;
    long long                                       logoutTimeStamp;

    ABCConditionCode                                lastConditionCode;
    NSString                                        *lastErrorString;
    BOOL                                            bInitialized;
    BOOL                                            bNewDeviceLogin;
    long                                            iLoginTimeSeconds;
    NSOperationQueue                                *exchangeQueue;
    NSOperationQueue                                *dataQueue;
    NSOperationQueue                                *walletsQueue;
    NSOperationQueue                                *genQRQueue;
    NSOperationQueue                                *txSearchQueue;
    NSOperationQueue                                *miscQueue;
    NSOperationQueue                                *watcherQueue;
    NSLock                                          *watcherLock;
    NSMutableDictionary                             *watchers;
    NSMutableDictionary                             *currencyCodesCache;
    NSMutableDictionary                             *currencySymbolCache;

    NSTimer                                         *exchangeTimer;
    NSTimer                                         *dataSyncTimer;
    NSTimer                                         *notificationTimer;


}
@property (nonatomic, strong) NSTimer                               *walletLoadingTimer;

@end

@implementation CoreBridge

- (void)initAll
{
    if (NO == bInitialized)
    {
        exchangeQueue = [[NSOperationQueue alloc] init];
        [exchangeQueue setMaxConcurrentOperationCount:1];
        dataQueue = [[NSOperationQueue alloc] init];
        [dataQueue setMaxConcurrentOperationCount:1];
        walletsQueue = [[NSOperationQueue alloc] init];
        [walletsQueue setMaxConcurrentOperationCount:1];
        genQRQueue = [[NSOperationQueue alloc] init];
        [genQRQueue setMaxConcurrentOperationCount:1];
        txSearchQueue = [[NSOperationQueue alloc] init];
        [txSearchQueue setMaxConcurrentOperationCount:1];
        miscQueue = [[NSOperationQueue alloc] init];
        [miscQueue setMaxConcurrentOperationCount:8];
        watcherQueue = [[NSOperationQueue alloc] init];
        [watcherQueue setMaxConcurrentOperationCount:1];

        watchers = [[NSMutableDictionary alloc] init];
        watcherLock = [[NSLock alloc] init];

        currencySymbolCache = [[NSMutableDictionary alloc] init];
        currencyCodesCache = [[NSMutableDictionary alloc] init];

        localeAsCurrencyNum = @{
            @"AUD" : @CURRENCY_NUM_AUD,
            @"CAD" : @CURRENCY_NUM_CAD,
            @"CNY" : @CURRENCY_NUM_CNY,
            @"CUP" : @CURRENCY_NUM_CUP,
            @"HKD" : @CURRENCY_NUM_HKD,
            @"MXN" : @CURRENCY_NUM_MXN,
            @"NZD" : @CURRENCY_NUM_NZD,
            @"PHP" : @CURRENCY_NUM_PHP,
            @"GBP" : @CURRENCY_NUM_GBP,
            @"USD" : @CURRENCY_NUM_USD,
            @"EUR" : @CURRENCY_NUM_EUR,
        };

        bInitialized = YES;

        [self cleanWallets];

        tABC_Error Error;
        tABC_Currency       *aCurrencies;
        int                 currencyCount;

        Error.code = ABC_CC_Ok;

        NSMutableData *seedData = [[NSMutableData alloc] init];
        [self fillSeedData:seedData];

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docs_dir = [paths objectAtIndex:0];
        NSString *ca_path = [[NSBundle mainBundle] pathForResource:@"ca-certificates" ofType:@"crt"];

        Error.code = ABC_CC_Ok;
        ABC_Initialize([docs_dir UTF8String],
                [ca_path UTF8String],
                API_KEY_HEADER,
                HIDDENBITZ_KEY,
                (unsigned char *)[seedData bytes],
                (unsigned int)[seedData length],
                &Error);
        [self setLastErrors:Error];

        // Fetch general info as soon as possible
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            tABC_Error error;
            ABC_GeneralInfoUpdate(&error);
            [self setLastErrors:Error];
        });

        Error.code = ABC_CC_Ok;

        // get the currencies
        aCurrencies = NULL;
        ABC_GetCurrencies(&aCurrencies, &currencyCount, &Error);
        [self setLastErrors:Error];

        self.currencyCount = currencyCount;
        // set up our internal currency arrays
        NSMutableArray *arrayCurrencyCodes = [[NSMutableArray alloc] initWithCapacity:self.currencyCount];
        NSMutableArray *arrayCurrencyNums = [[NSMutableArray alloc] initWithCapacity:self.currencyCount];
        NSMutableArray *arrayCurrencyStrings = [[NSMutableArray alloc] init];
        for (int i = 0; i < self.currencyCount; i++)
        {
            [arrayCurrencyStrings addObject:[NSString stringWithFormat:@"%s - %@",
                                                                       aCurrencies[i].szCode,
                                                                       [NSString stringWithUTF8String:aCurrencies[i].szDescription]]];
            [arrayCurrencyNums addObject:[NSNumber numberWithInt:aCurrencies[i].num]];
            [arrayCurrencyCodes addObject:[NSString stringWithUTF8String:aCurrencies[i].szCode]];
        }
        self.arrayCurrencyCodes = arrayCurrencyCodes;
        self.arrayCurrencyNums = arrayCurrencyNums;
        self.arrayCurrencyStrings = arrayCurrencyStrings;
        self.arrayCategories = nil;
        self.numCategories = 0;
        self.settings = [[ABCSettings alloc] init];
    }
}

- (void)fillSeedData:(NSMutableData *)data
{
    NSMutableString *strSeed = [[NSMutableString alloc] init];

    // add the UUID
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    [strSeed appendString:[[NSString alloc] initWithString:(__bridge NSString *)string]];
    CFRelease(string);

    // add the device name
    [strSeed appendString:[[UIDevice currentDevice] name]];

    // add the string to the data
    [data appendData:[strSeed dataUsingEncoding:NSUTF8StringEncoding]];

    double time = CACurrentMediaTime();

    [data appendBytes:&time length:sizeof(double)];

    UInt32 randomBytes = 0;
    if (0 == SecRandomCopyBytes(kSecRandomDefault, sizeof(int), (uint8_t*)&randomBytes)) {
        [data appendBytes:&randomBytes length:sizeof(UInt32)];
    }

    u_int32_t rand = arc4random();
    [data appendBytes:&rand length:sizeof(u_int32_t)];
}



- (void)freeAll
{
    if (YES == bInitialized)
    {
        exchangeQueue = nil;
        dataQueue = nil;
        walletsQueue = nil;
        genQRQueue = nil;
        txSearchQueue = nil;
        miscQueue = nil;
        watcherQueue = nil;
        bInitialized = NO;
        self.arrayCategories = nil;
        self.numCategories = 0;
        [self cleanWallets];
        self.settings = nil;
    }
}

- (void)startQueues
{
    if ([self isLoggedIn])
    {
        // Initialize the exchange rates queue
        exchangeTimer = [NSTimer scheduledTimerWithTimeInterval:ABC_EXCHANGE_RATE_REFRESH_INTERVAL_SECONDS
                                                         target:self
                                                       selector:@selector(requestExchangeRateUpdate:)
                                                       userInfo:nil
                                                        repeats:YES];
        // Request one right now
        [self requestExchangeRateUpdate:nil];

        // Initialize data sync queue
        dataSyncTimer = [NSTimer scheduledTimerWithTimeInterval:FILE_SYNC_FREQUENCY_SECONDS
                                                         target:self
                                                       selector:@selector(dataSyncAllWalletsAndAccount:)
                                                       userInfo:nil
                                                        repeats:YES];
    }
}

- (void)stopQueues
{
    if (exchangeTimer) {
        [exchangeTimer invalidate];
        exchangeTimer = nil;
    }
    if (dataSyncTimer) {
        [dataSyncTimer invalidate];
        dataSyncTimer = nil;
    }
    if (dataQueue)
        [dataQueue cancelAllOperations];
    if (walletsQueue)
        [walletsQueue cancelAllOperations];
    if (genQRQueue)
        [genQRQueue cancelAllOperations];
    if (txSearchQueue)
        [txSearchQueue cancelAllOperations];
    if (exchangeQueue)
        [exchangeQueue cancelAllOperations];
    if (miscQueue)
        [miscQueue cancelAllOperations];

}

- (void)postToDataQueue:(void(^)(void))cb;
{
    [dataQueue addOperationWithBlock:cb];
}

- (void)postToWalletsQueue:(void(^)(void))cb;
{
    [walletsQueue addOperationWithBlock:cb];
}

- (void)postToGenQRQueue:(void(^)(void))cb;
{
    [genQRQueue addOperationWithBlock:cb];
}

- (void)postToTxSearchQueue:(void(^)(void))cb;
{
    [txSearchQueue addOperationWithBlock:cb];
}

- (void)postToMiscQueue:(void(^)(void))cb;
{
    [miscQueue addOperationWithBlock:cb];
}

- (void)postToWatcherQueue:(void(^)(void))cb;
{
    [watcherQueue addOperationWithBlock:cb];
}

- (int)dataOperationCount
{
    int total = 0;
    total += dataQueue == nil     ? 0 : [dataQueue operationCount];
    total += exchangeQueue == nil ? 0 : [exchangeQueue operationCount];
    total += walletsQueue == nil  ? 0 : [walletsQueue operationCount];
    total += genQRQueue == nil  ? 0 : [genQRQueue operationCount];
    total += txSearchQueue == nil  ? 0 : [txSearchQueue operationCount];
    total += watcherQueue == nil  ? 0 : [watcherQueue operationCount];
    return total;
}

- (void)clearSyncQueue
{
    [dataQueue cancelAllOperations];
}

- (void)clearTxSearchQueue;
{
    [txSearchQueue cancelAllOperations];
}

- (void)clearMiscQueue;
{
    [miscQueue cancelAllOperations];
}

// select the wallet with the given UUID
- (Wallet *)selectWalletWithUUID:(NSString *)strUUID
{
    Wallet *wallet = nil;

    if (strUUID)
    {
        if ([strUUID length])
        {
            // If the transaction view is open, close it

            // look for the wallet in our arrays
            if (self.arrayWallets)
            {
                for (Wallet *curWallet in self.arrayWallets)
                {
                    if ([strUUID isEqualToString:curWallet.strUUID])
                    {
                        wallet = curWallet;
                        break;
                    }
                }
            }

            // if we haven't found it yet, try the archived wallets
            if (nil == wallet)
            {
                for (Wallet *curWallet in self.arrayArchivedWallets)
                {
                    if ([strUUID isEqualToString:curWallet.strUUID])
                    {
                        wallet = curWallet;
                        break;
                    }
                }
            }
        }
    }

    return wallet;
}

- (void)loadWalletUUIDs:(NSMutableArray *)arrayUUIDs
{
    tABC_Error Error;
    char **aUUIDS = NULL;
    unsigned int nCount;

    tABC_CC result = ABC_GetWalletUUIDs([self.name UTF8String],
                                        [self.password UTF8String],
                                        &aUUIDS, &nCount, &Error);
    if (ABC_CC_Ok == result)
    {
        if (aUUIDS)
        {
            unsigned int i;
            for (i = 0; i < nCount; ++i)
            {
                char *szUUID = aUUIDS[i];
                // If entry is NULL skip it
                if (!szUUID) {
                    continue;
                }
                [arrayUUIDs addObject:[NSString stringWithUTF8String:szUUID]];
                free(szUUID);
            }
            free(aUUIDS);
        }
    }
}

- (Wallet *)getWalletFromCore:(NSString *)uuid
{
    tABC_Error error;
    Wallet *wallet = [[Wallet alloc] init];
    wallet.strUUID = uuid;
    wallet.strName = loadingText;
    wallet.currencyNum = -1;
    wallet.balance = 0;
    wallet.loaded = NO;

    if ([self watcherExists:uuid]) {
        char *szName = NULL;
        ABC_WalletName([self.name UTF8String], [uuid UTF8String], &szName, &error);
        if (error.code == ABC_CC_Ok) {
            wallet.strName = [NSString safeStringWithUTF8String:szName];
        }
        if (szName) {
            free(szName);
        }

        int currencyNum;
        ABC_WalletCurrency([self.name UTF8String], [uuid UTF8String], &currencyNum, &error);
        if (error.code == ABC_CC_Ok) {
            wallet.currencyNum = currencyNum;
            wallet.currencyAbbrev = [self currencyAbbrevLookup:wallet.currencyNum];
            wallet.currencySymbol = [self currencySymbolLookup:wallet.currencyNum];
            wallet.loaded = YES;
        } else {
            wallet.loaded = NO;
            wallet.currencyNum = -1;
            wallet.strName = loadingText;
        }

        int64_t balance;
        ABC_WalletBalance([self.name UTF8String], [uuid UTF8String], &balance, &error);
        if (error.code == ABC_CC_Ok) {
            wallet.balance = balance;
        } else {
            wallet.balance = 0;
        }
    }

    bool archived = false;
    ABC_WalletArchived([self.name UTF8String], [uuid UTF8String], &archived, &error);
    wallet.archived = archived ? YES : NO;

    return wallet;
}

- (void)loadWallets:(NSMutableArray *)arrayWallets withTxs:(BOOL)bWithTx
{
    ABLog(2,@"ENTER loadWallets: %@", [NSThread currentThread].name);

    NSMutableArray *arrayUuids = [[NSMutableArray alloc] init];
    [self loadWalletUUIDs:arrayUuids];

    for (NSString *uuid in arrayUuids) {
        Wallet *wallet = [self getWalletFromCore:uuid];
        if (bWithTx && wallet.loaded) {
            [self loadTransactions:wallet];
        }
        [arrayWallets addObject:wallet];
    }
    ABLog(2,@"EXIT loadWallets: %@", [NSThread currentThread].name);

}

- (void)makeCurrentWallet:(Wallet *)wallet
{
    if ([self.arrayWallets containsObject:wallet])
    {
        self.currentWallet = wallet;
        self.currentWalletID = (int) [self.arrayWallets indexOfObject:self.currentWallet];
    }
    else if ([self.arrayArchivedWallets containsObject:wallet])
    {
        self.currentWallet = wallet;
        self.currentWalletID = (int) [self.arrayArchivedWallets indexOfObject:self.currentWallet];
    }

    [self postNotificationWalletsChanged];
}

- (void)makeCurrentWalletWithUUID:(NSString *)strUUID
{
    if ([self.arrayWallets containsObject:self.currentWallet])
    {
        Wallet *wallet = [self selectWalletWithUUID:strUUID];
        [self makeCurrentWallet:wallet];
    }
}

- (void)makeCurrentWalletWithIndex:(NSIndexPath *)indexPath
{
    //
    // Set new wallet. Hide the dropdown. Then reload the TransactionsView table
    //
    if(indexPath.section == 0)
    {
        if ([self.arrayWallets count] > indexPath.row)
        {
            self.currentWallet = [self.arrayWallets objectAtIndex:indexPath.row];
            self.currentWalletID = (int) [self.arrayWallets indexOfObject:self.currentWallet];

        }
    }
    else
    {
        if ([self.arrayArchivedWallets count] > indexPath.row)
        {
            self.currentWallet = [self.arrayArchivedWallets objectAtIndex:indexPath.row];
            self.currentWalletID = (int) [self.arrayArchivedWallets indexOfObject:self.currentWallet];
        }
    }

    [self postNotificationWalletsChanged];

}

- (void)cleanWallets
{
    self.arrayWallets = nil;
    self.arrayArchivedWallets = nil;
    self.arrayWalletNames = nil;
    self.arrayUUIDs = nil;
    self.currentWallet = nil;
    self.currentWalletID = 0;
    self.numWalletsLoaded = 0;
    self.numTotalWallets = 0;
    self.bAllWalletsLoaded = NO;
}

- (void)refreshWallets
{
    [self refreshWallets:nil];
}


- (void)refreshWallets:(void(^)(void))cb
{
    [self postToWatcherQueue:^(void) {
        [self postToWalletsQueue:^(void) {
            ABLog(2,@"ENTER refreshWallets WalletQueue: %@", [NSThread currentThread].name);
            NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
            NSMutableArray *arrayArchivedWallets = [[NSMutableArray alloc] init];
            NSMutableArray *arrayUUIDs = [[NSMutableArray alloc] init];
            NSMutableArray *arrayWalletNames = [[NSMutableArray alloc] init];

            [self loadWallets:arrayWallets archived:arrayArchivedWallets withTxs:true];
            [self loadWalletUUIDs:arrayUUIDs];

            //
            // Update wallet names for various dropdowns
            //
            int loadingCount = 0;
            for (int i = 0; i < [arrayWallets count]; i++)
            {
                Wallet *wallet = [arrayWallets objectAtIndex:i];
                [arrayWalletNames addObject:[NSString stringWithFormat:@"%@ (%@)", wallet.strName, [self formatSatoshi:wallet.balance]]];
                if (!wallet.loaded) {
                    loadingCount++;
                }
            }

            for (int i = 0; i < [arrayArchivedWallets count]; i++)
            {
                Wallet *wallet = [arrayArchivedWallets objectAtIndex:i];
                if (!wallet.loaded) {
                    loadingCount++;
                }
            }

            dispatch_async(dispatch_get_main_queue(),^{
                ABLog(2,@"ENTER refreshWallets MainQueue: %@", [NSThread currentThread].name);
                self.arrayWallets = arrayWallets;
                self.arrayArchivedWallets = arrayArchivedWallets;
                self.arrayUUIDs = arrayUUIDs;
                self.arrayWalletNames = arrayWalletNames;
                self.numTotalWallets = (int) ([arrayWallets count] + [arrayArchivedWallets count]);
                self.numWalletsLoaded = self.numTotalWallets  - loadingCount;

                if (loadingCount == 0)
                {
                    self.bAllWalletsLoaded = YES;
                }
                else
                {
                    self.bAllWalletsLoaded = NO;
                }

                if (nil == self.currentWallet)
                {
                    if ([self.arrayWallets count] > 0)
                    {
                        self.currentWallet = [arrayWallets objectAtIndex:0];
                    }
                    self.currentWalletID = 0;
                }
                else
                {
                    NSString *lastCurrentWalletUUID = self.currentWallet.strUUID;
                    self.currentWallet = [self selectWalletWithUUID:lastCurrentWalletUUID];
                    self.currentWalletID = (int) [self.arrayWallets indexOfObject:self.currentWallet];
                }
                [self checkWalletsLoadingNotification];
                [self postNotificationWalletsChanged];

                ABLog(2,@"EXIT refreshWallets MainQueue: %@", [NSThread currentThread].name);

                if (cb) cb();

            });
            ABLog(2,@"EXIT refreshWallets WalletQueue: %@", [NSThread currentThread].name);
        }];
    }];
}

//
// Will send a notification if at least the primary wallet is loaded
// In the case of a new device login, this will post a notification ONLY if all wallets are loaded
// AND no updates have come in from the core in walletLoadingTimerInterval of time. (about 10 seconds).
// This is a guesstimate of how long to wait before assuming a new device is synced on initial login.
//
- (void)checkWalletsLoadingNotification
{
    if (bNewDeviceLogin)
    {
        if (!self.bAllWalletsLoaded)
        {
            //
            // Wallets are loading from Git
            //
            [self postWalletsLoadingNotification];
        }
        else
        {
            //
            // Wallets are *kinda* loaded now. At least they're loaded from Git. But transactions still have to
            // be loaded from the blockchain. Hack: set a timer that checks if we've received a WALLETS_CHANGED update
            // within the past 15 seconds. If not, then assume the wallets have all been fully synced. If we get an
            // update, then reset the timer and wait another 10 seconds.
            //
            [self postWalletsLoadingNotification];
            if (self.walletLoadingTimer)
            {
                [self.walletLoadingTimer invalidate];
                self.walletLoadingTimer = nil;
            }
            ABLog(1, @"************************************************");
            ABLog(1, @"*** Received Packet from Core. Reset timer******");
            ABLog(1, @"************************************************");
            self.walletLoadingTimer = [NSTimer scheduledTimerWithTimeInterval:[Theme Singleton].walletLoadingTimerInterval
                                                                       target:self
                                                                     selector:@selector(postWalletsLoadedNotification)
                                                                     userInfo:nil
                                                                      repeats:NO];
        }

    }
    else
    {
        ABLog(1, [NSString stringWithFormat:@"************ numWalletsLoaded=%d", self.numWalletsLoaded]);
        if (!self.arrayWallets || self.numWalletsLoaded == 0)
            [self postWalletsLoadingNotification];
        else
            [self postWalletsLoadedNotification];

    }
}

- (void)postWalletsLoadingNotification
{
    ABLog(1, [NSString stringWithFormat:@"postWalletsLoading numWalletsLoaded=%d", self.numWalletsLoaded]);
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_WALLETS_LOADING object:self];
}

- (void)postWalletsLoadedNotification
{
    bNewDeviceLogin = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_WALLETS_LOADED object:self];
}

- (void) postNotificationWalletsChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_WALLETS_CHANGED
                                                        object:self userInfo:nil];
    [self updateWidgetQRCode];
}


- (void)loadWallets:(NSMutableArray *)arrayWallets archived:(NSMutableArray *)arrayArchivedWallets withTxs:(BOOL)bWithTx
{
    [self loadWallets:arrayWallets withTxs:bWithTx];

    // go through all the wallets and seperate out the archived ones
    for (int i = (int) [arrayWallets count] - 1; i >= 0; i--)
    {
        Wallet *wallet = [arrayWallets objectAtIndex:i];

        // if this is an archived wallet
        if ([wallet isArchived])
        {
            // add it to the archive wallet
            if (arrayArchivedWallets != nil)
            {
                [arrayArchivedWallets insertObject:wallet atIndex:0];
            }

            // remove it from the standard wallets
            [arrayWallets removeObjectAtIndex:i];
        }
    }
}
//
// This triggers a switch of libbitcoin servers and possibly an update if new information comes in
//
- (void)rotateWalletServer:(NSString *)walletUUID refreshData:(BOOL)bData notify:(void(^)(void))cb
{
    [self connectWatcher:walletUUID];
    [self postToMiscQueue:^{
        // Reconnect the watcher for this wallet
        if (bData) {
            // Clear data sync queue and sync the current wallet immediately
            [dataQueue cancelAllOperations];
            [dataQueue addOperationWithBlock:^{
                if (![User isLoggedIn]) {
                    return;
                }
                tABC_Error error;
                ABC_DataSyncWallet([self.name UTF8String],
                            [self.password UTF8String],
                            [walletUUID UTF8String],
                            ABC_BitCoin_Event_Callback,
                            (__bridge void *) self,
                            &error);
                [self setLastErrors:error];
                dispatch_async(dispatch_get_main_queue(),^{
                    if (cb) cb();
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(),^{
                if (cb) cb();
            });
        }
    }];
}

- (Wallet *)getWallet: (NSString *)walletUUID
{
    for (Wallet *w in self.arrayWallets)
    {
        if ([w.strUUID isEqualToString:walletUUID])
            return w;
    }
    for (Wallet *w in self.arrayArchivedWallets)
    {
        if ([w.strUUID isEqualToString:walletUUID])
            return w;
    }
    return nil;
}

- (Transaction *)getTransaction: (NSString *)walletUUID withTx:(NSString *) szTxId;
{
    tABC_Error Error;
    Transaction *transaction = nil;
    tABC_TxInfo *pTrans = NULL;
    Wallet *wallet = [self getWallet: walletUUID];
    if (wallet == nil)
    {
        ABLog(2,@("Could not find wallet for %@"), walletUUID);
        return nil;
    }
    tABC_CC result = ABC_GetTransaction([self.name UTF8String],
                                        [self.password UTF8String],
                                        [walletUUID UTF8String], [szTxId UTF8String],
                                        &pTrans, &Error);
    if (ABC_CC_Ok == result)
    {
        transaction = [[Transaction alloc] init];
        [self setTransaction: wallet transaction:transaction coreTx:pTrans];
    }
    else
    {
        ABLog(2,@("Error: CoreBridge.loadTransactions:  %s\n"), Error.szDescription);
        [self setLastErrors:Error];
    }
    ABC_FreeTransaction(pTrans);
    return transaction;
}

- (int64_t)getTotalSentToday:(Wallet *)wallet
{
    int64_t total = 0;

    if ([wallet.arrayTransactions count] == 0)
        return 0;

    for (Transaction *t in wallet.arrayTransactions)
    {
        if ([[NSCalendar currentCalendar] isDateInToday:t.date])
        {
            if (t.amountSatoshi < 0)
            {
                total += t.amountSatoshi * -1;
            }
        }
    }
    return total;

}

- (void) loadTransactions: (Wallet *) wallet
{
    tABC_Error Error;
    unsigned int tCount = 0;
    Transaction *transaction;
    tABC_TxInfo **aTransactions = NULL;
    tABC_CC result = ABC_GetTransactions([self.name UTF8String],
                                         [self.password UTF8String],
                                         [wallet.strUUID UTF8String],
                                         ABC_GET_TX_ALL_TIMES,
                                         ABC_GET_TX_ALL_TIMES, 
                                         &aTransactions,
                                         &tCount, &Error);
    if (ABC_CC_Ok == result)
    {
        NSMutableArray *arrayTransactions = [[NSMutableArray alloc] init];

        for (int j = tCount - 1; j >= 0; --j)
        {
            tABC_TxInfo *pTrans = aTransactions[j];
            transaction = [[Transaction alloc] init];
            [self setTransaction:wallet transaction:transaction coreTx:pTrans];
            [arrayTransactions addObject:transaction];
        }
        SInt64 bal = 0;
        for (int j = (int) arrayTransactions.count - 1; j >= 0; --j)
        {
            Transaction *t = arrayTransactions[j];
            bal += t.amountSatoshi;
            t.balance = bal;
        }
        wallet.arrayTransactions = arrayTransactions;
        wallet.balance = bal;
    }
    else
    {
        ABLog(2,@("Error: CoreBridge.loadTransactions:  %s\n"), Error.szDescription);
        [self setLastErrors:Error];
    }
    ABC_FreeTransactions(aTransactions, tCount);
}

- (void)setTransaction:(Wallet *) wallet transaction:(Transaction *) transaction coreTx:(tABC_TxInfo *) pTrans
{
    transaction.strID = [NSString stringWithUTF8String: pTrans->szID];
    transaction.strName = [NSString stringWithUTF8String: pTrans->pDetails->szName];
    transaction.strNotes = [NSString stringWithUTF8String: pTrans->pDetails->szNotes];
    transaction.strCategory = [NSString stringWithUTF8String: pTrans->pDetails->szCategory];
    transaction.date = [self dateFromTimestamp: pTrans->timeCreation];
    transaction.amountSatoshi = pTrans->pDetails->amountSatoshi;
    transaction.amountFiat = pTrans->pDetails->amountCurrency;
    transaction.abFees = pTrans->pDetails->amountFeesAirbitzSatoshi;
    transaction.minerFees = pTrans->pDetails->amountFeesMinersSatoshi;
    transaction.strWalletName = wallet.strName;
    transaction.strWalletUUID = wallet.strUUID;
    if (pTrans->szMalleableTxId) {
        transaction.strMallealbeID = [NSString stringWithUTF8String: pTrans->szMalleableTxId];
    }
    bool bSyncing = NO;
    transaction.confirmations = [self calcTxConfirmations:wallet
                                                 withTxId:transaction.strID
                                                isSyncing:&bSyncing];
    transaction.bConfirmed = transaction.confirmations >= CONFIRMED_CONFIRMATION_COUNT;
    transaction.bSyncing = bSyncing;
    if (transaction.strName) {
        transaction.strAddress = transaction.strName;
    } else {
        transaction.strAddress = @"";
    }
    NSMutableArray *outputs = [[NSMutableArray alloc] init];
    for (int i = 0; i < pTrans->countOutputs; ++i)
    {
        TxOutput *output = [[TxOutput alloc] init];
        output.strAddress = [NSString stringWithUTF8String: pTrans->aOutputs[i]->szAddress];
        output.bInput = pTrans->aOutputs[i]->input;
        output.value = pTrans->aOutputs[i]->value;

        [outputs addObject:output];
    }
    transaction.outputs = outputs;
    transaction.bizId = pTrans->pDetails->bizId;
}

- (int)calcTxConfirmations:(Wallet *) wallet withTxId:(NSString *)txId isSyncing:(bool *)syncing
{
    tABC_Error Error;
    int txHeight = 0;
    int blockHeight = 0;
    *syncing = NO;
    if ([wallet.strUUID length] == 0 || [txId length] == 0) {
        return 0;
    }
    if (ABC_TxHeight([wallet.strUUID UTF8String], [txId UTF8String], &txHeight, &Error) != ABC_CC_Ok) {
        *syncing = YES;
        if (txHeight < 0)
        {
            ABLog(0, @"calcTxConfirmations returning negative txHeight=%d", txHeight);
            return txHeight;
        }
        else
            return 0;
    }
    if (ABC_BlockHeight([wallet.strUUID UTF8String], &blockHeight, &Error) != ABC_CC_Ok) {
        *syncing = YES;
        return 0;
    }
    if (txHeight == 0 || blockHeight == 0) {
        return 0;
    }
    
    int retHeight = (blockHeight - txHeight) + 1;
    
    if (retHeight < 0)
    {
        retHeight = 0;
    }
    return retHeight;
}

- (NSMutableArray *)searchTransactionsIn: (Wallet *) wallet query:(NSString *)term addTo:(NSMutableArray *) arrayTransactions
{
    tABC_Error Error;
    unsigned int tCount = 0;
    Transaction *transaction;
    tABC_TxInfo **aTransactions = NULL;
    tABC_CC result = ABC_SearchTransactions([self.name UTF8String],
                                            [self.password UTF8String],
                                            [wallet.strUUID UTF8String], [term UTF8String],
                                            &aTransactions, &tCount, &Error);
    if (ABC_CC_Ok == result)
    {
        for (int j = tCount - 1; j >= 0; --j) {
            tABC_TxInfo *pTrans = aTransactions[j];
            transaction = [[Transaction alloc] init];
            [self setTransaction:wallet transaction:transaction coreTx:pTrans];
            [arrayTransactions addObject:transaction];
        }
    }
    else 
    {
        ABLog(2,@("Error: CoreBridge.searchTransactionsIn:  %s\n"), Error.szDescription);
        [self setLastErrors:Error];
    }
    ABC_FreeTransactions(aTransactions, tCount);
    return arrayTransactions;
}

- (void)reorderWallets: (NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    tABC_Error Error;
    Wallet *wallet;
    if(sourceIndexPath.section == 0)
    {
        wallet = [self.arrayWallets objectAtIndex:sourceIndexPath.row];
        [self.arrayWallets removeObjectAtIndex:sourceIndexPath.row];
    }
    else
    {
        wallet = [self.arrayArchivedWallets objectAtIndex:sourceIndexPath.row];
        [self.arrayArchivedWallets removeObjectAtIndex:sourceIndexPath.row];
    }

    if(destinationIndexPath.section == 0)
    {
        wallet.archived = NO;
        [self.arrayWallets insertObject:wallet atIndex:destinationIndexPath.row];

    }
    else
    {
        wallet.archived = YES;
        [self.arrayArchivedWallets insertObject:wallet atIndex:destinationIndexPath.row];
    }

    if (sourceIndexPath.section != destinationIndexPath.section)
    {
        // Wallet moved to/from archive. Reset attributes to Core
        [self setWalletAttributes:wallet];
    }

    NSMutableString *uuids = [[NSMutableString alloc] init];
    for (Wallet *w in self.arrayWallets)
    {
        [uuids appendString:w.strUUID];
        [uuids appendString:@"\n"];
    }
    for (Wallet *w in self.arrayArchivedWallets)
    {
        [uuids appendString:w.strUUID];
        [uuids appendString:@"\n"];
    }

    NSString *ids = [uuids stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (ABC_SetWalletOrder([self.name UTF8String],
                           [self.password UTF8String],
                           (char *)[ids UTF8String],
                           &Error) != ABC_CC_Ok)
    {
        ABLog(2,@("Error: CoreBridge.reorderWallets:  %s\n"), Error.szDescription);
        [self setLastErrors:Error];
    }

    [self refreshWallets];
}

- (bool)setWalletAttributes: (Wallet *) wallet
{
    tABC_Error Error;
    tABC_CC result = ABC_SetWalletArchived([self.name UTF8String],
                                           [self.password UTF8String],
                                           [wallet.strUUID UTF8String],
                                           wallet.archived, &Error);
    if (ABC_CC_Ok == result)
    {
        return true;
    }
    else
    {
        ABLog(2,@("Error: CoreBridge.setWalletAttributes:  %s\n"), Error.szDescription);
        [self setLastErrors:Error];
        return false;
    }
}

- (void)storeTransaction:(Transaction *)transaction
{
    [self postToMiscQueue:^{

        tABC_Error Error;
        tABC_TxDetails *pDetails;
        tABC_CC result = ABC_GetTransactionDetails([self.name UTF8String],
                [self.password UTF8String],
                [transaction.strWalletUUID UTF8String],
                [transaction.strID UTF8String],
                &pDetails, &Error);
        if (ABC_CC_Ok != result) {
            ABLog(2,@("Error: CoreBridge.storeTransaction:  %s\n"), Error.szDescription);
            [self setLastErrors:Error];
//            return false;
            return;
        }

        pDetails->szName = (char *) [transaction.strName UTF8String];
        pDetails->szCategory = (char *) [transaction.strCategory UTF8String];
        pDetails->szNotes = (char *) [transaction.strNotes UTF8String];
        pDetails->amountCurrency = transaction.amountFiat;
        pDetails->bizId = transaction.bizId;

        result = ABC_SetTransactionDetails([self.name UTF8String],
                [self.password UTF8String],
                [transaction.strWalletUUID UTF8String],
                [transaction.strID UTF8String],
                pDetails, &Error);

        if (ABC_CC_Ok != result) {
            ABLog(2,@("Error: CoreBridge.storeTransaction:  %s\n"), Error.szDescription);
            [self setLastErrors:Error];
//            return false;
            return;
        }

        [self refreshWallets];
//        return true;
        return;
    }];

    return; // This might as well be a void. async task return value can't ever really be tested
}

- (NSNumberFormatter *)generateNumberFormatter
{
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setMinimumFractionDigits:2];
    [f setMaximumFractionDigits:2];
    [f setLocale:[NSLocale localeWithLocaleIdentifier:@"USD"]];
    return f;
}

- (NSDate *)dateFromTimestamp:(int64_t) intDate
{
    return [NSDate dateWithTimeIntervalSince1970: intDate];
}

- (NSString *)formatCurrency:(double) currency withCurrencyNum:(int) currencyNum
{
    return [self formatCurrency:currency withCurrencyNum:currencyNum withSymbol:true];
}

- (NSString *)formatCurrency:(double) currency withCurrencyNum:(int) currencyNum withSymbol:(bool) symbol
{
    NSNumberFormatter *f = [self generateNumberFormatter];
    [f setNumberStyle: NSNumberFormatterCurrencyStyle];
    if (symbol) {
        NSString *symbol = [self currencySymbolLookup:currencyNum];
        [f setNegativePrefix:[NSString stringWithFormat:@"-%@ ",symbol]];
        [f setNegativeSuffix:@""];
        [f setCurrencySymbol:[NSString stringWithFormat:@"%@ ", symbol]];
    } else {
        [f setCurrencySymbol:@""];
    }
    return [f stringFromNumber:[NSNumber numberWithFloat:currency]];
}

- (int) currencyDecimalPlaces
{
    int decimalPlaces = 5;
    switch (self.settings.denominationType) {
        case ABC_DENOMINATION_BTC:
            decimalPlaces = 6;
            break;
        case ABC_DENOMINATION_MBTC:
            decimalPlaces = 3;
            break;
        case ABC_DENOMINATION_UBTC:
            decimalPlaces = 0;
            break;
    }
    return decimalPlaces;
}

- (int) maxDecimalPlaces
{
    int decimalPlaces = 8;
    switch (self.settings.denominationType) {
        case ABC_DENOMINATION_BTC:
            decimalPlaces = 8;
            break;
        case ABC_DENOMINATION_MBTC:
            decimalPlaces = 5;
            break;
        case ABC_DENOMINATION_UBTC:
            decimalPlaces = 2;
            break;
    }
    return decimalPlaces;
}

- (int64_t) cleanNumString:(NSString *) value
{
    NSNumberFormatter *f = [self generateNumberFormatter];
    NSNumber *num = [f numberFromString:value];
    return [num longLongValue];
}

- (NSString *)formatSatoshi: (int64_t) amount
{
    return [self formatSatoshi:amount withSymbol:true];
}

- (NSString *)formatSatoshi: (int64_t) amount withSymbol:(bool) symbol
{
    return [self formatSatoshi:amount withSymbol:symbol cropDecimals:-1];
}

- (NSString *)formatSatoshi: (int64_t) amount withSymbol:(bool) symbol forceDecimals:(int) forcedecimals
{
    return [self formatSatoshi:amount withSymbol:symbol cropDecimals:-1 forceDecimals:forcedecimals];
}

- (NSString *)formatSatoshi: (int64_t) amount withSymbol:(bool) symbol cropDecimals:(int) decimals
{
    return [self formatSatoshi:amount withSymbol:symbol cropDecimals:decimals forceDecimals:-1];
}

/** 
 * formatSatoshi 
 *  
 * forceDecimals specifies the number of decimals to shift to 
 * the left when converting from satoshi to BTC/mBTC/uBTC etc. 
 * ie. for BTC decimals = 8 
 *  
 * formatSatoshi will use the settings by default if 
 * forceDecimals is not supplied 
 *  
 * cropDecimals will crop the maximum number of digits to the 
 * right of the decimal. cropDecimals = 3 will make 
 * "1234.12345" -> "1234.123"
 *  
**/

- (NSString *)formatSatoshi: (int64_t) amount withSymbol:(bool) symbol cropDecimals:(int) decimals forceDecimals:(int) forcedecimals
{
    tABC_Error error;
    char *pFormatted = NULL;
    int decimalPlaces = forcedecimals > -1 ? forcedecimals : [self maxDecimalPlaces];
    bool negative = amount < 0;
    amount = llabs(amount);
    if (ABC_FormatAmount(amount, &pFormatted, decimalPlaces, false, &error) != ABC_CC_Ok)
    {
        return nil;
    }
    else
    {
        decimalPlaces = decimals > -1 ? decimals : decimalPlaces;
        NSMutableString *formatted = [[NSMutableString alloc] init];
        if (negative)
            [formatted appendString: @"-"];
        if (symbol)
        {
            [formatted appendString: self.settings.denominationLabelShort];
            [formatted appendString: @" "];
        }
        const char *p = pFormatted;
        const char *decimal = strstr(pFormatted, ".");
        const char *start = (decimal == NULL) ? p + strlen(p) : decimal;
        int offset = (start - pFormatted) % 3;
        NSNumberFormatter *f = [self generateNumberFormatter];

        for (int i = 0; i < strlen(pFormatted) && p - start <= decimalPlaces; ++i, ++p)
        {
            if (p < start)
            {
                if (i != 0 && (i - offset) % 3 == 0)
                    [formatted appendString:[f groupingSeparator]];
                [formatted appendFormat: @"%c", *p];
            }
            else if (p == decimal)
                [formatted appendString:[f currencyDecimalSeparator]];
            else
                [formatted appendFormat: @"%c", *p];
        }
        free(pFormatted);
        return formatted;
    }
}

- (int64_t) denominationToSatoshi: (NSString *) amount
{
    uint64_t parsedAmount;
    int decimalPlaces = [self maxDecimalPlaces];
    NSString *cleanAmount = [amount stringByReplacingOccurrencesOfString:@"," withString:@""];
    if (ABC_ParseAmount([cleanAmount UTF8String], &parsedAmount, decimalPlaces) != ABC_CC_Ok) {
    }
    return (int64_t) parsedAmount;
}

- (NSString *)conversionString:(Wallet *) wallet
{
    return [self conversionStringFromNum:wallet.currencyNum withAbbrev:YES];
}

- (NSString *)conversionStringFromNum:(int) currencyNum withAbbrev:(bool) includeAbbrev
{
    double currency;
    tABC_Error error;

    double denomination = self.settings.denomination;
    NSString *denominationLabel = self.settings.denominationLabel;
    tABC_CC result = ABC_SatoshiToCurrency([self.name UTF8String],
                                           [self.password UTF8String],
                                           denomination, &currency, currencyNum, &error);
    [self setLastErrors:error];
    if (result == ABC_CC_Ok)
    {
        NSString *abbrev = [self currencyAbbrevLookup:currencyNum];
        NSString *symbol = [self currencySymbolLookup:currencyNum];
        if (self.settings.denominationType == ABC_DENOMINATION_UBTC)
        {
            if(includeAbbrev) {
                return [NSString stringWithFormat:@"1000 %@ = %@ %.3f %@", denominationLabel, symbol, currency*1000, abbrev];
            }
            else
            {
                return [NSString stringWithFormat:@"1000 %@ = %@ %.3f", denominationLabel, symbol, currency*1000];
            }
        }
        else
        {
            if(includeAbbrev) {
                return [NSString stringWithFormat:@"1 %@ = %@ %.3f %@", denominationLabel, symbol, currency, abbrev];
            }
            else
            {
                return [NSString stringWithFormat:@"1 %@ = %@ %.3f", denominationLabel, symbol, currency];
            }
        }
    }
    else
    {
        return @"";
    }
}

// gets the recover questions for a given account
// nil is returned if there were no questions for this account
- (NSArray *)getRecoveryQuestionsForUserName:(NSString *)strUserName
                                   isSuccess:(BOOL *)bSuccess
                                    errorMsg:(NSMutableString *)error
{
    NSMutableArray *arrayQuestions = nil;
    char *szQuestions = NULL;

    *bSuccess = NO; 
    tABC_Error Error;
    tABC_CC result = ABC_GetRecoveryQuestions([strUserName UTF8String],
                                              &szQuestions,
                                              &Error);
    if (ABC_CC_Ok == result)
    {
        if (szQuestions && strlen(szQuestions))
        {
            // create an array of strings by pulling each question that is seperated by a newline
            arrayQuestions = [[NSMutableArray alloc] initWithArray:[[NSString stringWithUTF8String:szQuestions] componentsSeparatedByString: @"\n"]];
            // remove empties
            [arrayQuestions removeObject:@""];
            *bSuccess = YES; 
        }
        else
        {
            [error appendString:NSLocalizedString(@"This user does not have any recovery questions set!", nil)];
            *bSuccess = NO; 
        }
    }
    else
    {
        [error appendString:[Util errorMap:&Error]];
        [self setLastErrors:Error];
    }

    if (szQuestions)
    {
        free(szQuestions);
    }

    return arrayQuestions;
}

- (void)incRecoveryReminder
{
    [self incRecoveryReminder:1];
}

- (void)clearRecoveryReminder
{
    [self incRecoveryReminder:RECOVERY_REMINDER_COUNT];
}

- (void)incRecoveryReminder:(int)val
{
    tABC_Error error;
    tABC_AccountSettings *pSettings = NULL;
    tABC_CC cc = ABC_LoadAccountSettings([self.name UTF8String],
        [self.password UTF8String], &pSettings, &error);
    if (cc == ABC_CC_Ok) {
        pSettings->recoveryReminderCount += val;
        ABC_UpdateAccountSettings([self.name UTF8String],
            [self.password UTF8String], pSettings, &error);
    }
    ABC_FreeAccountSettings(pSettings);
}

- (int)getReminderCount
{
    int count = 0;
    tABC_Error error;
    tABC_AccountSettings *pSettings = NULL;
    tABC_CC cc = ABC_LoadAccountSettings([self.name UTF8String],
        [self.password UTF8String], &pSettings, &error);
    if (cc == ABC_CC_Ok) {
        count = pSettings->recoveryReminderCount;
    }
    ABC_FreeAccountSettings(pSettings);
    return count;
}

- (BOOL)needsRecoveryQuestionsReminder:(Wallet *)wallet
{
    BOOL bResult = NO;
    int reminderCount = [self getReminderCount];
    if (wallet.balance >= RECOVERY_REMINDER_AMOUNT && reminderCount < RECOVERY_REMINDER_COUNT) {
        BOOL bQuestions = NO;
        NSMutableString *errorMsg = [[NSMutableString alloc] init];
        [self getRecoveryQuestionsForUserName:self.name
                                            isSuccess:&bQuestions
                                            errorMsg:errorMsg];
        if (!bQuestions) {
            [self incRecoveryReminder];
            bResult = YES;
        } else {
            [self clearRecoveryReminder];
        }
    }
    return bResult;
}

- (bool)PINLoginExists:(NSString *)username
{
    bool exists = NO;

    if (username && 0 < username.length)
    {
        tABC_Error error;
        ABC_PinLoginExists([username UTF8String], &exists, &error);
        if (ABC_CC_Ok != error.code)
        {
            [self printABC_Error:&error];
        }
        [self setLastErrors:error];

    }
    return exists;
}


- (void)deletePINLogin
{
    NSString *username = NULL;
    if ([User isLoggedIn])
    {
        username = self.name;
    }

    if (!username || 0 == username.length)
    {
        username = [LocalSettings controller].cachedUsername;
    }

    tABC_Error error;
    if (username && 0 < username.length)
    {
        tABC_CC result = ABC_PinLoginDelete([username UTF8String],
                                            &error);
        if (ABC_CC_Ok != result)
        {
            [self setLastErrors:error];
        }
    }
}

- (void)setupLoginPIN
{
    if (!self.settings.bDisablePINLogin)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
            tABC_Error error;
            ABC_PinSetup([self.name UTF8String],
                         [self.password length] > 0 ? [self.password UTF8String] : nil,
                         &error);
        });
    }
}

- (BOOL)recentlyLoggedIn
{
    long now = (long) [[NSDate date] timeIntervalSince1970];
    return now - iLoginTimeSeconds <= PIN_REQUIRED_PERIOD_SECONDS;
}

- (void)loginCommon
{
    dispatch_async(dispatch_get_main_queue(),^{
        [self postWalletsLoadingNotification];
    });
    [self loadCategories];
    [self loadSettings];
    [self requestExchangeRateUpdate:nil];

    //
    // Do the following for first wallet then all others
    //
    // ABC_WalletLoad
    // ABC_WatcherLoop
    // ABC_WatchAddresses
    //
    // This gets the app up and running and all prior transactions viewable with no new updates
    // From the network
    //
    [self startAllWallets];   // Goes to watcherQueue

    //
    // Next issue one dataSync for each wallet and account
    // This makes sure we have updated git sync data from other devices
    //
    [self postToWatcherQueue: ^
    {
        // Goes to dataQueue after watcherQueue is complete from above
        [self dataSyncAllWalletsAndAccount:nil];

        //
        // Start the watchers to grab new blockchain transaction data. Do this AFTER git sync
        // So that new transactions will have proper meta data if other devices already tagged them
        //
        [self postToDataQueue:^
         {
             // Goes to watcherQueue after dataQueue is complete from above
             [self connectWatchers];
         }];
    }];

    //
    // Last, start the timers so we get repeated exchange rate updates and data syncs
    //
    [self postToWatcherQueue: ^
     {
         // Starts only after connectWatchers finishes from watcherQueue
         [self startQueues];
         
         iLoginTimeSeconds = [self saveLogoutDate];
         [self loadCategories];
         [self refreshWallets];
     }];
}

- (BOOL)didLoginExpire:(NSString *)username;
{
    //
    // If app was killed then the static var logoutTimeStamp will be zero so we'll pull the cached value
    // from the iOS Keychain. Also, on non A7 processors, we won't save anything in the keychain so we need
    // the static var to take care of cases where app is not killed.
    //
    if (0 == logoutTimeStamp)
    {
        logoutTimeStamp = [Keychain getKeychainInt:[Keychain createKeyWithUsername:[LocalSettings controller].cachedUsername key:LOGOUT_TIME_KEY] error:nil];
    }

    if (!logoutTimeStamp) return YES;

    long long currentTimeStamp = [[NSDate date] timeIntervalSince1970];

    if (currentTimeStamp > logoutTimeStamp)
    {
        return YES;
    }

    return NO;
}

//
// Saves the UNIX timestamp when user should be auto logged out
// Returns the current time
//

- (long) saveLogoutDate;
{
    long currentTimeStamp = (long) [[NSDate date] timeIntervalSince1970];
    logoutTimeStamp = currentTimeStamp + (60 * self.settings.minutesAutoLogout);

    // Save in iOS Keychain
    [Keychain setKeychainInt:logoutTimeStamp
                         key:[Keychain createKeyWithUsername:self.name key:LOGOUT_TIME_KEY]
               authenticated:YES];

    return currentTimeStamp;
}

//- (void)startPrimaryWallet;
//{
//    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
//    [self loadWalletUUIDs: arrayWallets];
//    if (0 < [arrayWallets count]) {
//        NSString *uuid = arrayWallets[0];
//        [self postToWatcherQueue:^{
//            tABC_Error error;
//            ABC_WalletLoad([self.name UTF8String], [uuid UTF8String], &error);
//            [self setLastErrors:error];
//            [self startWatcher:uuid];
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self refreshWallets];
//            });
//        }];
//    }
//}

- (void)startAllWallets
{
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [self loadWalletUUIDs: arrayWallets];
    for (NSString *uuid in arrayWallets) {
        [self postToWatcherQueue:^{
            tABC_Error error;
            ABC_WalletLoad([self.name UTF8String], [uuid UTF8String], &error);
            [self setLastErrors:error];
        }];
        [self startWatcher:uuid];
        [self refreshWallets]; // Also goes to watcher queue.
    }
}

- (void)stopAsyncTasks
{
    [self stopQueues];

    unsigned long wq, dq, gq, txq, eq, mq;

    // XXX: prevents crashing on logout
    while (YES)
    {
        wq = (unsigned long)[walletsQueue operationCount];
        dq = (unsigned long)[dataQueue operationCount];
        gq = (unsigned long)[genQRQueue operationCount];
        txq = (unsigned long)[txSearchQueue operationCount];
        eq = (unsigned long)[exchangeQueue operationCount];
        mq = (unsigned long)[miscQueue operationCount];

//        if (0 == (wq + dq + gq + txq + eq + mq + lq))
        if (0 == (wq + gq + txq + eq + mq))
            break;

        ABLog(0,
            @"Waiting for queues to complete wq=%lu dq=%lu gq=%lu txq=%lu eq=%lu mq=%lu",
            wq, dq, gq, txq, eq, mq);
        [NSThread sleepForTimeInterval:.2];
    }

    [self stopWatchers];
    [self cleanWallets];
}

- (void)logout
{
    [self stopAsyncTasks];

    tABC_Error Error;
    tABC_CC result = ABC_ClearKeyCache(&Error);

    if (ABC_CC_Ok != result)
    {
        [self setLastErrors:Error];
    }
    self.password = nil;
    self.name = nil;

}

- (BOOL)passwordOk:(NSString *)password
{
    NSString *name = self.name;
    bool ok = false;
    if (name && 0 < name.length)
    {
        const char *username = [name UTF8String];

        tABC_Error Error;
        ABC_PasswordOk(username, [password UTF8String], &ok, &Error);
        [self setLastErrors:Error];
    }
    return ok == true ? YES : NO;
}

- (BOOL)passwordExists
{
    return [self passwordExists:self.name];
}

- (BOOL)passwordExists:(NSString *)username;
{
    tABC_Error error;
    bool exists = false;
    ABC_PasswordExists([username UTF8String], &exists, &error);
    if (error.code == ABC_CC_Ok) {
        return exists == true ? YES : NO;
    }
    return YES;
}

- (BOOL)allWatchersReady
{
    return YES;
}

- (BOOL)watcherIsReady:(NSString *)UUID
{
    return YES;
}

- (void)startWatchers
{
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [self loadWalletUUIDs: arrayWallets];
    for (NSString *uuid in arrayWallets) {
        [self startWatcher:uuid];
    }
    [self connectWatchers];
}

- (void)connectWatchers
{
    if ([User isLoggedIn]) {
        NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
        [self loadWalletUUIDs:arrayWallets];
        for (NSString *uuid in arrayWallets)
        {
            [self connectWatcher:uuid];
        }
    }
}

- (void)connectWatcher:(NSString *)uuid
{
    [self postToWatcherQueue: ^{
        if ([User isLoggedIn]) {
            tABC_Error Error;
            ABC_WatcherConnect([uuid UTF8String], &Error);

            [self setLastErrors:Error];
            [self watchAddresses:uuid];
        }
    }];
}

- (void)disconnectWatchers
{
    if ([User isLoggedIn])
    {
        NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
        [self loadWalletUUIDs: arrayWallets];
        for (NSString *uuid in arrayWallets) {
            [self postToWatcherQueue: ^{
                const char *szUUID = [uuid UTF8String];
                tABC_Error Error;
                ABC_WatcherDisconnect(szUUID, &Error);
                [self setLastErrors:Error];
            }];
        }
    }
}

- (BOOL)watcherExists:(NSString *)uuid
{
    [watcherLock lock];
    BOOL exists = [watchers objectForKey:uuid] == nil ? NO : YES;
    [watcherLock unlock];
    return exists;
}

- (NSOperationQueue *)watcherGet:(NSString *)uuid
{
    [watcherLock lock];
    NSOperationQueue *queue = [watchers objectForKey:uuid];
    [watcherLock unlock];
    return queue;
}

- (void)watcherSet:(NSString *)uuid queue:(NSOperationQueue *)queue
{
    [watcherLock lock];
    [watchers setObject:queue forKey:uuid];
    [watcherLock unlock];
}

- (void)watcherRemove:(NSString *)uuid
{
    [watcherLock lock];
    [watchers removeObjectForKey:uuid];
    [watcherLock unlock];
}

- (void)startWatcher:(NSString *) walletUUID
{
    [self postToWatcherQueue: ^{
        if (![self watcherExists:walletUUID]) {
            tABC_Error Error;
            const char *szUUID = [walletUUID UTF8String];
            ABC_WatcherStart([self.name UTF8String],
                            [self.password UTF8String],
                            szUUID, &Error);
            [self setLastErrors:Error];

            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            [self watcherSet:walletUUID queue:queue];
            [queue addOperationWithBlock:^{
                [queue setName:walletUUID];
                tABC_Error Error;
                ABC_WatcherLoop([walletUUID UTF8String],
                        ABC_BitCoin_Event_Callback,
                        (__bridge void *) self,
                        &Error);
                [self setLastErrors:Error];
            }];

            [self watchAddresses:walletUUID];
//            if (bAllWalletsHaveBeenDataSynced) {
//                [self connectWatcher:walletUUID];
//            }
//            [self requestWalletDataSync:walletUUID];
        }
    }];
}

- (void)stopWatchers
{
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [self loadWalletUUIDs: arrayWallets];
    // stop watchers
    [self postToWatcherQueue: ^{
        for (NSString *uuid in arrayWallets) {
            tABC_Error Error;
            ABC_WatcherStop([uuid UTF8String], &Error);
        }
        // wait for threads to finish
        for (NSString *uuid in arrayWallets) {
            NSOperationQueue *queue = [self watcherGet:uuid];
            if (queue == nil) {
                continue;
            }
            // Wait until operations complete
            [queue waitUntilAllOperationsAreFinished];
            // Remove the watcher from the dictionary
            [self watcherRemove:uuid];
        }
        // Destroy watchers
        for (NSString *uuid in arrayWallets) {
            tABC_Error Error;
            ABC_WatcherDelete([uuid UTF8String], &Error);
            [self setLastErrors:Error];
        }
    }];
    
    while ([watcherQueue operationCount]);
}

- (void)deleteWatcherCache;
{
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [self loadWalletUUIDs:arrayWallets];
    // stop watchers
    for (NSString *uuid in arrayWallets) {
        tABC_Error error;
        ABC_WatcherDeleteCache([uuid UTF8String], &error);
    }
}

- (void)restoreConnectivity
{
    [self connectWatchers];
    [self startQueues];
}

- (void)lostConnectivity
{
}

- (void)prioritizeAddress:(NSString *)address inWallet:(NSString *)walletUUID
{
    char *szAddress = NULL;
    if (address)
    {
        szAddress = (char *)[address UTF8String];
    }

    if (walletUUID == nil)
        return;

    [self postToWatcherQueue:^{
        tABC_Error Error;
        ABC_PrioritizeAddress([self.name UTF8String],
                              [self.password UTF8String],
                              [walletUUID UTF8String],
                              [address UTF8String],
                              &Error);
        [self setLastErrors:Error];
        
    }];
}

- (void)watchAddresses: (NSString *) walletUUID
{
    tABC_Error Error;
    ABC_WatchAddresses([self.name UTF8String],
                    [self.password UTF8String],
                    [walletUUID UTF8String], &Error);
    [self setLastErrors:Error];
}

- (void)requestExchangeRateUpdate:(NSTimer *)object
{
    dispatch_async(dispatch_get_main_queue(),^
    {
        NSMutableArray *arrayCurrencyNums= [[NSMutableArray alloc] init];

        for (Wallet *w in self.arrayWallets)
        {
            if (w.loaded) {
                [arrayCurrencyNums addObject:[NSNumber numberWithInteger:w.currencyNum]];
            }
        }
        for (Wallet *w in self.arrayArchivedWallets)
        {
            if (w.loaded) {
                [arrayCurrencyNums addObject:[NSNumber numberWithInteger:w.currencyNum]];
            }
        }

        [exchangeQueue addOperationWithBlock:^{
            [[NSThread currentThread] setName:@"Exchange Rate Update"];
            [self requestExchangeUpdateBlocking:arrayCurrencyNums];
        }];
    });
}

- (void)requestExchangeUpdateBlocking:(NSMutableArray *)currencyNums
{
    if ([User isLoggedIn])
    {
        tABC_Error error;
        // Check the default currency for updates
        ABC_RequestExchangeRateUpdate([self.name UTF8String],
                                      [self.password UTF8String],
                                      self.settings.defaultCurrencyNum, &error);
        [self setLastErrors:error];

        // Check each wallet is up to date
        for (NSNumber *n in currencyNums)
        {
            // We pass no callback so this call is blocking
            ABC_RequestExchangeRateUpdate([self.name UTF8String],
                                          [self.password UTF8String],
                                          [n intValue], &error);
            [self setLastErrors:error];
        }

        dispatch_async(dispatch_get_main_queue(),^{
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_EXCHANGE_RATE_CHANGE object:self];
        });
    }
}

- (void)dataSyncAllWalletsAndAccount:(NSTimer *)object
{
    // Do not request a sync one is currently in progress
    if ([dataQueue operationCount] > 0) {
        return;
    }

    // Sync Wallets First
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [self loadWalletUUIDs: arrayWallets];
    for (NSString *uuid in arrayWallets) {
        [self requestWalletDataSync:uuid];
    }

    // Sync Account second
    [dataQueue addOperationWithBlock:^{
        [[NSThread currentThread] setName:@"Data Sync"];
        tABC_Error error;
        tABC_CC cc =
                ABC_DataSyncAccount([self.name UTF8String],
                        [self.password UTF8String],
                        ABC_BitCoin_Event_Callback,
                        (__bridge void *) self,
                        &error);
        if (cc == ABC_CC_InvalidOTP) {
            if ([self getOtpSecret] != nil) {
                [self performSelectorOnMainThread:@selector(notifyOtpSkew:)
                                       withObject:nil
                                    waitUntilDone:NO];
            } else {
                [self performSelectorOnMainThread:@selector(notifyOtpRequired:)
                                       withObject:nil
                                    waitUntilDone:NO];
            }
        }
    }];

    // Fetch general info last
    [dataQueue addOperationWithBlock:^{
        tABC_Error error;
        ABC_GeneralInfoUpdate(&error);
        [self setLastErrors:error];
    }];
}

- (void)requestWalletDataSync:(NSString *)uuid
{
    [dataQueue addOperationWithBlock:^{
        tABC_Error error;
        ABC_DataSyncWallet([self.name UTF8String],
                        [self.password UTF8String],
                        [uuid UTF8String],
                        ABC_BitCoin_Event_Callback,
                        (__bridge void *) self,
                        &error);
        [self setLastErrors:error];

        // Start watcher if the data has not been fetch
//        if (!bAllWalletsHaveBeenDataSynced) {
//            [self connectWatcher:uuid];
//            [self requestExchangeRateUpdate:nil];
//        }
    }];
}

- (bool)isTestNet
{
    bool result = false;
    tABC_Error Error;

    if (ABC_IsTestNet(&result, &Error) != ABC_CC_Ok) {
        [self setLastErrors:Error];
    }
    return result;
}

- (NSString *)coreVersion
{
    NSString *version;
    char *szVersion = NULL;
    ABC_Version(&szVersion, NULL);
    version = [NSString stringWithUTF8String:szVersion];
    free(szVersion);
    return version;
}

- (NSString *)currencyAbbrevLookup:(int)currencyNum
{
    ABLog(2,@"ENTER currencyAbbrevLookup: %@", [NSThread currentThread].name);
    NSNumber *c = [NSNumber numberWithInt:currencyNum];
    NSString *cached = [currencyCodesCache objectForKey:c];
    if (cached != nil) {
        ABLog(2,@"EXIT currencyAbbrevLookup CACHED code:%@ thread:%@", cached, [NSThread currentThread].name);
        return cached;
    }
    tABC_Error error;
    int currencyCount;
    tABC_Currency *currencies = NULL;
    ABC_GetCurrencies(&currencies, &currencyCount, &error);
    ABLog(2,@"CALLED ABC_GetCurrencies: %@ currencyCount:%d", [NSThread currentThread].name, currencyCount);
    if (error.code == ABC_CC_Ok) {
        for (int i = 0; i < currencyCount; ++i) {
            if (currencyNum == currencies[i].num) {
                NSString *code = [NSString stringWithUTF8String:currencies[i].szCode];
                [currencyCodesCache setObject:code forKey:c];
                ABLog(2,@"EXIT currencyAbbrevLookup code:%@ thread:%@", code, [NSThread currentThread].name);
                return code;
            }
        }
    }
    ABLog(2,@"EXIT currencyAbbrevLookup code:NULL thread:%@", [NSThread currentThread].name);
    return @"";
}

- (NSString *)currencySymbolLookup:(int)currencyNum
{
    NSNumber *c = [NSNumber numberWithInt:currencyNum];
    NSString *cached = [currencySymbolCache objectForKey:c];
    if (cached != nil) {
        return cached;
    }
    NSNumberFormatter *formatter = nil;
    NSString *code = [self currencyAbbrevLookup:currencyNum];
    for (NSString *l in NSLocale.availableLocaleIdentifiers) {
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.locale = [NSLocale localeWithLocaleIdentifier:l];
        if ([f.currencyCode isEqualToString:code]) {
            formatter = f;
            break;
        }
    }
    if (formatter != nil) {
        [currencySymbolCache setObject:formatter.currencySymbol forKey:c];
        return formatter.currencySymbol;
    } else {
        return @"";
    }
}

/*
 * determine currency based on locale
 */
- (int)getCurrencyNumOfLocale
{
    NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
    NSString *localCurrency = [locale objectForKey:NSLocaleCurrencyCode];
    NSNumber *currencyNum = [localeAsCurrencyNum objectForKey:localCurrency];
    if (currencyNum)
    {
        return [currencyNum intValue];
    }
    return CURRENCY_NUM_USD;
}

/*
 * set a new default currency for the account based on the parameter
 */
- (ABCConditionCode)setDefaultCurrencyNum:(int)currencyNum
{
    ABCConditionCode ccode = [self loadSettings];
    if (ABCConditionCodeOk == ccode)
    {
        self.settings.defaultCurrencyNum = currencyNum;
        ccode = [self saveSettings];
    }
    return ccode;
}

- (void)updateWidgetQRCode;
{

    if (!self.currentWallet || !self.currentWallet.strUUID)
        return;

    NSString *strUUID = self.currentWallet.strUUID;

    [self postToGenQRQueue:^(void) {

        //creates a receive request.  Returns a requestID.  Caller must free this ID when done with it
        tABC_CC result;
        tABC_Error error;
        tABC_TxDetails _details;

        //first need to create a transaction details struct
        memset(&_details, 0, sizeof(tABC_TxDetails));

        _details.amountSatoshi = 0;

        //the true fee values will be set by the core
        _details.amountFeesAirbitzSatoshi = 0;
        _details.amountFeesMinersSatoshi = 0;
        _details.amountCurrency = 0;

        _details.szName = (char *) [self.settings.fullName UTF8String];
        _details.szNotes = (char *) [@"" UTF8String];
        _details.szCategory = (char *) [@"" UTF8String];
        _details.attributes = 0x0; //for our own use (not used by the core)
        _details.bizId = 0;

        //
        // Must free all these before we leave
        //
        char *pRequestID = NULL;
        char *pszURI = NULL;
        unsigned char *pData = NULL;
        char *szRequestAddress = NULL;

        // create the request
        result = ABC_CreateReceiveRequest([self.name UTF8String],
                [self.password UTF8String],
                [strUUID UTF8String],
                &_details,
                &pRequestID,
                &error);

        if (result == ABC_CC_Ok)
        {
            unsigned int width = 0;
            UIImage *qrImage;

            result = ABC_GenerateRequestQRCode([self.name UTF8String],
                    [self.password UTF8String],
                    [strUUID UTF8String],
                    pRequestID,
                    &pszURI,
                    &pData,
                    &width,
                    &error);

            if (result == ABC_CC_Ok)
            {
                qrImage = [Util dataToImage:pData withWidth:width andHeight:width];


                tABC_CC result = ABC_GetRequestAddress([self.name UTF8String],
                        [self.password UTF8String],
                        [strUUID UTF8String],
                        pRequestID,
                        &szRequestAddress,
                        &error);

                if (result == ABC_CC_Ok)
                {
                    NSMutableString *addressString = [[NSMutableString alloc] init];
                    [addressString appendFormat:@"%s", szRequestAddress];

                    //
                    // Save QR and address in shared data so Widget can access it
                    //
                    static NSUserDefaults *tempSharedUserDefs = nil;

                    if (!tempSharedUserDefs) tempSharedUserDefs = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_ID];

                    NSData *imageData = UIImagePNGRepresentation(qrImage);

                    [tempSharedUserDefs setObject:imageData forKey:APP_GROUP_LAST_QR_IMAGE_KEY];
                    [tempSharedUserDefs setObject:addressString forKey:APP_GROUP_LAST_ADDRESS_KEY];
                    [tempSharedUserDefs setObject:self.currentWallet.strName forKey:APP_GROUP_LAST_WALLET_KEY];
                    [tempSharedUserDefs setObject:self.name forKey:APP_GROUP_LAST_ACCOUNT_KEY];
                    [tempSharedUserDefs synchronize];
                }
            }
        }

        if (pRequestID) free(pRequestID);
        if (pszURI) free(pszURI);
        if (pData) free(pData);
        if (szRequestAddress) free(szRequestAddress);
    }];
}

- (ABCConditionCode)createFirstWalletIfNeeded
{
    ABCConditionCode ccode = ABCConditionCodeError;
    NSMutableArray *wallets = [[NSMutableArray alloc] init];
    [self loadWalletUUIDs:wallets];
    
    if ([wallets count] == 0)
    {
        // create first wallet if it doesn't already exist
        ABLog(1, @"Creating first wallet in account");
        ccode = [self createWallet:nil currencyNum:0];
    }
    return ccode;
}




- (void)addCategory:(NSString *)strCategory;
{
    // check and see that it doesn't already exist
    if ([self.arrayCategories indexOfObject:strCategory] == NSNotFound)
    {
        // add the category to the core
        tABC_Error Error;
        ABC_AddCategory([self.name UTF8String],
                        [self.password UTF8String],
                        (char *)[strCategory UTF8String], &Error);
        [self setLastErrors:Error];
    }
    [self loadCategories];
}

- (void) loadCategories;
{
//    if (nil == self.arrayCategories || !self.numCategories)
    {
        [dataQueue addOperationWithBlock:^{
            char            **aszCategories = NULL;
            unsigned int    countCategories = 0;
            NSMutableArray *mutableArrayCategories = [[NSMutableArray alloc] init];
            
            // get the categories from the core
            tABC_Error error;
            ABC_GetCategories([self.name UTF8String],
                              [self.password UTF8String],
                              &aszCategories,
                              &countCategories,
                              &error);
            
            [self setLastErrors:error];
            
            // If we've never added any categories, add them now
            if (countCategories == 0)
            {
                NSMutableArray *arrayCategories = [[NSMutableArray alloc] init];
                //
                // Expense categories
                //
                [arrayCategories addObject:NSLocalizedString(@"Expense:Air Travel", @"default category Expense:Air Travel")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Alcohol & Bars", @"default category Expense:Alcohol & Bars")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Allowance", @"default category Expense:Allowance")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Amusement", @"default category Expense:Amusement")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Arts", @"default category Expense:Arts")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:ATM Fee", @"default category Expense:ATM Fee")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Auto & Transport", @"default category Expense:Auto & Transport")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Auto Insurance", @"default category Expense:Auto Insurance")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Auto Payment", @"default category Expense:Auto Payment")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Baby Supplies", @"default category Expense:Baby Supplies")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Babysitter & Daycare", @"default category Expense:Babysitter & Daycare")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Bank Fee", @"default category Expense:Bank Fee")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Bills & Utilities", @"default category Expense:Bills & Utilities")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Books", @"default category Expense:Books")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Books & Supplies", @"default category Expense:Books & Supplies")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Car Wash", @"default category Expense:Car Wash")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Cash & ATM", @"default category Expense:Cash & ATM")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Charity", @"default category Expense:Charity")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Clothing", @"default category Expense:Clothing")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Coffee Shops", @"default category Expense:Coffee Shops")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Credit Card Payment", @"default category Expense:Credit Card Payment")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Dentist", @"default category Expense:Dentist")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Deposit to Savings", @"default category Expense:Deposit to Savings")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Doctor", @"default category Expense:Doctor")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Education", @"default category Expense:Education")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Electronics & Software", @"default category Expense:Electronics & Software")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Entertainment", @"default category Expense:Entertainment")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Eyecare", @"default category Expense:Eyecare")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Fast Food", @"default category Expense:Fast Food")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Fees & Charges", @"default category Expense:Fees & Charges")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Financial", @"default category Expense:Financial")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Financial Advisor", @"default category Expense:Financial Advisor")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Food & Dining", @"default category Expense:Food & Dining")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Furnishings", @"default category Expense:Furnishings")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Gas & Fuel", @"default category Expense:Gas & Fuel")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Gift", @"default category Expense:Gift")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Gifts & Donations", @"default category Expense:Gifts & Donations")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Groceries", @"default category Expense:Groceries")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Gym", @"default category Expense:Gym")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Hair", @"default category Expense:Hair")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Health & Fitness", @"default category Expense:Health & Fitness")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:HOA Dues", @"default category Expense:HOA Dues")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Hobbies", @"default category Expense:Hobbies")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Home", @"default category Expense:Home")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Home Improvement", @"default category Expense:Home Improvement")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Home Insurance", @"default category Expense:Home Insurance")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Home Phone", @"default category Expense:Home Phone")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Home Services", @"default category Expense:Home Services")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Home Supplies", @"default category Expense:Home Supplies")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Hotel", @"default category Expense:Hotel")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Interest Exp", @"default category Expense:Interest Exp")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Internet", @"default category Expense:Internet")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:IRA Contribution", @"default category Expense:IRA Contribution")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Kids", @"default category Expense:Kids")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Kids Activities", @"default category Expense:Kids Activities")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Late Fee", @"default category Expense:Late Fee")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Laundry", @"default category Expense:Laundry")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Lawn & Garden", @"default category Expense:Lawn & Garden")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Life Insurance", @"default category Expense:Life Insurance")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Misc.", @"default category Expense:Misc.")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Mobile Phone", @"default category Expense:Mobile Phone")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Mortgage & Rent", @"default category Expense:Mortgage & Rent")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Mortgage Interest", @"default category Expense:Mortgage Interest")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Movies & DVDs", @"default category Expense:Movies & DVDs")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Music", @"default category Expense:Music")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Newspaper & Magazines", @"default category Expense:Newspaper & Magazines")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Not Sure", @"default category Expense:Not Sure")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Parking", @"default category Expense:Parking")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Personal Care", @"default category Expense:Personal Care")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Pet Food & Supplies", @"default category Expense:Pet Food & Supplies")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Pet Grooming", @"default category Expense:Pet Grooming")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Pets", @"default category Expense:Pets")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Pharmacy", @"default category Expense:Pharmacy")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Property", @"default category Expense:Property")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Public Transportation", @"default category Expense:Public Transportation")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Registration", @"default category Expense:Registration")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Rental Car & Taxi", @"default category Expense:Rental Car & Taxi")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Restaurants", @"default category Expense:Restaurants")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Service & Parts", @"default category Expense:Service & Parts")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Service Fee", @"default category Expense:Service Fee")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Shopping", @"default category Expense:Shopping")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Spa & Massage", @"default category Expense:Spa & Massage")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Sporting Goods", @"default category Expense:Sporting Goods")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Sports", @"default category Expense:Sports")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Student Loan", @"default category Expense:Student Loan")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Tax", @"default category Expense:Tax")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Television", @"default category Expense:Television")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Tolls", @"default category Expense:Tolls")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Toys", @"default category Expense:Toys")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Trade Commissions", @"default category Expense:Trade Commissions")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Travel", @"default category Expense:Travel")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Tuition", @"default category Expense:Tuition")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Utilities", @"default category Expense:Utilities")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Vacation", @"default category Expense:Vacation")];
                [arrayCategories addObject:NSLocalizedString(@"Expense:Vet", @"default category Expense:Vet")];
                
                //
                // Income categories
                //
                [arrayCategories addObject:NSLocalizedString(@"Income:Consulting Income", @"default category Income:Consulting Income")];
                [arrayCategories addObject:NSLocalizedString(@"Income:Div Income", @"default category Income:Div Income")];
                [arrayCategories addObject:NSLocalizedString(@"Income:Net Salary", @"default category Income:Net Salary")];
                [arrayCategories addObject:NSLocalizedString(@"Income:Other Income", @"default category Income:Other Income")];
                [arrayCategories addObject:NSLocalizedString(@"Income:Rent", @"default category Income:Rent")];
                [arrayCategories addObject:NSLocalizedString(@"Income:Sales", @"default category Income:Sales")];
                
                //
                // Exchange Categories
                //
                [arrayCategories addObject:NSLocalizedString(@"Exchange:Buy Bitcoin", @"default category Exchange:Buy Bitcoin")];
                [arrayCategories addObject:NSLocalizedString(@"Exchange:Sell Bitcoin", @"default category Exchange:Sell Bitcoin")];
                
                //
                // Transfer Categories
                //
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Bitcoin.de", @"default category Transfer:Bitcoin.de")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Bitfinex", @"default category Transfer:Bitfinex")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Bitstamp", @"default category Transfer:Bitstamp")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:BTC-e", @"default category Transfer:BTC-e")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:BTCChina", @"default category Transfer:BTCChina")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Bter", @"default category Transfer:Bter")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:CAVirtex", @"default category Transfer:CAVirtex")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Coinbase", @"default category Transfer:Coinbase")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:CoinMKT", @"default category Transfer:CoinMKT")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Huobi", @"default category Transfer:Huobi")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Kraken", @"default category Transfer:Kraken")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:MintPal", @"default category Transfer:MintPal")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:OKCoin", @"default category Transfer:OKCoin")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Vault of Satoshi", @"default category Transfer:Vault of Satoshi")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Wallet:Airbitz", @"default category Transfer:Wallet:Airbitz")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Wallet:Armory", @"default category Transfer:Wallet:Armory")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Wallet:Bitcoin Core", @"default category Transfer:Wallet:Bitcoin Core")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Wallet:Blockchain", @"default category Transfer:Wallet:Blockchain")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Wallet:Electrum", @"default category Transfer:Wallet:Electrum")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Wallet:Multibit", @"default category Transfer:Wallet:Multibit")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Wallet:Mycelium", @"default category Transfer:Wallet:Mycelium")];
                [arrayCategories addObject:NSLocalizedString(@"Transfer:Wallet:Dark Wallet", @"default category Transfer:Wallet:Dark Wallet")];
                
                // add default categories to core
                for (int i = 0; i < [arrayCategories count]; i++)
                {
                    NSString *strCategory = [arrayCategories objectAtIndex:i];
                    [mutableArrayCategories addObject:strCategory];
                    
                    ABC_AddCategory([self.name UTF8String],
                                    [self.password UTF8String],
                                    (char *)[strCategory UTF8String], &error);
                    [self setLastErrors:error];
                }
            }
            else
            {
                // store them in our own array
                
                if (aszCategories && countCategories > 0)
                {
                    for (int i = 0; i < countCategories; i++)
                    {
                        [mutableArrayCategories addObject:[NSString stringWithUTF8String:aszCategories[i]]];
                    }
                }

            }
            
            // free the core categories
            if (aszCategories != NULL)
            {
                [Util freeStringArray:aszCategories count:countCategories];
            }
            
            NSArray *tempArray = [mutableArrayCategories sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // store the final as storted
                self.arrayCategories = tempArray;
                self.numCategories = countCategories;
            });
        }];
    }
}

// saves the categories to the core
- (void)saveCategories:(NSMutableArray *)saveArrayCategories;
{
    tABC_Error Error;
    
    // got through the existing categories
    for (NSString *strCategory in self.arrayCategories)
    {
        // if this category is in our new list
        if ([saveArrayCategories containsObject:strCategory])
        {
            // remove it from our new list since it is already there
            [saveArrayCategories removeObject:strCategory];
        }
        else
        {
            // it doesn't exist in our new list so delete it from the core
            ABC_RemoveCategory([self.name UTF8String], [self.password UTF8String], (char *)[strCategory UTF8String], &Error);
            [self setLastErrors:Error];
        }
    }
    
    // add any categories from our new list that didn't exist in the core list
    for (NSString *strCategory in saveArrayCategories)
    {
        ABC_AddCategory([self.name UTF8String], [self.password UTF8String], (char *)[strCategory UTF8String], &Error);
        [self setLastErrors:Error];
    }
    [self loadCategories];
}


- (NSString *)sweepKey:(NSString *)privateKey intoWallet:(NSString *)walletUUID
{
    tABC_CC result = ABC_CC_Ok;
    tABC_Error Error;
    char *pszAddress = NULL;
    void *pData = NULL;
    result = ABC_SweepKey([self.name UTF8String],
                  [self.password UTF8String],
                  [walletUUID UTF8String],
                  [privateKey UTF8String],
                  &pszAddress,
                  ABC_Sweep_Complete_Callback,
                  pData,
                  &Error);
    if (ABC_CC_Ok == result && pszAddress)
    {
        NSString *address = [NSString stringWithUTF8String:pszAddress];
        free(pszAddress);
        return address;
    }
    return nil;
}

#pragma mark - ABC Callbacks

- (void)notifyReceiving:(NSArray *)params
{
    if ([params count] > 0)
    {
        [self refreshWallets:^
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TX_RECEIVED object:self userInfo:params[0]];
        }];
    }

}

- (void)notifyOtpRequired:(NSArray *)params
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_OTP_REQUIRED object:self];
}

- (void)notifyOtpSkew:(NSArray *)params
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_OTP_SKEW object:self];
}

- (void)notifyDataSync:(NSArray *)params
{
    if (! [User isLoggedIn])
        return;

    unsigned long numWallets = [self.arrayWallets count] + [self.arrayArchivedWallets count];

    [self loadCategories];
    
    [self refreshWallets:^
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DATA_SYNC_UPDATE object:self];

        // if there are new wallets, we need to start their watchers
        if ([self.arrayWallets count] + [self.arrayArchivedWallets count] != numWallets)
        {
            [self startWatchers];
        }
    }];
}

- (void)notifyDataSyncDelayed:(NSArray *)params
{
    if (notificationTimer) {
        [notificationTimer invalidate];
    }

    if (! [User isLoggedIn])
        return;

    notificationTimer = [NSTimer scheduledTimerWithTimeInterval:NOTIFY_DATA_SYNC_DELAY
                                                         target:self
                                                       selector:@selector(notifyDataSync:)
                                                       userInfo:nil
                                                        repeats:NO];
}

- (void)notifyRemotePasswordChange:(NSArray *)params
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REMOTE_PASSWORD_CHANGE object:self];
}

//- (void)otpSetError:(tABC_CC)cc
//{
//    bOtpError = ABC_CC_InvalidOTP == cc;
//}
//
//- (BOOL)otpHasError;
//{
//    return bOtpError;
//}
//
//- (void)otpClearError
//{
//    bOtpError = NO;
//}
//
- (NSString *)getOtpSecret
{
    tABC_Error error;
    NSString *secret = nil;
    char *szSecret = NULL;
    ABC_OtpKeyGet([self.name UTF8String], &szSecret, &error);
    if (error.code == ABC_CC_Ok && szSecret) {
        secret = [NSString stringWithUTF8String:szSecret];
    }
    if (szSecret) {
        free(szSecret);
    }
    ABLog(2,@("SECRET: %@"), secret);
    return secret;
}

- (NSString *) bitidParseURI:(NSString *)uri;
{
    tABC_Error error;
    char *szURLDomain = NULL;
    NSString *urlDomain;

    ABC_BitidParseUri([self.name UTF8String], nil, [uri UTF8String], &szURLDomain, &error);

    if (error.code == ABC_CC_Ok && szURLDomain) {
        urlDomain = [NSString stringWithUTF8String:szURLDomain];
    }
    if (szURLDomain) {
        free(szURLDomain);
    }
    ABLog(2,@("bitidParseURI domain: %@"), urlDomain);
    return urlDomain;

}

- (BOOL) bitidLogin:(NSString *)uri;
{
    tABC_Error error;

    ABC_BitidLogin([self.name UTF8String], nil, [uri UTF8String], &error);

    if (error.code == ABC_CC_Ok)
        return YES;
    return NO;
}

- (BitidSignature *)bitidSign:(NSString *)uri msg:(NSString *)message
{
    tABC_Error error;
    char *szAddress = NULL;
    char *szSignature = NULL;
    BitidSignature *bitid = [[BitidSignature alloc] init];

    tABC_CC result = ABC_BitidSign(
        [self.name UTF8String], [self.password UTF8String],
        [uri UTF8String], [message UTF8String], &szAddress, &szSignature, &error);
    if (result == ABC_CC_Ok) {
        bitid.address = [NSString stringWithUTF8String:szAddress];
        bitid.signature = [NSString stringWithUTF8String:szSignature];
    }
    if (szAddress) {
        free(szAddress);
    }
    if (szSignature) {
        free(szSignature);
    }
    return bitid;
}

- (NSArray *)getLocalAccounts:(NSString **)strError;
{
    char * pszUserNames;
    NSArray *arrayAccounts = nil;
    tABC_Error error;
    __block tABC_CC result = ABC_ListAccounts(&pszUserNames, &error);
    switch (result)
    {
        case ABC_CC_Ok:
        {
            NSString *str = [NSString stringWithCString:pszUserNames encoding:NSUTF8StringEncoding];
            arrayAccounts = [str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            NSMutableArray *stringArray = [[NSMutableArray alloc] init];
            for(NSString *str in arrayAccounts)
            {
                if(str && str.length!=0)
                {
                    [stringArray addObject:str];
                }
            }
            arrayAccounts = [stringArray copy];
            if (strError) *strError = nil;
            return arrayAccounts;
            break;
        }
        default:
        {
            if (strError) *strError = [Util errorMap:&error];
            return nil;
            break;
        }
    }
}

- (BOOL)accountExistsLocal:(NSString *)username;
{
    if (username == nil) {
        return NO;
    }
    tABC_Error error;
    bool result;
    ABC_AccountSyncExists([username UTF8String],
                          &result,
                          &error);
    return (BOOL)result;
}


- (ABCConditionCode)uploadLogs:(NSString *)userText;
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *versionbuild = [NSString stringWithFormat:@"%@ %@", version, build];

    NSOperatingSystemVersion osVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    ABC_Log([[NSString stringWithFormat:@"User Comment:%@", userText] UTF8String]);
    ABC_Log([[NSString stringWithFormat:@"Platform:%@", [[Theme Singleton] platform]] UTF8String]);
    ABC_Log([[NSString stringWithFormat:@"Platform String:%@", [[Theme Singleton] platformString]] UTF8String]);
    ABC_Log([[NSString stringWithFormat:@"OS Version:%d.%d.%d", (int)osVersion.majorVersion, (int)osVersion.minorVersion, (int)osVersion.patchVersion] UTF8String]);
    ABC_Log([[NSString stringWithFormat:@"Airbitz Version:%@", versionbuild] UTF8String]);

    tABC_Error error;
    ABC_UploadLogs([self.name UTF8String], NULL, &error);

    return [self setLastErrors:error];
}

- (ABCConditionCode)uploadLogs:(NSString *)userText
        complete:(void(^)(void))completionHandler
           error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;
{
    [self postToMiscQueue:^{

        ABCConditionCode ccode;
        ccode = [self uploadLogs:userText];

        NSString *errorString = [self getLastErrorString];

        dispatch_async(dispatch_get_main_queue(),^{
            if (ABC_CC_Ok == ccode) {
                if (completionHandler) completionHandler();
            } else {
                if (errorHandler) errorHandler(ccode, errorString);
            }
        });
    }];
    return ABCConditionCodeOk;
}

- (ABCConditionCode)accountDeleteLocal:(NSString *)account;
{
    tABC_Error error;
    ABC_AccountDelete((const char*)[account UTF8String], &error);

    return [self setLastErrors:error];
}

- (ABCConditionCode)walletRemove:(NSString *)uuid;
{
    // Check if we are trying to delete the current wallet
    if ([self.currentWallet.strUUID isEqualToString:uuid])
    {
        // Find a non-archived wallet that isn't the wallet we're going to delete
        // and make it the current wallet
        for (Wallet *wallet in self.arrayWallets)
        {
            if (![wallet.strUUID isEqualToString:uuid])
            {
                if (!wallet.archived)
                {
                    [self makeCurrentWallet:wallet];
                    break;
                }
            }
        }
    }
    ABLog(1,@"Deleting wallet [%@]", uuid);
    tABC_Error error;

    ABC_WalletRemove([self.name UTF8String], [uuid UTF8String], &error);

    [self refreshWallets];

    return [self setLastErrors:error];
}

- (ABCConditionCode)walletRemove:(NSString *)uuid
        complete:(void(^)(void))completionHandler
           error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;
{
    // Check if we are trying to delete the current wallet
    if ([self.currentWallet.strUUID isEqualToString:uuid])
    {
        // Find a non-archived wallet that isn't the wallet we're going to delete
        // and make it the current wallet
        for (Wallet *wallet in self.arrayWallets)
        {
            if (![wallet.strUUID isEqualToString:uuid])
            {
                if (!wallet.archived)
                {
                    [self makeCurrentWallet:wallet];
                    break;
                }
            }
        }
    }

    [self postToMiscQueue:^
    {
        ABLog(1,@"Deleting wallet [%@]", uuid);
        tABC_Error error;

        ABC_WalletRemove([self.name UTF8String], [uuid UTF8String], &error);
        ABCConditionCode ccode = [self setLastErrors:error];
        NSString *errorString = [self getLastErrorString];

        [self refreshWallets];

        dispatch_async(dispatch_get_main_queue(),^{
            if (ABC_CC_Ok == ccode) {
                if (completionHandler) completionHandler();
            } else {
                if (errorHandler) errorHandler(ccode, errorString);
            }
        });
    }];
    return ABCConditionCodeOk;
}

void ABC_BitCoin_Event_Callback(const tABC_AsyncBitCoinInfo *pInfo)
{
    CoreBridge *coreBridge = (__bridge id) pInfo->pData;
    if (pInfo->eventType == ABC_AsyncEventType_IncomingBitCoin) {
        NSDictionary *data = @{
            KEY_TX_DETAILS_EXITED_WALLET_UUID: [NSString stringWithUTF8String:pInfo->szWalletUUID],
            KEY_TX_DETAILS_EXITED_TX_ID: [NSString stringWithUTF8String:pInfo->szTxID]
        };
        NSArray *params = [NSArray arrayWithObjects: data, nil];
        [coreBridge performSelectorOnMainThread:@selector(notifyReceiving:) withObject:params waitUntilDone:NO];
    // } else if (pInfo->eventType == ABC_AsyncEventType_OtpRequired) {
    //     [coreBridge performSelectorOnMainThread:@selector(notifyOtpRequired:) withObject:nil waitUntilDone:NO];
    } else if (pInfo->eventType == ABC_AsyncEventType_BlockHeightChange) {
//        [coreBridge performSelectorOnMainThread:@selector(notifyBlockHeight:) withObject:nil waitUntilDone:NO];
        [coreBridge refreshWallets];
    } else if (pInfo->eventType == ABC_AsyncEventType_DataSyncUpdate) {
        [coreBridge performSelectorOnMainThread:@selector(notifyDataSyncDelayed:) withObject:nil waitUntilDone:NO];
    } else if (pInfo->eventType == ABC_AsyncEventType_RemotePasswordChange) {
        [coreBridge performSelectorOnMainThread:@selector(notifyRemotePasswordChange:) withObject:nil waitUntilDone:NO];
    }
}

void ABC_Sweep_Complete_Callback(tABC_CC cc, const char *szID, uint64_t amount)
{
    NSMutableDictionary *sweepData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:cc], KEY_SWEEP_CORE_CONDITION_CODE,
                                        [NSNumber numberWithUnsignedLongLong:amount], KEY_SWEEP_TX_AMOUNT,
                                      nil];
    if (szID)
    {
        [sweepData setValue:[NSString stringWithUTF8String:szID] forKey:KEY_SWEEP_TX_ID];
    }
    else
    {
        [sweepData setValue:@"" forKey:KEY_SWEEP_TX_ID];
    }

    // broadcast message out that the sweep is done
    dispatch_async(dispatch_get_main_queue(), ^ {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SWEEP
                                                            object:nil
                                                        userInfo:sweepData];
    });
}

/////////////////////////////////////////////////////////////////
//////////////////// New AirbitzCore methods ////////////////////
/////////////////////////////////////////////////////////////////

- (ABCConditionCode)createAccount:(NSString *)username password:(NSString *)password pin:(NSString *)pin;
{
    tABC_Error error;
    char *szPassword = [password length] == 0 ? NULL : [password UTF8String];
    ABC_CreateAccount([username UTF8String], szPassword, &error);
    ABCConditionCode ccode = [self setLastErrors:error];
    if (ABCConditionCodeOk == ccode)
    {
        ABC_SetPIN([username UTF8String], [password UTF8String], [pin UTF8String], &error);
        ccode = [self setLastErrors:error];

        if (ABCConditionCodeOk == ccode)
        {
            self.name = username;
            self.password = password;
            [self setupLoginPIN];
            // update user's default currency num to match their locale
            int currencyNum = [self getCurrencyNumOfLocale];
            return [self setDefaultCurrencyNum:currencyNum];
        }
    }
    return ccode;
}

- (ABCConditionCode)createAccount:(NSString *)username password:(NSString *)password pin:(NSString *)pin
        complete:(void (^)(void)) completionHandler
           error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        ABCConditionCode ccode = [self createAccount:username password:password pin:pin];
        NSString *errorString = [self getLastErrorString];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (ABCConditionCodeOk == ccode)
            {
                if (completionHandler) completionHandler();
            }
            else
            {
                if (errorHandler) errorHandler(ccode, errorString);
            }
        });
    });
    return ABCConditionCodeOk;

}

- (ABCConditionCode)changePIN:(NSString *)pin;
{
    tABC_Error error;
    if (!pin)
    {
        error.code = (tABC_CC) ABCConditionCodeNULLPtr;
        return [self setLastErrors:error];
    }
    const char * passwd = [self.password length] > 0 ? [self.password UTF8String] : nil;
    
    ABC_SetPIN([self.name UTF8String], passwd, [pin UTF8String], &error);
    ABCConditionCode ccode = [self setLastErrors:error];
    if (ABCConditionCodeOk == ccode)
    {
        ABC_PinSetup([self.name UTF8String],
                     passwd,
                     &error);
        ccode = [self setLastErrors:error];
    }
    return ccode;
}

- (ABCConditionCode)changePIN:(NSString *)pin
                     complete:(void (^)(void)) completionHandler
                        error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        ABCConditionCode ccode = [self changePIN:pin];
        NSString *errorString = [self getLastErrorString];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (ABCConditionCodeOk == ccode)
            {
                if (completionHandler) completionHandler();
            }
            else
            {
                if (errorHandler) errorHandler(ccode, errorString);
            }
        });
    });
    return ABCConditionCodeOk;
    
}


- (ABCConditionCode) createWallet:(NSString *)walletName currencyNum:(int) currencyNum;
{
    [self clearSyncQueue];
    if (currencyNum == 0)
    {
        if (self.settings)
        {
            currencyNum = self.settings.defaultCurrencyNum;
        }
        if (0 == currencyNum)
        {
            currencyNum = DEFAULT_CURRENCY_NUM;
        }
    }
    
    if (!self.arrayCurrencyNums || [self.arrayCurrencyNums indexOfObject:[NSNumber numberWithInt:currencyNum]] == NSNotFound)
    {
        currencyNum = DEFAULT_CURRENCY_NUM;
    }
    
    NSString *defaultWallet = [NSString stringWithString:defaultWalletName];
    if (nil == walletName || [walletName length] == 0)
    {
        walletName = defaultWallet;
    }
    
    tABC_Error error;
    char *szUUID = NULL;
    ABC_CreateWallet([self.name UTF8String],
                     [self.password UTF8String],
                     [walletName UTF8String],
                     currencyNum,
                     &szUUID,
                     &error);
    ABCConditionCode ccode = [self setLastErrors:error];
    
    if (ABCConditionCodeOk == ccode)
    {
        [self startAllWallets];
        [self connectWatchers];
        [self refreshWallets];
    }
    return ccode;
}

- (ABCConditionCode) createWallet:(NSString *)walletName currencyNum:(int) currencyNum
                         complete:(void (^)(void)) completionHandler
                            error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        ABCConditionCode ccode = [self createWallet:walletName currencyNum:currencyNum];
        NSString *errorString = [self getLastErrorString];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (ABCConditionCodeOk == ccode)
            {
                if (completionHandler) completionHandler();
            }
            else
            {
                if (errorHandler) errorHandler(ccode, errorString);
            }
        });
    });
    return ABCConditionCodeOk;

}


- (ABCConditionCode)signIn:(NSString *)username password:(NSString *)password otp:(NSString *)otp;
{
    tABC_Error error;
    ABCConditionCode ccode = ABCConditionCodeOk;
    bNewDeviceLogin = NO;

    if (!username || !password)
    {
        error.code = (tABC_CC) ABCConditionCodeNULLPtr;
        ccode = [self setLastErrors:error];
    }
    else
    {
        if (![self accountExistsLocal:username])
            bNewDeviceLogin = YES;
        
        if (otp)
        {
            ABC_OtpKeySet([username UTF8String], (char *) [otp UTF8String], &error);
            ccode = [self setLastErrors:error];
        }

        if (ABCConditionCodeOk == ccode)
        {
            ABC_SignIn([username UTF8String],
                    [password UTF8String], &error);
            ccode = [self setLastErrors:error];

            if (ABCConditionCodeOk == ccode)
            {
                self.name = username;
                self.password = password;
                [self loginCommon];
                [self setupLoginPIN];
            }
        }
    }

    return ccode;
}


- (ABCConditionCode)signIn:(NSString *)username password:(NSString *)password otp:(NSString *)otp
                     complete:(void (^)(void)) completionHandler
                        error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        ABCConditionCode ccode = [self signIn:username password:password otp:otp];
        NSString *errorString = [self getLastErrorString];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (ABCConditionCodeOk == ccode)
            {
                if (completionHandler) completionHandler();
            }
            else
            {
                if (errorHandler) errorHandler(ccode, errorString);
            }
        });
    });
    return ABCConditionCodeOk;
}

- (ABCConditionCode)signInWithPIN:(NSString *)username pin:(NSString *)pin;
{
    tABC_Error error;
    ABCConditionCode ccode;

    if (!username || !pin)
    {
        error.code = (tABC_CC) ABCConditionCodeNULLPtr;
        return [self setLastErrors:error];
    }

    if ([self PINLoginExists:username])
    {
        ABC_PinLogin([username UTF8String],
                [pin UTF8String],
                &error);
        ccode = [self setLastErrors:error];

        if (ABCConditionCodeOk == ccode)
        {
            self.name = username;
            self.password = nil;
            [self loginCommon];
        }
    }
    else
    {
        error.code = (tABC_CC) ABCConditionCodeError;
        ccode = [self setLastErrors:error];
    }
    return ccode;

}

- (ABCConditionCode)signInWithPIN:(NSString *)username pin:(NSString *)pin
                            complete:(void (^)(void)) completionHandler
                               error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
    {
        ABCConditionCode ccode = [self signInWithPIN:username pin:pin];
        NSString *errorString = [self getLastErrorString];
        dispatch_async(dispatch_get_main_queue(), ^(void)
        {
            if (ABCConditionCodeOk == ccode)
            {
                if (completionHandler) completionHandler();
            }
            else
            {
                if (errorHandler) errorHandler(ccode, errorString);
            }
        });
    });
    return ABCConditionCodeOk;
}

- (ABCConditionCode)changePasswordWithRecoveryAnswers:(NSString *)username
                                      recoveryAnswers:(NSString *)answers
                                          newPassword:(NSString *)password;
{
//    const char *ignore = "ignore";
    tABC_Error error;
    
    if (!username || !answers || !password)
    {
        error.code = ABC_CC_BadPassword;
        return [self setLastErrors:error];
    }
    [self stopWatchers];
    [self stopQueues];
    
    
    // NOTE: userNameTextField is repurposed for current password
    ABC_ChangePasswordWithRecoveryAnswers([username UTF8String], [answers UTF8String], [password UTF8String], &error);
    ABCConditionCode ccode = [self setLastErrors:error];
    
    if (ABCConditionCodeOk == ccode)
    {
        [self setupLoginPIN];
    }
    
    [self startWatchers];
    [self startQueues];
    
    return ccode;
}

- (ABCConditionCode)changePasswordWithRecoveryAnswers:(NSString *)username
                                      recoveryAnswers:(NSString *)answers
                                          newPassword:(NSString *)password
                         complete:(void (^)(void)) completionHandler
                            error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler
{
    [self postToDataQueue:^(void)
     {
         ABCConditionCode ccode = [self changePasswordWithRecoveryAnswers:username
                                                          recoveryAnswers:answers
                                                              newPassword:password];
         NSString *errorString = [self getLastErrorString];
         dispatch_async(dispatch_get_main_queue(), ^(void)
                        {
                            if (ABCConditionCodeOk == ccode)
                            {
                                if (completionHandler) completionHandler();
                            }
                            else
                            {
                                if (errorHandler) errorHandler(ccode, errorString);
                            }
                        });
         
     }];
    return ABCConditionCodeOk;
}


- (ABCConditionCode)changePassword:(NSString *)password;
{
    //    const char *ignore = "ignore";
    tABC_Error error;
    
    if (!password)
    {
        error.code = ABC_CC_BadPassword;
        return [self setLastErrors:error];
    }
    [self stopWatchers];
    [self stopQueues];
    
    
    ABC_ChangePassword([self.name UTF8String], [@"ignore" UTF8String], [password UTF8String], &error);
    ABCConditionCode ccode = [self setLastErrors:error];
    
    if (ABCConditionCodeOk == ccode)
    {
        [self setupLoginPIN];
    }
    
    [self startWatchers];
    [self startQueues];
    
    return ccode;
}

- (ABCConditionCode)changePassword:(NSString *)password
                          complete:(void (^)(void)) completionHandler
                             error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler
{
    [self postToDataQueue:^(void)
     {
         ABCConditionCode ccode = [self changePassword:password];
         NSString *errorString = [self getLastErrorString];
         dispatch_async(dispatch_get_main_queue(), ^(void)
                        {
                            if (ABCConditionCodeOk == ccode)
                            {
                                if (completionHandler) completionHandler();
                            }
                            else
                            {
                                if (errorHandler) errorHandler(ccode, errorString);
                            }
                        });
         
     }];
    return ABCConditionCodeOk;
}

- (ABCConditionCode)getNumWalletsInAccount:(int *)numWallets
{
    tABC_Error error;
    char **aUUIDS = NULL;
    unsigned int nCount;
    
    ABC_GetWalletUUIDs([self.name UTF8String],
                       [self.password UTF8String],
                       &aUUIDS, &nCount, &error);
    ABCConditionCode ccode = [self setLastErrors:error];

    if (ABCConditionCodeOk == ccode)
    {
        *numWallets = nCount;
        
        if (aUUIDS)
        {
            unsigned int i;
            for (i = 0; i < nCount; ++i)
            {
                char *szUUID = aUUIDS[i];
                // If entry is NULL skip it
                if (!szUUID) {
                    continue;
                }
                free(szUUID);
            }
            free(aUUIDS);
        }
    }
    return ccode;
}



- (ABCConditionCode)loadSettings;
{
    tABC_Error error;
    tABC_AccountSettings *pSettings = NULL;
    tABC_CC result = ABC_LoadAccountSettings([self.name UTF8String],
            [self.password UTF8String],
            &pSettings,
            &error);
    if (ABC_CC_Ok == result)
    {
        self.settings.minutesAutoLogout = pSettings->minutesAutoLogout;
        self.settings.defaultCurrencyNum = pSettings->currencyNum;
        if (pSettings->bitcoinDenomination.satoshi > 0)
        {
            self.settings.denomination = pSettings->bitcoinDenomination.satoshi;
            self.settings.denominationType = pSettings->bitcoinDenomination.denominationType;

            switch (self.settings.denominationType) {
                case ABC_DENOMINATION_BTC:
                    self.settings.denominationLabel = @"BTC";
                    self.settings.denominationLabelShort = @"Ƀ ";
                    break;
                case ABC_DENOMINATION_MBTC:
                    self.settings.denominationLabel = @"mBTC";
                    self.settings.denominationLabelShort = @"mɃ ";
                    break;
                case ABC_DENOMINATION_UBTC:
                    self.settings.denominationLabel = @"bits";
                    self.settings.denominationLabelShort = @"ƀ ";
                    break;

            }
        }
        self.settings.firstName            = pSettings->szFirstName          ? [NSString stringWithUTF8String:pSettings->szFirstName] : nil;
        self.settings.lastName             = pSettings->szLastName           ? [NSString stringWithUTF8String:pSettings->szLastName] : nil;
        self.settings.nickName             = pSettings->szNickname           ? [NSString stringWithUTF8String:pSettings->szNickname] : nil;
        self.settings.fullName             = pSettings->szFullName           ? [NSString stringWithUTF8String:pSettings->szFullName] : nil;
        self.settings.strPIN               = pSettings->szPIN                ? [NSString stringWithUTF8String:pSettings->szPIN] : nil;
        self.settings.exchangeRateSource   = pSettings->szExchangeRateSource ? [NSString stringWithUTF8String:pSettings->szExchangeRateSource] : nil;

        self.settings.bNameOnPayments = pSettings->bNameOnPayments;
        self.settings.bSpendRequirePin = pSettings->bSpendRequirePin;
        self.settings.spendRequirePinSatoshis = pSettings->spendRequirePinSatoshis;
        self.settings.bDisablePINLogin = pSettings->bDisablePINLogin;
    }
    ABC_FreeAccountSettings(pSettings);

    return [self setLastErrors:error];
}

- (ABCConditionCode)saveSettings;
{
    tABC_Error error;
    tABC_AccountSettings *pSettings;

    ABC_LoadAccountSettings([self.name UTF8String], [self.password UTF8String], &pSettings, &error);

    if (ABCConditionCodeOk == [self setLastErrors:error])
    {
        pSettings->minutesAutoLogout                      = self.settings.minutesAutoLogout         ;
        pSettings->currencyNum                            = self.settings.defaultCurrencyNum        ;
        pSettings->bitcoinDenomination.satoshi            = self.settings.denomination              ;
        pSettings->bitcoinDenomination.denominationType   = self.settings.denominationType          ;
        pSettings->bNameOnPayments                        = self.settings.bNameOnPayments           ;
        pSettings->bSpendRequirePin                       = self.settings.bSpendRequirePin          ;
        pSettings->spendRequirePinSatoshis                = self.settings.spendRequirePinSatoshis   ;
        pSettings->bDisablePINLogin                       = self.settings.bDisablePINLogin          ;

        self.settings.firstName          ? [self replaceString:&(pSettings->szFirstName         ) withString:[self.settings.firstName          UTF8String]] : nil;
        self.settings.lastName           ? [self replaceString:&(pSettings->szLastName          ) withString:[self.settings.lastName           UTF8String]] : nil;
        self.settings.nickName           ? [self replaceString:&(pSettings->szNickname          ) withString:[self.settings.nickName           UTF8String]] : nil;
        self.settings.fullName           ? [self replaceString:&(pSettings->szFullName          ) withString:[self.settings.fullName           UTF8String]] : nil;
        self.settings.strPIN             ? [self replaceString:&(pSettings->szPIN               ) withString:[self.settings.strPIN             UTF8String]] : nil;
        self.settings.exchangeRateSource ? [self replaceString:&(pSettings->szExchangeRateSource) withString:[self.settings.exchangeRateSource UTF8String]] : nil;

        ABC_UpdateAccountSettings([self.name UTF8String], [self.password UTF8String], pSettings, &error);
        if (ABCConditionCodeOk == [self setLastErrors:error])
        {
            ABC_FreeAccountSettings(pSettings);
        }
    }

    return (ABCConditionCode) error.code;
}

- (ABCConditionCode)setRecoveryQuestions:(NSString *)password
                               questions:(NSString *)questions
                                 answers:(NSString *)answers;
{
    tABC_Error error;
    ABC_SetAccountRecoveryQuestions([self.name UTF8String],
            [password UTF8String],
            [questions UTF8String],
            [answers UTF8String],
            &error);
    return [self setLastErrors:error];
}

- (ABCConditionCode)setRecoveryQuestions:(NSString *)password
                               questions:(NSString *)questions
                                 answers:(NSString *)answers
        complete:(void (^)(void)) completionHandler
           error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;
{
    [self postToMiscQueue:^
    {
        ABCConditionCode ccode = [self setRecoveryQuestions:password questions:questions answers:answers];
        NSString *errorString  = [self getLastErrorString];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (ABCConditionCodeOk == ccode)
            {
                if (completionHandler) completionHandler();
            }
            else
            {
                if (errorHandler) errorHandler(ccode, errorString);
            }
        });
    }];
    return ABCConditionCodeOk;
}

- (void)getRecoveryQuestionsChoices: (void (^)(
        NSMutableArray *arrayCategoryString,
        NSMutableArray *arrayCategoryNumeric,
        NSMutableArray *arrayCategoryMust)) completionHandler
        error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;
{

    [self postToMiscQueue:^{
        tABC_Error error;
        tABC_QuestionChoices *pQuestionChoices = NULL;
        ABC_GetQuestionChoices(&pQuestionChoices, &error);

        ABCConditionCode ccode = [self setLastErrors:error];
        NSString *errorString = [self getLastErrorString];

        if (ABCConditionCodeOk == ccode)
        {
            NSMutableArray        *arrayCategoryString  = [[NSMutableArray alloc] init];
            NSMutableArray        *arrayCategoryNumeric = [[NSMutableArray alloc] init];
            NSMutableArray        *arrayCategoryMust    = [[NSMutableArray alloc] init];

            [self categorizeQuestionChoices:pQuestionChoices
                             categoryString:&arrayCategoryString
                            categoryNumeric:&arrayCategoryNumeric
                               categoryMust:&arrayCategoryMust];


            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionHandler(arrayCategoryString, arrayCategoryNumeric, arrayCategoryMust);
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                errorHandler(ccode, errorString);
            });
        }
        ABC_FreeQuestionChoices(pQuestionChoices);
    }];
}

- (void)checkRecoveryAnswers:(NSString *)username answers:(NSString *)strAnswers
       complete:(void (^)(BOOL validAnswers)) completionHandler
          error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler
{

    [self postToMiscQueue:^{
        BOOL bValid = NO;
        bool bABCValid = false;
        tABC_Error error;
        ABCConditionCode ccode;

        ABC_CheckRecoveryAnswers([username UTF8String],
                [strAnswers UTF8String],
                &bABCValid,
                &error);
        ccode = [self setLastErrors:error];
        NSString *errorStr = [self getLastErrorString];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (ABCConditionCodeOk == ccode)
            {
                if (completionHandler) completionHandler(bABCValid);
            }
            else
            {
                if (errorHandler) errorHandler(ccode, errorStr);
            }
        });
    }];
}

- (ABCConditionCode)newSpendFromText:(NSString *)uri spendTarget:(SpendTarget **)spendTarget;
{
    tABC_Error error;
    if (!uri || !spendTarget)
    {
        error.code = (tABC_CC)ABCConditionCodeNULLPtr;
        return [self setLastErrors:error];
    }
    *spendTarget = [[SpendTarget alloc] init:self];
    tABC_SpendTarget *pSpend = NULL;

    ABC_SpendNewDecode([uri UTF8String], &pSpend, &error);
    ABCConditionCode ccode = [self setLastErrors:error];
    if (ABCConditionCodeOk == ccode)
        [*spendTarget spendObjectSet:(void *)pSpend];
    return ccode;
}

- (void)newSpendFromTextAsync:(NSString *)uri
        complete:(void(^)(SpendTarget *sp))completionHandler
           error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;
{
    [self postToMiscQueue:^{
        SpendTarget *spendTarget;
        ABCConditionCode ccode = [self newSpendFromText:uri spendTarget:&spendTarget];
        NSString *errorString = [self getLastErrorString];
        dispatch_async(dispatch_get_main_queue(),^{
            if (ABCConditionCodeOk == ccode) {
                if (completionHandler) completionHandler(spendTarget);
            } else {
                if (errorHandler) errorHandler(ccode, errorString);
            }
        });
    }];
}

- (ABCConditionCode)newSpendTransfer:(NSString *)destWalletUUID spendTarget:(SpendTarget **)spendTarget;
{
    tABC_Error error;
    if (!destWalletUUID || !spendTarget)
    {
        error.code = (tABC_CC)ABCConditionCodeNULLPtr;
        return [self setLastErrors:error];
    }
    *spendTarget = [[SpendTarget alloc] init:self];
    tABC_SpendTarget *pSpend = NULL;

    ABC_SpendNewTransfer([self.name UTF8String],
            [destWalletUUID UTF8String], 0, &pSpend, &error);
    ABCConditionCode ccode = [self setLastErrors:error];
    if (ABCConditionCodeOk == ccode)
    {
        (*spendTarget).destWallet = [self selectWalletWithUUID:destWalletUUID];
        [*spendTarget spendObjectSet:(void *)pSpend];
    }
    return ccode;
}

- (ABCConditionCode)newSpendInternal:(NSString *)address
                               label:(NSString *)label
                            category:(NSString *)category
                               notes:(NSString *)notes
                       amountSatoshi:(uint64_t)amountSatoshi
                         spendTarget:(SpendTarget **)spendTarget;
{
    tABC_Error error;
    *spendTarget = [[SpendTarget alloc] init:self];
    tABC_SpendTarget *pSpend = NULL;

    ABC_SpendNewInternal([address UTF8String], [label UTF8String],
            [category UTF8String], [notes UTF8String],
            amountSatoshi, &pSpend, &error);
    ABCConditionCode ccode = [self setLastErrors:error];
    if (ABCConditionCodeOk == ccode)
        [*spendTarget spendObjectSet:(void *)pSpend];
    return ccode;
}



//- (void)newSpendTransferAsync:(NSString *)destWalletUUID
//                     complete:(void(^)(SpendTarget *sp))completionHandler
//                        error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;
//{
//    [self postToMiscQueue:^{
//        SpendTarget *spendTarget;
//        ABCConditionCode ccode = [self newSpendTransfer:destWalletUUID spendTarget:&spendTarget];
//        NSString *errorString = [self getLastErrorString];
//        dispatch_async(dispatch_get_main_queue(),^{
//            if (ABCConditionCodeOk == ccode) {
//                if (completionHandler) completionHandler(spendTarget);
//            } else {
//                if (errorHandler) errorHandler(ccode, errorString);
//            }
//        });
//    }];
//}


- (ABCConditionCode) satoshiToCurrency:(uint64_t) satoshi
                           currencyNum:(int)currencyNum
                              currency:(double *)pCurrency;
{
    tABC_Error error;

    ABC_SatoshiToCurrency([self.name UTF8String], [self.password UTF8String],
            satoshi, pCurrency, currencyNum, &error);
    return [self setLastErrors:error];
}

- (ABCConditionCode) getLastConditionCode;
{
    return lastConditionCode;
}

- (NSString *) getLastErrorString;
{
    return lastErrorString;
}

- (NSString *)conditionCodeMap:(ABCConditionCode) cc;
{
    switch (cc)
    {
        case ABCConditionCodeAccountAlreadyExists:
            return NSLocalizedString(@"This account already exists.", nil);
        case ABCConditionCodeAccountDoesNotExist:
            return NSLocalizedString(@"We were unable to find your account. Be sure your username is correct.", nil);
        case ABCConditionCodeBadPassword:
            return NSLocalizedString(@"Invalid user name or password", nil);
        case ABCConditionCodeWalletAlreadyExists:
            return NSLocalizedString(@"Wallet already exists.", nil);
        case ABCConditionCodeInvalidWalletID:
            return NSLocalizedString(@"Wallet does not exist.", nil);
        case ABCConditionCodeURLError:
        case ABCConditionCodeServerError:
            return NSLocalizedString(@"Unable to connect to Airbitz server. Please try again later.", nil);
        case ABCConditionCodeNoRecoveryQuestions:
            return NSLocalizedString(@"No recovery questions are available for this user", nil);
        case ABCConditionCodeNotSupported:
            return NSLocalizedString(@"This operation is not supported.", nil);
        case ABCConditionCodeInsufficientFunds:
            return NSLocalizedString(@"Insufficient funds", nil);
        case ABCConditionCodeSpendDust:
            return NSLocalizedString(@"Amount is too small", nil);
        case ABCConditionCodeSynchronizing:
            return NSLocalizedString(@"Synchronizing with the network.", nil);
        case ABCConditionCodeNonNumericPin:
            return NSLocalizedString(@"PIN must be a numeric value.", nil);
        case ABCConditionCodeError:
        case ABCConditionCodeNULLPtr:
        case ABCConditionCodeNoAvailAccountSpace:
        case ABCConditionCodeDirReadError:
        case ABCConditionCodeFileOpenError:
        case ABCConditionCodeFileReadError:
        case ABCConditionCodeFileWriteError:
        case ABCConditionCodeFileDoesNotExist:
        case ABCConditionCodeUnknownCryptoType:
        case ABCConditionCodeInvalidCryptoType:
        case ABCConditionCodeDecryptError:
        case ABCConditionCodeDecryptFailure:
        case ABCConditionCodeEncryptError:
        case ABCConditionCodeScryptError:
        case ABCConditionCodeSysError:
        case ABCConditionCodeNotInitialized:
        case ABCConditionCodeReinitialization:
        case ABCConditionCodeJSONError:
        case ABCConditionCodeMutexError:
        case ABCConditionCodeNoTransaction:
        case ABCConditionCodeParseError:
        case ABCConditionCodeNoRequest:
        case ABCConditionCodeNoAvailableAddress:
        default:
            return NSLocalizedString(@"An error has occurred.", nil);
    }
}

+ (int) getMinimumPasswordLength { return ABC_MIN_PASS_LENGTH; };
+ (int) getMinimumPINLength { return ABC_MIN_PIN_LENGTH; };


////////////////////////////////////////////////////////
#pragma internal routines
////////////////////////////////////////////////////////

- (void)categorizeQuestionChoices:(tABC_QuestionChoices *)pChoices
                   categoryString:(NSMutableArray **)arrayCategoryString
                  categoryNumeric:(NSMutableArray **)arrayCategoryNumeric
                     categoryMust:(NSMutableArray **)arrayCategoryMust
{
    //splits wad of questions into three categories:  string, numeric and must
    if (pChoices)
    {
        if (pChoices->aChoices)
        {
            for (int i = 0; i < pChoices->numChoices; i++)
            {
                tABC_QuestionChoice *pChoice = pChoices->aChoices[i];
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

                [dict setObject: [NSString stringWithFormat:@"%s", pChoice->szQuestion] forKey:@"question"];
                [dict setObject: [NSNumber numberWithInt:pChoice->minAnswerLength] forKey:@"minLength"];

                //printf("question: %s, category: %s, min: %d\n", pChoice->szQuestion, pChoice->szCategory, pChoice->minAnswerLength);

                NSString *category = [NSString stringWithFormat:@"%s", pChoice->szCategory];
                if([category isEqualToString:@"string"])
                {
                    [*arrayCategoryString addObject:dict];
                }
                else if([category isEqualToString:@"numeric"])
                {
                    [*arrayCategoryNumeric addObject:dict];
                }
                else if([category isEqualToString:@"must"])
                {
                    [*arrayCategoryMust addObject:dict];
                }
            }
        }
    }
}

- (BOOL) isLoggedIn
{
    return !(nil == self.name);
}

// replaces the string in the given variable with a duplicate of another
- (void)replaceString:(char **)ppszValue withString:(const char *)szNewValue
{
    if (ppszValue)
    {
        if (*ppszValue)
        {
            free(*ppszValue);
        }
        *ppszValue = strdup(szNewValue);
    }
}



- (void)printABC_Error:(const tABC_Error *)pError
{
    if (pError)
    {
        if (pError->code != ABC_CC_Ok)
        {
            NSString *log;

            log = [NSString stringWithFormat:@"Code: %d, Desc: %s, Func: %s, File: %s, Line: %d\n",
                                             pError->code,
                                             pError->szDescription,
                                             pError->szSourceFunc,
                                             pError->szSourceFile,
                                             pError->nSourceLine];
            ABC_Log([log UTF8String]);
        }
    }
}

- (ABCConditionCode)setLastErrors:(tABC_Error)error;
{
    lastConditionCode = (ABCConditionCode) error.code;
    if (ABCConditionCodeOk == lastConditionCode)
    {
        lastErrorString = @"";
    }
    else
    {
        lastErrorString = [self errorMap:error];
        if (error.code == ABC_CC_DecryptError
                || error.code == ABC_CC_DecryptFailure)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MAIN_RESET object:self];
        }
    }
    return lastConditionCode;
}

- (NSString *)errorMap:(tABC_Error)error;
{
    if (ABCConditionCodeInvalidPinWait == error.code)
    {
        NSString *description = [NSString stringWithUTF8String:error.szDescription];
        if ([@"0" isEqualToString:description]) {
            return NSLocalizedString(@"Invalid PIN.", nil);
        } else {
            return [NSString stringWithFormat:
                    NSLocalizedString(@"Too many failed login attempts. Please try again in %@ seconds.", nil),
                    description];
        }
    }
    else
    {
        return [self conditionCodeMap:(ABCConditionCode) error.code];
    }

}



@end


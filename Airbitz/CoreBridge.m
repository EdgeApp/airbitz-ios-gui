
#import "ABC.h"
#import "Wallet.h"
#import "Transaction.h"
#import "TxOutput.h"
#import "ABC.h"
#import "Config.h"
#import "User.h"
#import "Util.h"
#import "LocalSettings.h"
#import "Keychain.h"

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

#define DOLLAR_CURRENCY_NUMBER	840

static NSDictionary *_localeAsCurrencyNum;
static long long _logoutTimeStamp = 0;

const int64_t RECOVERY_REMINDER_AMOUNT = 10000000;
const int RECOVERY_REMINDER_COUNT = 2;

static BOOL bInitialized = NO;
static BOOL bDataFetched = NO;
static long iLoginTimeSeconds = 0;
static NSOperationQueue *loadedQueue;
static NSOperationQueue *exchangeQueue;
static NSOperationQueue *dataQueue;
static NSOperationQueue *walletsQueue;
static NSOperationQueue *genQRQueue;
static NSOperationQueue *txSearchQueue;
static NSOperationQueue *miscQueue;
static NSOperationQueue *watcherQueue;
static NSLock *watcherLock;
static NSMutableDictionary *watchers;
static NSMutableDictionary *currencyCodesCache;
static NSMutableDictionary *currencySymbolCache;


static CoreBridge *singleton = nil;

@implementation BitidSignature
- (id)init
{
   self = [super init];
   return self;
}
@end

@interface CoreBridge ()
{
}

+ (void)loadTransactions:(Wallet *) wallet;
+ (void)setTransaction:(Wallet *) wallet transaction:(Transaction *) transaction coreTx:(tABC_TxInfo *) pTrans;
+ (NSDate *)dateFromTimestamp:(int64_t) intDate;

@end

@implementation CoreBridge

static NSTimer *_exchangeTimer;
static NSTimer *_dataSyncTimer;
static NSTimer *_notificationTimer;
static BOOL bOtpError = NO;

+ (CoreBridge *)Singleton
{
    return singleton;
}


+ (void)initAll
{
    if (NO == bInitialized)
    {
        loadedQueue = [[NSOperationQueue alloc] init];
        [loadedQueue setMaxConcurrentOperationCount:1];
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

        _localeAsCurrencyNum = @{
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

        singleton = [[CoreBridge alloc] init];
        bInitialized = YES;

        [CoreBridge cleanWallets];

        tABC_Error Error;
        tABC_Currency       *aCurrencies;
        int                 currencyCount;

        Error.code = ABC_CC_Ok;

        NSMutableData *seedData = [[NSMutableData alloc] init];
        [CoreBridge fillSeedData:seedData];

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docs_dir = [paths objectAtIndex:0];
        NSString *ca_path = [[NSBundle mainBundle] pathForResource:@"ca-certificates" ofType:@"crt"];

        Error.code = ABC_CC_Ok;
        ABC_Initialize([docs_dir UTF8String],
                [ca_path UTF8String],
                API_KEY_HEADER,
                CHAIN_API_USERPWD,
                HIDDENBITZ_KEY,
                (unsigned char *)[seedData bytes],
                (unsigned int)[seedData length],
                &Error);
        [Util printABC_Error:&Error];

        // Fetch general info as soon as possible
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            tABC_Error error;
            ABC_GeneralInfoUpdate(&error);
            [Util printABC_Error:&error];
        });

        Error.code = ABC_CC_Ok;

        // get the currencies
        aCurrencies = NULL;
        ABC_GetCurrencies(&aCurrencies, &currencyCount, &Error);
        [Util printABC_Error:&Error];

        singleton.currencyCount = currencyCount;
        // set up our internal currency arrays
        NSMutableArray *arrayCurrencyCodes = [[NSMutableArray alloc] initWithCapacity:singleton.currencyCount];
        NSMutableArray *arrayCurrencyNums = [[NSMutableArray alloc] initWithCapacity:singleton.currencyCount];
        NSMutableArray *arrayCurrencyStrings = [[NSMutableArray alloc] init];
        for (int i = 0; i < singleton.currencyCount; i++)
        {
            [arrayCurrencyStrings addObject:[NSString stringWithFormat:@"%s - %@",
                                                                       aCurrencies[i].szCode,
                                                                       [NSString stringWithUTF8String:aCurrencies[i].szDescription]]];
            [arrayCurrencyNums addObject:[NSNumber numberWithInt:aCurrencies[i].num]];
            [arrayCurrencyCodes addObject:[NSString stringWithUTF8String:aCurrencies[i].szCode]];
        }
        singleton.arrayCurrencyCodes = arrayCurrencyCodes;
        singleton.arrayCurrencyNums = arrayCurrencyNums;
        singleton.arrayCurrencyStrings = arrayCurrencyStrings;
        singleton.arrayCategories = nil;
        singleton.numCategories = 0;
    }
}

+ (void)fillSeedData:(NSMutableData *)data
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



+ (void)freeAll
{
    if (YES == bInitialized)
    {
        exchangeQueue = nil;
        dataQueue = nil;
        walletsQueue = nil;
        genQRQueue = nil;
        singleton = nil;
        txSearchQueue = nil;
        miscQueue = nil;
        loadedQueue = nil;
        watcherQueue = nil;
        bInitialized = NO;
        singleton.arrayCategories = nil;
        singleton.numCategories = 0;
        [CoreBridge cleanWallets];
    }
}

+ (void)startQueues
{
    if ([User isLoggedIn])
    {
        // Initialize the exchange rates queue
        _exchangeTimer = [NSTimer scheduledTimerWithTimeInterval:ABC_EXCHANGE_RATE_REFRESH_INTERVAL_SECONDS
            target:self
            selector:@selector(requestExchangeRateUpdate:)
            userInfo:nil
            repeats:YES];
        // Request one right now
        [self requestExchangeRateUpdate:nil];

        // Initialize data sync queue
        _dataSyncTimer = [NSTimer scheduledTimerWithTimeInterval:FILE_SYNC_FREQUENCY_SECONDS
            target:self
            selector:@selector(requestSyncData:)
            userInfo:nil
            repeats:YES];
        [self requestSyncData:nil];
    }
}

+ (void)stopQueues
{
    if (_exchangeTimer) {
        [_exchangeTimer invalidate];
        _exchangeTimer = nil;
    }
    if (_dataSyncTimer) {
        [_dataSyncTimer invalidate];
        _dataSyncTimer = nil;
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
    if (loadedQueue)
        [loadedQueue cancelAllOperations];

}

+ (void)postToSyncQueue:(void(^)(void))cb;
{
    [dataQueue addOperationWithBlock:cb];
}

+ (void)postToLoadedQueue:(void(^)(void))cb;
{
    [loadedQueue addOperationWithBlock:cb];
}

+ (void)postToWalletsQueue:(void(^)(void))cb;
{
    [walletsQueue addOperationWithBlock:cb];
}

+ (void)postToGenQRQueue:(void(^)(void))cb;
{
    [genQRQueue addOperationWithBlock:cb];
}

+ (void)postToTxSearchQueue:(void(^)(void))cb;
{
    [txSearchQueue addOperationWithBlock:cb];
}

+ (void)postToMiscQueue:(void(^)(void))cb;
{
    [miscQueue addOperationWithBlock:cb];
}

+ (void)postToWatcherQueue:(void(^)(void))cb;
{
    [watcherQueue addOperationWithBlock:cb];
}

+ (int)dataOperationCount
{
    int total = 0;
    total += dataQueue == nil     ? 0 : [dataQueue operationCount];
    total += exchangeQueue == nil ? 0 : [exchangeQueue operationCount];
    total += walletsQueue == nil  ? 0 : [walletsQueue operationCount];
    total += genQRQueue == nil  ? 0 : [genQRQueue operationCount];
    total += txSearchQueue == nil  ? 0 : [txSearchQueue operationCount];
    total += loadedQueue == nil  ? 0 : [loadedQueue operationCount];
    total += watcherQueue == nil  ? 0 : [watcherQueue operationCount];
    return total;
}

+ (void)clearSyncQueue
{
    [dataQueue cancelAllOperations];
}

+ (void)clearTxSearchQueue;
{
    [txSearchQueue cancelAllOperations];
}

+ (void)clearMiscQueue;
{
    [miscQueue cancelAllOperations];
}

// select the wallet with the given UUID
+ (Wallet *)selectWalletWithUUID:(NSString *)strUUID
{
    Wallet *wallet = nil;

    if (strUUID)
    {
        if ([strUUID length])
        {
            // If the transaction view is open, close it

            // look for the wallet in our arrays
            if (singleton.arrayWallets)
            {
                for (Wallet *curWallet in singleton.arrayWallets)
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
                for (Wallet *curWallet in singleton.arrayArchivedWallets)
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


+ (void)loadWalletUUIDs:(NSMutableArray *)arrayUUIDs
{
    tABC_Error Error;
    char **aUUIDS = NULL;
    unsigned int nCount;

    tABC_CC result = ABC_GetWalletUUIDs([[User Singleton].name UTF8String],
                                        [[User Singleton].password UTF8String],
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

+ (Wallet *)getWalletFromCore:(NSString *)uuid
{
    tABC_Error error;
    Wallet *wallet = [[Wallet alloc] init];
    wallet.strUUID = uuid;
    wallet.strName = loadingText;
    wallet.currencyNum = -1;
    wallet.balance = 0;
    wallet.loaded = NO;

    if ([CoreBridge watcherExists:uuid]) {
        char *szName = NULL;
        ABC_WalletName([[User Singleton].name UTF8String], [uuid UTF8String], &szName, &error);
        if (error.code == ABC_CC_Ok) {
            wallet.strName = [NSString safeStringWithUTF8String:szName];
        }
        if (szName) {
            free(szName);
        }

        int currencyNum;
        ABC_WalletCurrency([[User Singleton].name UTF8String], [uuid UTF8String], &currencyNum, &error);
        if (error.code == ABC_CC_Ok) {
            wallet.currencyNum = currencyNum;
            wallet.currencyAbbrev = [CoreBridge currencyAbbrevLookup:wallet.currencyNum];
            wallet.currencySymbol = [CoreBridge currencySymbolLookup:wallet.currencyNum];
            wallet.loaded = YES;
        } else {
            wallet.loaded = NO;
            wallet.currencyNum = -1;
            wallet.strName = loadingText;
        }

        int64_t balance;
        ABC_WalletBalance([[User Singleton].name UTF8String], [uuid UTF8String], &balance, &error);
        if (error.code == ABC_CC_Ok) {
            wallet.balance = balance;
        } else {
            wallet.balance = 0;
        }
    }

    bool archived = false;
    ABC_WalletArchived([[User Singleton].name UTF8String], [uuid UTF8String], &archived, &error);
    wallet.archived = archived ? YES : NO;

    return wallet;
}

+ (void)loadWallets:(NSMutableArray *)arrayWallets withTxs:(BOOL)bWithTx
{
    ABLog(2,@"ENTER loadWallets: %@", [NSThread currentThread].name);

    NSMutableArray *arrayUuids = [[NSMutableArray alloc] init];
    [CoreBridge loadWalletUUIDs:arrayUuids];

    for (NSString *uuid in arrayUuids) {
        Wallet *wallet = [CoreBridge getWalletFromCore:uuid];
        if (bWithTx && wallet.loaded) {
            [self loadTransactions:wallet];
        }
        [arrayWallets addObject:wallet];
    }
    ABLog(2,@"EXIT loadWallets: %@", [NSThread currentThread].name);

}

+ (void)makeCurrentWallet:(Wallet *)wallet
{
    if ([[CoreBridge Singleton].arrayWallets containsObject:[CoreBridge Singleton].currentWallet])
    {
        singleton.currentWallet = wallet;
        singleton.currentWalletID = (int) [singleton.arrayWallets indexOfObject:singleton.currentWallet];
    }

    [CoreBridge postNotificationWalletsChanged];
}

+ (void)makeCurrentWalletWithUUID:(NSString *)strUUID
{
    if ([[CoreBridge Singleton].arrayWallets containsObject:[CoreBridge Singleton].currentWallet])
    {
        Wallet *wallet = [self selectWalletWithUUID:strUUID];
        [self makeCurrentWallet:wallet];
    }
}

+ (void)makeCurrentWalletWithIndex:(NSIndexPath *)indexPath
{
    //
    // Set new wallet. Hide the dropdown. Then reload the TransactionsView table
    //
    if(indexPath.section == 0)
    {
        if ([singleton.arrayWallets count] > indexPath.row)
        {
            singleton.currentWallet = [singleton.arrayWallets objectAtIndex:indexPath.row];
            singleton.currentWalletID = (int) [singleton.arrayWallets indexOfObject:singleton.currentWallet];

        }
    }
    else
    {
        if ([singleton.arrayArchivedWallets count] > indexPath.row)
        {
            singleton.currentWallet = [singleton.arrayArchivedWallets objectAtIndex:indexPath.row];
            singleton.currentWalletID = (int) [singleton.arrayArchivedWallets indexOfObject:singleton.currentWallet];
        }
    }

    [CoreBridge postNotificationWalletsChanged];

}

+ (void)cleanWallets
{
    singleton.arrayWallets = nil;
    singleton.arrayArchivedWallets = nil;
    singleton.arrayWalletNames = nil;
    singleton.arrayUUIDs = nil;
    singleton.currentWallet = nil;
    singleton.currentWalletID = 0;
    singleton.numWalletsLoaded = 0;
    singleton.numTotalWallets = 0;
    singleton.bAllWalletsLoaded = NO;
}

+ (void)refreshWallets
{
    [CoreBridge refreshWallets:nil];
}

+ (void)refreshWallets:(void(^)(void))cb
{
    dispatch_async(dispatch_get_main_queue(),^{
        if ([CoreBridge Singleton].arrayWallets.count == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_WALLETS_LOADING object:self];
        }
    });
    [CoreBridge postToWatcherQueue:^(void) {
        [CoreBridge postToWalletsQueue:^(void) {
            ABLog(2,@"ENTER refreshWallets WalletQueue: %@", [NSThread currentThread].name);
            NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
            NSMutableArray *arrayArchivedWallets = [[NSMutableArray alloc] init];
            NSMutableArray *arrayUUIDs = [[NSMutableArray alloc] init];
            NSMutableArray *arrayWalletNames = [[NSMutableArray alloc] init];

            [CoreBridge loadWallets:arrayWallets archived:arrayArchivedWallets withTxs:true];
            [CoreBridge loadWalletUUIDs:arrayUUIDs];

            //
            // Update wallet names for various dropdowns
            //
            int loadingCount = 0;
            for (int i = 0; i < [arrayWallets count]; i++)
            {
                Wallet *wallet = [arrayWallets objectAtIndex:i];
                [arrayWalletNames addObject:[NSString stringWithFormat:@"%@ (%@)", wallet.strName, [CoreBridge formatSatoshi:wallet.balance]]];
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
                singleton.arrayWallets = arrayWallets;
                singleton.arrayArchivedWallets = arrayArchivedWallets;
                singleton.arrayUUIDs = arrayUUIDs;
                singleton.arrayWalletNames = arrayWalletNames;
                singleton.numTotalWallets = (int) ([arrayWallets count] + [arrayArchivedWallets count]);
                singleton.numWalletsLoaded = singleton.numTotalWallets  - loadingCount;

                if (loadingCount == 0)
                {
                    singleton.bAllWalletsLoaded = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_WALLETS_LOADED object:self];
                }
                else
                {
                    singleton.bAllWalletsLoaded = NO;
                }

                if (nil == singleton.currentWallet)
                {
                    if ([singleton.arrayWallets count] > 0)
                    {
                        singleton.currentWallet = [arrayWallets objectAtIndex:0];
                    }
                    singleton.currentWalletID = 0;
                }
                else
                {
                    NSString *lastCurrentWalletUUID = singleton.currentWallet.strUUID;
                    singleton.currentWallet = [self selectWalletWithUUID:lastCurrentWalletUUID];
                    singleton.currentWalletID = (int) [singleton.arrayWallets indexOfObject:singleton.currentWallet];
                }
                [CoreBridge postNotificationWalletsChanged];

                ABLog(2,@"EXIT refreshWallets MainQueue: %@", [NSThread currentThread].name);

                if (cb) cb();

            });
            ABLog(2,@"EXIT refreshWallets WalletQueue: %@", [NSThread currentThread].name);
        }];
    }];

}

+ (void) postNotificationWalletsChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_WALLETS_CHANGED
                                                        object:self userInfo:nil];
    [CoreBridge updateWidgetQRCode];
}


+ (void)loadWallets:(NSMutableArray *)arrayWallets archived:(NSMutableArray *)arrayArchivedWallets withTxs:(BOOL)bWithTx
{
    [CoreBridge loadWallets:arrayWallets withTxs:bWithTx];

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
+ (void)rotateWalletServer:(NSString *)walletUUID refreshData:(BOOL)bData notify:(void(^)(void))cb
{
    [CoreBridge connectWatcher:walletUUID];
    [CoreBridge postToMiscQueue:^{
        // Reconnect the watcher for this wallet
        if (bData) {
            // Clear data sync queue and sync the current wallet immediately
            [dataQueue cancelAllOperations];
            [dataQueue addOperationWithBlock:^{
                if (![User isLoggedIn]) {
                    return;
                }
                tABC_Error error;
                ABC_DataSyncWallet([[User Singleton].name UTF8String],
                            [[User Singleton].password UTF8String],
                            [walletUUID UTF8String],
                            ABC_BitCoin_Event_Callback,
                            (__bridge void *) singleton,
                            &error);
                [Util printABC_Error: &error];
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

+ (Wallet *)getWallet: (NSString *)walletUUID
{
    for (Wallet *w in singleton.arrayWallets)
    {
        if ([w.strUUID isEqualToString:walletUUID])
            return w;
    }
    for (Wallet *w in singleton.arrayArchivedWallets)
    {
        if ([w.strUUID isEqualToString:walletUUID])
            return w;
    }
    return nil;
}

+ (Transaction *)getTransaction: (NSString *)walletUUID withTx:(NSString *) szTxId;
{
    tABC_Error Error;
    Transaction *transaction = nil;
    tABC_TxInfo *pTrans = NULL;
    Wallet *wallet = [CoreBridge getWallet: walletUUID];
    if (wallet == nil)
    {
        ABLog(2,@("Could not find wallet for %@"), walletUUID);
        return nil;
    }
    tABC_CC result = ABC_GetTransaction([[User Singleton].name UTF8String],
                                        [[User Singleton].password UTF8String],
                                        [walletUUID UTF8String], [szTxId UTF8String],
                                        &pTrans, &Error);
    if (ABC_CC_Ok == result)
    {
        transaction = [[Transaction alloc] init];
        [CoreBridge setTransaction: wallet transaction:transaction coreTx:pTrans];
    }
    else
    {
        ABLog(2,@("Error: CoreBridge.loadTransactions:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
    }
    ABC_FreeTransaction(pTrans);
    return transaction;
}

+ (int64_t)getTotalSentToday:(Wallet *)wallet
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

+ (void) loadTransactions: (Wallet *) wallet
{
    tABC_Error Error;
    unsigned int tCount = 0;
    Transaction *transaction;
    tABC_TxInfo **aTransactions = NULL;
    tABC_CC result = ABC_GetTransactions([[User Singleton].name UTF8String],
                                         [[User Singleton].password UTF8String],
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
            [CoreBridge setTransaction:wallet transaction:transaction coreTx:pTrans];
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
        [Util printABC_Error:&Error];
    }
    ABC_FreeTransactions(aTransactions, tCount);
}

+ (void)setTransaction:(Wallet *) wallet transaction:(Transaction *) transaction coreTx:(tABC_TxInfo *) pTrans
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

+ (int)calcTxConfirmations:(Wallet *) wallet withTxId:(NSString *)txId isSyncing:(bool *)syncing
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

+ (NSMutableArray *)searchTransactionsIn: (Wallet *) wallet query:(NSString *)term addTo:(NSMutableArray *) arrayTransactions 
{
    tABC_Error Error;
    unsigned int tCount = 0;
    Transaction *transaction;
    tABC_TxInfo **aTransactions = NULL;
    tABC_CC result = ABC_SearchTransactions([[User Singleton].name UTF8String],
                                            [[User Singleton].password UTF8String],
                                            [wallet.strUUID UTF8String], [term UTF8String],
                                            &aTransactions, &tCount, &Error);
    if (ABC_CC_Ok == result)
    {
        for (int j = tCount - 1; j >= 0; --j) {
            tABC_TxInfo *pTrans = aTransactions[j];
            transaction = [[Transaction alloc] init];
            [CoreBridge setTransaction:wallet transaction:transaction coreTx:pTrans];
            [arrayTransactions addObject:transaction];
        }
    }
    else 
    {
        ABLog(2,@("Error: CoreBridge.searchTransactionsIn:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
    }
    ABC_FreeTransactions(aTransactions, tCount);
    return arrayTransactions;
}

+ (void)reorderWallets: (NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    tABC_Error Error;
    Wallet *wallet;
    if(sourceIndexPath.section == 0)
    {
        wallet = [singleton.arrayWallets objectAtIndex:sourceIndexPath.row];
        [singleton.arrayWallets removeObjectAtIndex:sourceIndexPath.row];
    }
    else
    {
        wallet = [singleton.arrayArchivedWallets objectAtIndex:sourceIndexPath.row];
        [singleton.arrayArchivedWallets removeObjectAtIndex:sourceIndexPath.row];
    }

    if(destinationIndexPath.section == 0)
    {
        wallet.archived = NO;
        [singleton.arrayWallets insertObject:wallet atIndex:destinationIndexPath.row];

    }
    else
    {
        wallet.archived = YES;
        [singleton.arrayArchivedWallets insertObject:wallet atIndex:destinationIndexPath.row];
    }

    if (sourceIndexPath.section != destinationIndexPath.section)
    {
        // Wallet moved to/from archive. Reset attributes to Core
        [CoreBridge setWalletAttributes:wallet];
    }

    NSMutableString *uuids = [[NSMutableString alloc] init];
    for (Wallet *w in singleton.arrayWallets)
    {
        [uuids appendString:w.strUUID];
        [uuids appendString:@"\n"];
    }
    for (Wallet *w in singleton.arrayArchivedWallets)
    {
        [uuids appendString:w.strUUID];
        [uuids appendString:@"\n"];
    }

    NSString *ids = [uuids stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (ABC_SetWalletOrder([[User Singleton].name UTF8String],
                           [[User Singleton].password UTF8String],
                           (char *)[ids UTF8String],
                           &Error) != ABC_CC_Ok)
    {
        ABLog(2,@("Error: CoreBridge.reorderWallets:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
    }

    [CoreBridge refreshWallets];
}

+ (bool)setWalletAttributes: (Wallet *) wallet
{
    tABC_Error Error;
    tABC_CC result = ABC_SetWalletArchived([[User Singleton].name UTF8String],
                                           [[User Singleton].password UTF8String],
                                           [wallet.strUUID UTF8String],
                                           wallet.archived, &Error);
    if (ABC_CC_Ok == result)
    {
        return true;
    }
    else
    {
        ABLog(2,@("Error: CoreBridge.setWalletAttributes:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
        return false;
    }
}

+ (void)storeTransaction:(Transaction *)transaction
{
    [CoreBridge postToMiscQueue:^{

        tABC_Error Error;
        tABC_TxDetails *pDetails;
        tABC_CC result = ABC_GetTransactionDetails([[User Singleton].name UTF8String],
                [[User Singleton].password UTF8String],
                [transaction.strWalletUUID UTF8String],
                [transaction.strID UTF8String],
                &pDetails, &Error);
        if (ABC_CC_Ok != result) {
            ABLog(2,@("Error: CoreBridge.storeTransaction:  %s\n"), Error.szDescription);
            [Util printABC_Error:&Error];
//            return false;
            return;
        }

        pDetails->szName = (char *) [transaction.strName UTF8String];
        pDetails->szCategory = (char *) [transaction.strCategory UTF8String];
        pDetails->szNotes = (char *) [transaction.strNotes UTF8String];
        pDetails->amountCurrency = transaction.amountFiat;
        pDetails->bizId = transaction.bizId;

        result = ABC_SetTransactionDetails([[User Singleton].name UTF8String],
                [[User Singleton].password UTF8String],
                [transaction.strWalletUUID UTF8String],
                [transaction.strID UTF8String],
                pDetails, &Error);

        if (ABC_CC_Ok != result) {
            ABLog(2,@("Error: CoreBridge.storeTransaction:  %s\n"), Error.szDescription);
            [Util printABC_Error:&Error];
//            return false;
            return;
        }

        [CoreBridge refreshWallets];
//        return true;
        return;
    }];

    return; // This might as well be a void. async task return value can't ever really be tested
}

+ (NSNumberFormatter *)generateNumberFormatter
{
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setMinimumFractionDigits:2];
    [f setMaximumFractionDigits:2];
    [f setLocale:[NSLocale localeWithLocaleIdentifier:@"USD"]];
    return f;
}

+ (NSDate *)dateFromTimestamp:(int64_t) intDate
{
    return [NSDate dateWithTimeIntervalSince1970: intDate];
}

+ (NSString *)formatCurrency:(double) currency withCurrencyNum:(int) currencyNum
{
    return [CoreBridge formatCurrency:currency withCurrencyNum:currencyNum withSymbol:true];
}

+ (NSString *)formatCurrency:(double) currency withCurrencyNum:(int) currencyNum withSymbol:(bool) symbol
{
    NSNumberFormatter *f = [CoreBridge generateNumberFormatter];
    [f setNumberStyle: NSNumberFormatterCurrencyStyle];
    if (symbol) {
        NSString *symbol = [CoreBridge currencySymbolLookup:currencyNum];
        [f setNegativePrefix:[NSString stringWithFormat:@"-%@ ",symbol]];
        [f setNegativeSuffix:@""];
        [f setCurrencySymbol:[NSString stringWithFormat:@"%@ ", symbol]];
    } else {
        [f setCurrencySymbol:@""];
    }
    return [f stringFromNumber:[NSNumber numberWithFloat:currency]];
}

+ (int) currencyDecimalPlaces
{
    int decimalPlaces = 5;
    switch ([[User Singleton] denominationType]) {
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

+ (int) maxDecimalPlaces
{
    int decimalPlaces = 8;
    switch ([[User Singleton] denominationType]) {
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

+ (int64_t) cleanNumString:(NSString *) value
{
    NSNumberFormatter *f = [CoreBridge generateNumberFormatter];
    NSNumber *num = [f numberFromString:value];
    return [num longLongValue];
}

+ (NSString *)formatSatoshi: (int64_t) amount
{
    return [CoreBridge formatSatoshi:amount withSymbol:true];
}

+ (NSString *)formatSatoshi: (int64_t) amount withSymbol:(bool) symbol
{
    return [CoreBridge formatSatoshi:amount withSymbol:symbol cropDecimals:-1];
}

+ (NSString *)formatSatoshi: (int64_t) amount withSymbol:(bool) symbol forceDecimals:(int) forcedecimals
{
    return [CoreBridge formatSatoshi:amount withSymbol:symbol cropDecimals:-1 forceDecimals:forcedecimals];
}

+ (NSString *)formatSatoshi: (int64_t) amount withSymbol:(bool) symbol cropDecimals:(int) decimals
{
    return [CoreBridge formatSatoshi:amount withSymbol:symbol cropDecimals:decimals forceDecimals:-1];
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

+ (NSString *)formatSatoshi: (int64_t) amount withSymbol:(bool) symbol cropDecimals:(int) decimals forceDecimals:(int) forcedecimals
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
            [formatted appendString: [User Singleton].denominationLabelShort];
            [formatted appendString: @" "];
        }
        const char *p = pFormatted;
        const char *decimal = strstr(pFormatted, ".");
        const char *start = (decimal == NULL) ? p + strlen(p) : decimal;
        int offset = (start - pFormatted) % 3;
        NSNumberFormatter *f = [CoreBridge generateNumberFormatter];

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

+ (int64_t) denominationToSatoshi: (NSString *) amount
{
    uint64_t parsedAmount;
    int decimalPlaces = [self maxDecimalPlaces];
    NSString *cleanAmount = [amount stringByReplacingOccurrencesOfString:@"," withString:@""];
    if (ABC_ParseAmount([cleanAmount UTF8String], &parsedAmount, decimalPlaces) != ABC_CC_Ok) {
    }
    return (int64_t) parsedAmount;
}

+ (NSString *)conversionString:(Wallet *) wallet
{
    return [self conversionStringFromNum:wallet.currencyNum withAbbrev:YES];
}

+ (NSString *)conversionStringFromNum:(int) currencyNum withAbbrev:(bool) includeAbbrev
{
    double currency;
    tABC_Error error;

    double denomination = [User Singleton].denomination;
    NSString *denominationLabel = [User Singleton].denominationLabel;
    tABC_CC result = ABC_SatoshiToCurrency([[User Singleton].name UTF8String],
                                           [[User Singleton].password UTF8String],
                                           denomination, &currency, currencyNum, &error);
    [Util printABC_Error:&error];
    if (result == ABC_CC_Ok)
    {
        NSString *abbrev = [CoreBridge currencyAbbrevLookup:currencyNum];
        NSString *symbol = [CoreBridge currencySymbolLookup:currencyNum];
        if ([User Singleton].denominationType == ABC_DENOMINATION_UBTC)
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
+ (NSArray *)getRecoveryQuestionsForUserName:(NSString *)strUserName
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
        [Util printABC_Error:&Error];
    }

    if (szQuestions)
    {
        free(szQuestions);
    }

    return arrayQuestions;
}

+ (BOOL)recoveryAnswers:(NSString *)strAnswers areValidForUserName:(NSString *)strUserName status:(tABC_Error *)error
{
    BOOL bValid = NO;
    bool bABCValid = false;

    tABC_CC result = ABC_CheckRecoveryAnswers([strUserName UTF8String],
                                              [strAnswers UTF8String],
                                              &bABCValid,
                                              error);
    if (ABC_CC_Ok == result)
    {
        if (bABCValid == true)
        {
            bValid = YES;
        }
    }
    else
    {
        [Util printABC_Error:error];
    }

    return bValid;
}

+ (void)incRecoveryReminder
{
    [CoreBridge incRecoveryReminder:1];
}

+ (void)clearRecoveryReminder
{
    [CoreBridge incRecoveryReminder:RECOVERY_REMINDER_COUNT];
}

+ (void)incRecoveryReminder:(int)val
{
    tABC_Error error;
    tABC_AccountSettings *pSettings = NULL;
    tABC_CC cc = ABC_LoadAccountSettings([[User Singleton].name UTF8String],
        [[User Singleton].password UTF8String], &pSettings, &error);
    if (cc == ABC_CC_Ok) {
        pSettings->recoveryReminderCount += val;
        ABC_UpdateAccountSettings([[User Singleton].name UTF8String],
            [[User Singleton].password UTF8String], pSettings, &error);
    }
    ABC_FreeAccountSettings(pSettings);
}

+ (int)getReminderCount
{
    int count = 0;
    tABC_Error error;
    tABC_AccountSettings *pSettings = NULL;
    tABC_CC cc = ABC_LoadAccountSettings([[User Singleton].name UTF8String],
        [[User Singleton].password UTF8String], &pSettings, &error);
    if (cc == ABC_CC_Ok) {
        count = pSettings->recoveryReminderCount;
    }
    ABC_FreeAccountSettings(pSettings);
    return count;
}

+ (BOOL)needsRecoveryQuestionsReminder:(Wallet *)wallet
{
    BOOL bResult = NO;
    int reminderCount = [CoreBridge getReminderCount];
    if (wallet.balance >= RECOVERY_REMINDER_AMOUNT && reminderCount < RECOVERY_REMINDER_COUNT) {
        BOOL bQuestions = NO;
        NSMutableString *errorMsg = [[NSMutableString alloc] init];
        [CoreBridge getRecoveryQuestionsForUserName:[User Singleton].name
                                            isSuccess:&bQuestions
                                            errorMsg:errorMsg];
        if (!bQuestions) {
            [CoreBridge incRecoveryReminder];
            bResult = YES;
        } else {
            [CoreBridge clearRecoveryReminder];
        }
    }
    return bResult;
}

+ (bool)PINLoginExists
{
    NSString *username = [LocalSettings controller].cachedUsername;
    
    return [self PINLoginExists:username];
}

+ (bool)PINLoginExists:(NSString *)username
{
    bool exists = NO;
    if (username && 0 < username.length)
    {
        tABC_Error error;
        tABC_CC result = ABC_PinLoginExists([username UTF8String],
                                            &exists,
                                            &error);
        if (ABC_CC_Ok != result)
        {
            [Util printABC_Error:&error];
        }
    }
    return exists;
}

+ (void)deletePINLogin
{
    NSString *username = NULL;
    if ([User isLoggedIn])
    {
        username = [User Singleton].name;
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
            [Util printABC_Error:&error];
        }
    }
}

+ (void)setupLoginPIN
{
    NSString *name = [User Singleton].name;
    if (name && 0 < name.length)
    {
        const char *username = [name UTF8String];
        NSString *pass = [User Singleton].password;
        const char *password = (nil == pass ? NULL : [pass UTF8String]);

        // retrieve the user's settings to check whether PIN logins are disabled
        tABC_CC cc = ABC_CC_Ok;
        tABC_Error Error;
        tABC_AccountSettings *pSettings = NULL;
        
        cc = ABC_LoadAccountSettings(username,
                                     password,
                                     &pSettings,
                                     &Error);
        if (cc == ABC_CC_Ok) {
            if (!pSettings->bDisablePINLogin)
            {
                // attempt to setup the PIN package on disk
                tABC_Error error;
                tABC_CC result = ABC_PinSetup(username,
                                              password,
                                              &error);
                if (ABC_CC_Ok != result)
                {
                    [Util printABC_Error:&error];
                }
            }
        } else {
            [Util printABC_Error:&Error];
        }
        ABC_FreeAccountSettings(pSettings);
    }
}

+ (void)PINLoginWithPIN:(NSString *)PIN error:(tABC_Error *)pError
{
    if ([CoreBridge PINLoginExists])
    {
        NSString *username = [LocalSettings controller].cachedUsername;
        tABC_CC result = ABC_PinLogin([username UTF8String],
                                      [PIN UTF8String],
                                      pError);
        if (ABC_CC_Ok == result)
        {
            [User login:[LocalSettings controller].cachedUsername password:NULL];
        }
    }
    else
    {
        pError->code = ABC_CC_BadPassword;
    }
}

+ (BOOL)recentlyLoggedIn
{
    long now = (long) [[NSDate date] timeIntervalSince1970];
    return now - iLoginTimeSeconds <= PIN_REQUIRED_PERIOD_SECONDS;
}

+ (void)login
{
    NSString *username = [User Singleton].name;
    if (username && 0 < username.length)
    {
        [LocalSettings controller].cachedUsername = [User Singleton].name;
    }

    [LocalSettings saveAll];
    bDataFetched = NO;
    bOtpError = NO;
    [CoreBridge startPrimaryWallet];
    [CoreBridge postToWatcherQueue: ^
    {
        [CoreBridge postToLoadedQueue:^
        {
            [CoreBridge startAsyncTasks];
        }];
    }];

    iLoginTimeSeconds = [CoreBridge saveLogoutDate];
    [CoreBridge loadCategories];
}

+ (BOOL)didLoginExpire:(NSString *)username;
{
    //
    // If app was killed then the static var _logoutTimeStamp will be zero so we'll pull the cached value
    // from the iOS Keychain. Also, on non A7 processors, we won't save anything in the keychain so we need
    // the static var to take care of cases where app is not killed.
    //
    if (0 == _logoutTimeStamp)
    {
        _logoutTimeStamp = [Keychain getKeychainInt:[Keychain createKeyWithUsername:[LocalSettings controller].cachedUsername key:LOGOUT_TIME_KEY] error:nil];
    }

    if (!_logoutTimeStamp) return YES;

    long long currentTimeStamp = [[NSDate date] timeIntervalSince1970];

    if (currentTimeStamp > _logoutTimeStamp)
    {
        return YES;
    }

    return NO;
}

//
// Saves the UNIX timestamp when user should be auto logged out
// Returns the current time
//

+ (long) saveLogoutDate;
{
    long currentTimeStamp = (long) [[NSDate date] timeIntervalSince1970];
    _logoutTimeStamp = currentTimeStamp + (60 * [User Singleton].minutesAutoLogout);

    // Save in iOS Keychain
    [Keychain setKeychainInt:_logoutTimeStamp
                         key:[Keychain createKeyWithUsername:[User Singleton].name key:LOGOUT_TIME_KEY]
               authenticated:YES];

    return currentTimeStamp;
}

+ (void)startPrimaryWallet;
{
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWalletUUIDs: arrayWallets];
    if (0 < [arrayWallets count]) {
        NSString *uuid = arrayWallets[0];
        [CoreBridge postToLoadedQueue:^{
            tABC_Error error;
            ABC_WalletLoad([[User Singleton].name UTF8String], [uuid UTF8String], &error);
            [Util printABC_Error:&error];
            [CoreBridge startWatcher:uuid];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [CoreBridge refreshWallets];
            });
        }];
    }
}

+ (void)startAsyncTasks
{
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWalletUUIDs: arrayWallets];
    bool bIsFirstWallet = YES;
    for (NSString *uuid in arrayWallets) {
        if (bIsFirstWallet)
        {
            bIsFirstWallet = NO;
            continue;
        }
        [CoreBridge postToLoadedQueue:^{
            tABC_Error error;
            ABC_WalletLoad([[User Singleton].name UTF8String], [uuid UTF8String], &error);
            [Util printABC_Error:&error];
            [CoreBridge startWatcher:uuid];
        }];
    }
    [CoreBridge postToLoadedQueue:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [CoreBridge startQueues];
        });
    }];
    [CoreBridge postToLoadedQueue:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [CoreBridge refreshWallets];
        });
    }];
}

+ (void)stopAsyncTasks
{
    [CoreBridge stopQueues];

    unsigned long wq, dq, gq, txq, eq, mq, lq;

    // XXX: prevents crashing on logout
    while (YES)
    {
        wq = (unsigned long)[walletsQueue operationCount];
        dq = (unsigned long)[dataQueue operationCount];
        gq = (unsigned long)[genQRQueue operationCount];
        txq = (unsigned long)[txSearchQueue operationCount];
        eq = (unsigned long)[exchangeQueue operationCount];
        mq = (unsigned long)[miscQueue operationCount];
        lq = (unsigned long)[loadedQueue operationCount];

//        if (0 == (wq + dq + gq + txq + eq + mq + lq))
        if (0 == (wq + gq + txq + eq + mq + lq))
            break;

        ABLog(0,
            @"Waiting for queues to complete wq=%lu dq=%lu gq=%lu txq=%lu eq=%lu mq=%lu lq=%lu",
            wq, dq, gq, txq, eq, mq, lq);
        [NSThread sleepForTimeInterval:.2];
    }

    [CoreBridge stopWatchers];
    [CoreBridge cleanWallets];
}

+ (void)logout
{
    [CoreBridge stopAsyncTasks];

    tABC_Error Error;
    tABC_CC result = ABC_ClearKeyCache(&Error);

    if (ABC_CC_Ok != result)
    {
        [Util printABC_Error:&Error];
    }
}

+ (BOOL)passwordOk:(NSString *)password
{
    NSString *name = [User Singleton].name;
    bool ok = false;
    if (name && 0 < name.length)
    {
        const char *username = [name UTF8String];

        tABC_Error Error;
        ABC_PasswordOk(username, [password UTF8String], &ok, &Error);
        [Util printABC_Error:&Error];
    }
    return ok == true ? YES : NO;
}

+ (BOOL)passwordExists
{
    return [CoreBridge passwordExists:[User Singleton].name];
}

+ (BOOL)passwordExists:(NSString *)username;
{
    tABC_Error error;
    bool exists = false;
    ABC_PasswordExists([username UTF8String], &exists, &error);
    if (error.code == ABC_CC_Ok) {
        return exists == true ? YES : NO;
    }
    return YES;
}

+ (BOOL)allWatchersReady
{
    return YES;
}

+ (BOOL)watcherIsReady:(NSString *)UUID
{
    return YES;
}

+ (void)startWatchers
{
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWalletUUIDs: arrayWallets];
    for (NSString *uuid in arrayWallets) {
        [CoreBridge startWatcher:uuid];
    }
    if (bDataFetched) {
        [CoreBridge connectWatchers];
    }
}

+ (void)connectWatchers
{
    if ([User isLoggedIn]) {
        NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
        [CoreBridge loadWalletUUIDs:arrayWallets];
        for (NSString *uuid in arrayWallets)
        {
            [CoreBridge connectWatcher:uuid];
        }
    }
}

+ (void)connectWatcher:(NSString *)uuid
{
//    dispatch_async(dispatch_get_main_queue(),^{
    [CoreBridge postToWatcherQueue: ^{
        if ([User isLoggedIn]) {
            tABC_Error Error;
            ABC_WatcherConnect([uuid UTF8String], &Error);

            [Util printABC_Error:&Error];
            [self watchAddresses:uuid];
        }
    }];
//    });
}

+ (void)disconnectWatchers
{
    if ([User isLoggedIn])
    {
        NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
        [CoreBridge loadWalletUUIDs: arrayWallets];
        for (NSString *uuid in arrayWallets) {
            [CoreBridge postToWatcherQueue: ^{
                const char *szUUID = [uuid UTF8String];
                tABC_Error Error;
                ABC_WatcherDisconnect(szUUID, &Error);
                [Util printABC_Error:&Error];
            }];
        }
    }
}

+ (BOOL)watcherExists:(NSString *)uuid
{
    [watcherLock lock];
    BOOL exists = [watchers objectForKey:uuid] == nil ? NO : YES;
    [watcherLock unlock];
    return exists;
}

+ (NSOperationQueue *)watcherGet:(NSString *)uuid
{
    [watcherLock lock];
    NSOperationQueue *queue = [watchers objectForKey:uuid];
    [watcherLock unlock];
    return queue;
}

+ (void)watcherSet:(NSString *)uuid queue:(NSOperationQueue *)queue
{
    [watcherLock lock];
    [watchers setObject:queue forKey:uuid];
    [watcherLock unlock];
}

+ (void)watcherRemove:(NSString *)uuid
{
    [watcherLock lock];
    [watchers removeObjectForKey:uuid];
    [watcherLock unlock];
}

+ (void)startWatcher:(NSString *) walletUUID
{
    [CoreBridge postToWatcherQueue: ^{
        if (![CoreBridge watcherExists:walletUUID]) {
            tABC_Error Error;
            const char *szUUID = [walletUUID UTF8String];
            ABC_WatcherStart([[User Singleton].name UTF8String],
                            [[User Singleton].password UTF8String],
                            szUUID, &Error);
            [Util printABC_Error: &Error];

            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            [CoreBridge watcherSet:walletUUID queue:queue];
            [queue addOperationWithBlock:^{
                [queue setName:walletUUID];
                tABC_Error Error;
                ABC_WatcherLoop([walletUUID UTF8String],
                        ABC_BitCoin_Event_Callback,
                        (__bridge void *) singleton,
                        &Error);
                [Util printABC_Error:&Error];
            }];

            [CoreBridge watchAddresses:walletUUID];
            if (bDataFetched) {
                [CoreBridge connectWatcher:walletUUID];
            }
            [CoreBridge requestWalletDataSync:walletUUID];
        }
    }];
}

+ (void)stopWatchers
{
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWalletUUIDs: arrayWallets];
    // stop watchers
    [CoreBridge postToWatcherQueue: ^{
        for (NSString *uuid in arrayWallets) {
            tABC_Error Error;
            ABC_WatcherStop([uuid UTF8String], &Error);
        }
        // wait for threads to finish
        for (NSString *uuid in arrayWallets) {
            NSOperationQueue *queue = [CoreBridge watcherGet:uuid];
            if (queue == nil) {
                continue;
            }
            // Wait until operations complete
            [queue waitUntilAllOperationsAreFinished];
            // Remove the watcher from the dictionary
            [CoreBridge watcherRemove:uuid];
        }
        // Destroy watchers
        for (NSString *uuid in arrayWallets) {
            tABC_Error Error;
            ABC_WatcherDelete([uuid UTF8String], &Error);
            [Util printABC_Error:&Error];
        }
    }];
    
    while ([watcherQueue operationCount]);
}

+ (void)deleteWatcherCache;
{
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWalletUUIDs:arrayWallets];
    // stop watchers
    for (NSString *uuid in arrayWallets) {
        tABC_Error error;
        ABC_WatcherDeleteCache([uuid UTF8String], &error);
    }
}

+ (void)restoreConnectivity
{
    [CoreBridge connectWatchers];
    [CoreBridge startQueues];
}

+ (void)lostConnectivity
{
}

+ (void)prioritizeAddress:(NSString *)address inWallet:(NSString *)walletUUID
{
    char *szAddress = NULL;
    if (address)
    {
        szAddress = (char *)[address UTF8String];
    }

    if (walletUUID == nil)
        return;

    [CoreBridge postToWatcherQueue:^{
        tABC_Error Error;
        ABC_PrioritizeAddress([[User Singleton].name UTF8String],
                              [[User Singleton].password UTF8String],
                              [walletUUID UTF8String],
                              [address UTF8String],
                              &Error);
        [Util printABC_Error: &Error];
        
    }];
}

+ (void)watchAddresses: (NSString *) walletUUID
{
    tABC_Error Error;
    ABC_WatchAddresses([[User Singleton].name UTF8String],
                    [[User Singleton].password UTF8String],
                    [walletUUID UTF8String], &Error);
    [Util printABC_Error: &Error];
}

+ (void)requestExchangeRateUpdate:(NSTimer *)object
{
    dispatch_async(dispatch_get_main_queue(),^
    {
        NSMutableArray *arrayCurrencyNums= [[NSMutableArray alloc] init];

        for (Wallet *w in singleton.arrayWallets)
        {
            if (w.loaded) {
                [arrayCurrencyNums addObject:[NSNumber numberWithInteger:w.currencyNum]];
            }
        }
        for (Wallet *w in singleton.arrayArchivedWallets)
        {
            if (w.loaded) {
                [arrayCurrencyNums addObject:[NSNumber numberWithInteger:w.currencyNum]];
            }
        }

        [exchangeQueue addOperationWithBlock:^{
            [[NSThread currentThread] setName:@"Exchange Rate Update"];
            [CoreBridge requestExchangeUpdateBlocking:arrayCurrencyNums];
        }];
    });
}

+ (void)requestExchangeUpdateBlocking:(NSMutableArray *)currencyNums
{
    if ([User isLoggedIn])
    {
        tABC_Error error;
        // Check the default currency for updates
        ABC_RequestExchangeRateUpdate([[User Singleton].name UTF8String],
                                      [[User Singleton].password UTF8String],
                                      [User Singleton].defaultCurrencyNum, &error);
        [Util printABC_Error: &error];

        // Check each wallet is up to date
        for (NSNumber *n in currencyNums)
        {
            // We pass no callback so this call is blocking
            ABC_RequestExchangeRateUpdate([[User Singleton].name UTF8String],
                                          [[User Singleton].password UTF8String],
                                          [n intValue], &error);
            [Util printABC_Error: &error];
        }

        dispatch_async(dispatch_get_main_queue(),^{
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_EXCHANGE_RATE_CHANGE object:self];
        });
    }
}

+ (void)requestSyncData:(NSTimer *)object
{
    // Do not request a sync one is currently in progress
    if ([dataQueue operationCount] > 0) {
        return;
    }

    // Fetch general info
    [dataQueue addOperationWithBlock:^{
        tABC_Error error;
        ABC_GeneralInfoUpdate(&error);
        [Util printABC_Error:&error];
    }];
    // Sync Account
    if (bDataFetched) {
        [dataQueue addOperationWithBlock:^{
            [[NSThread currentThread] setName:@"Data Sync"];
            tABC_Error error;
            tABC_CC cc =
                ABC_DataSyncAccount([[User Singleton].name UTF8String],
                                    [[User Singleton].password UTF8String],
                                    ABC_BitCoin_Event_Callback,
                                    (__bridge void *) singleton,
                                    &error);
            if (cc == ABC_CC_InvalidOTP) {
                if ([self getOtpSecret] != nil) {
                    [singleton performSelectorOnMainThread:@selector(notifyOtpSkew:)
                                                withObject:nil
                                            waitUntilDone:NO];
                } else {
                    [singleton performSelectorOnMainThread:@selector(notifyOtpRequired:)
                                                withObject:nil
                                            waitUntilDone:NO];
                }
            }
        }];
    }
    // Sync Wallets
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWalletUUIDs: arrayWallets];
    for (NSString *uuid in arrayWallets) {
        [CoreBridge requestWalletDataSync:uuid];
    }
    // Mark data as sync'd
    [dataQueue addOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(),^{
            bDataFetched = YES;
        });
    }];
}

+ (void)requestWalletDataSync:(NSString *)uuid
{
    [dataQueue addOperationWithBlock:^{
        tABC_Error error;
        ABC_DataSyncWallet([[User Singleton].name UTF8String],
                        [[User Singleton].password UTF8String],
                        [uuid UTF8String],
                        ABC_BitCoin_Event_Callback,
                        (__bridge void *) singleton,
                        &error);
        [Util printABC_Error: &error];

        // Start watcher if the data has not been fetch
        if (!bDataFetched) {
            [CoreBridge connectWatcher:uuid];
            [CoreBridge requestExchangeRateUpdate:nil];
        }
    }];
}

+ (bool)isTestNet
{
    bool result = false;
    tABC_Error Error;

    if (ABC_IsTestNet(&result, &Error) != ABC_CC_Ok) {
        [Util printABC_Error: &Error];
    }
    return result;
}

+ (NSString *)coreVersion
{
    NSString *version;
    char *szVersion = NULL;
    ABC_Version(&szVersion, NULL);
    version = [NSString stringWithUTF8String:szVersion];
    free(szVersion);
    return version;
}

+ (NSString *)currencyAbbrevLookup:(int)currencyNum
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

+ (NSString *)currencySymbolLookup:(int)currencyNum
{
    NSNumber *c = [NSNumber numberWithInt:currencyNum];
    NSString *cached = [currencySymbolCache objectForKey:c];
    if (cached != nil) {
        return cached;
    }
    NSNumberFormatter *formatter = nil;
    NSString *code = [CoreBridge currencyAbbrevLookup:currencyNum];
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
+ (int)getCurrencyNumOfLocale
{
    NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
    NSString *localCurrency = [locale objectForKey:NSLocaleCurrencyCode];
    NSNumber *currencyNum = [_localeAsCurrencyNum objectForKey:localCurrency];
    if (currencyNum)
    {
        return [currencyNum intValue];
    }
    return CURRENCY_NUM_USD;
}

/*
 * set a new default currency for the account based on the parameter
 */
+ (bool)setDefaultCurrencyNum:(int)currencyNum
{
    tABC_CC cc = ABC_CC_Ok;
    tABC_Error Error;
    tABC_AccountSettings *pSettings = NULL;
    cc = ABC_LoadAccountSettings([[User Singleton].name UTF8String],
                                 [[User Singleton].password UTF8String],
                                 &pSettings,
                                 &Error);
    if (cc == ABC_CC_Ok) {
        pSettings->currencyNum = currencyNum;
        ABC_UpdateAccountSettings([[User Singleton].name UTF8String],
                                  [[User Singleton].password UTF8String],
                                  pSettings,
                                  &Error);
        if (cc == ABC_CC_Ok)
        {
            [[User Singleton] loadSettings];
        }
        else
        {
            [Util printABC_Error:&Error];
        }
    } else {
        [Util printABC_Error:&Error];
    }
    ABC_FreeAccountSettings(pSettings);
    return cc == ABC_CC_Ok;
}

+ (void)updateWidgetQRCode;
{

    if (!singleton.currentWallet || !singleton.currentWallet.strUUID)
        return;

    NSString *strUUID = singleton.currentWallet.strUUID;

    [CoreBridge postToGenQRQueue:^(void) {

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

        _details.szName = (char *) [[User Singleton].fullName UTF8String];
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
        result = ABC_CreateReceiveRequest([[User Singleton].name UTF8String],
                [[User Singleton].password UTF8String],
                [strUUID UTF8String],
                &_details,
                &pRequestID,
                &error);

        if (result == ABC_CC_Ok)
        {
            unsigned int width = 0;
            UIImage *qrImage;

            result = ABC_GenerateRequestQRCode([[User Singleton].name UTF8String],
                    [[User Singleton].password UTF8String],
                    [strUUID UTF8String],
                    pRequestID,
                    &pszURI,
                    &pData,
                    &width,
                    &error);

            if (result == ABC_CC_Ok)
            {
                qrImage = [Util dataToImage:pData withWidth:width andHeight:width];


                tABC_CC result = ABC_GetRequestAddress([[User Singleton].name UTF8String],
                        [[User Singleton].password UTF8String],
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
                    [tempSharedUserDefs setObject:[CoreBridge Singleton].currentWallet.strName forKey:APP_GROUP_LAST_WALLET_KEY];
                    [tempSharedUserDefs setObject:[User Singleton].name forKey:APP_GROUP_LAST_ACCOUNT_KEY];
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

+ (void)setupNewAccount
{
    [dataQueue addOperationWithBlock:^{
        // update user's default currency num to match their locale
        int currencyNum = [CoreBridge getCurrencyNumOfLocale];
        [CoreBridge setDefaultCurrencyNum:currencyNum];

        NSMutableArray *wallets = [[NSMutableArray alloc] init];
        [CoreBridge loadWalletUUIDs:wallets];

        if ([wallets count] == 0)
        {
            // create first wallet if it doesn't already exist
            tABC_Error error;
            char *szUUID = NULL;
            ABC_CreateWallet([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                    [NSLocalizedString(@"My Wallet", @"Name of initial wallet") UTF8String],
                    currencyNum, &szUUID, &error);
            if (szUUID) {
                free(szUUID);
            }

        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DATA_SYNC_UPDATE object:nil];
            [FadingAlertView dismiss:NO];
        });
        [CoreBridge startWatchers];

    }];
    
    [CoreBridge loadCategories];
}

+ (void)addCategory:(NSString *)strCategory;
{
    // check and see that it doesn't already exist
    if ([singleton.arrayCategories indexOfObject:strCategory] == NSNotFound)
    {
        // add the category to the core
        tABC_Error Error;
        ABC_AddCategory([[User Singleton].name UTF8String],
                        [[User Singleton].password UTF8String],
                        (char *)[strCategory UTF8String], &Error);
        [Util printABC_Error:&Error];
    }
    [CoreBridge loadCategories];
}

+ (void) loadCategories;
{
//    if (nil == singleton.arrayCategories || !singleton.numCategories)
    {
        [dataQueue addOperationWithBlock:^{
            char            **aszCategories = NULL;
            unsigned int    countCategories = 0;
            NSMutableArray *mutableArrayCategories = [[NSMutableArray alloc] init];
            
            // get the categories from the core
            tABC_Error error;
            ABC_GetCategories([[User Singleton].name UTF8String],
                              [[User Singleton].password UTF8String],
                              &aszCategories,
                              &countCategories,
                              &error);
            
            [Util printABC_Error:&error];
            
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
                    
                    ABC_AddCategory([[User Singleton].name UTF8String],
                                    [[User Singleton].password UTF8String],
                                    (char *)[strCategory UTF8String], &error);
                    [Util printABC_Error:&error];
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
                singleton.arrayCategories = tempArray;
                singleton.numCategories = countCategories;
            });
        }];
    }
}

// saves the categories to the core
+ (void)saveCategories:(NSMutableArray *)saveArrayCategories;
{
    tABC_Error Error;
    
    // got through the existing categories
    for (NSString *strCategory in singleton.arrayCategories)
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
            ABC_RemoveCategory([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], (char *)[strCategory UTF8String], &Error);
            [Util printABC_Error:&Error];
        }
    }
    
    // add any categories from our new list that didn't exist in the core list
    for (NSString *strCategory in saveArrayCategories)
    {
        ABC_AddCategory([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], (char *)[strCategory UTF8String], &Error);
        [Util printABC_Error:&Error];
    }
    [CoreBridge loadCategories];
}


+ (NSString *)sweepKey:(NSString *)privateKey intoWallet:(NSString *)walletUUID withCallback:(tABC_Sweep_Done_Callback)callback
{
    tABC_CC result = ABC_CC_Ok;
    tABC_Error Error;
    char *pszAddress = NULL;
    void *pData = NULL;
    result = ABC_SweepKey([[User Singleton].name UTF8String],
                  [[User Singleton].password UTF8String],
                  [walletUUID UTF8String],
                  [privateKey UTF8String],
                  &pszAddress,
                  callback,
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
        [CoreBridge refreshWallets:^
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

    unsigned long numWallets = [singleton.arrayWallets count] + [singleton.arrayArchivedWallets count];

    [CoreBridge loadCategories];
    
    [CoreBridge refreshWallets:^
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DATA_SYNC_UPDATE object:self];

        // if there are new wallets, we need to start their watchers
        if ([singleton.arrayWallets count] + [singleton.arrayArchivedWallets count] != numWallets)
        {
            [CoreBridge startWatchers];
        }
    }];
}

- (void)notifyDataSyncDelayed:(NSArray *)params
{
    if (_notificationTimer) {
        [_notificationTimer invalidate];
    }

    if (! [User isLoggedIn])
        return;

    _notificationTimer = [NSTimer scheduledTimerWithTimeInterval:NOTIFY_DATA_SYNC_DELAY
        target:self
        selector:@selector(notifyDataSync:)
        userInfo:nil
        repeats:NO];
}

- (void)notifyRemotePasswordChange:(NSArray *)params
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REMOTE_PASSWORD_CHANGE object:self];
}

+ (void)otpSetError:(tABC_CC)cc
{
    bOtpError = ABC_CC_InvalidOTP == cc;
}

+ (BOOL)otpHasError;
{
    return bOtpError;
}

+ (void)otpClearError
{
    bOtpError = NO;
}

+ (NSString *)getOtpSecret
{
    tABC_Error error;
    NSString *secret = nil;
    char *szSecret = NULL;
    ABC_OtpKeyGet([[User Singleton].name UTF8String], &szSecret, &error);
    if (error.code == ABC_CC_Ok && szSecret) {
        secret = [NSString stringWithUTF8String:szSecret];
    }
    if (szSecret) {
        free(szSecret);
    }
    ABLog(2,@("SECRET: %@"), secret);
    return secret;
}

+ (NSString *) bitidParseURI:(NSString *)uri;
{
    tABC_Error error;
    char *szURLDomain = NULL;
    NSString *urlDomain;

    ABC_BitidParseUri([[User Singleton].name UTF8String], nil, [uri UTF8String], &szURLDomain, &error);

    if (error.code == ABC_CC_Ok && szURLDomain) {
        urlDomain = [NSString stringWithUTF8String:szURLDomain];
    }
    if (szURLDomain) {
        free(szURLDomain);
    }
    ABLog(2,@("bitidParseURI domain: %@"), urlDomain);
    return urlDomain;

}

+ (BOOL) bitidLogin:(NSString *)uri;
{
    tABC_Error error;

    ABC_BitidLogin([[User Singleton].name UTF8String], nil, [uri UTF8String], &error);

    if (error.code == ABC_CC_Ok)
        return YES;
    return NO;
}

+ (BitidSignature *)bitidSign:(NSString *)uri msg:(NSString *)message 
{
    tABC_Error error;
    char *szAddress = NULL;
    char *szSignature = NULL;
    BitidSignature *bitid = [[BitidSignature alloc] init];

    tABC_CC result = ABC_BitidSign(
        [[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
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

+ (NSArray *)getLocalAccounts:(NSString **)strError;
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


+ (void)uploadLogs:(NSString *)userText notify:(void(^)(void))cb error:(void(^)(void))cberror;
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
    
    [CoreBridge postToMiscQueue:^{
        tABC_Error error;
        ABC_UploadLogs([[User Singleton].name UTF8String], NULL, &error);
        dispatch_async(dispatch_get_main_queue(),^{
            if (ABC_CC_Ok == error.code) {
                if (cb) cb();
            } else {
                if (cberror) cberror();
            }
        });
    }];
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
        [CoreBridge refreshWallets];
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


@end

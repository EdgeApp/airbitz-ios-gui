
#import "ABC.h"
#import "Wallet.h"
#import "Transaction.h"
#import "TxOutput.h"
#import "ABC.h"
#import "User.h"
#import "Util.h"
#import "LocalSettings.h"

#import "CoreBridge.h"

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

#define FILE_SYNC_FREQUENCY_SECONDS     10
#define NOTIFY_DATA_SYNC_DELAY          1

#define DOLLAR_CURRENCY_NUMBER	840

static NSDictionary *_localeAsCurrencyNum;

const int64_t RECOVERY_REMINDER_AMOUNT = 2000000;
const int RECOVERY_REMINDER_COUNT = 2;

static BOOL bInitialized = NO;
static BOOL bDataFetched = NO;
static int iLoginTimeSeconds = 0;
static NSOperationQueue *exchangeQueue;
static NSOperationQueue *dataQueue;
static NSMutableDictionary *watchers;
static CoreBridge *singleton = nil;

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

+ (void)initAll
{
    if (NO == bInitialized)
    {
        exchangeQueue = [[NSOperationQueue alloc] init];
        [exchangeQueue setMaxConcurrentOperationCount:1];
        dataQueue = [[NSOperationQueue alloc] init];
        [dataQueue setMaxConcurrentOperationCount:1];

        watchers = [[NSMutableDictionary alloc] init];

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
    }
}

+ (void)freeAll
{
    if (YES == bInitialized)
    {
        exchangeQueue = nil;
        dataQueue = nil;
        singleton = nil;
        bInitialized = NO;
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
    if (_exchangeTimer)
    {
        [_exchangeTimer invalidate];
        _exchangeTimer = nil;
    }
    if (_dataSyncTimer)
    {
        [_dataSyncTimer invalidate];
        _dataSyncTimer = nil;
    }
    if (dataQueue)
    {
        [dataQueue cancelAllOperations];
    }
}

+ (void)postToSyncQueue:(void(^)(void))cb;
{
    [dataQueue addOperationWithBlock:cb];
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

+ (void)loadWallets:(NSMutableArray *)arrayWallets withTxs:(BOOL)bWithTx
{
    tABC_Error Error;
    tABC_WalletInfo **aWalletInfo = NULL;
    unsigned int nCount;

    NSLog(@"CoreBridge.LoadWallets\n");
    tABC_CC result = ABC_GetWallets([[User Singleton].name UTF8String],
                                    [[User Singleton].password UTF8String],
                                    &aWalletInfo, &nCount, &Error);
    if (ABC_CC_Ok == result)
    {
        if (aWalletInfo)
        {
            unsigned int i;
            for (i = 0; i < nCount; ++i)
            {
                Wallet *wallet;
                tABC_WalletInfo *pWalletInfo = aWalletInfo[i];
                // If entry is NULL skip it
                if (!pWalletInfo)
                {
                    continue;
                }

                wallet = [[Wallet alloc] init];
                [CoreBridge setWallet:wallet withInfo:pWalletInfo];
                [arrayWallets addObject:wallet];
                if (bWithTx) {
                    [self loadTransactions: wallet];
                }
            }
        }
    }
    else
    {
        NSLog(@("Error: CoreBridge.loadWallets:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
    }
    ABC_FreeWalletInfoArray(aWalletInfo, nCount);
}

+ (void)loadWallets:(NSMutableArray *)arrayWallets
{
    [CoreBridge loadWallets:arrayWallets withTxs:YES];
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

+ (void)loadWallets:(NSMutableArray *)arrayWallets archived:(NSMutableArray *)arrayArchivedWallets
{
    [CoreBridge loadWallets:arrayWallets archived:arrayArchivedWallets withTxs:YES];
}

+ (void)reloadWallet:(Wallet *) wallet;
{
    tABC_Error Error;
    tABC_WalletInfo *pWalletInfo = NULL;
    tABC_CC result = ABC_GetWalletInfo([[User Singleton].name UTF8String],
                                       [[User Singleton].password UTF8String],
                                       [wallet.strUUID UTF8String],
                                       &pWalletInfo, &Error);
    if (ABC_CC_Ok == result && pWalletInfo != NULL)
    {
        wallet.strName = [NSString stringWithUTF8String: pWalletInfo->szName];
        wallet.strUUID = [NSString stringWithUTF8String: pWalletInfo->szUUID];
        wallet.archived = pWalletInfo->archived;
        wallet.balance = pWalletInfo->balanceSatoshi;
        wallet.currencyNum = pWalletInfo->currencyNum;
        [self loadTransactions:wallet];
    }
    else
    {
        NSLog(@("Error: CoreBridge.reloadWallets:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
    }
    ABC_FreeWalletInfo(pWalletInfo);
}

+ (void)refreshWallet:(NSString *)walletUUID refreshData:(BOOL)bData notify:(void(^)(void))cb
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Reconnect the watcher for this wallet
        [CoreBridge connectWatcher:walletUUID];
        if (bData) {
                // Clear data sync queue and sync the current wallet immediately
                [dataQueue cancelAllOperations];
                [dataQueue addOperationWithBlock:^{
                tABC_Error error;
                ABC_DataSyncWallet([[User Singleton].name UTF8String],
                            [[User Singleton].password UTF8String],
                            [walletUUID UTF8String],
                            ABC_BitCoin_Event_Callback,
                            (__bridge void *) singleton,
                            &error);
                [Util printABC_Error: &error];
                dispatch_async(dispatch_get_main_queue(),^{
                    cb();
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(),^{
                cb();
            });
        }
    });
}

+ (Wallet *)getWallet: (NSString *)walletUUID
{
    tABC_Error Error;
    Wallet *wallet = nil;
    tABC_WalletInfo *pWalletInfo = NULL;
    tABC_CC result = ABC_GetWalletInfo([[User Singleton].name UTF8String],
                                       [[User Singleton].password UTF8String],
                                       [walletUUID UTF8String],
                                       &pWalletInfo, &Error);
    if (ABC_CC_Ok == result && pWalletInfo != NULL)
    {
        wallet = [[Wallet alloc] init];
        [CoreBridge setWallet:wallet withInfo:pWalletInfo];
    }
    else
    {
        NSLog(@("Error: CoreBridge.reloadWallets:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
    }
    ABC_FreeWalletInfo(pWalletInfo);
    return wallet;
}

+ (Transaction *)getTransaction: (NSString *)walletUUID withTx:(NSString *) szTxId;
{
    tABC_Error Error;
    Transaction *transaction = nil;
    tABC_TxInfo *pTrans = NULL;
    Wallet *wallet = [CoreBridge getWallet: walletUUID];
    if (wallet == nil)
    {
        NSLog(@("Could not find wallet for %@"), walletUUID);
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
        NSLog(@("Error: CoreBridge.loadTransactions:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
    }
    ABC_FreeTransaction(pTrans);
    return transaction;
}

+ (int64_t)getTotalSentToday:(Wallet *)wallet
{
    tABC_Error Error;
    unsigned int tCount = 0;
    int64_t total = 0;
    tABC_TxInfo **aTransactions = NULL;

    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSUInteger preservedComponents = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit);
    NSDate *thisMorning = [calendar dateFromComponents:[calendar components:preservedComponents fromDate:date]];
    
    tABC_CC result = ABC_GetTransactions([[User Singleton].name UTF8String],
                                         [[User Singleton].password UTF8String],
                                         [wallet.strUUID UTF8String],
                                         [thisMorning timeIntervalSince1970],
                                         [thisMorning timeIntervalSince1970] + 1000 * 60 * 60 * 24,
                                         &aTransactions,
                                         &tCount, &Error);
    if (ABC_CC_Ok == result) {
        for (int j = tCount - 1; j >= 0; --j) {
            tABC_TxInfo *pTrans = aTransactions[j];
            // Is this a spend?
            if (pTrans->pDetails->amountSatoshi < 0) {
                total += pTrans->pDetails->amountSatoshi * -1;
            }
        }
    } else {
        [Util printABC_Error:&Error];
    }
    ABC_FreeTransactions(aTransactions, tCount);
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
    }
    else
    {
        NSLog(@("Error: CoreBridge.loadTransactions:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
    }
    ABC_FreeTransactions(aTransactions, tCount);
}

+ (void)setWallet:(Wallet *) wallet withInfo:(tABC_WalletInfo *) pWalletInfo
{
    wallet.strUUID = [NSString stringWithUTF8String: pWalletInfo->szUUID];
    wallet.strName = [NSString stringWithUTF8String: pWalletInfo->szName];
    wallet.archived = pWalletInfo->archived;
    wallet.balance = pWalletInfo->balanceSatoshi;
    wallet.currencyNum = pWalletInfo->currencyNum;
    wallet.currencyAbbrev = [CoreBridge currencyAbbrevLookup:wallet.currencyNum];
    wallet.currencySymbol = [CoreBridge currencySymbolLookup:wallet.currencyNum];
    wallet.loaded = wallet.currencyNum == -1 ? NO : YES;
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
                                                 withTxId:transaction.strMallealbeID
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

+ (unsigned int)calcTxConfirmations:(Wallet *) wallet withTxId:(NSString *)txId isSyncing:(bool *)syncing
{
    tABC_Error Error;
    unsigned int txHeight = 0;
    unsigned int blockHeight = 0;
    *syncing = NO;
    if ([wallet.strUUID length] == 0 || [txId length] == 0) {
        return 0;
    }
    if (ABC_TxHeight([wallet.strUUID UTF8String], [txId UTF8String], &txHeight, &Error) != ABC_CC_Ok) {
        *syncing = YES;
        return 0;
    }
    if (ABC_BlockHeight([wallet.strUUID UTF8String], &blockHeight, &Error) != ABC_CC_Ok) {
        *syncing = YES;
        return 0;
    }
    if (txHeight == 0 || blockHeight == 0) {
        return 0;
    }
    return (blockHeight - txHeight) + 1;
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
        NSLog(@("Error: CoreBridge.searchTransactionsIn:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
    }
    ABC_FreeTransactions(aTransactions, tCount);
    return arrayTransactions;
}

+ (void)setWalletOrder: (NSMutableArray *) arrayWallets archived:(NSMutableArray *) arrayArchivedWallets
{
    tABC_Error Error;
    int i = 0;
    unsigned int walletCount = (unsigned int) [arrayWallets count] + (unsigned int)[arrayArchivedWallets count];
    const char **paUUIDS = malloc(sizeof(char *) * walletCount);
    for (Wallet *w in arrayWallets)
    {
        paUUIDS[i] = [w.strUUID UTF8String];
        i++;
    }
    for (Wallet *w in arrayArchivedWallets)
    {
        paUUIDS[i] = [w.strUUID UTF8String];
        i++;
    }
    if (ABC_SetWalletOrder([[User Singleton].name UTF8String],
                           [[User Singleton].password UTF8String],
                           (char **)paUUIDS,
                           walletCount,
                           &Error) != ABC_CC_Ok)
    {
        NSLog(@("Error: CoreBridge.setWalletOrder:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
    }
    free(paUUIDS);
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
        NSLog(@("Error: CoreBridge.setWalletAttributes:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
        return false;
    }
}

+ (bool)storeTransaction: (Transaction *) transaction
{
    tABC_Error Error;
    tABC_TxDetails *pDetails;
    tABC_CC result = ABC_GetTransactionDetails([[User Singleton].name UTF8String],
                                               [[User Singleton].password UTF8String],
                                               [transaction.strWalletUUID UTF8String],
                                               [transaction.strID UTF8String],
                                               &pDetails, &Error);
    if (ABC_CC_Ok != result)
    {
        NSLog(@("Error: CoreBridge.storeTransaction:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
        return false;
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
    
    if (ABC_CC_Ok != result)
    {
        NSLog(@("Error: CoreBridge.storeTransaction:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
        return false;
    }

    return true;
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
            decimalPlaces = 5;
            break;
        case ABC_DENOMINATION_MBTC:
            decimalPlaces = 3;
            break;
        case ABC_DENOMINATION_UBTC:
            decimalPlaces = 2;
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
    int64_t parsedAmount;
    int decimalPlaces = [self maxDecimalPlaces];
#warning TODO this should be handled by the ABC_ParseAmount...maybe
    NSString *cleanAmount = [amount stringByReplacingOccurrencesOfString:@"," withString:@""];
    if (ABC_ParseAmount([cleanAmount UTF8String], &parsedAmount, decimalPlaces) != ABC_CC_Ok)
    {
#warning TODO handle error
    }
    return parsedAmount;
}

+ (NSString *)conversionString:(Wallet *) wallet
{
    double currency;
    tABC_Error error;

    double denomination = [User Singleton].denomination;
    NSString *denominationLabel = [User Singleton].denominationLabel;
    tABC_CC result = ABC_SatoshiToCurrency([[User Singleton].name UTF8String],
                                           [[User Singleton].password UTF8String],
                                           denomination, &currency, wallet.currencyNum, &error);
    [Util printABC_Error:&error];
    if (result == ABC_CC_Ok)
        return [NSString stringWithFormat:@"1 %@ = %@ %.3f %@", denominationLabel, wallet.currencySymbol, currency, wallet.currencyAbbrev];
    else
        return @"";
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

+ (BOOL)recoveryAnswers:(NSString *)strAnswers areValidForUserName:(NSString *)strUserName
{
    BOOL bValid = NO;
    bool bABCValid = false;

    tABC_Error Error;
    tABC_CC result = ABC_CheckRecoveryAnswers([strUserName UTF8String],
                                              [strAnswers UTF8String],
                                              &bABCValid,
                                              &Error);
    if (ABC_CC_Ok == result)
    {
        if (bABCValid == true)
        {
            bValid = YES;
        }
    }
    else
    {
        [Util printABC_Error:&Error];
    }

    return bValid;
}

+ (BOOL)needsRecoveryQuestionsReminder:(Wallet *)wallet
{
    tABC_CC cc = ABC_CC_Ok;
    tABC_Error Error;
    tABC_AccountSettings *pSettings = NULL;
    BOOL bResult = NO;

    cc = ABC_LoadAccountSettings([[User Singleton].name UTF8String],
                                 [[User Singleton].password UTF8String],
                                 &pSettings,
                                 &Error);
    if (cc == ABC_CC_Ok) {
        if (wallet.balance >= RECOVERY_REMINDER_AMOUNT && pSettings->recoveryReminderCount < RECOVERY_REMINDER_COUNT) {
            bool bQuestions = NO;
            NSMutableString *errorMsg = [[NSMutableString alloc] init];
            [CoreBridge getRecoveryQuestionsForUserName:[User Singleton].name
                                              isSuccess:&bQuestions
                                               errorMsg:errorMsg];
            if (!bQuestions) {
                pSettings->recoveryReminderCount++;
                ABC_UpdateAccountSettings([[User Singleton].name UTF8String],
                                          [[User Singleton].password UTF8String],
                                          pSettings,
                                          &Error);
                bResult = YES;
            }
        }
    } else {
        [Util printABC_Error:&Error];
    }
    ABC_FreeAccountSettings(pSettings);
    return bResult;
}

+ (NSString *)getPIN
{
    tABC_Error error;
    char *szPIN = NULL;
    NSString *storedPIN = nil;

    NSString *name = [User Singleton].name;
    if (name && 0 < name.length)
    {
        NSString *pass = [User Singleton].password;
        const char *password = (nil == pass ? NULL : [pass UTF8String]);
        const char *username = [name UTF8String];
        ABC_GetPIN(username,
                   password,
                   &szPIN, &error);
        [Util printABC_Error:&error];
    }
    if (szPIN) {
        storedPIN = [NSString stringWithUTF8String:szPIN];
    }
    free(szPIN);
    return storedPIN;
}

+ (bool)PINLoginExists
{
    NSString *username = [LocalSettings controller].cachedUsername;
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

+ (tABC_CC)PINLoginWithPIN:(NSString *)PIN
{
    if ([CoreBridge PINLoginExists])
    {
        NSString *username = [LocalSettings controller].cachedUsername;
        tABC_Error error;
        tABC_CC result = ABC_PinLogin([username UTF8String],
                                      [PIN UTF8String],
                                      &error);
        if (ABC_CC_Ok == result)
        {
            [User login:[LocalSettings controller].cachedUsername password:NULL];
        }
        return result;
    }
    else
    {
        return ABC_CC_PinExpired;
    }
}

+ (int)loginTimeSeconds
{
    return iLoginTimeSeconds;
}

+ (void)login
{
    NSString *username = [User Singleton].name;
    if (username && 0 < username.length)
    {
        [LocalSettings controller].cachedUsername = [User Singleton].name;
    }

    [LocalSettings saveAll];
    [CoreBridge setupLoginPIN];
    bDataFetched = NO;
    [CoreBridge startQueues];
    [CoreBridge startWatchers];

    iLoginTimeSeconds = (int) [[NSDate date] timeIntervalSince1970];
}

+ (void)logout
{
    [CoreBridge stopWatchers];
    [CoreBridge stopQueues];

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
        [CoreBridge loadWalletUUIDs: arrayWallets];
        for (NSString *uuid in arrayWallets) {
            [CoreBridge connectWatcher:uuid];
        }
    }
}

+ (void)connectWatcher:(NSString *)uuid
{
    if ([User isLoggedIn]) {
        tABC_Error Error;
        ABC_WatcherConnect([uuid UTF8String], &Error);
        [Util printABC_Error:&Error];
        [self watchAddresses:uuid];
    }
}

+ (void)disconnectWatchers
{
    if ([User isLoggedIn])
    {
        NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
        [CoreBridge loadWalletUUIDs: arrayWallets];
        for (NSString *uuid in arrayWallets) {
            const char *szUUID = [uuid UTF8String];
            tABC_Error Error;
            ABC_WatcherDisconnect(szUUID, &Error);
            [Util printABC_Error:&Error];
        }
    }
}

+ (void)startWatcher:(NSString *) walletUUID
{
    const char *szUUID = [walletUUID UTF8String];
    if ([watchers objectForKey:walletUUID] == nil)
    {
        tABC_Error Error;
        ABC_WatcherStart([[User Singleton].name UTF8String],
                        [[User Singleton].password UTF8String],
                        szUUID, &Error);
        [Util printABC_Error: &Error];

        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [watchers setObject:queue forKey:walletUUID];

        [queue addOperationWithBlock:^{
            [queue setName:walletUUID];
            tABC_Error Error;
            ABC_WatcherLoop([walletUUID UTF8String],
                    ABC_BitCoin_Event_Callback,
                    (__bridge void *) singleton,
                    &Error);
            [Util printABC_Error:&Error];
        }];

        ABC_WatchAddresses([[User Singleton].name UTF8String],
                            [[User Singleton].password UTF8String],
                            szUUID, &Error);
        [Util printABC_Error:&Error];

        if (bDataFetched) {
            [CoreBridge connectWatcher:walletUUID];
        }
    }
}

+ (void)stopWatchers
{
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWalletUUIDs: arrayWallets];
    // stop watchers
    for (NSString *uuid in arrayWallets)
    {
        tABC_Error Error;
        ABC_WatcherStop([uuid UTF8String], &Error);
    }
    // wait for threads to finish
    for (NSString *uuid in arrayWallets)
    {
        NSOperationQueue *queue = [watchers objectForKey:uuid];
        if (queue == nil) {
            continue;
        }
        // Wait until operations complete
        [queue waitUntilAllOperationsAreFinished];
        // Remove the watcher from the dictionary
        [watchers removeObjectForKey:uuid];
    }
    // Destroy watchers
    for (NSString *uuid in arrayWallets)
    {
        tABC_Error Error;
        ABC_WatcherDelete([uuid UTF8String], &Error);
        [Util printABC_Error: &Error];
    }
}

+ (void)prioritizeAddress:(NSString *)address inWallet:(NSString *)walletUUID
{
    char *szAddress = NULL;
    if (address)
    {
        szAddress = (char *)[address UTF8String];
    }
    tABC_Error Error;
    ABC_PrioritizeAddress([[User Singleton].name UTF8String],
                          [[User Singleton].password UTF8String],
                          [walletUUID UTF8String],
                          [address UTF8String],
                          &Error);
    [Util printABC_Error: &Error];
}

+ (void)watchAddresses: (NSString *) walletUUID
{
    tABC_Error Error;
    ABC_WatchAddresses([[User Singleton].name UTF8String],
                       [[User Singleton].password UTF8String],
                       [walletUUID UTF8String], &Error);
    [Util printABC_Error: &Error];
}

+ (uint64_t)maxSpendable:(NSString *)walletUUID
               toAddress:(NSString *)destAddress
              isTransfer:(BOOL)bTransfer
{
    tABC_Error Error;
    uint64_t result = 0;
    ABC_MaxSpendable([[User Singleton].name UTF8String],
                     [[User Singleton].password UTF8String],
                     [walletUUID UTF8String],
                     [destAddress UTF8String],
                     bTransfer, &result, &Error);
    [Util printABC_Error: &Error];
    return result;
}

+ (bool)calcSendFees:(NSString *) walletUUID 
                 sendTo:(NSString *) destAddr
           amountToSend:(int64_t) sendAmount
         storeResultsIn:(int64_t *) totalFees
         walletTransfer:(bool) bTransfer
{
    tABC_Error error;
    tABC_TxDetails details;
    details.amountSatoshi = sendAmount;
    details.amountCurrency = 0;
    details.amountFeesAirbitzSatoshi = 0;
    details.amountFeesMinersSatoshi = 0;
    details.szName = "";
    details.szCategory = "";
    details.szNotes = "";
    details.attributes = 0;
    if (ABC_CalcSendFees([[User Singleton].name UTF8String],
                         [[User Singleton].password UTF8String],
                         [walletUUID UTF8String],
                         [destAddr UTF8String],
                         bTransfer,
                         &details,
                         totalFees,
                         &error) != ABC_CC_Ok)
    {
        if (error.code != ABC_CC_InsufficientFunds)
        {
            [Util printABC_Error: &error];
        }
        return false;
    }
    return true;
}

+ (void)requestExchangeRateUpdate:(NSTimer *)object
{
    [exchangeQueue addOperationWithBlock:^{
        [[NSThread currentThread] setName:@"Exchange Rate Update"];
        [CoreBridge requestExchangeUpdateBlocking];
    }];
}

+ (void)requestExchangeUpdateBlocking
{
    if ([User isLoggedIn])
    {
        tABC_Error error;
        // Check the default currency for updates
        ABC_RequestExchangeRateUpdate([[User Singleton].name UTF8String],
                                      [[User Singleton].password UTF8String],
                                      [User Singleton].defaultCurrencyNum, NULL, NULL, &error);
        [Util printABC_Error: &error];

        NSMutableArray *wallets = [[NSMutableArray alloc] init];
        [CoreBridge loadWallets:wallets withTxs:NO];

        // Check each wallet is up to date
        for (Wallet *w in wallets)
        {
            // We pass no callback so this call is blocking
            ABC_RequestExchangeRateUpdate([[User Singleton].name UTF8String],
                                          [[User Singleton].password UTF8String],
                                          w.currencyNum, NULL, NULL, &error);
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
    // Sync Account
    if (bDataFetched) {
        [dataQueue addOperationWithBlock:^{
            [[NSThread currentThread] setName:@"Data Sync"];
            tABC_Error error;
            ABC_DataSyncAccount([[User Singleton].name UTF8String],
                                [[User Singleton].password UTF8String],
                                ABC_BitCoin_Event_Callback,
                                (__bridge void *) singleton,
                                &error);
            [Util printABC_Error: &error];
        }];
    }
    // Sync Wallets
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWalletUUIDs: arrayWallets];
    for (NSString *uuid in arrayWallets) {
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
            dispatch_async(dispatch_get_main_queue(),^{
                if (!bDataFetched) {
                    [CoreBridge connectWatcher:uuid];
                    [CoreBridge requestExchangeRateUpdate:nil];
                }
            });
        }];
    }
    // Mark data as sync'd
    [dataQueue addOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(),^{
            bDataFetched = YES;
        });
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

+ (NSString *)currencyAbbrevLookup:(int) currencyNum
{
#warning TODO move this to the core
    if (currencyNum == CURRENCY_NUM_USD) {
        return @"USD";
    } else if (currencyNum == CURRENCY_NUM_CAD) {
        return @"CAD";
    } else if (currencyNum == CURRENCY_NUM_MXN) {
        return @"MXN";
    } else if (currencyNum == CURRENCY_NUM_GBP) {
        return @"GBP";
    } else if (currencyNum == CURRENCY_NUM_CUP) {
        return @"CUP";
    } else if (currencyNum == CURRENCY_NUM_CNY) {
        return @"CNY";
    } else if (currencyNum == CURRENCY_NUM_EUR) {
        return @"EUR";
    } else if (currencyNum == CURRENCY_NUM_AUD) {
        return @"AUD";
    } else if (currencyNum == CURRENCY_NUM_HKD) {
        return @"HKD";
    } else if (currencyNum == CURRENCY_NUM_NZD) {
        return @"NZD";
    } else if (currencyNum == CURRENCY_NUM_PHP) {
        return @"PHP";
    } else {
        return @"USD";
    }
}

+ (NSString *)currencySymbolLookup:(int) currencyNum
{
    switch (currencyNum) {
        case CURRENCY_NUM_CNY:
            return @"¥";
        case CURRENCY_NUM_EUR:
            return @"€";
        case CURRENCY_NUM_GBP:
            return @"£";
        case CURRENCY_NUM_CUP:
        case CURRENCY_NUM_PHP:
            return @"₱";
            return @"₱";
        default:
            return @"$";
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

+ (void)setupNewAccount:(FadingAlertView *)fadingAlert
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // update user's default currency num to match their locale
        int currencyNum = [CoreBridge getCurrencyNumOfLocale];
        [CoreBridge setDefaultCurrencyNum:currencyNum];

        // create first wallet
        tABC_CC result;
        tABC_Error Error;
        char **szUUID = NULL;
        result = ABC_CreateWallet([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                  [NSLocalizedString(@"My Wallet", @"Name of initial wallet") UTF8String],
                                  currencyNum,
                                  0, NULL, &szUUID, &Error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DATA_SYNC_UPDATE object:nil];
            [fadingAlert dismiss:YES];
        });
        free(szUUID);
        [CoreBridge startWatchers];

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
        for (int i = 0; i < [arrayCategories count]; i++) {
            NSString *strCategory = [arrayCategories objectAtIndex:i];
            ABC_AddCategory([[User Singleton].name UTF8String],
                            [[User Singleton].password UTF8String],
                            (char *)[strCategory UTF8String], &Error);
            [Util printABC_Error:&Error];
        }
    });
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
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TX_RECEIVED object:self userInfo:params[0]];
    }

}

- (void)notifyBlockHeight:(NSArray *)params
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_BLOCK_HEIGHT_CHANGE object:self];
}

- (void)notifyExchangeRate:(NSArray *)params
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_EXCHANGE_RATE_CHANGE object:self];
}

- (void)notifyDataSync:(NSArray *)params
{
    // if there are new wallets, we need to start their watchers
    [CoreBridge startWatchers];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DATA_SYNC_UPDATE object:self];

}

- (void)notifyDataSyncDelayed:(NSArray *)params
{
    if (_notificationTimer) {
        [_notificationTimer invalidate];
    }
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
    } else if (pInfo->eventType == ABC_AsyncEventType_BlockHeightChange) {
        [coreBridge performSelectorOnMainThread:@selector(notifyBlockHeight:) withObject:nil waitUntilDone:NO];
    } else if (pInfo->eventType == ABC_AsyncEventType_ExchangeRateUpdate) {
        [coreBridge performSelectorOnMainThread:@selector(notifyExchangeRate:) withObject:nil waitUntilDone:NO];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SWEEP
                                                        object:nil
                                                      userInfo:sweepData];
}

@end

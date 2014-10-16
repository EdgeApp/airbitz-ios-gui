
#import "ABC.h"
#import "Wallet.h"
#import "Transaction.h"
#import "TxOutput.h"
#import "ABC.h"
#import "User.h"
#import "Util.h"
#import "CommonTypes.h"

#import "CoreBridge.h"

#import <pthread.h>

#define CURRENCY_NUM_CAD                124
#define CURRENCY_NUM_CNY                156
#define CURRENCY_NUM_CUP                192
#define CURRENCY_NUM_MXN                484
#define CURRENCY_NUM_GBP                826
#define CURRENCY_NUM_USD                840
#define CURRENCY_NUM_EUR                978
#define FILE_SYNC_FREQUENCY_SECONDS     10

const int64_t RECOVERY_REMINDER_AMOUNT = 2000000;
const int RECOVERY_REMINDER_COUNT = 2;

static BOOL bInitialized = NO;
static BOOL bDataFetched = NO;
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

+ (void)initAll
{
    if (NO == bInitialized)
    {
        exchangeQueue = [[NSOperationQueue alloc] init];
        [exchangeQueue setMaxConcurrentOperationCount:1];
        dataQueue = [[NSOperationQueue alloc] init];
        [dataQueue setMaxConcurrentOperationCount:1];

        watchers = [[NSMutableDictionary alloc] init];
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
    [f setMinimumFractionDigits:3];
    [f setMaximumFractionDigits:3];
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
        if (wallet.balance > RECOVERY_REMINDER_AMOUNT && pSettings->recoveryReminderCount < RECOVERY_REMINDER_COUNT) {
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

+ (void)login
{
    bDataFetched = NO;
    [CoreBridge startQueues];
    [CoreBridge startWatchers];
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
    NSLog(@("******* %ld\n"), result);
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
            return @"₱";
        default:
            return @"$";
    }
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
        [coreBridge performSelectorOnMainThread:@selector(notifyDataSync:) withObject:nil waitUntilDone:NO];
    } else if (pInfo->eventType == ABC_AsyncEventType_RemotePasswordChange) {
        [coreBridge performSelectorOnMainThread:@selector(notifyRemotePasswordChange:) withObject:nil waitUntilDone:NO];
    }
}

@end



#import "ABC.h"
#import "Wallet.h"
#import "Transaction.h"
#import "TxOutput.h"
#import "ABC.h"
#import "User.h"
#import "Util.h"

#import "CoreBridge.h"

#define CURRENCY_NUM_CAD                124
#define CURRENCY_NUM_CNY                156
#define CURRENCY_NUM_MXN                484
#define CURRENCY_NUM_USD                840
#define CURRENCY_NUM_EUR                978

@interface CoreBridge ()
{
}

@property (nonatomic, strong) NSMutableArray *arrayWallets;
@property (nonatomic, strong) NSMutableArray *arrayArchivedWallets;

+ (void)loadTransactions:(Wallet *) wallet;
+ (void)setTransaction:(Wallet *) wallet transaction:(Transaction *) transaction coreTx:(tABC_TxInfo *) pTrans;
+ (NSDate *)dateFromTimestamp:(int64_t) intDate;

@end

@implementation CoreBridge

+ (void)loadWallets:(NSMutableArray *)arrayWallets
{
    tABC_Error Error;
    tABC_WalletInfo **aWalletInfo = NULL;
    unsigned int nCount;

    tABC_CC result = ABC_GetWallets([[User Singleton].name UTF8String],
                                    [[User Singleton].password UTF8String],
                                    &aWalletInfo, &nCount, &Error);
    if (ABC_CC_Ok == result)
    {
        unsigned int i;
        for (i = 0; i < nCount; ++i)
        {
            Wallet *wallet;
            tABC_WalletInfo *pWalletInfo = aWalletInfo[i];

            wallet = [[Wallet alloc] init];
            [CoreBridge setWallet:wallet withInfo:pWalletInfo];
            [arrayWallets addObject:wallet];
            [self loadTransactions: wallet];
        }
    }
    else
    {
        NSLog(@("Error: CoreBridge.loadWallets:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
    }
    ABC_FreeWalletInfoArray(aWalletInfo, nCount);
}

+ (void)loadWallets:(NSMutableArray *)arrayWallets archived:(NSMutableArray *) arrayArchivedWallets
{
    [CoreBridge loadWallets:arrayWallets];

    // go through all the wallets and seperate out the archived ones
    for (int i = (int) [arrayWallets count] - 1; i >= 0; i--)
    {
        Wallet *wallet = [arrayWallets objectAtIndex:i];

        // if this is an archived wallet
        if ((wallet.attributes & WALLET_ATTRIBUTE_ARCHIVE_BIT) == 1)
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

+ (void)reloadWallet: (Wallet *) wallet;
{
    tABC_Error Error;
    tABC_WalletInfo *pWalletInfo = NULL;
    tABC_CC result = ABC_GetWalletInfo([[User Singleton].name UTF8String],
                                       [[User Singleton].password UTF8String],
                                       [wallet.strUUID UTF8String],
                                       &pWalletInfo, &Error);
    if (ABC_CC_Ok == result)
    {
        wallet.strName = [NSString stringWithUTF8String: pWalletInfo->szName];
        wallet.strUUID = [NSString stringWithUTF8String: pWalletInfo->szUUID];
        wallet.attributes = 0;
        wallet.balance = pWalletInfo->balanceSatoshi;
        wallet.currencyNum = pWalletInfo->currencyNum;
        [self loadTransactions: wallet];
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
    if (ABC_CC_Ok == result)
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
                                         [wallet.strUUID UTF8String], &aTransactions,
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
    wallet.attributes = pWalletInfo->attributes;
    wallet.balance = pWalletInfo->balanceSatoshi;
    wallet.currencyNum = pWalletInfo->currencyNum;
#warning TODO move this to the core
    if (wallet.currencyNum == CURRENCY_NUM_USD) {
        wallet.currencySymbol = @"USD";
    } else if (wallet.currencyNum == CURRENCY_NUM_CAD) {
        wallet.currencySymbol = @"CAD";
    } else if (wallet.currencyNum == CURRENCY_NUM_MXN) {
        wallet.currencySymbol = @"MXN";
    } else if (wallet.currencyNum == CURRENCY_NUM_CNY) {
        wallet.currencySymbol = @"CNY";
    } else if (wallet.currencyNum == CURRENCY_NUM_EUR) {
        wallet.currencySymbol = @"EUR";
    } else {
        wallet.currencySymbol = @"USD";
    }
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
    transaction.confirmations = [self calcTxConfirmations:wallet withTxId:transaction.strMallealbeID];
    transaction.bConfirmed = transaction.confirmations >= CONFIRMED_CONFIRMATION_COUNT;
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
}

+ (unsigned int)calcTxConfirmations:(Wallet *) wallet withTxId:(NSString *)txId
{
    tABC_Error Error;
    unsigned int txHeight = 0;
    unsigned int blockHeight = 0;
    if ([wallet.strUUID length] == 0 || [txId length] == 0)
    {
        return 0;
    }
    if (ABC_TxHeight([wallet.strUUID UTF8String], [txId UTF8String], &txHeight, &Error) != ABC_CC_Ok)
    {
        NSLog(@("Error: CoreBridge.calcTxConfirmations:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
        return 0;
    }
    if (ABC_BlockHeight([wallet.strUUID UTF8String], &blockHeight, &Error) != ABC_CC_Ok)
    {
        NSLog(@("Error: CoreBridge.calcTxConfirmations:  %s\n"), Error.szDescription);
        [Util printABC_Error:&Error];
        return 0;
    }
    if (txHeight == 0 || blockHeight == 0)
        return 0;
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
    tABC_CC result = ABC_SetWalletAttributes([[User Singleton].name UTF8String],
                                             [[User Singleton].password UTF8String],
                                             [wallet.strUUID UTF8String],
                                             wallet.attributes, &Error);
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

+ (NSDate *)dateFromTimestamp:(int64_t) intDate
{
    return [NSDate dateWithTimeIntervalSince1970: intDate];
}

+ (NSString *)formatCurrency: (double) currency
{
    return [CoreBridge formatCurrency:currency withSymbol:true];
}

+ (NSString *)formatCurrency: (double) currency withSymbol:(bool) symbol
{
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle: NSNumberFormatterCurrencyStyle];
    if (symbol)
        [f setCurrencySymbol:@"$ "];
    else
        [f setCurrencySymbol:@""];
    return [f stringFromNumber:[NSNumber numberWithFloat:currency]];
}

+ (int) currencyDecimalPlaces
{
    int decimalPlaces = 5;
    if ([[[User Singleton] denominationLabel] isEqualToString:@"uBTC"])
        decimalPlaces = 2;
    else if ([[[User Singleton] denominationLabel] isEqualToString:@"mBTC"])
        decimalPlaces = 3;
    return decimalPlaces;
}

+ (int) maxDecimalPlaces
{
    int decimalPlaces = 8;
    if ([[[User Singleton] denominationLabel] isEqualToString:@"µBTC"])
        decimalPlaces = 2;
    else if ([[[User Singleton] denominationLabel] isEqualToString:@"mBTC"])
        decimalPlaces = 5;
    return decimalPlaces;
}

+ (int64_t) cleanNumString:(NSString *) value
{
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    NSNumber *num = [f numberFromString:value];
    return [num longLongValue];
}

+ (NSString *)formatSatoshi: (int64_t) amount
{
    return [CoreBridge formatSatoshi:amount withSymbol:true];
}

+ (NSString *)formatSatoshi: (int64_t) amount withSymbol:(bool) symbol
{
    return [CoreBridge formatSatoshi:amount withSymbol:symbol overrideDecimals:-1];
}

+ (NSString *)formatSatoshi: (int64_t) amount withSymbol:(bool) symbol overrideDecimals:(int) decimals
{
    tABC_Error error;
    char *pFormatted = NULL;
    int decimalPlaces = [self maxDecimalPlaces];
    bool negative = amount < 0;
    amount = llabs(amount);
    if (ABC_FormatAmount(amount, &pFormatted, decimalPlaces, &error) != ABC_CC_Ok)
    {
        return nil;
    }
    else
    {
        decimalPlaces = decimals > -1 ? decimals : decimalPlaces;
        NSMutableString *formatted = [[NSMutableString alloc] init];
        if (negative)
            [formatted appendString: @"("];
        if (symbol)
        {
            [formatted appendString: [User Singleton].denominationLabelShort];
            [formatted appendString: @" "];
        }
        const char *p = pFormatted;
        const char *decimal = strstr(pFormatted, ".");
        const char *start = (decimal == NULL) ? p + strlen(p) : decimal;
        int offset = (start - pFormatted) % 3;
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
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
        if (negative)
            [formatted appendString: @")"];
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
    tABC_CC result = ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                           denomination, &currency, wallet.currencyNum, &error);
    [Util printABC_Error:&error];
    if (result == ABC_CC_Ok)
        return [NSString stringWithFormat:@"1.00 %@ = $%.2f %@", denominationLabel, currency, wallet.currencySymbol];
    else
        return @"";
}

// gets the recover questions for a given account
// nil is returned if there were no questions for this account
+ (NSArray *)getRecoveryQuestionsForUserName:(NSString *)strUserName
{
    NSMutableArray *arrayQuestions = nil;
    char *szQuestions = NULL;

    tABC_Error Error;
    tABC_CC result = ABC_GetRecoveryQuestions([strUserName UTF8String],
                                              &szQuestions,
                                              &Error);
    if (ABC_CC_Ok == result)
    {
        if (szQuestions)
        {
            if (strlen(szQuestions))
            {
                // create an array of strings by pulling each question that is seperated by a newline
                arrayQuestions = [[NSMutableArray alloc] initWithArray:[[NSString stringWithUTF8String:szQuestions] componentsSeparatedByString: @"\n"]];
                // remove empties
                [arrayQuestions removeObject:@""];
            }
        }
    }
    else
    {
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


+ (void)logout
{
    [CoreBridge stopWatchers];

    tABC_Error Error;
    tABC_CC result = ABC_ClearKeyCache(&Error);
    if (ABC_CC_Ok != result)
    {
        [Util printABC_Error:&Error];
#warning TODO: handle error
    }
}

+ (void)startWatchers
{
    NSLog(@"startWatchers\n");
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    NSMutableArray *arrayArchivedWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWallets: arrayWallets archived:arrayArchivedWallets];
    for (Wallet * wallet in arrayWallets)
    {
        [self startWatcher:wallet.strUUID];
    }
}

+ (void)startWatcher: (NSString *) walletUUID
{
    tABC_Error Error;
    NSLog(@("ABC_WatcherStart(%@)\n"), walletUUID);
    ABC_WatcherStart([[User Singleton].name UTF8String],
                     [[User Singleton].password UTF8String],
                     [walletUUID UTF8String], &Error);
    [CoreBridge watchAddresses: walletUUID];
    [Util printABC_Error:&Error];
}

+ (void)stopWatchers
{
    tABC_Error Error;
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    NSMutableArray *arrayArchivedWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWallets: arrayWallets archived:arrayArchivedWallets];
    for(Wallet * wallet in arrayWallets)
    {
        ABC_WatcherStop([wallet.strUUID UTF8String], &Error);
        [Util printABC_Error: &Error];
    }
}

+ (void)watchAddresses: (NSString *) walletUUID
{
    tABC_Error Error;
    ABC_WatchAddresses([[User Singleton].name UTF8String],
                       [[User Singleton].password UTF8String],
                       [walletUUID UTF8String], &Error);
    [Util printABC_Error: &Error];
}

+ (bool)calcSendFees:(NSString *) walletUUID 
                 sendTo:(NSString *) destAddr
           amountToSend:(int64_t) sendAmount
         storeResultsIn:(int64_t *) totalFees
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

+ (void)requestExchangeRateUpdate:(int) currencyNum
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, ABC_EXCHANGE_RATE_REFRESH_INTERVAL_SECONDS * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        tABC_Error error;
        ABC_RequestExchangeRateUpdate([[User Singleton].name UTF8String],
                                      [[User Singleton].password UTF8String],
                                      currencyNum, &error);
        [Util printABC_Error: &error];
    });
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

@end

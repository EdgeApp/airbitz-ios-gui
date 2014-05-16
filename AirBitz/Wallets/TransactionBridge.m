

#import "ABC.h"
#import "Wallet.h"
#import "Transaction.h"
#import "ABC.h"
#import "User.h"

#import "TransactionBridge.h"

@interface TransactionBridge ()
{
}

@property (nonatomic, strong) NSMutableArray *arrayWallets;
@property (nonatomic, strong) NSMutableArray *arrayArchivedWallets;

+ (void)loadTransactions:(Wallet *) wallet;
+ (void)setTransaction:(Wallet *) wallet transaction:(Transaction *) transaction coreTx:(tABC_TxInfo *) pTrans;
+ (NSDate *)dateFromTimestamp:(int64_t) intDate;

@end

@implementation TransactionBridge

+ (void)loadWallets: (NSMutableArray *) arrayWallets archived:(NSMutableArray *) arrayArchivedWallets
{
    tABC_Error Error;
    tABC_WalletInfo **aWalletInfo = NULL;
    unsigned int nCount;

    ABC_GetWallets([[User Singleton].name UTF8String], 
                   [[User Singleton].password UTF8String], 
                   &aWalletInfo, &nCount, &Error);
    if (ABC_CC_Ok == Error.code)
    {
        unsigned int i;
        for (i = 0; i < nCount; ++i) {
            Wallet *wallet;
            tABC_WalletInfo *pWalletInfo = aWalletInfo[i];

            wallet = [[Wallet alloc] init];
            wallet.strUUID = [NSString stringWithUTF8String: pWalletInfo->szUUID];
            wallet.strName = [NSString stringWithUTF8String: pWalletInfo->szName];
            wallet.attributes = pWalletInfo->attributes;
            wallet.balance = pWalletInfo->balanceSatoshi;
            wallet.currencyNum = pWalletInfo->currencyNum;
            if (wallet.attributes & WALLET_ATTRIBUTE_ARCHIVE_BIT == 1)
                [arrayArchivedWallets addObject:wallet];
            else
                [arrayWallets addObject:wallet];
            [self loadTransactions: wallet];
        }
    }
    else
    {
        NSLog(@("Error: TransactionBridge.loadWallets:  %s\n"), Error.szDescription);
    }
    ABC_FreeWalletInfoArray(aWalletInfo, nCount);
}

+ (void)reloadWallet: (Wallet *) wallet;
{
    tABC_Error Error;
    tABC_WalletInfo *pWalletInfo = NULL;
    ABC_GetWalletInfo([[User Singleton].name UTF8String], 
                      [[User Singleton].password UTF8String], 
                      [wallet.strUUID UTF8String],
                      &pWalletInfo, &Error);
    if (ABC_CC_Ok == Error.code)
    {
        wallet.strName = [NSString stringWithUTF8String: pWalletInfo->szName];
        wallet.attributes = 0;
        wallet.balance = pWalletInfo->balanceSatoshi;
        wallet.currencyNum = pWalletInfo->currencyNum;
        [self loadTransactions: wallet];
    }
    else
    {
        NSLog(@("Error: TransactionBridge.reloadWallets:  %s\n"), Error.szDescription);
    }
    ABC_FreeWalletInfo(pWalletInfo);
}

+ (void) loadTransactions: (Wallet *) wallet
{
    tABC_Error Error;
    unsigned int tCount = 0;
    Transaction *transaction;
    tABC_TxInfo **aTransactions = NULL;
    ABC_GetTransactions([[User Singleton].name UTF8String],
                        [[User Singleton].password UTF8String],
                        [wallet.strUUID UTF8String], &aTransactions,
                        &tCount, &Error);
    if (ABC_CC_Ok == Error.code)
    {
        NSMutableArray *arrayTransactions = [[NSMutableArray alloc] init];

        for (int j = tCount - 1; j >= 0; --j)
        {
            tABC_TxInfo *pTrans = aTransactions[j];
            transaction = [[Transaction alloc] init];
            [TransactionBridge setTransaction: wallet transaction:transaction coreTx:pTrans];
            [arrayTransactions addObject:transaction];
        }
        SInt64 bal = 0;
        for (int j = arrayTransactions.count - 1; j >= 0; --j)
        {
            Transaction *t = arrayTransactions[j];
            bal += t.amountSatoshi;
            t.balance = bal;
        }
        wallet.arrayTransactions = arrayTransactions;
    }
    else
    {
        NSLog(@("Error: TransactionBridge.loadTransactions:  %s\n"), Error.szDescription);
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
    transaction.strWalletName = wallet.strName;
    transaction.strWalletUUID = wallet.strUUID;
#warning TODO: Hardcoded confirmations...Need to add the info to our structs or cut-it-out
    transaction.confirmations = 3;
    transaction.bConfirmed = NO;
    if (transaction.strName) {
        transaction.strAddress = transaction.strName;
    } else {
        transaction.strAddress = @"1zf76dh4TG";
    }
}

+ (NSMutableArray *)searchTransactionsIn: (Wallet *) wallet query:(NSString *)term addTo:(NSMutableArray *) arrayTransactions 
{
    tABC_Error Error;
    unsigned int tCount = 0;
    Transaction *transaction;
    tABC_TxInfo **aTransactions = NULL;
    ABC_SearchTransactions([[User Singleton].name UTF8String],
                           [[User Singleton].password UTF8String],
                           [wallet.strUUID UTF8String], [term UTF8String],
                           &aTransactions, &tCount, &Error);
    if (ABC_CC_Ok == Error.code)
    {
        for (int j = tCount - 1; j >= 0; --j) {
            tABC_TxInfo *pTrans = aTransactions[j];
            transaction = [[Transaction alloc] init];
            [TransactionBridge setTransaction:wallet transaction:transaction coreTx:pTrans];
            [arrayTransactions addObject:transaction];
        }
    }
    else 
    {
        NSLog(@("Error: TransactionBridge.searchTransactionsIn:  %s\n"), Error.szDescription);
    }
    ABC_FreeTransactions(aTransactions, tCount);
    return arrayTransactions;
}

+ (bool)setWalletAttributes: (Wallet *) wallet
{
    tABC_Error Error;
    tABC_TxDetails *pDetails;
    ABC_SetWalletAttributes([[User Singleton].name UTF8String], 
                            [[User Singleton].password UTF8String], 
                            [wallet.strUUID UTF8String],
                            wallet.attributes, &Error);
    if (ABC_CC_Ok != Error.code)
    {
        return true;
    }
    else
    {
        NSLog(@("Error: TransactionBridge.storeTransaction:  %s\n"), Error.szDescription);
        return false;
    }
}

+ (bool)storeTransaction: (Transaction *) transaction
{
    tABC_Error Error;
    tABC_TxDetails *pDetails;
    ABC_GetTransactionDetails([[User Singleton].name UTF8String], 
                              [[User Singleton].password UTF8String], 
                              [transaction.strWalletUUID UTF8String],
                              [transaction.strID UTF8String],
                              &pDetails, &Error);
    if (ABC_CC_Ok != Error.code)
    {
        NSLog(@("Error: TransactionBridge.storeTransaction:  %s\n"), Error.szDescription);
        return false;
    }
    pDetails->szName = (char *) [transaction.strName UTF8String];
    pDetails->szCategory = (char *) [transaction.strCategory UTF8String];
    pDetails->szNotes = (char *) [transaction.strNotes UTF8String];
    pDetails->amountCurrency = transaction.amountFiat;
    ABC_SetTransactionDetails([[User Singleton].name UTF8String], 
                            [[User Singleton].password UTF8String], 
                            [transaction.strWalletUUID UTF8String],
                            [transaction.strID UTF8String],
                            pDetails, &Error);
    if (ABC_CC_Ok == Error.code)
    {
        return true;
    }
    else 
    {
        NSLog(@("Error: TransactionBridge.storeTransaction:  %s\n"), Error.szDescription);
        return false;
    }
}

+ (NSDate *)dateFromTimestamp:(int64_t) intDate
{
    return [NSDate dateWithTimeIntervalSince1970: intDate];
}

+ (NSString *)formatCurrency: (double) currency
{
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle: NSNumberFormatterCurrencyStyle];
    [f setCurrencySymbol:@"$ "];
    return [f stringFromNumber:[NSNumber numberWithFloat:currency]];
}

+ (NSString *)formatBitcoin: (double) bitcoin
{
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle: NSNumberFormatterCurrencyStyle];
    [f setCurrencySymbol:@"B "];
    return [f stringFromNumber:[NSNumber numberWithFloat:bitcoin]];
}

@end


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
    unsigned int i;
    for (i = 0; i < nCount; ++i) {
        Wallet *wallet;
        tABC_WalletInfo *pWalletInfo = aWalletInfo[i];

        wallet = [[Wallet alloc] init];
        wallet.strUUID = [NSString stringWithUTF8String: pWalletInfo->szUUID];
        wallet.strName = [NSString stringWithUTF8String: pWalletInfo->szName];
        wallet.attributes = 0;
        wallet.balance = pWalletInfo->balanceSatoshi;
        wallet.currencyNum = pWalletInfo->currencyNum;
        [arrayWallets addObject:wallet];
        [self loadTransactions: wallet];
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
    wallet.strName = [NSString stringWithUTF8String: pWalletInfo->szName];
    wallet.attributes = 0;
    wallet.balance = pWalletInfo->balanceSatoshi;
    wallet.currencyNum = pWalletInfo->currencyNum;
    [self loadTransactions: wallet];

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
    NSMutableArray *arrayTransactions = [[NSMutableArray alloc] init];
    for (int j = tCount - 1; j >= 0; --j) {
        tABC_TxInfo *pTrans = aTransactions[j];
        transaction = [[Transaction alloc] init];
        [TransactionBridge setTransaction: wallet transaction:transaction coreTx:pTrans];
        [arrayTransactions addObject:transaction];
    }
    wallet.arrayTransactions = arrayTransactions;
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
    transaction.balance = pTrans->pDetails->amountCurrency;
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
    for (int j = tCount - 1; j >= 0; --j) {
        tABC_TxInfo *pTrans = aTransactions[j];
        transaction = [[Transaction alloc] init];
        [TransactionBridge setTransaction:wallet transaction:transaction coreTx:pTrans];
        [arrayTransactions addObject:transaction];
    }
    ABC_FreeTransactions(aTransactions, tCount);
    return arrayTransactions;
}

+ (void)storeTransaction: (Transaction *) transaction
{
    tABC_Error Error;
    tABC_TxDetails *pDetails;
    ABC_GetTransactionDetails([[User Singleton].name UTF8String], 
                              [[User Singleton].password UTF8String], 
                              [transaction.strWalletUUID UTF8String],
                              [transaction.strID UTF8String],
                              &pDetails, &Error);
    pDetails->szName = (char *) [transaction.strName UTF8String];
    pDetails->szCategory = (char *) [transaction.strCategory UTF8String];
    pDetails->szNotes = (char *) [transaction.strNotes UTF8String];
    pDetails->amountCurrency = transaction.balance;
    NSLog(@("%s %s %s\n"), pDetails->szName, pDetails->szCategory, pDetails->szNotes);
    ABC_SetTransactionDetails([[User Singleton].name UTF8String], 
                              [[User Singleton].password UTF8String], 
                              [transaction.strWalletUUID UTF8String],
                              [transaction.strID UTF8String],
                              pDetails, &Error);
}

+ (NSDate *)dateFromTimestamp:(int64_t) intDate
{
    return [NSDate dateWithTimeIntervalSince1970: intDate];
}

@end

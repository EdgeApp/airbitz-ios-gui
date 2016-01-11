//
//  SpendTarget.m
//  AirBitz
//

#import "SpendTarget.h"
#import "User.h"
#import "CoreBridge.h"
#import "Wallet.h"
#import "ABC.h"
#import "Util.h"

@implementation SpendTarget

- (id)init
{
    self = [super init];
    if (self) {
        _pSpend = NULL;
        _bizId = 0;
    }
    return self;
}

- (void)dealloc
{
    if (_pSpend != NULL) {
        ABC_SpendTargetFree(_pSpend);
        _pSpend = NULL;
    }
}

- (BOOL)newSpend:(NSString *)text error:(tABC_Error *)pError
{
    ABC_SpendNewDecode([text UTF8String], &_pSpend, pError);
    return pError->code == ABC_CC_Ok ? YES : NO;
}

- (BOOL)newTransfer:(NSString *)walletUUID error:(tABC_Error *)pError
{
    ABC_SpendNewTransfer([[User Singleton].name UTF8String],
        [walletUUID UTF8String], 0, &_pSpend, pError);
    return pError->code == ABC_CC_Ok ? YES : NO;
}

- (BOOL)spendNewInternal:(NSString *)address label:(NSString *)label
                category:(NSString *)category notes:(NSString *)notes
           amountSatoshi:(uint64_t)amountSatoshi
                   error:(tABC_Error *)pError
{
    ABC_SpendNewInternal([address UTF8String], [label UTF8String],
        [category UTF8String], [notes UTF8String],
        amountSatoshi, &_pSpend, pError);
    return pError->code == ABC_CC_Ok ? YES : NO;
}

- (NSString *)signTx:(tABC_Error *)pError
{
    NSString *rawTx = nil;
    char *szRawTx = NULL;

    ABC_SpendSignTx([[User Singleton].name UTF8String],
            [self.srcWallet.strUUID UTF8String], _pSpend, &szRawTx, pError);
    if (pError->code == ABC_CC_Ok) {
        rawTx = [NSString stringWithUTF8String:szRawTx];
        free(szRawTx);
    }
    return rawTx;
}

- (BOOL)broadcastTx:(NSString *)rawTx error:(tABC_Error *)pError
{
    ABC_SpendBroadcastTx([[User Singleton].name UTF8String],
        [self.srcWallet.strUUID UTF8String], _pSpend, [rawTx UTF8String], pError);
    return pError->code == ABC_CC_Ok;
}

- (NSString *)saveTx:(NSString *)rawTx error:(tABC_Error *)pError
{
    NSString *txid = nil;
    char *szTxId = NULL;

    ABC_SpendSaveTx([[User Singleton].name UTF8String],
        [self.srcWallet.strUUID UTF8String], _pSpend, [rawTx UTF8String], &szTxId, pError);
    if (pError->code == ABC_CC_Ok) {
        txid = [NSString stringWithUTF8String:szTxId];
        free(szTxId);
        [self updateTransaction:txid];
    }
    return txid;
}

- (NSString *)approve:(tABC_Error *)pError
{
    NSString *txId = nil;
    NSString *rawTx = [self signTx:pError];
    if (nil != rawTx && [self broadcastTx:rawTx error:pError]) {
        txId = [self saveTx:rawTx error:pError];
    }
    return txId;
}

- (void)updateTransaction:(NSString *)txId
{
    NSString *transferCategory = NSLocalizedString(@"Transfer:Wallet:", nil);
    NSString *spendCategory = NSLocalizedString(@"Expense:", nil);

    tABC_Error error;
    tABC_TxInfo *pTrans = NULL;
    if (_pSpend->szDestUUID) {
        NSAssert((self.destWallet), @"destWallet missing");
    }
    ABC_GetTransaction([[User Singleton].name UTF8String], NULL,
        [self.srcWallet.strUUID UTF8String], [txId UTF8String], &pTrans, &error);
    if (ABC_CC_Ok == error.code) {
        if (self.destWallet) {
            pTrans->pDetails->szName = strdup([self.destWallet.strName UTF8String]);
            pTrans->pDetails->szCategory = strdup([[NSString stringWithFormat:@"%@%@", transferCategory, self.destWallet.strName] UTF8String]);
        } else {
            if (!pTrans->pDetails->szCategory) {
                pTrans->pDetails->szCategory = strdup([[NSString stringWithFormat:@"%@", spendCategory] UTF8String]);
            }
        }
        if (_amountFiat > 0) {
            pTrans->pDetails->amountCurrency = _amountFiat;
        }
        if (0 < _bizId) {
            pTrans->pDetails->bizId = _bizId;
        }
        ABC_SetTransactionDetails([[User Singleton].name UTF8String], NULL,
            [self.srcWallet.strUUID UTF8String], [txId UTF8String],
            pTrans->pDetails, &error);
    }
    ABC_FreeTransaction(pTrans);
    pTrans = NULL;

    // This was a transfer
    if (self.destWallet) {
        ABC_GetTransaction([[User Singleton].name UTF8String], NULL,
            [self.destWallet.strUUID UTF8String], [txId UTF8String], &pTrans, &error);
        if (ABC_CC_Ok == error.code) {
            pTrans->pDetails->szName = strdup([self.srcWallet.strName UTF8String]);
            pTrans->pDetails->szCategory = strdup([[NSString stringWithFormat:@"%@%@", transferCategory, self.srcWallet.strName] UTF8String]);

            ABC_SetTransactionDetails([[User Singleton].name UTF8String], NULL,
                [self.destWallet.strUUID UTF8String], [txId UTF8String],
                pTrans->pDetails, &error);
        }
        ABC_FreeTransaction(pTrans);
        pTrans = NULL;
    }
}

- (BOOL)isMutable
{
    return _pSpend->amountMutable == true ? YES : NO;
}

- (uint64_t)maxSpendable:(NSString *)walletUUID
{
    tABC_Error error;
    uint64_t result = 0;
    ABC_SpendGetMax([[User Singleton].name UTF8String],
        [walletUUID UTF8String], _pSpend, &result, &error);
    return result;
}

- (tABC_Error)calcSendFees:(NSString *)walletUUID
                 totalFees:(uint64_t *)totalFees
{
    tABC_Error error;
    ABC_SpendGetFee([[User Singleton].name UTF8String],
        [walletUUID UTF8String], _pSpend, totalFees, &error);
    return error;
}

@end

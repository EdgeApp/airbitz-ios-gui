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

- (NSString *)approve:(NSString *)walletUUID
                 fiat:(double)fiatAmount
                error:(tABC_Error *)pError
{
    char *szTxId = NULL;
    NSString *txId = nil;

    ABC_SpendApprove([[User Singleton].name UTF8String], [walletUUID UTF8String],
            _pSpend, &szTxId, pError);
    if (pError->code == ABC_CC_Ok) {
        txId = [NSString stringWithUTF8String:szTxId];
        [self updateTransaction:walletUUID txId:txId fiatAmount:fiatAmount];
    }
    if (NULL != szTxId) {
        free(szTxId);
    }
    return txId;
}

- (void)updateTransaction:(NSString *)walletUUID
                     txId:(NSString *)txId
               fiatAmount:(double)fiatAmount
{
    NSString *categoryText = NSLocalizedString(@"Transfer:Wallet:", nil);

    tABC_Error error;
    tABC_TxInfo *pTrans = NULL;
    Wallet *destWallet = nil;
    Wallet *srcWallet = [CoreBridge getWallet:walletUUID];
    if (_pSpend->szDestUUID) {
        destWallet = [CoreBridge getWallet:[NSString safeStringWithUTF8String:_pSpend->szDestUUID]];
    }
    ABC_GetTransaction([[User Singleton].name UTF8String], NULL,
        [walletUUID UTF8String], [txId UTF8String], &pTrans, &error);
    if (ABC_CC_Ok == error.code) {
        if (destWallet) {
            pTrans->pDetails->szName = strdup([destWallet.strName UTF8String]);
            pTrans->pDetails->szCategory = strdup([[NSString stringWithFormat:@"%@%@", categoryText, destWallet.strName] UTF8String]);
        }
        if (fiatAmount > 0) {
            pTrans->pDetails->amountCurrency = fiatAmount;
        }
        ABC_SetTransactionDetails([[User Singleton].name UTF8String], NULL,
            [walletUUID UTF8String], [txId UTF8String],
            pTrans->pDetails, &error);
    }
    ABC_FreeTransaction(pTrans);
    pTrans = NULL;

    // This was a transfer
    if (destWallet) {
        ABC_GetTransaction([[User Singleton].name UTF8String], NULL,
            [destWallet.strUUID UTF8String], [txId UTF8String], &pTrans, &error);
        if (ABC_CC_Ok == error.code) {
            pTrans->pDetails->szName = strdup([srcWallet.strName UTF8String]);
            pTrans->pDetails->szCategory = strdup([[NSString stringWithFormat:@"%@%@", categoryText, srcWallet.strName] UTF8String]);

            ABC_SetTransactionDetails([[User Singleton].name UTF8String], NULL,
                [destWallet.strUUID UTF8String], [txId UTF8String],
                pTrans->pDetails, &error);
        }
        ABC_FreeTransaction(pTrans);
        pTrans = NULL;
    }
}

- (uint64_t)maxSpendable:(NSString *)walletUUID
{
    tABC_Error error;
    uint64_t result = 0;
    ABC_SpendGetMax([[User Singleton].name UTF8String],
        [walletUUID UTF8String], _pSpend, &result, &error);
    return result;
}

- (BOOL)calcSendFees:(NSString *)walletUUID 
           totalFees:(uint64_t *)totalFees
{
    tABC_Error error;
    ABC_SpendGetFee([[User Singleton].name UTF8String],
        [walletUUID UTF8String], _pSpend, totalFees, &error);
    return error.code  == ABC_CC_Ok ? YES : NO;
}

@end

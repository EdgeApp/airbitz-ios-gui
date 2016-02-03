//
//  ABCSpend.m
//  AirBitz
//

#import "ABCSpend.h"
#import "AirbitzCore.h"
#import "ABCWallet.h"
#import "ABC.h"
#import "ABCError.h"

@interface ABCSpend ()

@property (nonatomic)               tABC_SpendTarget        *pSpend;
@property (nonatomic, strong)       AirbitzCore *abc;
@property (nonatomic)               ABCConditionCode        lastConditionCode;
@property (nonatomic, strong)       NSString                *lastErrorString;

@end

@implementation ABCSpend

- (id)init:(id)abc;
{
    self = [super init];
    if (self) {
        self.pSpend = NULL;
        self.bizId = 0;
        self.abc = abc;
    }
    return self;
}

- (void)dealloc
{
    if (self.pSpend != NULL) {
        ABC_SpendTargetFree(self.pSpend);
        self.pSpend = NULL;
    }
}

- (void)spendObjectSet:(void *)o;
{
    self.pSpend = (tABC_SpendTarget *)o;
    [self copyABCtoOBJC];
}

- (void)copyABCtoOBJC
{
    if (!self.pSpend) return;

    self.amount         = self.pSpend->amount;
    self.amountMutable  = self.pSpend->amountMutable;
    self.bSigned        = self.pSpend->bSigned;
    self.spendName      = self.pSpend->szName       ? [NSString stringWithUTF8String:self.pSpend->szName] : nil;
    self.returnURL      = self.pSpend->szRet        ? [NSString stringWithUTF8String:self.pSpend->szRet] : nil;
    self.destUUID       = self.pSpend->szDestUUID   ? [NSString stringWithUTF8String:self.pSpend->szDestUUID] : nil;
}

- (void)copyOBJCtoABC
{
    self.pSpend->amount              = self.amount       ;
//    self.pSpend->amountMutable       = self.amountMutable;
//    self.pSpend->bSigned             = self.bSigned      ;
//    [self replaceString:&(self.pSpend->szName         ) withString:[self.spendName          UTF8String]];
//    [self replaceString:&(self.pSpend->szRet          ) withString:[self.spendName          UTF8String]];
//    [self replaceString:&(self.pSpend->szDestUUID     ) withString:[self.spendName          UTF8String]];
//    szRet                           =
//    szDestUUID                      =
}


- (ABCConditionCode)signTx:(NSString **)txData;
{
    NSString *rawTx = nil;
    char *szRawTx = NULL;
    tABC_Error error;

    ABC_SpendSignTx([self.abc.name UTF8String],
            [self.srcWallet.strUUID UTF8String], _pSpend, &szRawTx, &error);
    ABCConditionCode ccode = [ABCError setLastErrors:error];
    if (ABCConditionCodeOk == ccode)
    {
        rawTx = [NSString stringWithUTF8String:szRawTx];
        free(szRawTx);
        *txData = rawTx;
    }
    return ccode;
}
- (void)signTx:(void (^)(NSString * txData)) completionHandler
        error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;
{
    [self.abc postToMiscQueue:^
    {
        NSString *txData;
        ABCConditionCode ccode = [self signTx:&txData];
        NSString *errorString  = [ABCError getLastErrorString];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (ABCConditionCodeOk == ccode)
            {
                if (completionHandler) completionHandler(txData);
            }
            else
            {
                if (errorHandler) errorHandler(ccode, errorString);
            }
        });
    }];
}

- (void)signAndSaveTx:(void (^)(NSString * rawTx)) completionHandler
         error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;
{
    [self.abc postToMiscQueue:^
    {
        NSString *rawTx;
        NSString *txId;
        tABC_Error error;

        ABCConditionCode ccode = [self signTx:&rawTx];
        if (ABCConditionCodeOk == ccode)
        {
            ccode = [self saveTx:rawTx txId:&txId];
        }
        NSString *errorString  = [ABCError getLastErrorString];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (ABCConditionCodeOk == ccode)
            {
                if (completionHandler) completionHandler(rawTx);
            }
            else
            {
                if (errorHandler) errorHandler(ccode, errorString);
            }
        });
    }];
}

- (ABCConditionCode)broadcastTx:(NSString *)rawTx;
{
    tABC_Error error;
    ABC_SpendBroadcastTx([self.abc.name UTF8String],
        [self.srcWallet.strUUID UTF8String], _pSpend, [rawTx UTF8String], &error);
    return [ABCError setLastErrors:error];
}

- (ABCConditionCode)saveTx:(NSString *)rawTx txId:(NSString **)txId
{
    NSString *txidTemp = nil;
    char *szTxId = NULL;
    tABC_Error error;

    ABC_SpendSaveTx([self.abc.name UTF8String],
        [self.srcWallet.strUUID UTF8String], _pSpend, [rawTx UTF8String], &szTxId, &error);
    ABCConditionCode ccode = [ABCError setLastErrors:error];
    if (ccode == ABCConditionCodeOk) {
        txidTemp = [NSString stringWithUTF8String:szTxId];
        free(szTxId);
        [self updateTransaction:txidTemp];
        *txId = txidTemp;
    }
    return ccode;
}

- (ABCConditionCode)signBroadcastSaveTx:(NSString **)txId;
{
    NSString *txIdTemp = nil;
    NSString *rawTx;
    ABCConditionCode ccode = [self signTx:&rawTx];
    if (nil != rawTx)
    {
        ccode = [self broadcastTx:rawTx];
        if (ABCConditionCodeOk == ccode)
        {
            ccode = [self saveTx:rawTx txId:&txIdTemp];
            if (ABCConditionCodeOk == ccode)
            {
                *txId = txIdTemp;
            }
        }
    }
    return ccode;
}

- (void)signBroadcastSaveTx:(void (^)(NSString * txId)) completionHandler
         error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;
{
    [self.abc postToMiscQueue:^
    {
        NSString *txId;
        ABCConditionCode ccode = [self signBroadcastSaveTx:&txId];
        NSString *errorString  = [ABCError getLastErrorString];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (ABCConditionCodeOk == ccode)
            {
                if (completionHandler) completionHandler(txId);
            }
            else
            {
                if (errorHandler) errorHandler(ccode, errorString);
            }
        });
    }];

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
    ABC_GetTransaction([self.abc.name UTF8String], NULL,
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
        ABC_SetTransactionDetails([self.abc.name UTF8String], NULL,
            [self.srcWallet.strUUID UTF8String], [txId UTF8String],
            pTrans->pDetails, &error);
    }
    ABC_FreeTransaction(pTrans);
    pTrans = NULL;

    // This was a transfer
    if (self.destWallet) {
        ABC_GetTransaction([self.abc.name UTF8String], NULL,
            [self.destWallet.strUUID UTF8String], [txId UTF8String], &pTrans, &error);
        if (ABC_CC_Ok == error.code) {
            pTrans->pDetails->szName = strdup([self.srcWallet.strName UTF8String]);
            pTrans->pDetails->szCategory = strdup([[NSString stringWithFormat:@"%@%@", transferCategory, self.srcWallet.strName] UTF8String]);

            ABC_SetTransactionDetails([self.abc.name UTF8String], NULL,
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
    ABC_SpendGetMax([self.abc.name UTF8String],
        [walletUUID UTF8String], _pSpend, &result, &error);
    return result;
}

- (ABCConditionCode)calcSendFees:(NSString *)walletUUID
                       totalFees:(uint64_t *)totalFees
{
    tABC_Error error;
    [self copyOBJCtoABC];
    ABC_SpendGetFee([self.abc.name UTF8String],
        [walletUUID UTF8String], self.pSpend, totalFees, &error);
    return [ABCError setLastErrors:error];
}

- (void)calcSendFees:(NSString *)walletUUID
            complete:(void (^)(uint64_t totalFees)) completionHandler
               error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;
{
    [self.abc postToMiscQueue:^
    {
        uint64_t totalFees = 0;
        ABCConditionCode ccode = [self calcSendFees:walletUUID totalFees:&totalFees];
        NSString *errorString  = [ABCError getLastErrorString];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (ABCConditionCodeOk == ccode)
            {
                if (completionHandler) completionHandler(totalFees);
            }
            else
            {
                if (errorHandler) errorHandler(ccode, errorString);
            }
        });
    }];

}


@end

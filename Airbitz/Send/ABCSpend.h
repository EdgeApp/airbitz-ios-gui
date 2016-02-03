//
//  ABCSpend.h
//  AirBitz
//

#import "Wallet.h"
#import "AirbitzCore.h"

@interface ABCSpend : NSObject

@property (nonatomic, strong)       Wallet                  *srcWallet;
@property (nonatomic, strong)       Wallet                  *destWallet;
@property (nonatomic)               long                    bizId;
@property (nonatomic)               double                  amountFiat;

@property (nonatomic)               uint64_t                amount;

/** True if the GUI can change the amount. */
@property (nonatomic)               bool                    amountMutable;

/** The destination to show to the user. This is often an address,
 * but also could be something else like a wallet name. */
@property (nonatomic)               NSString                *spendName;

/** True if this is a signed bip70 payment request. */
@property (nonatomic)               bool                    bSigned;

/** Non-null if the payment request provides a URL
 * to visit once the payment is done. */
@property (nonatomic)               NSString                *returnURL;

/** The destination wallet if this is a transfer, otherwise NULL */
@property (nonatomic)               NSString                *destUUID;


- (id)init:(id)abc;
- (void)spendObjectSet:(void *)o;

- (BOOL)isMutable;
- (uint64_t)maxSpendable:(NSString *)walletUUID;


/*
 * signTx
 * @param NSString *txData: pointer to string return signed tx
 *
 * @return ABCConditionCode
*/
- (ABCConditionCode)signTx:(NSString **)txData;

/*
 * signTx
 * @param complete: completion handler code block which is called with uint64_t totalFees
 *                          @param NSString *txData: signed transaction data
 * @param error: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return void
*/
- (void)signTx:(void (^)(NSString * txData)) completionHandler
        error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;


- (ABCConditionCode)broadcastTx:(NSString *)rawTx;
- (ABCConditionCode)saveTx:(NSString *)rawTx txId:(NSString **)txId;
- (void)signAndSaveTx:(void (^)(NSString * rawTx)) completionHandler
                error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;
- (ABCConditionCode)signBroadcastSaveTx:(NSString **)txId;
- (void)signBroadcastSaveTx:(void (^)(NSString * txId)) completionHandler
        error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;


/*
 * calcSendFees
 * @param NSString *walletUUID:
 * @param uint64_t *totalFees: pointer to populate with total fees
 *
 * @return ABCConditionCode
*/
- (ABCConditionCode)calcSendFees:(NSString *)walletUUID
                       totalFees:(uint64_t *)totalFees;

/*
 * calcSendFeesAsync
 * @param NSString *walletUUID:
 * @param complete: completion handler code block which is called with uint64_t totalFees
 *                          @param uint64_t           totalFees: total transaction fees
 * @param error: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return void
*/
- (void)calcSendFees:(NSString *)walletUUID
            complete:(void (^)(uint64_t totalFees)) completionHandler
               error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;

@end

//
//  CoreBridge.h
//  AirBitz
//

#import "ABC.h"
#import "Wallet.h"
#import "Transaction.h"

#define CONFIRMED_CONFIRMATION_COUNT 6

@interface CoreBridge : NSObject

+ (void)initAll;
+ (void)freeAll;
+ (void)startQueues;
+ (void)stopQueues;
+ (void)postToSyncQueue:(void(^)(void))cb;

+ (void)loadWallets:(NSMutableArray *)arrayWallets;
+ (void)loadWallets:(NSMutableArray *)arrayWallets withTxs:(BOOL)bWithTx;
+ (void)loadWallets:(NSMutableArray *)arrayWallets archived:(NSMutableArray *)arrayArchivedWallets withTxs:(BOOL)bWithTx;
+ (void)loadWallets:(NSMutableArray *)arrayWallets archived:(NSMutableArray *)arrayArchivedWallets;
+ (void)reloadWallet: (Wallet *) wallet;
+ (Wallet *)getWallet: (NSString *)walletUUID;
+ (Transaction *)getTransaction: (NSString *)walletUUID withTx:(NSString *) szTxId;

+ (void)setWalletOrder: (NSMutableArray *) arrayWallets archived:(NSMutableArray *) arrayArchivedWallets;
+ (bool)setWalletAttributes: (Wallet *) wallet;

+ (NSMutableArray *)searchTransactionsIn: (Wallet *) wallet query:(NSString *)term addTo:(NSMutableArray *) arrayTransactions;
+ (bool)storeTransaction: (Transaction *) transaction;

+ (int) currencyDecimalPlaces;
+ (int) maxDecimalPlaces;
+ (int64_t) cleanNumString:(NSString *) value;
+ (NSString *)formatCurrency:(double) currency withCurrencyNum:(int)currencyNum;
+ (NSString *)formatCurrency:(double) currency withCurrencyNum:(int)currencyNum withSymbol:(bool)symbol;
+ (NSString *)formatSatoshi:(int64_t) bitcoin;
+ (NSString *)formatSatoshi:(int64_t) bitcoin withSymbol:(bool) symbol;
+ (NSString *)formatSatoshi:(int64_t) bitcoin withSymbol:(bool) symbol cropDecimals:(int) decimals;
+ (NSString *)formatSatoshi:(int64_t) bitcoin withSymbol:(bool) symbol forceDecimals:(int) forcedecimals;
+ (NSString *)formatSatoshi:(int64_t) bitcoin withSymbol:(bool) symbol cropDecimals:(int) decimals forceDecimals:(int) forcedecimals;
+ (int64_t) denominationToSatoshi: (NSString *) amount;
+ (NSString *)conversionString: (Wallet *) wallet;
+ (NSArray *)getRecoveryQuestionsForUserName:(NSString *)strUserName
                                   isSuccess:(BOOL *)bSuccess
                                    errorMsg:(NSMutableString *)error;
+ (BOOL)recoveryAnswers:(NSString *)strAnswers areValidForUserName:(NSString *)strUserName;
+ (void)logout;
+ (BOOL)allWatchersReady;
+ (BOOL)watcherIsReady:(NSString *)UUID;
+ (void)startWatchers;
+ (void)startWatcher:(NSString *)walletUUID;
+ (void)stopWatchers;
+ (uint64_t)maxSpendable:(NSString *)walletUUID
               toAddress:(NSString *)destAddress
              isTransfer:(BOOL)bTransfer;
+ (bool)calcSendFees:(NSString *) walletUUID 
                 sendTo:(NSString *) destAddr 
           amountToSend:(int64_t) sendAmount
         storeResultsIn:(int64_t *) totalFees
         walletTransfer:(bool)bTransfer;
+ (bool)isTestNet;
+ (NSString *)coreVersion;
+ (NSString *)currencyAbbrevLookup:(int) currencyNum;
+ (NSString *)currencySymbolLookup:(int) currencyNum;

void ABC_BitCoin_Event_Callback(const tABC_AsyncBitCoinInfo *pInfo);

@end

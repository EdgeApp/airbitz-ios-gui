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

+ (void)loadWallets: (NSMutableArray *) arrayWallets archived:(NSMutableArray *) arrayArchivedWallets;
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
+ (NSString *)formatSatoshi:(int64_t) bitcoin withSymbol:(bool) symbol overrideDecimals:(int) decimals;
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
+ (void)startWatcher: (NSString *) walletUUID;
+ (void)stopWatchers;
+ (void)watchAddresses:(NSString *) walletUUID;
+ (uint64_t)maxSpendable:(NSString *)walletUUID
               toAddress:(NSString *)destAddress
              isTransfer:(BOOL)bTransfer;
+ (bool)calcSendFees:(NSString *) walletUUID 
                 sendTo:(NSString *) destAddr 
           amountToSend:(int64_t) sendAmount
         storeResultsIn:(int64_t *) totalFees
         walletTransfer:(bool)bTransfer;
+ (bool)isTestNet;
+ (NSString *)currencyAbbrevLookup:(int) currencyNum;
+ (NSString *)currencySymbolLookup:(int) currencyNum;

@end

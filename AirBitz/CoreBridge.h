//
//  CoreBridge.h
//  AirBitz
//

#import "ABC.h"
#import "Wallet.h"
#import "Transaction.h"
#import "FadingAlertView.h"

#define CONFIRMED_CONFIRMATION_COUNT 6
#define PIN_REQUIRED_PERIOD_SECONDS     120

@interface CoreBridge : NSObject

+ (void)initAll;
+ (void)freeAll;
+ (void)startQueues;
+ (void)stopQueues;
+ (void)postToSyncQueue:(void(^)(void))cb;
+ (void)clearSyncQueue;
+ (void)postToWalletsQueue:(void(^)(void))cb;
+ (int)dataOperationCount;

+ (void)loadWalletUUIDs:(NSMutableArray *)arrayUUIDs;
+ (void)loadWallets:(NSMutableArray *)arrayWallets;
+ (void)loadWallets:(NSMutableArray *)arrayWallets withTxs:(BOOL)bWithTx;
+ (void)loadWallets:(NSMutableArray *)arrayWallets archived:(NSMutableArray *)arrayArchivedWallets withTxs:(BOOL)bWithTx;
+ (void)loadWallets:(NSMutableArray *)arrayWallets archived:(NSMutableArray *)arrayArchivedWallets;
+ (void)reloadWallet: (Wallet *) wallet;
+ (void)refreshWallet:(NSString *)walletUUID refreshData:(BOOL)bData notify:(void(^)(void))cb;
+ (Wallet *)getWallet: (NSString *)walletUUID;
+ (Transaction *)getTransaction: (NSString *)walletUUID withTx:(NSString *) szTxId;
+ (int64_t)getTotalSentToday:(Wallet *)wallet;

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
+ (NSString *)conversionStringFromNum:(int) currencyNum withAbbrev:(bool) abbrev;
+ (NSArray *)getRecoveryQuestionsForUserName:(NSString *)strUserName
                                   isSuccess:(BOOL *)bSuccess
                                    errorMsg:(NSMutableString *)error;
+ (BOOL)recoveryAnswers:(NSString *)strAnswers areValidForUserName:(NSString *)strUserName status:(tABC_Error *)error;
+ (BOOL)needsRecoveryQuestionsReminder:(Wallet *)wallet;
+ (NSString *)getPIN;
+ (bool)PINLoginExists;
+ (bool)PINLoginExists:(NSString *)username;
+ (void)deletePINLogin;
+ (void)setupLoginPIN;
+ (tABC_CC)PINLoginWithPIN:(NSString *)PIN;
+ (BOOL)recentlyLoggedIn;
+ (void)login;
+ (void)logout;
+ (BOOL)passwordOk:(NSString *)password;
+ (BOOL)allWatchersReady;
+ (BOOL)watcherIsReady:(NSString *)UUID;
+ (void)connectWatchers;
+ (void)disconnectWatchers;
+ (void)startWatchers;
+ (void)startWatcher:(NSString *)walletUUID;
+ (void)stopWatchers;
+ (void)prioritizeAddress:(NSString *)address inWallet:(NSString *)walletUUID;
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
+ (NSString *)currencySymbolLookup:(int)currencyNum;
+ (int)getCurrencyNumOfLocale;
+ (bool)setDefaultCurrencyNum:(int)currencyNum;
+ (void)setupNewAccount:(FadingAlertView *)fadingAlert;
+ (NSString *)sweepKey:(NSString *)privateKey intoWallet:(NSString *)walletUUID withCallback:(tABC_Sweep_Done_Callback)callback;
+ (void)otpSetError:(tABC_CC)cc;
+ (BOOL)otpHasError;
+ (void)otpClearError;

void ABC_BitCoin_Event_Callback(const tABC_AsyncBitCoinInfo *pInfo);
void ABC_Sweep_Complete_Callback(tABC_CC cc, const char *szID, uint64_t amount);

@end

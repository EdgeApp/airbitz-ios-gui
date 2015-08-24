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

@property (nonatomic, strong) NSMutableArray            *arrayWallets;
@property (nonatomic, strong) NSMutableArray            *arrayArchivedWallets;
@property (nonatomic, strong) NSMutableArray            *arrayWalletNames;
@property (nonatomic, strong) NSMutableArray            *arrayUUIDs;
@property (nonatomic, strong) Wallet                    *currentWallet;
@property (nonatomic)         int                       currentWalletID;


+ (CoreBridge *)Singleton;
+ (void)initAll;
+ (void)freeAll;
+ (void)startQueues;
+ (void)stopQueues;
+ (void)postToSyncQueue:(void(^)(void))cb;
+ (void)clearSyncQueue;
+ (void)clearTxSearchQueue;
+ (void)postToWalletsQueue:(void(^)(void))cb;
+ (void)postToGenQRQueue:(void(^)(void))cb;
+ (void)postToTxSearchQueue:(void(^)(void))cb;
+ (void)postToMiscQueue:(void(^)(void))cb;
+ (int)dataOperationCount;

// New methods
+ (void)refreshWallets;
+ (void)rotateWalletServer:(NSString *)walletUUID refreshData:(BOOL)bData notify:(void(^)(void))cb;
+ (void)reorderWallets: (NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;
+ (void)makeCurrentWallet:(Wallet *)wallet;
+ (void)makeCurrentWalletWithIndex:(NSIndexPath *)indexPath;
+ (void)makeCurrentWalletWithUUID:(NSString *)strUUID;
+ (Wallet *)selectWalletWithUUID:(NSString *)strUUID;



+ (Wallet *)getWallet: (NSString *)walletUUID;
+ (Transaction *)getTransaction: (NSString *)walletUUID withTx:(NSString *) szTxId;
+ (int64_t)getTotalSentToday:(Wallet *)wallet;

+ (bool)setWalletAttributes: (Wallet *) wallet;

+ (NSMutableArray *)searchTransactionsIn: (Wallet *) wallet query:(NSString *)term addTo:(NSMutableArray *) arrayTransactions;
+ (void)storeTransaction:(Transaction *)transaction;

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
+ (bool)PINLoginExists;
+ (bool)PINLoginExists:(NSString *)username;
+ (void)deletePINLogin;
+ (void)setupLoginPIN;
+ (void)PINLoginWithPIN:(NSString *)PIN error:(tABC_Error *)pError;
+ (BOOL)recentlyLoggedIn;
+ (void)login;
+ (void)logout;
+ (BOOL)passwordOk:(NSString *)password;
+ (BOOL)passwordExists;
+ (BOOL)allWatchersReady;
+ (BOOL)watcherIsReady:(NSString *)UUID;
+ (void)connectWatchers;
+ (void)disconnectWatchers;
+ (void)startWatchers;
+ (void)startWatcher:(NSString *)walletUUID;
+ (void)stopWatchers;
+ (void)restoreConnectivity;
+ (void)lostConnectivity;
+ (void)prioritizeAddress:(NSString *)address inWallet:(NSString *)walletUUID;
+ (bool)isTestNet;
+ (NSString *)coreVersion;
+ (NSString *)currencyAbbrevLookup:(int) currencyNum;
+ (NSString *)currencySymbolLookup:(int)currencyNum;
+ (int)getCurrencyNumOfLocale;
+ (bool)setDefaultCurrencyNum:(int)currencyNum;
+ (void)setupNewAccount;
+ (NSString *)sweepKey:(NSString *)privateKey intoWallet:(NSString *)walletUUID withCallback:(tABC_Sweep_Done_Callback)callback;
+ (void)otpSetError:(tABC_CC)cc;
+ (BOOL)otpHasError;
+ (void)otpClearError;

void ABC_BitCoin_Event_Callback(const tABC_AsyncBitCoinInfo *pInfo);
void ABC_Sweep_Complete_Callback(tABC_CC cc, const char *szID, uint64_t amount);

@end

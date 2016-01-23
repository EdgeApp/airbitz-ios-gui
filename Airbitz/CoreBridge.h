//
//  CoreBridge.h
//  AirBitz
//

#import "ABC.h"
#import "Wallet.h"
#import "Transaction.h"
#import "FadingAlertView.h"
#import "Theme.h"
#import "ABCConditionCode.h"

#define CONFIRMED_CONFIRMATION_COUNT 6
#define PIN_REQUIRED_PERIOD_SECONDS     120

@interface BitidSignature : NSObject
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *signature;
@end

@interface CoreBridge : NSObject

@property (nonatomic, strong) NSMutableArray            *arrayWallets;
@property (nonatomic, strong) NSMutableArray            *arrayArchivedWallets;
@property (nonatomic, strong) NSMutableArray            *arrayWalletNames;
@property (nonatomic, strong) NSMutableArray            *arrayUUIDs;
@property (nonatomic, strong) Wallet                    *currentWallet;
@property (nonatomic, strong) NSArray                   *arrayCurrencyCodes;
@property (nonatomic, strong) NSArray                   *arrayCurrencyNums;
@property (nonatomic, strong) NSArray                   *arrayCurrencyStrings;
@property (nonatomic, strong) NSArray                   *arrayCategories;
@property (nonatomic)         int                       currentWalletID;
@property (nonatomic)         BOOL                      bAllWalletsLoaded;
@property (nonatomic)         int                       numWalletsLoaded;
@property (nonatomic)         int                       numTotalWallets;
@property (nonatomic)         int                       currencyCount;
@property (nonatomic)         int                       numCategories;


- (void)initAll;
- (void)freeAll;
- (void)startQueues;
- (void)stopQueues;
- (void)postToSyncQueue:(void(^)(void))cb;

- (void)clearSyncQueue;
- (void)clearTxSearchQueue;

- (void)postToLoadedQueue:(void(^)(void))cb;
- (void)postToWalletsQueue:(void(^)(void))cb;
- (void)postToGenQRQueue:(void(^)(void))cb;
- (void)postToTxSearchQueue:(void(^)(void))cb;
- (void)postToMiscQueue:(void(^)(void))cb;

- (int)dataOperationCount;

// New methods
- (void)refreshWallets;
- (void)rotateWalletServer:(NSString *)walletUUID refreshData:(BOOL)bData notify:(void(^)(void))cb;
- (void)reorderWallets: (NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;
- (void)makeCurrentWallet:(Wallet *)wallet;
- (void)makeCurrentWalletWithIndex:(NSIndexPath *)indexPath;
- (void)makeCurrentWalletWithUUID:(NSString *)strUUID;
- (Wallet *)selectWalletWithUUID:(NSString *)strUUID;
- (long) saveLogoutDate;
- (BOOL)didLoginExpire:(NSString *)username;
- (void)addCategory:(NSString *)strCategory;
- (void)loadCategories;
- (void)saveCategories:(NSMutableArray *)saveArrayCategories;
- (void)uploadLogs:(NSString *)userText notify:(void(^)(void))cb error:(void(^)(void))cberror;
- (void)walletRemove:(NSString *)uuid notify:(void(^)(void))cb error:(void(^)(void))cberror;
- (NSArray *)getLocalAccounts:(NSString **)strError;
- (BOOL)accountExistsLocal:(NSString *)username;
- (tABC_CC)accountDeleteLocal:(NSString *)account;

- (void)updateWidgetQRCode;


- (Wallet *)getWallet: (NSString *)walletUUID;
- (Transaction *)getTransaction: (NSString *)walletUUID withTx:(NSString *) szTxId;
- (int64_t)getTotalSentToday:(Wallet *)wallet;

- (bool)setWalletAttributes: (Wallet *) wallet;

- (NSMutableArray *)searchTransactionsIn: (Wallet *) wallet query:(NSString *)term addTo:(NSMutableArray *) arrayTransactions;
- (void)storeTransaction:(Transaction *)transaction;

- (int) currencyDecimalPlaces;
- (int) maxDecimalPlaces;
- (int64_t) cleanNumString:(NSString *) value;
- (NSString *)formatCurrency:(double) currency withCurrencyNum:(int)currencyNum;
- (NSString *)formatCurrency:(double) currency withCurrencyNum:(int)currencyNum withSymbol:(bool)symbol;
- (NSString *)formatSatoshi:(int64_t) bitcoin;
- (NSString *)formatSatoshi:(int64_t) bitcoin withSymbol:(bool) symbol;
- (NSString *)formatSatoshi:(int64_t) bitcoin withSymbol:(bool) symbol cropDecimals:(int) decimals;
- (NSString *)formatSatoshi:(int64_t) bitcoin withSymbol:(bool) symbol forceDecimals:(int) forcedecimals;
- (NSString *)formatSatoshi:(int64_t) bitcoin withSymbol:(bool) symbol cropDecimals:(int) decimals forceDecimals:(int) forcedecimals;
- (int64_t) denominationToSatoshi: (NSString *) amount;
- (NSString *)conversionString: (Wallet *) wallet;
- (NSString *)conversionStringFromNum:(int) currencyNum withAbbrev:(bool) abbrev;
- (NSArray *)getRecoveryQuestionsForUserName:(NSString *)strUserName
                                   isSuccess:(BOOL *)bSuccess
                                    errorMsg:(NSMutableString *)error;
- (BOOL)recoveryAnswers:(NSString *)strAnswers areValidForUserName:(NSString *)strUserName status:(tABC_Error *)error;
- (BOOL)needsRecoveryQuestionsReminder:(Wallet *)wallet;
- (bool)PINLoginExists;
- (bool)PINLoginExists:(NSString *)username;
- (void)deletePINLogin;
- (void)setupLoginPIN;
- (void)PINLoginWithPIN:(NSString *)PIN error:(tABC_Error *)pError;
- (BOOL)recentlyLoggedIn;
- (void)login;
- (void)logout;
- (BOOL)passwordOk:(NSString *)password;
- (BOOL)passwordExists;
- (BOOL)passwordExists:(NSString *)username;
- (BOOL)allWatchersReady;
- (BOOL)watcherIsReady:(NSString *)UUID;
- (void)connectWatchers;
- (void)disconnectWatchers;
- (void)startWatchers;
- (void)startWatcher:(NSString *)walletUUID;
- (void)stopWatchers;
- (void)deleteWatcherCache;
- (void)restoreConnectivity;
- (void)lostConnectivity;
- (void)prioritizeAddress:(NSString *)address inWallet:(NSString *)walletUUID;
- (bool)isTestNet;
- (NSString *)coreVersion;
- (NSString *)currencyAbbrevLookup:(int) currencyNum;
- (NSString *)currencySymbolLookup:(int)currencyNum;
- (int)getCurrencyNumOfLocale;
- (bool)setDefaultCurrencyNum:(int)currencyNum;
- (void)setupNewAccount;
- (NSString *)sweepKey:(NSString *)privateKey intoWallet:(NSString *)walletUUID withCallback:(tABC_Sweep_Done_Callback)callback;
- (void)otpSetError:(tABC_CC)cc;
- (BOOL)otpHasError;
- (void)otpClearError;
- (NSString *) bitidParseURI:(NSString *)uri;
- (BOOL) bitidLogin:(NSString *)uri;
- (BitidSignature *) bitidSign:(NSString *)uri msg:(NSString *)msg;

void ABC_BitCoin_Event_Callback(const tABC_AsyncBitCoinInfo *pInfo);
void ABC_Sweep_Complete_Callback(tABC_CC cc, const char *szID, uint64_t amount);

///////////////////////// New AirbitzCore methods //////////////////////

/*
 * signIn
 * @param NSString* username: username to login
 * @param NSString* password: password of user
 * @param NSString* otp: One Time Password token (optional) send nil if logging in w/o OTP
 *
 * (Optional. If used, method returns immediately with ABCCConditionCodeOk)
 * @param completionHandler: completion handler code block
 * @param errorHandler: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *
 * @return ABCConditionCode
 */
- (ABCConditionCode)signIn:(NSString *)username password:(NSString *)password otp:(NSString *)otp;
- (ABCConditionCode)signIn:(NSString *)username password:(NSString *)password otp:(NSString *)otp
                     complete:(void (^)(void)) completionHandler
                        error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;

/*
 * signInWithPINAsync
 * @param NSString* username: username to login
 * @param NSString* pin: user's 4 digit PIN
 *
 * (Optional. If used, method returns immediately with ABCCConditionCodeOk)
 * @param completionHandler: completion handler code block
 * @param errorHandler: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 * @return ABCConditionCode
 */
- (ABCConditionCode)signInWithPIN:(NSString *)username pin:(NSString *)pin;
- (ABCConditionCode)signInWithPIN:(NSString *)username pin:(NSString *)pin
                            complete:(void (^)(void)) completionHandler
                               error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;


/*
 * checkRecoveryAnswersAsync
 * @param NSString* strAnswers: concatenated string of recovery answers
 * @param NSString* username: username
 * @param completionHandler: completion handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param BOOL               bABCValid: YES if answers are correct
 *                          @param NSString         *strAnswers: NSString answers
 * @return void
 */
- (void)checkRecoveryAnswersAsync:(NSString *)username answers:(NSString *)strAnswers
                         complete:(void (^)(ABCConditionCode ccode,
                                 BOOL bABCValid)) completionHandler;

/*
 * getRecoveryQuestionsChoicesAsync
 * @param completionHandler: completion handler code block which is called with the following args
 *                          @param ABCConditionCode ccode: ABC error code
 *                          @param NSMutableString  arrayCategoryString:  array of string based questions
 *                          @param NSMutableString  arrayCategoryNumeric: array of numeric based questions
 *                          @param NSMutableString  arrayCategoryMust:    array of questions of which one must have an answer
 * @return void
 */
-(void)getRecoveryQuestionsChoicesAsync:(void (^)(ABCConditionCode ccode,
        NSMutableArray *arrayCategoryString,
        NSMutableArray *arrayCategoryNumeric,
        NSMutableArray *arrayCategoryMust)) completionHandler;


/*
 * errorMap
 * @param  ABCConditionCode: error code to look up
 * @return NSString*       : text description of error
 */
- (NSString *)conditionCodeMap:(const ABCConditionCode) code;


/*
 * getLocalAccounts
 * @param  NSArray**       : array of strings of account names
 * @return ABCConditionCode: error code to look up
 */
//- (ABCConditionCode)getLocalAccounts:(NSArray **) arrayAccounts;

/*
 * uploadLogsAsync
 * @param NSString* username: username
 * @param completionHandler: completion handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 * @return void
 */
- (void)uploadLogsAsync:(NSString *)username complete:(void (^)(ABCConditionCode ccode)) completionHandler;


- (ABCConditionCode) getLastConditionCode;
- (NSString *) getLastErrorString;


@end

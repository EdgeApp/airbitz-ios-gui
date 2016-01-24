//
//  CoreBridge.h
//  AirBitz
//

#import "Wallet.h"
#import "Transaction.h"
#import "FadingAlertView.h"
#import "Theme.h"
#import "ABCConditionCode.h"

#define CONFIRMED_CONFIRMATION_COUNT 6
#define PIN_REQUIRED_PERIOD_SECONDS     120
#define ABC_ARRAY_EXCHANGES     @[@"Bitstamp", @"BraveNewCoin", @"Coinbase", @"CleverCoin"]


@interface BitidSignature : NSObject
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *signature;
@end

@interface ABCSettings : NSObject

// User Settings
@property (nonatomic) int minutesAutoLogout;
@property (nonatomic) int defaultCurrencyNum;
@property (nonatomic) int64_t denomination;
@property (nonatomic, copy) NSString* denominationLabel;
@property (nonatomic) int denominationType;
@property (nonatomic, copy) NSString* firstName;
@property (nonatomic, copy) NSString* lastName;
@property (nonatomic, copy) NSString* nickName;
@property (nonatomic, copy) NSString* fullName;
@property (nonatomic, copy) NSString* strPIN;
@property (nonatomic, copy) NSString* exchangeRateSource;
@property (nonatomic) bool bNameOnPayments;
@property (nonatomic, copy) NSString* denominationLabelShort;
@property (nonatomic) bool bSpendRequirePin;
@property (nonatomic) int64_t spendRequirePinSatoshis;
@property (nonatomic) bool bDisablePINLogin;

@end

@interface CoreBridge : NSObject

@property (nonatomic, strong) ABCSettings               *settings;
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


@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *password;


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
- (NSArray *)getLocalAccounts:(NSString **)strError;
- (BOOL)accountExistsLocal:(NSString *)username;
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
- (BOOL)needsRecoveryQuestionsReminder:(Wallet *)wallet;
- (bool)PINLoginExists;
- (bool)PINLoginExists:(NSString *)username;
- (void)deletePINLogin;
- (void)setupLoginPIN;
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
- (NSString *)sweepKey:(NSString *)privateKey intoWallet:(NSString *)walletUUID;
- (NSString *) bitidParseURI:(NSString *)uri;
- (BOOL) bitidLogin:(NSString *)uri;
- (BitidSignature *) bitidSign:(NSString *)uri msg:(NSString *)msg;

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
 *                          @param NSString *       errorString: error message
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
 *                          @param NSString *       errorString: error message
 * @return ABCConditionCode
 */
- (ABCConditionCode)signInWithPIN:(NSString *)username pin:(NSString *)pin;
- (ABCConditionCode)signInWithPIN:(NSString *)username pin:(NSString *)pin
                            complete:(void (^)(void)) completionHandler
                               error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;

/*
 * uploadLogs
 * @param NSString* userText: text to send to support staff
 *
 * (Optional. If used, method returns immediately with ABCCConditionCodeOk)
 * @param complete: completion handler code block which is called with void
 * @param error: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return ABCConditionCode
 */
- (ABCConditionCode)uploadLogs:(NSString *)userText;
- (ABCConditionCode)uploadLogs:(NSString *)userText
        complete:(void(^)(void))completionHandler
           error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;

/*
 * walletRemove
 * @param NSString* uuid: UUID of wallet to delete
 *
 * (Optional. If used, method returns immediately with ABCCConditionCodeOk)
 * @param complete: completion handler code block which is called with void
 * @param error: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return ABCConditionCode
 */

- (ABCConditionCode)walletRemove:(NSString *)uuid;
- (ABCConditionCode)walletRemove:(NSString *)uuid
                        complete:(void(^)(void))completionHandler
                           error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;

/*
 * loadSettings
 *      Load account settings from disk and update the ABCSettings object inside AirbitzCore object
 * @param void
 *
 * @return ABCConditionCode
 */

- (ABCConditionCode)loadSettings;


/*
 * saveSettings
 *      Uses ABCSettings object inside AirbitzCore object and saves settings to disk
 * @param void
 *
 * @return ABCConditionCode
 */
- (ABCConditionCode)saveSettings;

/*
 * accountDeleteLocal
 *      Deletes named account from local device. Account is recoverable if it contains a password
 * @param NSString* username: username of account to delete
 *
 * @return ABCConditionCode
 */
- (ABCConditionCode)accountDeleteLocal:(NSString *)username;


/*
 * checkRecoveryAnswers
 * @param NSString* username: username
 * @param NSString* strAnswers: concatenated string of recovery answers separated by '\n' after each answer
 *
 * @param complete: completion handler code block which is called with void
 * @param error: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return ABCConditionCode
 */
- (void)checkRecoveryAnswers:(NSString *)username
        answers:(NSString *)strAnswers
       complete:(void (^)(BOOL validAnswers)) completionHandler
          error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;

/*
 * getRecoveryQuestionsChoices
 * @param complete: completion handler code block which is called with the following args
 *                          @param NSMutableString  arrayCategoryString:  array of string based questions
 *                          @param NSMutableString  arrayCategoryNumeric: array of numeric based questions
 *                          @param NSMutableString  arrayCategoryMust:    array of questions of which one must have an answer
 * @param error: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return void
 */
- (void)getRecoveryQuestionsChoices: (void (^)(
        NSMutableArray *arrayCategoryString,
        NSMutableArray *arrayCategoryNumeric,
        NSMutableArray *arrayCategoryMust)) completionHandler
                              error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;

/*
 * setRecoveryQuestions
 * @param NSString* password: password of currently logged in user
 * @param NSString* questions: concatenated string of recovery questions separated by '\n' after each question
 * @param NSString* answers: concatenated string of recovery answers separated by '\n' after each answer
 *
 * (Optional. If used, method returns immediately with ABCCConditionCodeOk)
 * @param complete: completion handler code block which is called with void
 * @param error: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return ABCConditionCode
 */

- (ABCConditionCode)setRecoveryQuestions:(NSString *)password
                               questions:(NSString *)questions
                                 answers:(NSString *)answers;
- (ABCConditionCode)setRecoveryQuestions:(NSString *)password
                               questions:(NSString *)questions
                                 answers:(NSString *)answers
                                complete:(void (^)(void)) completionHandler
                                   error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;


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


- (ABCConditionCode) getLastConditionCode;
- (NSString *) getLastErrorString;


@end

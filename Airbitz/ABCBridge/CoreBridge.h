//
//  CoreBridge.h
//  Airbitz
//

#import "Wallet.h"
#import "Transaction.h"
#import "FadingAlertView.h"
#import "Theme.h"
#import "ABCConditionCode.h"
#import "ABCSpend.h"
#import "ABCRequest.h"
#import "ABCSettings.h"

#define ABC_NOTIFICATION_LOGOUT                             @"ABC_Main_Views_Reset"
#define ABC_NOTIFICATION_REMOTE_PASSWORD_CHANGE             @"ABC_Remote_Password_Change"
#define ABC_NOTIFICATION_OTP_REQUIRED                       @"ABC_Otp_Required"
#define ABC_NOTIFICATION_OTP_SKEW                           @"ABC_Otp_Skew"
#define ABC_NOTIFICATION_DATA_SYNC_UPDATE                   @"ABC_Data_Sync_Update"
#define ABC_NOTIFICATION_EXCHANGE_RATE_CHANGE               @"ABC_Exchange_Rate_Change"
#define ABC_NOTIFICATION_TX_RECEIVED                        @"ABC_Transaction_Received"
#define ABC_NOTIFICATION_WALLETS_LOADING                    @"ABC_Wallets_Loading"
#define ABC_NOTIFICATION_WALLETS_LOADED                     @"ABC_Wallets_Loaded"
#define ABC_NOTIFICATION_WALLETS_CHANGED                    @"ABC_Wallets_Changed"

static const int ABCDenominationBTC  = 0;
static const int ABCDenominationMBTC = 1;
static const int ABCDenominationUBTC = 2;

#define CONFIRMED_CONFIRMATION_COUNT 6
#define PIN_REQUIRED_PERIOD_SECONDS     120
#define ABC_ARRAY_EXCHANGES     @[@"Bitstamp", @"BraveNewCoin", @"Coinbase", @"CleverCoin"]

#define ABCLog(level, format_string,...) \
((abcDebugLog(level, [NSString stringWithFormat:format_string,##__VA_ARGS__])))

void abcDebugLog(int level, NSString *string);
void abcSetDebugLevel(int level);

typedef enum eABCDeviceCaps
{
    ABCDeviceCapsTouchID,
} ABCDeviceCaps;

@class ABCSpend;
@class CoreBridge;
@class ABCSettings;
@class ABCRequest;

@interface BitidSignature : NSObject
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *signature;
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


- (id)init:(NSString *)abcAPIKey hbits:(NSString *)hbitsKey;
- (void)free;
- (void)startQueues;
- (void)stopQueues;

- (void)clearSyncQueue;
- (void)clearTxSearchQueue;

- (void)postToDataQueue:(void(^)(void))cb;
- (void)postToWalletsQueue:(void(^)(void))cb;
- (void)postToGenQRQueue:(void(^)(void))cb;
- (void)postToTxSearchQueue:(void(^)(void))cb;
- (void)postToMiscQueue:(void(^)(void))cb;

- (int)dataOperationCount;

// New methods
- (void)rotateWalletServer:(NSString *)walletUUID refreshData:(BOOL)bData notify:(void(^)(void))cb;
- (void)reorderWallets: (NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;
- (void)makeCurrentWallet:(Wallet *)wallet;
- (void)makeCurrentWalletWithIndex:(NSIndexPath *)indexPath;
- (void)makeCurrentWalletWithUUID:(NSString *)strUUID;
- (Wallet *)selectWalletWithUUID:(NSString *)strUUID;
- (long) saveLogoutDate;
- (void)addCategory:(NSString *)strCategory;
- (void)loadCategories;
- (void)saveCategories:(NSMutableArray *)saveArrayCategories;
- (BOOL)accountExistsLocal:(NSString *)username;
- (BOOL) isLoggedIn;



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
- (BOOL)recentlyLoggedIn;
- (void)logout;
- (BOOL)passwordOk:(NSString *)password;
- (BOOL)passwordExists;
- (BOOL)passwordExists:(NSString *)username;
- (void)restoreConnectivity;
- (void)lostConnectivity;
- (void)prioritizeAddress:(NSString *)address inWallet:(NSString *)walletUUID;
- (NSString *)coreVersion;
- (NSString *)currencyAbbrevLookup:(int) currencyNum;
- (NSString *)currencySymbolLookup:(int)currencyNum;
- (int)getCurrencyNumOfLocale;
- (NSString *)sweepKey:(NSString *)privateKey intoWallet:(NSString *)walletUUID;
- (NSString *) bitidParseURI:(NSString *)uri;
- (BOOL) bitidLogin:(NSString *)uri;
- (BitidSignature *) bitidSign:(NSString *)uri msg:(NSString *)msg;

///////////////////////// New AirbitzCore methods //////////////////////

/*
 * createAccount
 * @param NSString* username:
 * @param NSString* password:
 * @param NSString* pin:
 *
 * (Optional. If used, method returns immediately with ABCCConditionCodeOk)
 * @param completionHandler: completion handler code block
 * @param errorHandler: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 *
 * @return ABCConditionCode
 */
- (ABCConditionCode)createAccount:(NSString *)username password:(NSString *)password pin:(NSString *)pin;
- (ABCConditionCode)createAccount:(NSString *)username password:(NSString *)password pin:(NSString *)pin
                         complete:(void (^)(void)) completionHandler
                            error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;

/*
 * createWallet
 * @param NSString* walletName: set to nil to use default wallet name
 * @param int       currencyNum: ISO currency number for wallet. set to 0 to use defaultCurrencyNum from
 *                               settings or the global default currency number if settings unavailable
 *
 * (Optional. If used, method returns immediately with ABCCConditionCodeOk)
 * @param completionHandler: completion handler code block
 * @param errorHandler: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return ABCConditionCode
 */
- (ABCConditionCode) createWallet:(NSString *)walletName currencyNum:(int) currencyNum;
- (ABCConditionCode) createWallet:(NSString *)walletName currencyNum:(int) currencyNum
                         complete:(void (^)(void)) completionHandler
                            error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;


/*
 * renameWallet
 * @param NSString* walletUUID: UUID of wallet to rename
 * @param NSString*    newName: new name of wallet
 * @return ABCConditionCode
 */
- (ABCConditionCode) renameWallet:(NSString *)walletUUID
                          newName:(NSString *)walletName;

- (ABCConditionCode) createFirstWalletIfNeeded;
- (ABCConditionCode) getNumWalletsInAccount:(int *)numWallets;

- (ABCConditionCode)getOTPResetUsernames:(NSMutableArray **) usernameArray;
- (ABCConditionCode)hasOTPResetPending:(BOOL *)needsReset;

/**
 * getOTPLocalKey
 * @param NSString* username: user to get the OTP key for
 * @param NSString**     key: pointer to key returned from routine
 * @return ABCConditionCode
 */
- (ABCConditionCode)getOTPLocalKey:(NSString *)username
                               key:(NSString **)key;

/**
 * setOTPKey
 * Associates an OTP key with the given username.
 * This will not write to disk until the user has successfully logged in
 * at least once.
 * @param NSString* username: user to set the OTP key for
 * @param NSString*      key: key to set
 * @return ABCConditionCode
 */
- (ABCConditionCode)setOTPKey:(NSString *)username
                          key:(NSString *)key;

/**
 * removeOTPKey
 * Removes the OTP key for current user.
 * This will remove the key from disk as well.
 * @return ABCConditionCode
 */
- (ABCConditionCode)removeOTPKey;

/**
 * getOTPDetails
 * Reads the OTP configuration from the server.
 * This will remove the key from disk as well.
 * @param NSString* username:
 * @param NSString* password:
 * @param     bool*  enabled: enabled flag if OTP is enabled for this user
 * @param     long*  timeout: number seconds required after a reset is requested
 *                            before OTP is disabled. This is set by setOTPAuth
 * @return ABCConditionCode
 */
- (ABCConditionCode)getOTPDetails:(NSString *)username
                         password:(NSString *)password
                          enabled:(bool *)enabled
                          timeout:(long *)timeout;

/**
 * setOTPAuth
 * Sets up OTP authentication on the server for currently logged in user
 * This will generate a new token if the username doesn't already have one.
 * @param     long   timeout: number seconds required after a reset is requested
 *                            before OTP is disabled.
 * @return ABCConditionCode
 */
- (ABCConditionCode)setOTPAuth:(long)timeout;

/**
 * removeOTPAuth
 * Removes the OTP authentication requirement from the server for the 
 * currently logged in user
 * @return ABCConditionCode
 */
- (ABCConditionCode)removeOTPAuth;

/**
 * getOTPResetDateForLastFailedAccountLogin
 *
 * Returns the OTP reset date for the last account that failed to log in,
 * if any. Returns an empty string otherwise.
 * @param NSDate   **date: pointer to NSDate for return value date
 * @return ABCConditionCode
 */
- (ABCConditionCode)getOTPResetDateForLastFailedAccountLogin:(NSDate **)date;

/**
 * requestOTPReset
 * Launches an OTP reset timer on the server,
 * which will disable the OTP authentication requirement when it expires.
 *
 * This only works after the caller has successfully authenticated
 * with the server, such as through a password login,
 * but has failed to fully log in due to a missing OTP key.
 * @param NSString   *username:
 *
 * (Optional. If used, method returns immediately with ABCCConditionCodeOk)
 * @param completionHandler: completion handler code block
 * @param errorHandler: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return ABCConditionCode
 */
- (ABCConditionCode)requestOTPReset:(NSString *)username;
- (ABCConditionCode)requestOTPReset:(NSString *)username
                           complete:(void (^)(void)) completionHandler
                              error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;

/**
 * removeOTPResetRequest
 * Removes the OTP reset request from the server for the
 * currently logged in user
 * @return ABCConditionCode
 */
- (ABCConditionCode)removeOTPResetRequest;

/**
 * encodeStringToQRImage
 * Encodes a string into a QR code returned as UIImage *
 *
 * @param     NSString*   string: string to encode
 * @param     UIImage**    image: returned image
 * @return ABCConditionCode
 */
- (ABCConditionCode)encodeStringToQRImage:(NSString *)string
                                    image:(UIImage **)image;


/**
 * isAccountUsernameAvailable
 * Checks if username is available
 *
 * @param     NSString*   username: username to check
 * @return ABCConditionCodeOk if username is available
 */
- (ABCConditionCode)isAccountUsernameAvailable:(NSString *)username;

/**
 * PINLoginExists
 * Checks if PIN login is possible for the given username. This checks if
 * there is a local PIN package on the device from a prior login
 *
 * @param     NSString   *username: username to check
 * @return    BOOL: YES if username is available
 */
- (BOOL)PINLoginExists:(NSString *)username;

- (NSString *) getLastAccessedAccount;
- (void) setLastAccessedAccount:(NSString *) account;


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
 * signInWithPIN
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
 * autoReloginOrTouchIDIfPossible
 *
 * Attempts to auto-relogin the most recently logged in user if they are within their auto-logout 
 * setting (default 1 hour). Should be called upon initial execution of app and when the Login screen 
 * reappears after logout.
 *
 * @param username: user account to attempt to relogin
 * @param doBeforeLogin: completion handler code block executes before login is attempted
 * @param completeWithLogin: completion handler code block executes if login is successful
 * @param completeNoLogin: completion handler code block executes if relogin not attempted
 * @param errorHandler: error handler code block which is called if relogin attempted but failed
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return ABCConditionCode
 */
- (void)autoReloginOrTouchIDIfPossible:(NSString *)username
                         doBeforeLogin:(void (^)(void)) doBeforeLogin
                     completeWithLogin:(void (^)(BOOL usedTouchID)) completionWithLogin
                       completeNoLogin:(void (^)(void)) completionNoLogin
                                 error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;

/*
 * checkPasswordRules
 *  Checks a password for valid entropy looking for correct minimum
 *  requirements such as upper, lowercase letters, numbers, and # of digits
 * @param NSString                     *password: password to check
 * @param BOOL                            *valid: pointer to valid which is true if password passes checks
 * @param double                 *secondsToCrack: pointer to estimated time it takes to crack password
 * @param int                             *count: pointer to number of rules used
 * @param NSMutableArray        *ruleDescription: pointer to array of NSString * with description of each rule
 * @param NSMutableArray             *rulePassed: pointer to array of NSNumber * with BOOL of whether rule passed
 * @param NSMutableString   *checkResultsMessage: pointer to message describing failures
 *
 * @return ABCConditionCode
 */
- (ABCConditionCode)checkPasswordRules:(NSString *)password
                                 valid:(BOOL *)valid
                        secondsToCrack:(double *)secondsToCrack
                                 count:(unsigned int *)count
                       ruleDescription:(NSMutableArray **)ruleDescription
                            rulePassed:(NSMutableArray **)rulePassed
                   checkResultsMessage:(NSMutableString **) checkResultsMessage;


/*
 * changePassword
 * @param NSString* password: new password for currently logged in user
 *
 * (Optional. If used, method returns immediately with ABCCConditionCodeOk)
 * @param completionHandler: completion handler code block
 * @param errorHandler: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return ABCConditionCode
 */
- (ABCConditionCode)changePassword:(NSString *)password;
- (ABCConditionCode)changePassword:(NSString *)password
                          complete:(void (^)(void)) completionHandler
                             error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;

/*
 * changePasswordWithRecoveryAnswers
 * @param NSString*        username: username whose password to change
 * @param NSString* recoveryAnswers: recovery answers delimited by '\n'
 * @param NSString*     newPassword: new password
 *
 * (Optional. If used, method returns immediately with ABCCConditionCodeOk)
 * @param completionHandler: completion handler code block
 * @param errorHandler: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return ABCConditionCode
 */
- (ABCConditionCode)changePasswordWithRecoveryAnswers:(NSString *)username
                                      recoveryAnswers:(NSString *)answers
                                          newPassword:(NSString *)password;
- (ABCConditionCode)changePasswordWithRecoveryAnswers:(NSString *)username
                                      recoveryAnswers:(NSString *)answers
                                          newPassword:(NSString *)password
                                             complete:(void (^)(void)) completionHandler
                                                error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;

/*
 * changePIN
 * @param NSString* pin: new pin for currently logged in user
 *
 * (Optional. If used, method returns immediately with ABCCConditionCodeOk)
 * @param completionHandler: completion handler code block
 * @param errorHandler: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return ABCConditionCode
 */
- (ABCConditionCode)changePIN:(NSString *)pin;
- (ABCConditionCode)changePIN:(NSString *)pin
                     complete:(void (^)(void)) completionHandler
                        error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;


/*
 * createReceiveRequestWithDetails
 * @param ABCRequest    *request: object with various bitcoin request details and return info
 *
 * (Optional. If used, method returns immediately with ABCCConditionCodeOk)
 * @param completionHandler: completion handler code block
 * @param errorHandler: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return ABCConditionCode
 */
- (ABCConditionCode)createReceiveRequestWithDetails:(ABCRequest *)request;
- (ABCConditionCode)createReceiveRequestWithDetails:(ABCRequest *)request
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
 * newSpendFromText
 *      Creates a ABCSpend object from text. Text could be a bitcoin address or URI
 * @param NSString* uri: bitcoin address or full BIP21 uri
 * @param ABCSpend **abcSpend: pointer to ABCSpend object
 * @return ABCConditionCode
 */
- (ABCConditionCode)newSpendFromText:(NSString *)uri abcSpend:(ABCSpend **)abcSpend;


/*
 * newSpendFromTextAsync
 *      Creates a ABCSpend object from text. Text could be a bitcoin address or URI
 * @param NSString* walletUUID: walletUUID of destination wallet for transfer
 *
 * @param complete: completion handler code block which is called with ABCSpend *
 *                          @param ABCSpend *    abcSpend: ABCSpend object
 * @param error: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return void
 */

- (void)newSpendFromTextAsync:(NSString *)uri
                     complete:(void(^)(ABCSpend *sp))completionHandler
                        error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;


/*
 * newSpendFromTransfer
 *      Creates a ABCSpend object from text. Text could be a bitcoin address or URI
 * @param NSString* walletUUID: walletUUID of destination wallet for transfer
 * @param ABCSpend **abcSpend: pointer to ABCSpend object
 * @return ABCConditionCode
 */
- (ABCConditionCode)newSpendTransfer:(NSString *)destWalletUUID abcSpend:(ABCSpend **)abcSpend;

/*
 * newSpendFromTransferAsync
 *      Creates a ABCSpend object from walletUUID.
 * @param NSString* walletUUID: walletUUID of destination wallet for transfer
 *
 * @param complete: completion handler code block which is called with ABCSpend *
 *                          @param ABCSpend *    abcSpend: ABCSpend object
 * @param error: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return void
 */
//- (void)newSpendTransferAsync:(NSString *)uri
//                     complete:(void(^)(ABCSpend *sp))completionHandler
//                        error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;


- (ABCConditionCode)newSpendInternal:(NSString *)address
                               label:(NSString *)label
                            category:(NSString *)category
                               notes:(NSString *)notes
                       amountSatoshi:(uint64_t)amountSatoshi
                         abcSpend:(ABCSpend **)abcSpend;


/*
 * clearBlockchainCache
 * clears the local cache of blockchain info and force a re-download. This will cause wallets
 * to report incorrect balances which the blockchain is resynced
 *
 * @param complete: completion handler code block which is called with ABCSpend *
 *                          @param ABCSpend *    abcSpend: ABCSpend object
 * @param error: error handler code block which is called with the following args
 *                          @param ABCConditionCode       ccode: ABC error code
 *                          @param NSString *       errorString: error message
 * @return ABCConditionCodeOk (always returns Ok)
 */
- (ABCConditionCode)clearBlockchainCache;
- (ABCConditionCode)clearBlockchainCache:(void (^)(void)) completionHandler
                                   error:(void (^)(ABCConditionCode ccode, NSString *errorString)) errorHandler;


/*
 * satoshiToCurrency
 *      Convert bitcoin amount in satoshis to a fiat currency amount
 * @param uint_64t     satoshi: amount to convert in satoshis
 * @param int      currencyNum: ISO currency number of fiat currency to convert to
 * @param double    *pCurrency: pointer to resulting value
 * @return ABCConditionCode
 */
- (ABCConditionCode) satoshiToCurrency:(uint64_t) satoshi
                           currencyNum:(int)currencyNum
                              currency:(double *)pCurrency;

/*
 * currencyToSatoshi
 *      Convert fiat amount to a satoshi amount
 * @param double      currency: amount to convert in satoshis
 * @param int      currencyNum: ISO currency number of fiat currency to convert from
 * @param uint_64t   *pSatoshi: pointer to resulting value
 * @return ABCConditionCode
 */
- (ABCConditionCode) currencyToSatoshi:(double)currency
                           currencyNum:(int)currencyNum
                               satoshi:(int64_t *)pSatoshi;
- (bool)isTestNet;


/*
 * getLocalAccounts
 *      Get a list of previously logged in account names on this device
 * @param  NSMutableArray*       : array of strings of account names
 * @return ABCConditionCode: error code to look up
 */
- (ABCConditionCode) getLocalAccounts:(NSMutableArray *) accounts;

- (ABCConditionCode) getLastConditionCode;
- (NSString *) getLastErrorString;
- (BOOL) hasDeviceCapability:(ABCDeviceCaps) caps;

/*
 * shouldAskUserToEnableTouchID
 *  Evaluates if user should be asked to enable touch ID based
 *  on various factors such as if they have ever disabled touchID
 *  in the past, if they have touchID hardware support, and if
 *  this account has a password. PIN only accounts can't user TouchID
 *  at the moment. If user previously had touchID enabled, this will
 *  automatically enable touchID and return NO.
 *  Should be called while logged in.
 * @return BOOL: Should GUI ask if user wants to enable
 */
- (BOOL) shouldAskUserToEnableTouchID;

+ (int) getMinimumUsernamedLength;
+ (int) getMinimumPasswordLength;
+ (int) getMinimumPINLength;

/*
 * enterBackground
 * Call this routine from within applicationDidEnterBackground to have ABC
 * spin down any background queues
 */
- (void)enterBackground;


/*
 * enterBackground
 * Call this routine from within applicationDidEnterBackground to have ABC
 * spin down any background queues
 */
- (void)enterForeground;


@end

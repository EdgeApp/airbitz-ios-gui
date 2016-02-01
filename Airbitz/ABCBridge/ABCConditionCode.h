//
//  ABCConditionCode.h
//  Airbitz
//
//  This needs to get generated from ABC.h error codes

typedef enum eABCConditionCode
{
    /** The function completed without an error */
            ABCConditionCodeOk = 0,
    /** An error occured */
            ABCConditionCodeError = 1,
    /** Unexpected NULL pointer */
            ABCConditionCodeNULLPtr = 2,
    /** Max number of accounts have been created */
            ABCConditionCodeNoAvailAccountSpace = 3,
    /** Could not read directory */
            ABCConditionCodeDirReadError = 4,
    /** Could not open file */
            ABCConditionCodeFileOpenError = 5,
    /** Could not read from file */
            ABCConditionCodeFileReadError = 6,
    /** Could not write to file */
            ABCConditionCodeFileWriteError = 7,
    /** No such file */
            ABCConditionCodeFileDoesNotExist = 8,
    /** Unknown crypto type */
            ABCConditionCodeUnknownCryptoType = 9,
    /** Invalid crypto type */
            ABCConditionCodeInvalidCryptoType = 10,
    /** Decryption error */
            ABCConditionCodeDecryptError = 11,
    /** Decryption failure due to incorrect key */
            ABCConditionCodeDecryptFailure = 12,
    /** Encryption error */
            ABCConditionCodeEncryptError = 13,
    /** Scrypt error */
            ABCConditionCodeScryptError = 14,
    /** Account already exists */
            ABCConditionCodeAccountAlreadyExists = 15,
    /** Account does not exist */
            ABCConditionCodeAccountDoesNotExist = 16,
    /** JSON parsing error */
            ABCConditionCodeJSONError = 17,
    /** Incorrect password */
            ABCConditionCodeBadPassword = 18,
    /** Wallet already exists */
            ABCConditionCodeWalletAlreadyExists = 19,
    /** URL call failure */
            ABCConditionCodeURLError = 20,
    /** An call to an external API failed  */
            ABCConditionCodeSysError = 21,
    /** No required initialization made  */
            ABCConditionCodeNotInitialized = 22,
    /** Initialization after already initializing  */
            ABCConditionCodeReinitialization = 23,
    /** Server error  */
            ABCConditionCodeServerError = 24,
    /** The user has not set recovery questions */
            ABCConditionCodeNoRecoveryQuestions = 25,
    /** Functionality not supported */
            ABCConditionCodeNotSupported = 26,
    /** Mutex error if some type */
            ABCConditionCodeMutexError = 27,
    /** Transaction not found */
            ABCConditionCodeNoTransaction = 28,
    ABCConditionCodeEmpty_Wallet = 28, /* Deprecated */
    /** Failed to parse input text */
            ABCConditionCodeParseError = 29,
    /** Invalid wallet ID */
            ABCConditionCodeInvalidWalletID = 30,
    /** Request (address) not found */
            ABCConditionCodeNoRequest = 31,
    /** Not enough money to send transaction */
            ABCConditionCodeInsufficientFunds = 32,
    /** We are still sync-ing */
            ABCConditionCodeSynchronizing = 33,
    /** Problem with the PIN */
            ABCConditionCodeNonNumericPin = 34,
    /** Unable to find an address */
            ABCConditionCodeNoAvailableAddress = 35,
    /** The user has entered a bad PIN, and must wait. */
            ABCConditionCodeInvalidPinWait = 36, ABCConditionCodePinExpired = 36,
    /** Two Factor required */
            ABCConditionCodeInvalidOTP = 37,
    /** Trying to send too little money. */
            ABCConditionCodeSpendDust = 38,
    /** The server says app is obsolete and needs to be upgraded. */
            ABCConditionCodeObsolete = 1000
} ABCConditionCode;

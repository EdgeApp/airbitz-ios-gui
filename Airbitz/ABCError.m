//
//  ABCError.m
//  Airbitz
//

#import <Foundation/Foundation.h>
#import "ABCError.h"
#import "CoreBridge.h"

@interface ABCError ()

@property (atomic)              ABCConditionCode        lastConditionCode;
@property (atomic, strong)      NSString                *lastErrorString;

@end

static ABCError *singleton;

@implementation ABCError

+ (void)initAll
{
    singleton = [ABCError alloc];
}

+ (ABCError *) Singleton
{
    return singleton;
}

+ (ABCConditionCode)setLastErrors:(tABC_Error)error;
{
    singleton.lastConditionCode = (ABCConditionCode) error.code;
    if (ABCConditionCodeOk == singleton.lastConditionCode)
    {
        singleton.lastErrorString = @"";
    }
    else
    {
        singleton.lastErrorString = [ABCError errorMap:error];
        if (error.code == ABC_CC_DecryptError
                || error.code == ABC_CC_DecryptFailure)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:ABC_NOTIFICATION_LOGOUT object:self];
        }
    }
    return singleton.lastConditionCode;
}

+ (ABCConditionCode) getLastConditionCode;
{
    return singleton.lastConditionCode;
}

+ (NSString *) getLastErrorString;
{
    return singleton.lastErrorString;
}

+ (NSString *)errorMap:(tABC_Error)error;
{
    if (ABCConditionCodeInvalidPinWait == error.code)
    {
        NSString *description = [NSString stringWithUTF8String:error.szDescription];
        if ([@"0" isEqualToString:description]) {
            return NSLocalizedString(@"Invalid PIN.", nil);
        } else {
            return [NSString stringWithFormat:
                    NSLocalizedString(@"Too many failed login attempts. Please try again in %@ seconds.", nil),
                    description];
        }
    }
    else
    {
        return [ABCError conditionCodeMap:(ABCConditionCode) error.code];
    }

}

+ (NSString *)conditionCodeMap:(ABCConditionCode) cc;
{
    switch (cc)
    {
        case ABCConditionCodeAccountAlreadyExists:
            return NSLocalizedString(@"This account already exists.", nil);
        case ABCConditionCodeAccountDoesNotExist:
            return NSLocalizedString(@"We were unable to find your account. Be sure your username is correct.", nil);
        case ABCConditionCodeBadPassword:
            return NSLocalizedString(@"Invalid user name or password", nil);
        case ABCConditionCodeWalletAlreadyExists:
            return NSLocalizedString(@"Wallet already exists.", nil);
        case ABCConditionCodeInvalidWalletID:
            return NSLocalizedString(@"Wallet does not exist.", nil);
        case ABCConditionCodeURLError:
        case ABCConditionCodeServerError:
            return NSLocalizedString(@"Unable to connect to Airbitz server. Please try again later.", nil);
        case ABCConditionCodeNoRecoveryQuestions:
            return NSLocalizedString(@"No recovery questions are available for this user", nil);
        case ABCConditionCodeNotSupported:
            return NSLocalizedString(@"This operation is not supported.", nil);
        case ABCConditionCodeInsufficientFunds:
            return NSLocalizedString(@"Insufficient funds", nil);
        case ABCConditionCodeSpendDust:
            return NSLocalizedString(@"Amount is too small", nil);
        case ABCConditionCodeSynchronizing:
            return NSLocalizedString(@"Synchronizing with the network.", nil);
        case ABCConditionCodeNonNumericPin:
            return NSLocalizedString(@"PIN must be a numeric value.", nil);
        case ABCConditionCodeError:
        case ABCConditionCodeNULLPtr:
        case ABCConditionCodeNoAvailAccountSpace:
        case ABCConditionCodeDirReadError:
        case ABCConditionCodeFileOpenError:
        case ABCConditionCodeFileReadError:
        case ABCConditionCodeFileWriteError:
        case ABCConditionCodeFileDoesNotExist:
        case ABCConditionCodeUnknownCryptoType:
        case ABCConditionCodeInvalidCryptoType:
        case ABCConditionCodeDecryptError:
        case ABCConditionCodeDecryptFailure:
        case ABCConditionCodeEncryptError:
        case ABCConditionCodeScryptError:
        case ABCConditionCodeSysError:
        case ABCConditionCodeNotInitialized:
        case ABCConditionCodeReinitialization:
        case ABCConditionCodeJSONError:
        case ABCConditionCodeMutexError:
        case ABCConditionCodeNoTransaction:
        case ABCConditionCodeParseError:
        case ABCConditionCodeNoRequest:
        case ABCConditionCodeNoAvailableAddress:
        default:
            return NSLocalizedString(@"An error has occurred.", nil);
    }
}


@end
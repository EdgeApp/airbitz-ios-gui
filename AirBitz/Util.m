//
//  Util.m
//  AirBitz
//
//  Created by Adam Harris on 5/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "Util.h"
#import "ABC.h"
#import "CommonTypes.h"

@implementation Util

+ (NSString *)errorMap:(const tABC_Error *)pError
{
    switch (pError->code)
    {
        case ABC_CC_AccountAlreadyExists:
            return NSLocalizedString(@"This account already exists.", nil);
        case ABC_CC_AccountDoesNotExist:
            return NSLocalizedString(@"We were unable to find your account. Be sure your username is correct.", nil);
        case ABC_CC_BadPassword:
            return NSLocalizedString(@"Invalid user name or password", nil);
        case ABC_CC_WalletAlreadyExists:
            return NSLocalizedString(@"Wallet already exists.", nil);
        case ABC_CC_InvalidWalletID:
            return NSLocalizedString(@"Wallet does not exist.", nil);
        case ABC_CC_URLError:
        case ABC_CC_ServerError:
            return NSLocalizedString(@"Unable to connect to Airbitz server. Please try again later.", nil);
        case ABC_CC_NoRecoveryQuestions:
            return NSLocalizedString(@"No recovery questions are available for this user", nil);
        case ABC_CC_NotSupported:
            return NSLocalizedString(@"This operation is not supported.", nil);
        case ABC_CC_InsufficientFunds:
            return NSLocalizedString(@"Insufficient funds", nil);
        case ABC_CC_Synchronizing:
            return NSLocalizedString(@"Synchronizing with the network.", nil);
        case ABC_CC_NonNumericPin:
            return NSLocalizedString(@"PIN must be a numeric value.", nil);
        case ABC_CC_PinExpired:
            return NSLocalizedString(@"PIN login cancelled", nil);
        case ABC_CC_Error:
        case ABC_CC_NULLPtr:
        case ABC_CC_NoAvailAccountSpace:
        case ABC_CC_DirReadError:
        case ABC_CC_FileOpenError:
        case ABC_CC_FileReadError:
        case ABC_CC_FileWriteError:
        case ABC_CC_FileDoesNotExist:
        case ABC_CC_UnknownCryptoType:
        case ABC_CC_InvalidCryptoType:
        case ABC_CC_DecryptError:
        case ABC_CC_DecryptFailure:
        case ABC_CC_EncryptError:
        case ABC_CC_ScryptError:
        case ABC_CC_SysError:
        case ABC_CC_NotInitialized:
        case ABC_CC_Reinitialization:
        case ABC_CC_JSONError:
        case ABC_CC_MutexError:
        case ABC_CC_NoTransaction:
        case ABC_CC_ParseError:
        case ABC_CC_NoRequest:
        case ABC_CC_NoAvailableAddress:
        default:
            return NSLocalizedString(@"An error has occurred.", nil);
    }
}

+ (void)printABC_Error:(const tABC_Error *)pError
{
    if (pError)
    {
        if (pError->code != ABC_CC_Ok)
        {
            printf("Code: %d, Desc: %s, Func: %s, File: %s, Line: %d\n",
                   pError->code,
                   pError->szDescription,
                   pError->szSourceFunc,
                   pError->szSourceFile,
                   pError->nSourceLine
                   );
        }
        if (pError->code == ABC_CC_DecryptError
                    || pError->code == ABC_CC_DecryptFailure)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MAIN_RESET object:self];
        }
    }
}

// resizes a view that is one of the tab bar screens to the approriate size to avoid the toolbar
// display view is if the view has a sub-view that also does not include the top 'name of screen' bar
+ (void)resizeView:(UIView *)theView withDisplayView:(UIView *)theDisplayView
{
    CGRect frame;

    if (theView)
    {
        frame = theView.frame;
        frame.size.height = SUB_SCREEN_HEIGHT;
        theView.frame = frame;
    }

    if (theDisplayView)
    {
        frame = theDisplayView.frame;
        frame.size.height = DISPLAY_AREA_HEIGHT;
        theDisplayView.frame = frame;
    }
}


+ (void)freeStringArray:(char **)aszStrings count:(unsigned int)count
{
    if ((aszStrings != NULL) && (count > 0))
    {
        for (int i = 0; i < count; i++)
        {
            free(aszStrings[i]);
        }
        free(aszStrings);
    }
}

// creates the full name from an address book record
+ (NSString *)getNameFromAddressRecord:(ABRecordRef)person
{
    NSString *strFirstName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *strMiddleName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
    NSString *strLastName  = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);

    NSMutableString *strFullName = [[NSMutableString alloc] init];
    if (strFirstName)
    {
        if ([strFirstName length])
        {
            [strFullName appendString:strFirstName];
        }
    }
    if (strMiddleName)
    {
        if ([strMiddleName length])
        {
            if ([strFullName length])
            {
                [strFullName appendString:@" "];
            }
            [strFullName appendString:strMiddleName];
        }
    }
    if (strLastName)
    {
        if ([strLastName length])
        {
            if ([strFullName length])
            {
                [strFullName appendString:@" "];
            }
            [strFullName appendString:strLastName];
        }
    }

    // if we don't have a name yet, try the company
    if ([strFullName length] == 0)
    {
        NSString *strCompanyName  = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonOrganizationProperty);
        if (strCompanyName)
        {
            if ([strCompanyName length])
            {
                [strFullName appendString:strCompanyName];
            }
        }
    }

    return strFullName;
}

+ (void)callTelephoneNumber:(NSString *)telNum
{
    static UIWebView *webView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        webView = [UIWebView new];
    });
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:telNum]]];
}

@end

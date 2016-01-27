//
//  Keychain.m
//  Airbitz
//
//  Created by Paul Puey on 2015-08-31.
//  Copyright (c) 2015 Airbitz. All rights reserved.
//


#import "Keychain.h"
#import "NSMutableData+Secure.h"
#import "Theme.h"
#import "User.h"
#import "LocalSettings.h"
#import "AppDelegate.h"
#import <LocalAuthentication/LocalAuthentication.h>

@implementation Keychain

+ (BOOL) setKeychainData:(NSData *)data key:(NSString *)key authenticated:(BOOL) authenticated;
{
    if (! key) return NO;
    if (![Keychain bHasSecureEnclave]) return NO;

        id accessible = (authenticated) ? (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly :
            (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    NSDictionary *query = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService:SEC_ATTR_SERVICE,
            (__bridge id)kSecAttrAccount:key};

    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL) == errSecItemNotFound) {
        if (! data) return YES;

        NSDictionary *item = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
                (__bridge id)kSecAttrService:SEC_ATTR_SERVICE,
                (__bridge id)kSecAttrAccount:key,
                (__bridge id)kSecAttrAccessible:accessible,
                (__bridge id)kSecValueData:data};
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef)item, NULL);

        if (status == noErr) return YES;
        NSLog(@"SecItemAdd error status %d", (int)status);
        return NO;
    }

    if (! data) {
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);

        if (status == noErr) return YES;
        NSLog(@"SecItemDelete error status %d", (int)status);
        return NO;
    }

    NSDictionary *update = @{(__bridge id)kSecAttrAccessible:accessible,
            (__bridge id)kSecValueData:data};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)update);

    if (status == noErr) return YES;
    NSLog(@"SecItemUpdate error status %d", (int)status);
    return NO;
}

+ (NSData *) getKeychainData:(NSString *)key error:(NSError **)error;
{
    NSDictionary *query = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService:SEC_ATTR_SERVICE,
            (__bridge id)kSecAttrAccount:key,
            (__bridge id)kSecReturnData:@YES};
    CFDataRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);

    if (status == errSecItemNotFound) return nil;
    if (status == noErr) return CFBridgingRelease(result);
    if (error) *error = [NSError errorWithDomain:@"Airbitz" code:status
                                        userInfo:@{NSLocalizedDescriptionKey:@"SecItemCopyMatching error"}];
    return nil;
}


+ (BOOL) setKeychainString:(NSString *)s key:(NSString *)key authenticated:(BOOL) authenticated;
{
    @autoreleasepool {
        NSData *d = (s) ? CFBridgingRelease(CFStringCreateExternalRepresentation(SecureAllocator(), (CFStringRef)s,
                kCFStringEncodingUTF8, 0)) : nil;

        return [self setKeychainData:d key:key authenticated:authenticated];
    }
}

+ (NSString *) getKeychainString:(NSString *)key error:(NSError **)error;
{
    @autoreleasepool {
        NSData *d = [self getKeychainData:key error:error];

        return (d) ? CFBridgingRelease(CFStringCreateFromExternalRepresentation(SecureAllocator(), (CFDataRef)d,
                kCFStringEncodingUTF8)) : nil;
    }
}

+ (BOOL) setKeychainInt:(int64_t) i key:(NSString *)key authenticated:(BOOL) authenticated;
{
    @autoreleasepool {
        NSMutableData *d = [NSMutableData secureDataWithLength:sizeof(int64_t)];

        *(int64_t *)d.mutableBytes = i;
        return [self setKeychainData:d key:key authenticated:authenticated];
    }
}

+ (int64_t) getKeychainInt:(NSString *)key error:(NSError **)error;
{
    @autoreleasepool {
        NSData *d = [self getKeychainData:key error:error];

        return (d.length == sizeof(int64_t)) ? *(int64_t *)d.bytes : 0;
    }
}

+ (NSString *) createKeyWithUsername:(NSString *)username key:(NSString *)key;
{
    return [NSString stringWithFormat:@"%@___%@",username,key];
}

+ (BOOL) bHasSecureEnclave;
{
    LAContext *context = [LAContext new];
    NSError *error = nil;

    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error])
    {
        return YES;
    }

    return NO;
}

// Authenticate w/touchID
+ (BOOL)authenticateTouchID:(NSString *)promptString fallbackString:(NSString *)fallbackString;
{
    LAContext *context = [LAContext new];
    NSError *error = nil;
    __block NSInteger authcode = 0;

    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error])
    {
        context.localizedFallbackTitle = fallbackString;

        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                localizedReason:(promptString.length > 0 ? promptString : @" ") reply:^(BOOL success, NSError *error)
                {
                    authcode = (success) ? 1 : error.code;
                }];

        while (authcode == 0) {
            [[NSRunLoop mainRunLoop] limitDateForMode:NSDefaultRunLoopMode];
        }

        if (authcode == LAErrorAuthenticationFailed)
        {
            return NO;
        }
        else if (authcode == 1)
        {
            return YES;
        }
        else if (authcode == LAErrorUserCancel || authcode == LAErrorSystemCancel)
        {
            return NO;
        }
    }
    else if (error)
    {
        NSLog(@"[LAContext canEvaluatePolicy:] %@", error.localizedDescription);
    }

    return NO;
}

+ (void) disableRelogin:(NSString *)username;
{
    [Keychain setKeychainData:nil
                          key:[Keychain createKeyWithUsername:username key:RELOGIN_KEY]
                authenticated:YES];
}

+ (void) disableTouchID:(NSString *)username;
{
    [Keychain setKeychainData:nil
                          key:[Keychain createKeyWithUsername:username key:USE_TOUCHID_KEY]
                authenticated:YES];
}

+ (void) clearKeychainInfo:(NSString *)username;
{
    [Keychain setKeychainData:nil
                          key:[Keychain createKeyWithUsername:username key:PASSWORD_KEY]
                authenticated:YES];
    [Keychain setKeychainData:nil
                          key:[Keychain createKeyWithUsername:username key:RELOGIN_KEY]
                authenticated:YES];
    [Keychain setKeychainData:nil
                          key:[Keychain createKeyWithUsername:username key:USE_TOUCHID_KEY]
                authenticated:YES];
}

+ (BOOL) disableKeychainBasedOnSettings;
{
    BOOL disableFingerprint = NO;
    if (![Keychain bHasSecureEnclave])
        return YES;

    if ([[LocalSettings controller].touchIDUsersDisabled indexOfObject:[AppDelegate abc].name] != NSNotFound)
        disableFingerprint = YES;

    [Keychain setKeychainInt:disableFingerprint ? 0 : 1
                         key:[Keychain createKeyWithUsername:[AppDelegate abc].name key:USE_TOUCHID_KEY]
               authenticated:YES];

    if ([AppDelegate abc].settings.bDisablePINLogin && disableFingerprint)
    {
        // If user has disabled TouchID and PIN relogin, then do not use Keychain at all for maximum security
        [Keychain clearKeychainInfo:[AppDelegate abc].name];
        return YES;
    }

    return NO;
}

+ (void) updateLoginKeychainInfo:(NSString *)username
                        password:(NSString *)password
                         relogin:(BOOL) bRelogin
                      useTouchID:(BOOL) bUseTouchID;
{
    if ([self disableKeychainBasedOnSettings])
        return;

    NSString *name = [AppDelegate abc].name;
    
    [Keychain setKeychainInt:bRelogin
                         key:[Keychain createKeyWithUsername:[AppDelegate abc].name key:RELOGIN_KEY]
               authenticated:YES];
    [Keychain setKeychainInt:bUseTouchID
                         key:[Keychain createKeyWithUsername:[AppDelegate abc].name key:USE_TOUCHID_KEY]
               authenticated:YES];
    [Keychain setKeychainString:password
                            key:[Keychain createKeyWithUsername:[AppDelegate abc].name key:PASSWORD_KEY]
                authenticated:YES];
}

+ (void) updateLoginKeychainInfo:(NSString *)username
                        password:(NSString *)password
                      useTouchID:(BOOL) bUseTouchID;
{
    if ([self disableKeychainBasedOnSettings])
        return;

    NSString *name = [AppDelegate abc].name;

    [Keychain setKeychainInt:1
                         key:[Keychain createKeyWithUsername:[AppDelegate abc].name key:RELOGIN_KEY]
               authenticated:YES];
    [Keychain setKeychainInt:bUseTouchID
                         key:[Keychain createKeyWithUsername:[AppDelegate abc].name key:USE_TOUCHID_KEY]
               authenticated:YES];
    if (password != nil)
    {
        [Keychain setKeychainString:password
                                key:[Keychain createKeyWithUsername:[AppDelegate abc].name key:PASSWORD_KEY]
                      authenticated:YES];
    }
}

@end
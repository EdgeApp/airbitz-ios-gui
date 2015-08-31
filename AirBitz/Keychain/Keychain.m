//
//  Keychain.m
//  Airbitz
//
//  Created by Paul Puey on 2015-08-31.
//  Copyright (c) 2015 Airbitz. All rights reserved.
//


#import "Keychain.h"
#import "NSMutableData+Secure.h"

@implementation Keychain

+ (BOOL) setKeychainData:(NSData *)data key:(NSString *)key authenticated:(BOOL) authenticated;
{
    if (! key) return NO;

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

@end
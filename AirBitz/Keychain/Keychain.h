//
//  Keychain.h
//  Airbitz
//
//  Created by Paul Puey on 2015-08-31.
//  Copyright (c) 2015 Airbitz. All rights reserved.
//

#import <Foundation/Foundation.h>

#define USERNAME_KEY            @"key_username"
#define PASSWORD_KEY            @"key_password"
#define PIN_KEY                 @"key_pin"
#define SEC_ATTR_SERVICE        @"co.airbitz.airbitz"

@interface Keychain : NSObject

+ (BOOL) setKeychainData:(NSData *)data key:(NSString *)key authenticated:(BOOL) authenticated;
+ (NSData *) getKeychainData:(NSString *)key error:(NSError **)error;
+ (BOOL) setKeychainString:(NSString *)s key:(NSString *)key authenticated:(BOOL) authenticated;
+ (NSString *) getKeychainString:(NSString *)key error:(NSError **)error;

@end
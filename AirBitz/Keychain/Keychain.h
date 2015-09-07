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
#define RELOGIN_KEY             @"key_relogin"
#define USE_TOUCHID_KEY         @"key_use_touchid"
#define LOGIN_TIME_KEY          @"key_logintime"
#define SEC_ATTR_SERVICE        @"co.airbitz.airbitz"

@interface Keychain : NSObject

+ (BOOL) setKeychainData:(NSData *)data key:(NSString *)key authenticated:(BOOL) authenticated;
+ (NSData *) getKeychainData:(NSString *)key error:(NSError **)error;
+ (BOOL) setKeychainString:(NSString *)s key:(NSString *)key authenticated:(BOOL) authenticated;
+ (BOOL) setKeychainInt:(int64_t) i key:(NSString *)key authenticated:(BOOL) authenticated;
+ (int64_t) getKeychainInt:(NSString *)key error:(NSError **)error;

+ (NSString *) getKeychainString:(NSString *)key error:(NSError **)error;
+ (BOOL)authenticateTouchID:(NSString *)promptString fallbackString:(NSString *)fallbackString;

+ (void) disableRelogin;
+ (void) disableTouchID;
+ (BOOL) disableKeychainBasedOnSettings;
+ (void) clearKeychainInfo;
+ (void) updateLoginKeychainInfo:(NSString *)username
                             pin:(NSString *)PINCode
                        password:(NSString *)password
                         relogin:(BOOL) bRelogin;

@end
//
//  ABCKeychain.h
//  Airbitz
//
//  Created by Paul Puey on 2015-08-31.
//  Copyright (c) 2015 Airbitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AirbitzCore.h"
#import "ABCSettings.h"
#import "ABCLocalSettings.h"

#define PASSWORD_KEY            @"key_password"
#define RELOGIN_KEY             @"key_relogin"
#define USE_TOUCHID_KEY         @"key_use_touchid"
#define LOGOUT_TIME_KEY          @"key_logout_time"
#define SEC_ATTR_SERVICE        @"co.airbitz.airbitz"

@class ABCSettings;
@class ABCLocalSettings;

@interface ABCKeychain : NSObject

@property (nonatomic) ABCSettings *settings;
@property (nonatomic) ABCLocalSettings *localSettings;

- (id) init:(AirbitzCore *)abc;
- (BOOL) setKeychainData:(NSData *)data key:(NSString *)key authenticated:(BOOL) authenticated;
- (NSData *) getKeychainData:(NSString *)key error:(NSError **)error;
- (BOOL) setKeychainString:(NSString *)s key:(NSString *)key authenticated:(BOOL) authenticated;
- (BOOL) setKeychainInt:(int64_t) i key:(NSString *)key authenticated:(BOOL) authenticated;
- (int64_t) getKeychainInt:(NSString *)key error:(NSError **)error;
- (NSString *) getKeychainString:(NSString *)key error:(NSError **)error;
- (NSString *) createKeyWithUsername:(NSString *)username key:(NSString *)key;
- (BOOL) bHasSecureEnclave;
- (BOOL)authenticateTouchID:(NSString *)promptString fallbackString:(NSString *)fallbackString;
- (void) disableRelogin:(NSString *)username;
- (void) disableTouchID:(NSString *)username;
- (BOOL) disableKeychainBasedOnSettings:(NSString *)username;
- (void) clearKeychainInfo:(NSString *)username;
- (void) updateLoginKeychainInfo:(NSString *)username
                        password:(NSString *)password
                      useTouchID:(BOOL) bUseTouchID;
//- (void) updateLoginKeychainInfo:(NSString *)username
//                        password:(NSString *)password
//                      useTouchID:(BOOL) bUseTouchID
//                         relogin:(BOOL) bRelogin;

@end
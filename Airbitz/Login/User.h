//
//  User.h
//  Airbitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 Airbitz. All rights reserved.
//
//  master user object that other modules can access in order to get userName and password

#import <Foundation/Foundation.h>
#import "CommonTypes.h"
#import "ABC.h"
#import "AppDelegate.h"

@interface User : NSObject

@property (nonatomic) NSUInteger sendInvalidEntryCount;
@property (nonatomic) NSUInteger sendState;
@property (nonatomic) NSRunLoop *runLoop;
@property (nonatomic) NSTimer *sendInvalidEntryTimer;
@property (nonatomic) NSUInteger PINLoginInvalidEntryCount;
@property (nonatomic) BOOL needsPasswordCheck;

//
// Per user local device settings. Not sync'ed across devices
//
@property (nonatomic) bool bDailySpendLimit;
@property (nonatomic) int64_t dailySpendLimitSatoshis;
@property (nonatomic) NSInteger pinLoginCount;

+ (void)initAll;
+ (void)freeAll;
+ (User *)Singleton;
+ (BOOL)isLoggedIn;
+ (void)login:(NSString *)user password:(NSString *)pword;
+ (void)login:(NSString *)user password:(NSString *)pword setupPIN:(BOOL)setupPIN;

- (id)init;
- (void)clear;
- (void)loadSettings;
- (void)saveLocalSettings;
- (SendViewState)sendInvalidEntry;
- (void)startInvalidEntryWait;
- (void)endInvalidEntryWait;
- (NSTimeInterval)getRemainingInvalidEntryWait;
- (bool)haveExceededPINLoginInvalidEntries;
- (void)resetPINLoginInvalidEntryCount;
- (void)incPINorTouchIDLogin;
- (void)loadLocalSettings;
- (void)saveDisclaimerViewed;


@end

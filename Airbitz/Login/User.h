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
#import "ABCAccount.h"

@interface User : NSObject

@property (nonatomic) NSUInteger sendInvalidEntryCount;
@property (nonatomic) NSUInteger sendState;
@property (nonatomic) NSRunLoop *runLoop;
@property (nonatomic) NSTimer *sendInvalidEntryTimer;
@property (nonatomic) NSUInteger PINLoginInvalidEntryCount;
@property (nonatomic) BOOL needsPasswordCheck;
@property (nonatomic) NSString *affiliateInfo;
@property (nonatomic) NSDictionary *dictAffiliateInfo;

//
// Per user local device settings. Not sync'ed across devices
//
@property (nonatomic) bool bDailySpendLimit;
@property (nonatomic) int64_t dailySpendLimitSatoshis;

//
// Password check settings
//
@property (nonatomic) NSDate   *lastPasswordLogin;
@property (nonatomic) NSInteger passwordReminderCount;
@property (nonatomic) NSInteger passwordReminderDays;
@property (nonatomic) NSInteger numNonPasswordLogin;
@property (nonatomic) NSInteger numPasswordUsed;

+ (void)initAll;
+ (void)freeAll;
+ (User *)Singleton;
+ (BOOL)isLoggedIn;
+ (void)login:(ABCAccount *)user;

- (id)init;
- (void)clear;
- (void)saveLocalSettings;
- (SendViewState)sendInvalidEntry;
- (void)startInvalidEntryWait;
- (void)endInvalidEntryWait;
- (NSTimeInterval)getRemainingInvalidEntryWait;
- (bool)haveExceededPINLoginInvalidEntries;
- (void)resetPINLoginInvalidEntryCount;
- (void)incPINorTouchIDLogin;
- (void)passwordUsed;
- (void)passwordWrongAndSkipped;
- (void)resetPasswordReminderToDefaults;
- (void)loadLocalSettings;


@end

//
// Created by Paul P on 1/30/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ABCConditionCode.h"
#import "CoreBridge.h"

@class CoreBridge;

@interface ABCSettings : NSObject

@property (nonatomic) CoreBridge *abc;

// User Settings that are synced across devices
@property (nonatomic) int minutesAutoLogout;
@property (nonatomic) int defaultCurrencyNum;
@property (nonatomic) int64_t denomination;
@property (nonatomic, copy) NSString* denominationLabel;
@property (nonatomic) int denominationType;
@property (nonatomic, copy) NSString* firstName;
@property (nonatomic, copy) NSString* lastName;
@property (nonatomic, copy) NSString* nickName;
@property (nonatomic, copy) NSString* fullName;
@property (nonatomic, copy) NSString* strPIN;
@property (nonatomic, copy) NSString* exchangeRateSource;
@property (nonatomic) bool bNameOnPayments;
@property (nonatomic, copy) NSString* denominationLabelShort;
@property (nonatomic) bool bSpendRequirePin;
@property (nonatomic) int64_t spendRequirePinSatoshis;
@property (nonatomic) bool bDisablePINLogin;

- (ABCConditionCode)loadSettings;
- (ABCConditionCode)saveSettings;
- (id)initWithABC:(CoreBridge *)abc;

@end


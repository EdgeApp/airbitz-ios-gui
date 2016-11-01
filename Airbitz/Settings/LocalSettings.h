//
//  LocalSettings.h
//  AirBitz
//
//  Created by Adam Harris on 8/16/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <Foundation/Foundation.h>

// this is singleton object class
// this means it has static methods that create on instance of itself for use by all

@interface LocalSettings : NSObject

@property (nonatomic, assign)   BOOL            bDisableBLE;
@property (nonatomic, assign)   BOOL            bMerchantMode;
@property (nonatomic, assign)   BOOL            bLocalNotificationsAllowed;
@property (nonatomic, assign)   NSInteger       previousNotificationID;
@property (nonatomic, assign)   NSInteger       receiveBitcoinCount;    // how many times user received bitcoin, for messaging
@property (nonatomic, retain)   NSMutableArray  *notifications;
@property (nonatomic, retain)   NSMutableArray  *otpNotifications;
@property (nonatomic, retain)   NSString        *clientID;
@property (nonatomic, assign)   NSTimeInterval  noPasswordNotificationTime;


@property (nonatomic) bool bDisclaimerViewed;
@property (nonatomic) bool reviewNotified;
@property (nonatomic) bool showRunningBalance;
@property (nonatomic) bool hideBalance;
@property (nonatomic) BOOL bCheckedForAffiliate;
@property (nonatomic) NSString          *affiliateInfo;
@property (nonatomic) NSDate            *firstLoginTime;
@property (nonatomic) NSInteger         loginCount;



+ (void)initAll;
+ (void)freeAll;

+ (void)loadAll;
+ (void)saveAll;

+ (LocalSettings *)controller;

- (BOOL)offerUserReview:(int)numTransactions earliestDate:(NSDate *)earliestDate;
- (BOOL)offerRequestHelp;
- (BOOL)offerSendHelp;
- (BOOL)offerBleHelp;
- (BOOL)offerWalletHelp;
- (BOOL)offerPluginsHelp;

@end


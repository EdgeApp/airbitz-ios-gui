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
@property (nonatomic, retain)   NSString        *cachedUsername;
@property (nonatomic, assign)   NSInteger       previousNotificationID;
@property (nonatomic, retain)   NSMutableArray  *notifications;
@property (nonatomic, retain)   NSString        *clientID;

+ (void)initAll;
+ (void)freeAll;

+ (void)loadAll;
+ (void)saveAll;

+ (LocalSettings *)controller;

@end


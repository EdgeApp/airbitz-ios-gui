//
//  Wallet.h
//  AirBitz
//
//  Created by Adam Harris on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WALLET_ATTRIBUTE_ARCHIVE_BIT 0x1 // BIT0 is the archive bit

@interface Wallet : NSObject

@property (nonatomic, copy)     NSString        *strUUID;
@property (nonatomic, copy)     NSString        *strName;
@property (nonatomic, copy)     NSString        *strUserName;
@property (nonatomic, assign)   int             currencyNum;
@property (nonatomic, copy)     NSString        *currencyAbbrev;
@property (nonatomic, copy)     NSString        *currencySymbol;
@property (nonatomic, assign)   unsigned int    archived;
@property (nonatomic, assign)   double          balance;
@property (nonatomic, strong)   NSArray         *arrayTransactions;
@property (nonatomic, assign)   BOOL            loaded;

- (BOOL)isArchived;

@end

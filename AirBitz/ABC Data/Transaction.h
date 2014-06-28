//
//  Transaction.h
//  AirBitz
//
//  Created by Adam Harris on 3/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Transaction : NSObject

@property (nonatomic, copy)     NSString        *strID;
@property (nonatomic, copy)     NSString        *strMallealbeID;
@property (nonatomic, copy)     NSString        *strWalletUUID;
@property (nonatomic, copy)     NSString        *strWalletName;
@property (nonatomic, copy)     NSString        *strName;
@property (nonatomic, copy)     NSString        *strAddress;
@property (nonatomic, strong)   NSDate          *date;
@property (nonatomic, assign)   BOOL            bConfirmed;
@property (nonatomic, assign)   BOOL            bSyncing;
@property (nonatomic, assign)   unsigned int    confirmations;
@property (nonatomic, assign)   SInt64			amountSatoshi;
@property (nonatomic, assign)   double          amountFiat;
@property (nonatomic, assign)   SInt64			minerFees;
@property (nonatomic, assign)   SInt64			abFees;
@property (nonatomic, assign)   SInt64          balance;
@property (nonatomic, copy)     NSString        *strCategory;
@property (nonatomic, copy)     NSString        *strNotes;
@property (nonatomic, strong)   NSArray         *outputs;

@end

//
//  Transaction.h
//  AirBitz
//
//  Created by Adam Harris on 3/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <Foundation/Foundation.h>

#define EXCHANGE_RATE			600.0	/* cw temp dollars divided by this equals bitcoin */

@interface Transaction : NSObject

@property (nonatomic, copy)     NSString        *strID;
@property (nonatomic, copy)     NSString        *strWalletUUID;
@property (nonatomic, copy)     NSString        *strWalletName;
@property (nonatomic, copy)     NSString        *strName;
@property (nonatomic, copy)     NSString        *strAddress;
@property (nonatomic, strong)   NSDate          *date;
@property (nonatomic, assign)   BOOL            bConfirmed;
@property (nonatomic, assign)   unsigned int    confirmations;
@property (nonatomic, assign)   double          amount;
@property (nonatomic, assign)   double          balance;
@property (nonatomic, copy)     NSString        *strCategory;
@property (nonatomic, copy)     NSString        *strNotes;

@end

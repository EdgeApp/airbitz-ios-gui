//
//  TxOutput.h
//  AirBitz
//
//  Created by Timbo on 6/17/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TxOutput : NSObject

@property (nonatomic, copy)     NSString        *strAddress;
@property (nonatomic, assign)   BOOL            bInput;
@property (nonatomic, assign)   SInt64			value;

@end

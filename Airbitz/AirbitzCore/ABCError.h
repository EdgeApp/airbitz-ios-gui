//
// Created by Paul P on 1/30/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ABCConditionCode.h"
#import "ABC.h"

@interface ABCError : NSObject

/*
 * errorMap
 * @param  ABCConditionCode: error code to look up
 * @return NSString*       : text description of error
 */
+ (NSString *)conditionCodeMap:(const ABCConditionCode) code;

+ (void)initAll;
+ (ABCConditionCode)setLastErrors:(tABC_Error)error;
+ (ABCConditionCode) getLastConditionCode;
+ (NSString *) getLastErrorString;

@end
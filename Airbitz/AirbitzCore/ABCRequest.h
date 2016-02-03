//
// Created by Paul P on 1/30/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ABC.h"
#import "AirbitzCore.h"

@class AirbitzCore;

//
// Object used to pass in address request details
// Optional fields payeeName, category, notes, and bizId will cause
// transactions details of incoming transaction to be automatically tagged
// with the information from this object.
//
@interface ABCRequest : NSObject
// The following are passed into ABC as details for the request
@property (nonatomic, copy) NSString *walletUUID;    // required
@property (nonatomic)       int64_t  amountSatoshi;  // optional: will be added to URI/QRcode if given
@property (nonatomic, copy) NSString *payeeName;     // optional: will be added to URI/QRcode if given
@property (nonatomic, copy) NSString *category;      // optional: will be added to URI/QRcode if given
@property (nonatomic, copy) NSString *notes;         // optional: will be added to URI/QRcode if given
@property (nonatomic)       unsigned int bizId;      // optional: will be added to URI/QRcode if given

// The following are returned by ABC
@property (nonatomic, weak) AirbitzCore *abc; // pointer to AirbitzCore object that created request
@property (nonatomic, copy) NSString *requestID;
@property (nonatomic, copy) NSString *uri;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) UIImage  *qrCode;



/*
 * finalizeRequest
 * Finalizes the request so the address cannot be used by future requests. Forces address
 * rotation so the next request gets a different address
 *
 * @return ABCConditionCode
 */
- (ABCConditionCode)finalizeRequest;

- (ABCConditionCode)modifyRequestWithDetails;



@end


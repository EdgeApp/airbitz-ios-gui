//
// Created by Paul P on 1/31/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ABCLocalSettings.h"
#import "AirbitzCore.h"

@class AirbitzCore;


@interface ABCLocalSettings : NSObject

@property (nonatomic, retain)   NSString        *lastLoggedInAccount;
@property (nonatomic, retain)   NSMutableArray  *touchIDUsersEnabled;
@property (nonatomic, retain)   NSMutableArray  *touchIDUsersDisabled;

- (id)init:(AirbitzCore *)abc;
- (void)loadAll;
- (void)saveAll;

@end
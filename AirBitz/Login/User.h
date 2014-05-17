//
//  User.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//
//  master user object that other modules can access in order to get userName and password

#import <Foundation/Foundation.h>

@interface User : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *password;

// User Settings
@property (nonatomic) int64_t denomination;
@property (nonatomic, copy) NSString* denominationLabel;

+ (void)initAll;
+ (void)freeAll;
+(User *)Singleton;

-(id)init;
-(void)clear;
-(void)loadSettings;

@end

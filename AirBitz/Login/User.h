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

+ (void)initAll;
+ (void)freeAll;
+(User *)Singleton;

-(id)init;
-(void)clear;

@end

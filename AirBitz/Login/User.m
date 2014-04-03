//
//  User.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "User.h"
#import "Config.h"



static BOOL bInitialized = NO;

@implementation User

static User *singleton = nil;  // this will be the one and only object this static singleton class has

+ (void)initAll
{
	if (NO == bInitialized)
	{
        singleton = [[User alloc] init];
		bInitialized = YES;
	}
}

+ (void)freeAll
{
	if (YES == bInitialized)
	{
        // release our singleton
        singleton = nil;
        
		bInitialized = NO;
	}
}

+(User *)Singleton
{
	return singleton;
}

-(id)init
{
	self = [super init];
	if(self)
	{
		[self clear];
	}
	return self;
}

-(void)clear
{
	#if HARD_CODED_LOGIN
	self.name = HARD_CODED_LOGIN_NAME;
	self.password = HARD_CODED_LOGIN_PASSWORD;
	#else
	self.name = nil;
	self.password = nil;
	#endif
}

@end

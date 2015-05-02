//
//  Theme.m
//  AirBitz
//
//  Created by Paul Puey on 5/2/15.
//  Copyright (c) 2015 AirBitz. All rights reserved.
//

#import "Theme.h"
#import "Util.h"

static BOOL bInitialized = NO;

@implementation Theme

static Theme *singleton = nil;  // this will be the one and only object this static singleton class has

+ (void)initAll
{
    if (NO == bInitialized)
    {
        singleton = [[Theme alloc] init];
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

+ (Theme *)Singleton
{
    return singleton;
}

- (id)init
{
    self = [super init];

    //    self.denomination = 100000000;
    self.colorTextLink = UIColorFromARGB(0xFF007aFF);
    
    return self;
}

@end

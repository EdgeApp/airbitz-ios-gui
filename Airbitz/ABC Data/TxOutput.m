//
//  TxOutput.m
//  AirBitz
//
//  Created by Timbo on 6/17/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "TxOutput.h"

@interface TxOutput ()
@end

@implementation TxOutput

#pragma mark - NSObject overrides

- (id)init
{
    self = [super init];
    if (self) 
    {
        self.strAddress = @"";
        self.bInput = false;
        self.value = 0;
    }
    return self;
}

- (void)dealloc 
{
}

@end

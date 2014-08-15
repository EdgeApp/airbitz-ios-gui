//
//  Contact.m
//  AirBitz
//
//  Created by Carson Whitsett on 8/14/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "Contact.h"


@implementation Contact

- (id)init
{
    self = [super init];
    if (self)
	{
        self.strName = @"";
        self.strData = @"";
        self.strDataLabel = @"";
        self.imagePhoto = nil;
    }
    return self;
}

- (void)dealloc
{
	
}

// overriding the description - used in debugging
- (NSString *)description
{
	return([NSString stringWithFormat:@"ABContact: %@ - %@: %@", self.strName, self.strDataLabel, self.strData]);
}

- (NSComparisonResult)compare:(Contact *)otherObject
{
    return [self.strName compare:otherObject.strName];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
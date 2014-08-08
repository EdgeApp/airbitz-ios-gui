//
//  Wallet.m
//  AirBitz
//
//  Created by Adam Harris on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "Wallet.h"
#import "ABC.h"

@interface Wallet ()


@end

@implementation Wallet

#pragma mark - NSObject overrides

- (id)init
{
    self = [super init];
    if (self) 
	{
        self.strUUID = @"";
        self.strName = @"";
        self.strUserName = @"";
        self.arrayTransactions = [[NSArray alloc] init];
    }
    return self;
}

- (void)dealloc 
{

}

// overriding the NSObject isEqual
// allows us to call things like removeObject in array's of these
- (BOOL)isEqual:(id)object
{
	if ([object isKindOfClass:[Wallet class]])
	{
		Wallet *walletOther = object;
		
        if ([self.strUUID isEqualToString:walletOther.strUUID])
        {
			return YES;
		}
	}
    
	// if we got this far then they are not equal
	return NO;
}

// overriding the NSObject hash
// since we are overriding isEqual, we have to override hash to make sure they agree
- (NSUInteger)hash
{
    return([self.strUUID hash]);
}

- (BOOL)isArchived
{
    return self.archived == 1;
}

// overriding the description - used in debugging
- (NSString *)description
{
	return([NSString stringWithFormat:@"Wallet - UUID: %@, Name: %@, UserName: %@, CurrencyNum: %d, Attributes: %d, Balance: %lf, Transactions: %@",
            self.strUUID,
            self.strName,
            self.strUserName,
            self.currencyNum,
            self.archived,
            self.balance,
            self.arrayTransactions
            ]);
}

@end

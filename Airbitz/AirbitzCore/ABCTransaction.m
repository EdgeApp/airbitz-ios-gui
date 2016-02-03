//
//  ABCTransaction.m
//  AirBitz
//
//  Created by Adam Harris on 3/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "ABCTransaction.h"

@interface ABCTransaction ()


@end

@implementation ABCTransaction

#pragma mark - NSObject overrides

- (id)init
{
    self = [super init];
    if (self) 
    {
        self.strID = @"";
        self.strWalletUUID = @"";
        self.strWalletName = @"";
        self.strName = @"";
        self.strAddress = @"";
        self.date = [NSDate date];
        self.strCategory = @"";
        self.strNotes = @"";
        self.outputs = [[NSArray alloc] init];
        self.bizId = 0;
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
    if ([object isKindOfClass:[ABCTransaction class]])
    {
        ABCTransaction *transactionOther = object;

        if ([self.strID isEqualToString:transactionOther.strID])
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
    return([self.strID hash]);
}

// overriding the description - used in debugging
- (NSString *)description
{
    return([NSString stringWithFormat:@"ABCTransaction - ID: %@, WalletUUID: %@, WalletName: %@, Name: %@, Address: %@, Date: %@, Confirmed: %@, Confirmations: %u, AmountSatoshi: %lli, AmountFiat: %lf, Balance: %lli, Category: %@, Notes: %@",
            self.strID,
            self.strWalletUUID,
            self.strWalletName,
            self.strName,
            self.strAddress,
            [self.date descriptionWithLocale:[NSLocale currentLocale]],
            (self.bConfirmed == YES ? @"Yes" : @"No"),
            self.confirmations,
            self.amountSatoshi,
            self.amountFiat,
            self.balance,
            self.strCategory,
            self.strNotes
            ]);
}

@end

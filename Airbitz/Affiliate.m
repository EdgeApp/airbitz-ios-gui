//
// Created by Paul P on 3/14/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import "AFNetworking.h"
#import "Affiliate.h"
#import "MainViewController.h"
#import "BrandStrings.h"
#import "Strings.h"
#import "LocalSettings.h"
#import "User.h"
#import "AB.h"

NSString *ServerRoot              = @"https://api.airbitz.co/";
NSString *AffiliatesRegister      = @"https://api.airbitz.co/affiliates/register";
NSString *AffiliatesQuery         = @"https://api.airbitz.co/affiliates/query";
NSString *AffiliatesTouch         = @"https://api.airbitz.co/affiliates/";

@interface Affiliate ()
{
}

@property (strong, nonatomic)        AFHTTPRequestOperationManager *afmanager;


@end

@implementation Affiliate
{

}

NSString *AffiliateDataStore = @"affiliate_program";
NSString *AffiliateLinkDataStoreKey = @"affiliate_link";
NSString *AffiliateInfoDataStoreKey = @"affiliate_info";

// Pings the server to see if the device's IP address has been recently (last 3 minutes)
// registered as having clicked on an affiliate link. If so, it gets information
// on the affiliate such as public address and saves the info in non-synced LocalSettings.
- (void) queryAffiliateInfo;
{
    [self queryAffiliateInfo:nil error:nil];
}
- (void) queryAffiliateInfo:(void (^)(NSDictionary *dict)) completionHandler
                      error:(void (^)(void)) errorHandler;
{
    if ([LocalSettings controller].bCheckedForAffiliate)
    {
        NSString *json = [LocalSettings controller].affiliateInfo;
        NSData * jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSError * error=nil;
        NSDictionary * parsedData = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
        if (completionHandler) completionHandler(parsedData);
        return;
    }
    
    self.afmanager = [MainViewController createAFManager];
    [self.afmanager GET:AffiliatesQuery parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *results = (NSDictionary *) responseObject;
        
        // Convert back to JSON to save in LocalSettings12
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:results
                                                           options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                             error:&error];
        
        if (! jsonData) {
            NSLog(@"Got an error: %@", error);
            [LocalSettings controller].affiliateInfo = @"";
            [LocalSettings controller].bCheckedForAffiliate = YES;
            [LocalSettings saveAll];
            if (errorHandler) errorHandler();
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [LocalSettings controller].affiliateInfo = jsonString;
            [LocalSettings controller].bCheckedForAffiliate = YES;
            [LocalSettings saveAll];
            if (completionHandler) completionHandler(results);
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        ABCLog(1, @"Error getting affiliate bitid URI");
        [LocalSettings controller].affiliateInfo = @"";
        [LocalSettings controller].bCheckedForAffiliate = YES;
        [LocalSettings saveAll];
        if (errorHandler) errorHandler();
    }];
}

// Should be called after a new account is created. This will take any affiliate info that is
// saved in LocalSettings and copy it to the user's data synced account.
- (void) copyLocalAffiliateInfoToAccount:(ABCAccount *)account;
{
    NSString *affiliateInfo = [LocalSettings controller].affiliateInfo;
    if (!affiliateInfo)
        affiliateInfo = @"";
    [account.dataStore dataWrite:AffiliateDataStore withKey:AffiliateInfoDataStoreKey withValue:affiliateInfo];
}

- (void) loadAffiliateInfoFromAccountToUser;
{
    NSMutableString *affiliateInfo = [[NSMutableString alloc] init];
    
    ABCError *error = [abcAccount.dataStore dataRead:AffiliateDataStore withKey:AffiliateInfoDataStoreKey data:affiliateInfo];
    
    if (!error)
    {
        NSData * jsonData = [affiliateInfo dataUsingEncoding:NSUTF8StringEncoding];
        NSError * error=nil;
        NSDictionary *dictAffiliateInfo = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
        [User Singleton].dictAffiliateInfo = dictAffiliateInfo;
        [User Singleton].affiliateInfo = [NSString stringWithString:affiliateInfo];
    }
    else
    {
        [User Singleton].dictAffiliateInfo = nil;
        [User Singleton].affiliateInfo = nil;
    }

}

- (void) getAffliateURL:(void (^)(NSString *url)) completionHandler
                  error:(void (^)(void)) errorHandler;
{
    // Try to see if we have a link saved in the datastore
    NSMutableString *data = [[NSMutableString alloc] init];
    
    ABCError *error = [abcAccount.dataStore dataRead:AffiliateDataStore withKey:AffiliateLinkDataStoreKey data:data];

    if (!error && [data length] > 0)
    {
        NSString *url = [NSString stringWithString:data];
        if (completionHandler) completionHandler(url);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
    {
        self.afmanager = [MainViewController createAFManager];

        [self.afmanager GET:AffiliatesRegister parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
        {
            NSDictionary *results = (NSDictionary *) responseObject;
            NSString *bitiduri = [results objectForKey:@"bitid_uri"];

            if (!bitiduri)
            {
                if (errorHandler) errorHandler();
            }
            else
            {
                ABCBitIDSignature *bitidSignature = [abcAccount bitidSign:bitiduri message:bitiduri];
                if (!bitidSignature)
                {
                    if (errorHandler) errorHandler();
                }
                else
                {
                    // Get an address from the Core
                    ABCReceiveAddress *receiveAddress = [abcAccount.currentWallet createNewReceiveAddress];

                    if (!receiveAddress)
                    {
                        if (errorHandler) errorHandler();
                    }
                    else
                    {
                        NSDictionary *params = @{
                                                 @"bitid_address" : bitidSignature.address,
                                                 @"bitid_signature" : bitidSignature.signature,
                                                 @"bitid_url" : bitiduri,
                                                 @"payment_address" : receiveAddress.address
                                                 };
                        
                        [self.afmanager POST:AffiliatesRegister parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
                         {
                             NSDictionary *results = (NSDictionary *) responseObject;
                             NSString *affiliateURL = [results objectForKey:@"affiliate_link"];
                             
                             receiveAddress.metaData.payeeName = appTitle;
                             receiveAddress.metaData.category  = [NSString stringWithFormat:@"%@:%@", abcStringIncomeCategory, affiliate_revenue];
                             receiveAddress.metaData.notes     = [NSString stringWithFormat:notesAffiliateRevenue, affiliateURL];
                             [receiveAddress modifyRequestWithDetails];
                             [receiveAddress finalizeRequest];
                             
                             // Save link in data store
                             ABCError *error2 = [abcAccount.dataStore dataWrite:AffiliateDataStore withKey:AffiliateLinkDataStoreKey withValue:affiliateURL];
                             
                             if (!error2)
                             {
                                 if (completionHandler) completionHandler(affiliateURL);
                             }
                             else
                             {
                                 if (errorHandler) errorHandler();
                             }
                         } failure:^(AFHTTPRequestOperation *operation, NSError *error)
                         {
                             if (errorHandler) errorHandler();
                         }];
                    }
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            ABCLog(1, @"Error registering affiliate bitid URI");
            if (errorHandler) errorHandler();
        }];
    });
}
@end

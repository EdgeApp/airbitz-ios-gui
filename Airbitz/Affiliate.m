//
// Created by Paul P on 3/14/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "Affiliate.h"
#import "MainViewController.h"
#import "BrandStrings.h"
#import "Strings.h"

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

- (void) getAffliateURL:(void (^)(NSString *url)) completionHandler
                  error:(void (^)(void)) errorHandler;
{
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
                BitidSignature *bitidSignature = [abcAccount bitidSign:bitiduri msg:bitiduri];
                if (!bitidSignature)
                {
                    if (errorHandler) errorHandler();
                }
                else
                {
                    // Get an address from the Core
                    ABCReceiveAddress *receiveAddress = [abcAccount.currentWallet createNewReceiveAddress];

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
                        receiveAddress.metaData.category  = incomeAffiliateRevenue;
                        receiveAddress.metaData.notes     = [NSString stringWithFormat:notesAffiliateRevenue, affiliateURL];
                        [receiveAddress modifyRequestWithDetails];
                        [receiveAddress finalizeRequest];
                        if (completionHandler) completionHandler(affiliateURL);

                    } failure:^(AFHTTPRequestOperation *operation, NSError *error)
                    {
                        if (errorHandler) errorHandler();
                    }];

                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            ABCLog(1, @"Error getting affiliate bitid URI");
            if (errorHandler) errorHandler();
        }];
    });
}
@end
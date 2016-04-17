//
//  MainController.h
//  Airbitz
//
//  Created by Paul P on 4/17/16.
//  Copyright © 2016 Airbitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

#if TARGET_OS_IPHONE
#import "AirbitzViewController.h"
@interface MainController : AirbitzViewController
#else
#import <Cocoa/Cocoa.h>
@interface MainController : NSViewController
#endif
{
    NSURL                       *_uri;
    BOOL                        firstLaunch;
    BOOL                        _bNewDeviceLogin;
    BOOL                        _bShowingWalletsLoadingAlert;
    BOOL                        _bDoneShowingWalletsLoadingAlert;
    
    NSTimer                     *updateExchangeRateTimer;
    
    NSString                    *_affiliateURL;
}

@property (nonatomic, strong)        NSArray                *arrayContacts;

@property (nonatomic, strong)        NSMutableDictionary    *dictImages; // images for the contacts and businesses
@property (nonatomic, strong)        NSMutableDictionary    *dictAddresses; // addresses for the contacts and businesses
@property (nonatomic, strong)        NSMutableDictionary    *dictImageURLFromBizName; // urls for business thumbnails
@property (nonatomic, strong)        NSMutableDictionary    *dictBizIds; // bizIds for the businesses
@property (nonatomic, strong)        NSMutableDictionary    *dictImageURLFromBizID;
@property (nonatomic, strong)        NSMutableArray         *arrayPluginBizIDs;
@property (nonatomic, strong)        NSMutableArray         *arrayNearBusinesses; // businesses that match distance criteria

@property (strong, nonatomic)        AFHTTPRequestOperationManager *afmanager;
@property (nonatomic, copy) NSString *strWalletUUID; // used when bringing up wallet screen for a specific wallet
@property (nonatomic, copy) NSString *strTxID;       // used when bringing up wallet screen for a specific wallet
@property (nonatomic)       BOOL     bCreatingFirstWallet;

+ (AFHTTPRequestOperationManager *) createAFManager;
+ (MainController *) Singleton;

@end

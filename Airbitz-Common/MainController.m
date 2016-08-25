//
//  MainController.m
//  Airbitz
//
//  Created by Paul P on 4/17/16.
//  Copyright © 2016 Airbitz. All rights reserved.
//

#import "MainController.h"
#import "ABCContext.h"
#import "User.h"
#import "Config.h"
#import "LocalSettings.h"
#import "NotificationChecker.h"
#import "Server.h"

@interface MainController () <ABCAccountDelegate>
{
}

@end

static MainController *singleton;

@implementation MainController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    [User initAll];
    //    [DropDownAlertView initAll];
    //    [FadingAlertView initAll];
    //
    singleton = self;
    
    _bNewDeviceLogin = NO;
    _bShowingWalletsLoadingAlert = NO;
    _bDoneShowingWalletsLoadingAlert = NO;
    self.arrayContacts = nil;
    self.dictImages = [[NSMutableDictionary alloc] init];
    self.dictAddresses = [[NSMutableDictionary alloc] init];
    self.dictImageURLFromBizName = [[NSMutableDictionary alloc] init];
    self.dictBizIds = [[NSMutableDictionary alloc] init];
    self.dictImageURLFromBizID = [[NSMutableDictionary alloc] init];
    self.arrayPluginBizIDs = [[NSMutableArray alloc] init];
    self.arrayNearBusinesses = [[NSMutableArray alloc] init];
    
    // init and set API key
    NSString *token = [NSString stringWithFormat:@"Token %@", AIRBITZ_DIRECTORY_API_KEY];
    
    self.afmanager = [AFHTTPRequestOperationManager manager];
    self.afmanager.requestSerializer = [AFJSONRequestSerializer serializer];
    [self.afmanager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];
    [self.afmanager.requestSerializer setValue:[LocalSettings controller].clientID forHTTPHeaderField:@"X-Client-ID"];
    [self.afmanager.requestSerializer setTimeoutInterval:10];
    
    [self checkEnabledPlugins];
    
    [NotificationChecker initAll];
    [NotificationChecker start];
    
#define EXCHANGE_RATE_REFRESH_INTERVAL_SECONDS 60
    
    updateExchangeRateTimer = [NSTimer scheduledTimerWithTimeInterval:EXCHANGE_RATE_REFRESH_INTERVAL_SECONDS
                                                               target:self
                                                             selector:@selector(sendUpdateExchangeNotification:)
                                                             userInfo:nil
                                                              repeats:YES];
}

+ (MainController *) Singleton;
{
    return singleton;
}

+ (AFHTTPRequestOperationManager *) createAFManager;
{
    return singleton.afmanager;
}

- (void) sendUpdateExchangeNotification:(id)object
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_EXCHANGE_RATE_CHANGED object:self userInfo:nil];
}

- (void)checkEnabledPlugins
{
    //get business details
    int arrayPluginBizIds[] = {11139, 11140, 11141};
    
    for (int i = 0; i < sizeof(arrayPluginBizIds); i++ )
    {
        int bizId = arrayPluginBizIds[i];
        NSString *requestURL = [NSString stringWithFormat:@"%@/business/%u/", SERVER_API, bizId];
        
        [self.afmanager GET:requestURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *results = (NSDictionary *)responseObject;
            
            NSNumber *numBizId = [results objectForKey:@"bizId"];
            NSString *desc = [results objectForKey:@"description"];
            if ([desc containsString:@"enabled"])
            {
                ABCLog(1, @"Plugin Bizid Enabled: %u", (unsigned int) [numBizId integerValue]);
                [self.arrayPluginBizIDs addObject:numBizId];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            ABCLog(1, @"Plugin Bizid Disabled");
        }];
        
    }
}


@end

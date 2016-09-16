//
//  SSOViewController.h
//  Airbitz
//
//  Created by Paul Puey 2016-08-09.
//  Copyright (c) 2016 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AirbitzViewController.h"

@protocol SSOViewControllerDelegate;

typedef enum eSSOMode
{
    SSOModeBitID,
    SSOModeAirbitzSSO
} tSSOMode;

@interface SSOViewController : AirbitzViewController

@property (assign)            id<SSOViewControllerDelegate>     delegate;
@property (nonatomic, strong)        ABCParsedURI               *parsedURI;
@property (nonatomic, strong)        ABCEdgeLoginInfo           *edgeLoginInfo;
@property (nonatomic, assign)        tSSOMode                   ssoMode;

@end

@protocol SSOViewControllerDelegate <NSObject>

@required
- (void)SSOViewControllerDone:(SSOViewController *)controller;
@optional

@end

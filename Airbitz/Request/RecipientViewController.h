//
//  RecipientViewController.h
//  AirBitz
//
//  Created by Adam Harris on 8/14/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AirbitzViewController.h"

typedef enum eRecipientMode
{
    RecipientMode_Email,
    RecipientMode_SMS
} tRecipientMode;

@protocol RecipientViewControllerDelegate;

@interface RecipientViewController : AirbitzViewController

@property (assign)            id<RecipientViewControllerDelegate>   delegate;
@property (nonatomic, assign) tRecipientMode                        mode;

@end

@protocol RecipientViewControllerDelegate <NSObject>

@required

- (void)RecipientViewControllerDone:(RecipientViewController *)controller withFullName:(NSString *)strFullName andTarget:(NSString *)strTarget;

@optional

@end
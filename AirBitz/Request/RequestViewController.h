//
//  RequestViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RequestViewControllerDelegate;

@interface RequestViewController : UIViewController

@property (assign) id<RequestViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString  *walletUUID;

-(void) resetViews;

@end


@protocol RequestViewControllerDelegate <NSObject>

@required
-(void)RequestViewControllerDone:(RequestViewController *)vc;
@end

//
//  BusinessDetailsViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/17/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@protocol BusinessDetailsViewControllerDelegate;

@interface BusinessDetailsViewController : UIViewController

//@property (nonatomic, strong) NSDictionary *businessGeneralInfo;
@property (assign) id<BusinessDetailsViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *bizId;
@property (nonatomic, readwrite) float distance;
@property (nonatomic, readwrite) CLLocationCoordinate2D latLong;
@end




@protocol BusinessDetailsViewControllerDelegate <NSObject>

@required
-(void)businessDetailsViewControllerDone:(BusinessDetailsViewController *)controller;
@end
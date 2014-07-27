//
//  Location.h
//  Tart
//
//  Created by Adam Harris on 5/29/12.
//  Copyright 2012 Ditty Labs, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol LocationDelegate;

@interface Location : NSObject <CLLocationManagerDelegate>
{

}


@property (nonatomic, strong) CLLocationManager	*locationManager;
@property (nonatomic, strong) CLLocation        *curLocation;
@property (nonatomic, assign) BOOL              bHaveLocation;
@property (assign) id<LocationDelegate> delegate;
// static methods
+ (void)initAllWithDelegate:(id)delegate;
+ (void)freeAll;
//specify how often (in seconds) to update location
+ (void)startLocatingWithPeriod:(NSTimeInterval)seconds; //once an accurate location is found, don't try again for this long
+ (void)stopLocating;
+ (Location *)controller;

@end





@protocol LocationDelegate <NSObject>

@optional
-(void)DidReceiveLocation;

@end

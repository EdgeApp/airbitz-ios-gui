//
//  Annotation.h
//
//  Created by Carson Whitsett on 3/5/2011.
//  Copyright 2011 Ditty Labs, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>



@interface Annotation : NSObject<MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSDictionary *business;

-(id)initWithCoordinate:(CLLocationCoordinate2D) c;

@end
	
	

//
//  MapView.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/20/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "Annotation.h"

@interface MapView : MKMapView

-(Annotation *)addAnnotationForBusiness:(NSDictionary *)business;
-(void)removeAnnotationForBusiness:(NSDictionary *)business;
-(void)removeAllAnnotations;
- (void)zoomToFitMapAnnotations;

@end

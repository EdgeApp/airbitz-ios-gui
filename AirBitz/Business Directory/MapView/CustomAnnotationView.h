//
//  CustomAnnotationView.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/25/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "SMCalloutView.h"

@interface CustomAnnotationView : MKAnnotationView

@property (strong, nonatomic) SMCalloutView *calloutView;

@end

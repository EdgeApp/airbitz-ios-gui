//
//  MapView.m
//
 
//  Copyright (c) 2014, Airbitz
//  All rights reserved.
//
//  Redistribution and use in source and binary forms are permitted provided that
//  the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//  3. Redistribution or use of modified source code requires the express written
//  permission of Airbitz Inc.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the Airbitz Project.
//
//  See AUTHORS for contributing developers
//


#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end


#import "MapView.h"
#import "Annotation.h"

@interface MKMapView (UIGestureRecognizer)

// this tells the compiler that MKMapView actually implements this method
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;

@end

@implementation MapView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)zoomToFitMapAnnotations
{
    if([self.annotations count] == 0)
        return;
	
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;
	
    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;
	
    for(Annotation *annotation in self.annotations)
    {
		if((annotation.coordinate.latitude == self.userLocation.coordinate.latitude) && (annotation.coordinate.longitude == self.userLocation.coordinate.longitude))
		{
			//skip user's actual location
			if([self.annotations count] == 1) return; //just user's location and nothing else.  Bail.
		}
		else
		{
			topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
			topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
			
			bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
			bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
		}
    }
	
    MKCoordinateRegion region;
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.2; // Add a little extra space on the sides
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.2; // Add a little extra space on the sides
    region = [self regionThatFits:region];

    if (CLLocationCoordinate2DIsValid(region.center))
    {
        [self setRegion:region animated:YES];
    }
}


-(Annotation *)addAnnotationForBusiness:(NSDictionary *)business
{
	NSObject <MKAnnotation> *ann = nil;
	
	CLLocationCoordinate2D coord;
	
	NSDictionary* locationDict = [business objectForKey:@"location"];
	if(locationDict && (locationDict != (id)[NSNull null]))
	{
		
		coord.latitude = [[locationDict objectForKey:@"latitude"] floatValue];
		coord.longitude = [[locationDict objectForKey:@"longitude"] floatValue];
		
		ann = (Annotation*)[[Annotation alloc] initWithCoordinate:coord]; //loc.m_latlong

		((Annotation *)ann).title = [business objectForKey:@"name"];
		((Annotation *)ann).subtitle = [business objectForKey:@"address"];
		((Annotation *)ann).business = business;

		[self addAnnotation:ann];

	}
	return (Annotation *)ann;
}

-(void)removeAnnotationForBusiness:(NSDictionary *)business
{
	CLLocationCoordinate2D coord;
	
	NSDictionary* locationDict = [business objectForKey:@"location"];
	if(locationDict && (locationDict != (id)[NSNull null]))
	{
		coord.latitude = [[locationDict objectForKey:@"latitude"] floatValue];
		coord.longitude = [[locationDict objectForKey:@"longitude"] floatValue];
		
		NSObject <MKAnnotation> *ann;
		for (ann in self.annotations)
		{
			if ([ann isKindOfClass:[Annotation class]])
			{
				//only remove annotation if it's far off the map
				if ((ann.coordinate.longitude == coord.longitude) && (ann.coordinate.latitude == coord.latitude))
				{
					//dbgprintf("Removed %d\n", ann.m_bibbit.m_itemID);
					[self removeAnnotation:ann];
				}
			}
		}
	}
}

-(void)removeAllAnnotations
{
	NSObject <MKAnnotation> *ann;
	for (ann in self.annotations)
	{
		if ([ann isKindOfClass:[Annotation class]])
		{
			[self removeAnnotation:ann];
		}
	}
}

// override UIGestureRecognizer's delegate method so we can prevent MKMapView's recognizer from firing
// when we interact with UIControl subclasses inside our callout view.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]])
        return NO;
    else
        return [super gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
}


/*
-(void)populateMap:(NSNotification *)notification
{
	//remove out of range annotations
	NSObject <MKAnnotation> *ann;
	for (ann in m_myMapView.annotations)
	{
		if ([ann isKindOfClass:[Annotation class]])
		{
			//only remove annotation if it's far off the map
			if ((ann.coordinate.longitude > m_myMapView.centerCoordinate.longitude + m_myMapView.region.span.longitudeDelta * 3) ||
				(ann.coordinate.longitude < m_myMapView.centerCoordinate.longitude - m_myMapView.region.span.longitudeDelta * 3) ||
				(ann.coordinate.latitude < m_myMapView.centerCoordinate.latitude - m_myMapView.region.span.latitudeDelta * 3) ||
				(ann.coordinate.latitude < m_myMapView.centerCoordinate.latitude - m_myMapView.region.span.latitudeDelta * 3))
			{
				//dbgprintf("Removed %d\n", ann.m_bibbit.m_itemID);
				[m_myMapView removeAnnotation:ann];
			}
		}
	}
	
	if([notification userInfo])
	{
		NSArray *theItems = (NSArray*)([[notification userInfo] objectForKey:@"Items"]);
		if(theItems)
		{
			int cnt =  [theItems count];
			
			for (int i=0;i < cnt; ++i)
			{
				Bibbit* loc = [theItems objectAtIndex:i];
				
				//see if annotation is already in map
				BOOL alreadyExists = false;
				for (ann in m_myMapView.annotations)
				{
					if ([ann isKindOfClass:[Annotation class]])
					{
						if(((Annotation *)ann).m_bibbit.m_itemID == loc.m_itemID)
						{
							alreadyExists = true;
							
							//set pin color based on distance from user
							float distance = GetDistanceBetween2GeoPoints(gAppDelegate->m_localUserLocation.coordinate, ann.coordinate);
							MKAnnotationView *annView = [m_myMapView viewForAnnotation:ann];
							
							if ([annView isKindOfClass:[MKPinAnnotationView class]])
							{
								if(loc.m_type == BIBBIT_TYPE_DRONE)
								{
									if(distance < PICKUP_RADIUS_METERS) //1 mile
									{
										((MKPinAnnotationView *)annView).rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
									}
									else
									{
										((MKPinAnnotationView *)annView).rightCalloutAccessoryView = nil;
									}
								}
								else
								{
									if(distance < PICKUP_RADIUS_METERS) //1 mile
									{
										((MKPinAnnotationView *)annView).pinColor = MKPinAnnotationColorGreen;
										((MKPinAnnotationView *)annView).rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
									}
									else
									{
										((MKPinAnnotationView *)annView).pinColor = MKPinAnnotationColorRed;
										((MKPinAnnotationView *)annView).rightCalloutAccessoryView = nil;
									}
								}
							}
							break;
						}
					}
				}
				if(!alreadyExists)
				{
					ann = (Annotation*)[[Annotation alloc] initWithCoordinate:loc.m_latlong]; //loc.m_latlong
					((Annotation *)ann).m_bibbit = loc;
					//NSLog(@"Name: %@, length:%d", loc.m_name, [loc.m_name length]);
					if([loc.m_name length])
					{
						((Annotation *)ann).m_title = loc.m_name;
					}
					else
					{
						((Annotation *)ann).m_title = @"No Name";
					}
					((Annotation *)ann).m_subTitle = loc.m_message;
					
					[m_myMapView addAnnotation:ann];
					//dbgprintf("Added %d\n", ann.m_bibbit.m_itemID);
					[ann release];
				}
			}
		}
	}
	//[self centerMap];
	//[m_loadingView setHidden:YES];
}
*/

@end

//
//  Location.m
//  Tart
//
//  Created by Adam Harris on 5/29/12.
//  Copyright 2012 Ditty Labs, LLC. All rights reserved.
//

#import "Location.h"
#import "AB.h"
#import "Util.h"
#import "Strings.h"

#define ACCURACY_METERS 100

static BOOL bInitialized = NO;

static Location *singleton = nil;  // this will be the one and only object this static singleton class has

@interface Location ()
{
	NSTimeInterval updatePeriod;
	NSTimer *periodTimer;
}
- (void)start;
- (void)stop;
- (void)showAlert:(NSString *)strMsg withTitle:(NSString *)strTitle;
@end

@implementation Location;

@synthesize locationManager = m_locationManager;
@synthesize curLocation = m_curLocation;
@synthesize bHaveLocation = m_bHaveLocation;

#pragma mark - Static Methods

+ (void)initAllWithDelegate:(id)delegate
{
	if (NO == bInitialized)
	{
        singleton = [[Location alloc] init];
        singleton.delegate = delegate;
		bInitialized = YES;
	}   
}

+ (void)freeAll
{
	if (YES == bInitialized)
	{
        // release our singleton
        singleton = nil;
        
		bInitialized = NO;
	}
}

// returns the user held by the singleton 
// (this call is both a container and an object class and the container holds one of itself)
+ (Location *)controller
{
    return (singleton);
}

+ (void)startLocatingWithPeriod:(NSTimeInterval)seconds
{
    if (bInitialized && singleton) 
    {
		singleton->updatePeriod = seconds;
        [singleton stop];
        [singleton start];
    }
}

+ (void)stopLocating
{
    if (bInitialized && singleton) 
    {
        [singleton stop];
    }
}

#pragma mark - NSObject overrides

- (id)init
{
    self = [super init];
    if (self) 
	{        
        self.curLocation = nil;
        //[self start];
    }
    
    return self;
}

- (void)dealloc 
{
    self.locationManager = nil;
    self.curLocation = nil;
}



#pragma mark - Misc Methods

- (void)start
{
    [self stop];
    
    if (NO == [CLLocationManager locationServicesEnabled])
    {
        [self showAlert:@"Your location services are not currently enabled. Therefore, this application will not be able to calculate distances. If you would like this feature, please go to the device settings under \"General / Location Services\" and enable it."
              withTitle:@"Location Warning"];
    }
    else
    {
        if (!self.locationManager)
        {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
			self.locationManager.distanceFilter = 500; //meters
        }
#ifdef __IPHONE_8_0
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        } else {
            [self.locationManager startUpdatingLocation];
        }
#else
        [self.locationManager startUpdatingLocation];
#endif
    }
}

- (void)stop
{
    //ABCLog(2,@"Stopping location");
    self.bHaveLocation = NO;
    if (self.locationManager)
    {
        [self.locationManager stopUpdatingLocation];
    }
	if(periodTimer)
	{
		[periodTimer invalidate];
		periodTimer = nil;
	}
}

- (void)showAlert:(NSString *)strMsg withTitle:(NSString *)strTitle
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1000 * 500);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        UIAlertView *alert = [[UIAlertView alloc]
                            initWithTitle:strTitle
                            message:strMsg
                            delegate:nil
                            cancelButtonTitle:okButtonText
                            otherButtonTitles:nil];
        [alert show];
    });
}

#pragma mark - CLLocationManagerDelegate Methods

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    self.bHaveLocation = YES;
    self.curLocation = newLocation;
    
    //ABCLog(2,@"Aquired location: %lf, %lf (%lf)", newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy);
    
	// if we are at our accuracy then we are done
	if (newLocation.horizontalAccuracy <= ACCURACY_METERS)
	{
		if(updatePeriod)
		{
			if (self.locationManager)
			{
				[self.locationManager stopUpdatingLocation];
				if(periodTimer == nil)
				{
					//ABCLog(2,@"Setting period timer for %f seconds", updatePeriod);
					periodTimer = [NSTimer scheduledTimerWithTimeInterval:updatePeriod target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
				}
			}
		}
        //ABCLog(2,@"Location is accurate enough");
	}
	if([self.delegate respondsToSelector:@selector(DidReceiveLocation)])
	{
		[self.delegate DidReceiveLocation];
	}
}

// the location manager had an issue with obtaining the location
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{	
	NSMutableString *msg = [[NSMutableString alloc] initWithString:@"The application is having difficulty obtaining your location. Please try again later."];
	
    ABCLog(2,@"Location error: %ld", (long)[error code]);
    
	if ([error domain] == kCLErrorDomain) 
	{
		// We handle CoreLocation-related errors here
		switch ([error code]) 
		{
				// "Don't Allow" on two successive app launches is the same as saying "never allow". The user
				// can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
			case kCLErrorDenied:
				[msg setString:@"You have not allowed this application to obtain your location. Therefore, this application will not be able to calculate distances. If you would like this feature, please go to the device settings under \"General / Location Servies\" and enable it for this application"];
				break;
				
			case kCLErrorLocationUnknown:
				break;
				
			default:
				break;
		}
	}

    self.bHaveLocation = NO;
    
    [self showAlert:msg withTitle:@"Location Warning"];
	if([self.delegate respondsToSelector:@selector(DidReceiveLocation)])
	{
		[self.delegate DidReceiveLocation];
	}
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (kCLAuthorizationStatusAuthorizedWhenInUse == status || kCLAuthorizationStatusAuthorizedAlways == status) {
        [self.locationManager startUpdatingLocation];
    }
}

-(void)timerFired:(NSTimer *)timer
{
	//ABCLog(2,@"Timer fired.");
	if(self.locationManager)
	{
		//ABCLog(2,@"Starting location");
		[self.locationManager startUpdatingLocation];
	}
}

@end


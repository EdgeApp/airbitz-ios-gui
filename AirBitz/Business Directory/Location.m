//
//  Location.m
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

#import "Location.h"
#import "AppDelegate.h"

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
    
    //NSLog(@"Starting location");
    
    if (NO == [CLLocationManager locationServicesEnabled])
    {
        [self showAlert:@"Your location services are not currently enabled. Therefore, this application will not be able to calculate distances. If you would like this feature, please go to the device settings under \"General / Location Services\" and enable it."
              withTitle:@"Location Warning"];
        //NSLog(@"No general location to start with");
    }
    else
    {
        if (!self.locationManager)
        {
            self.locationManager = [[CLLocationManager alloc] init];
            //self.locationManager.purpose = @"Your location is used to find businesses in your area.";
            self.locationManager.delegate = self;
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
			self.locationManager.distanceFilter = 500; //meters
        }
        [self.locationManager startUpdatingLocation];
    }
}

- (void)stop
{
    //NSLog(@"Stopping location");
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
    UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:strTitle 
						  message:strMsg
						  delegate:nil
						  cancelButtonTitle:@"OK"
						  otherButtonTitles:nil];
	[alert show];
}

#pragma mark - CLLocationManagerDelegate Methods

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    self.bHaveLocation = YES;
    self.curLocation = newLocation;
    
    //NSLog(@"Aquired location: %lf, %lf (%lf)", newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy);
    
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
					//NSLog(@"Setting period timer for %f seconds", updatePeriod);
					periodTimer = [NSTimer scheduledTimerWithTimeInterval:updatePeriod target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
				}
			}
		}
        //NSLog(@"Location is accurate enough");
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
	
    NSLog(@"Location error: %ld", (long)[error code]);
    
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

-(void)timerFired:(NSTimer *)timer
{
	//NSLog(@"Timer fired.");
	if(self.locationManager)
	{
		//NSLog(@"Starting location");
		[self.locationManager startUpdatingLocation];
	}
}

@end


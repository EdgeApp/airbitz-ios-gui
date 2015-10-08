//
//  GDrive.h
//  AirBitz
//
//  Created by Carson Whitsett on 6/4/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//
//  Interface to Google Drive
//	Call +CreateForViewController and pass in the current viewController.
//	the passed-in viewController will get a delegate callback -GDrive:isAuthenticated: with either YES or NO returned
//  If YES is returned...
//	call -uploadFile with the fileData.  Pass a name and mimeType.
//
//	Requires DriveLib.a which is compiled from the google-api-objectivec-client-read-only project (downloaded from Google).  Compile both the device and the simulator versions (generates a libGTLTouchStaticLib.a for each), then use lipo to combine them into one like this:
//
//	lipo -create Debug-iphoneos/libGTLTouchStaticLib.a Debug-iphonesimulator/libGTLTouchStaticLib.a -output DriveLib.a
//
//	Also requires the entire original google project to be accessible from this project (via user header search paths) so that the necessary .h and .m files can be included

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol GDriveDelegate;

@interface GDrive : NSObject

+(id)CreateForViewController:(UIViewController *)vc ; //will bring up credential dialog if necessary
- (void)uploadFile:(NSData *)fileData name:(NSString *)name mimeType:(NSString *)mimeType;
- (void)dismissAuthenticationController;	//will force authentication screen to go away (if it's up)
@end




@protocol GDriveDelegate <NSObject>

@optional
- (void) GDrive:(GDrive *)gDrive isAuthenticated:(BOOL)authenticated;
- (void) GDrive:(GDrive *)gDrive uploadSuccessful:(BOOL)success;
- (void) GDriveAuthControllerPresented;
@required


@end
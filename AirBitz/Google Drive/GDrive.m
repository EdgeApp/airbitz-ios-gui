//
//  GDrive.m
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



#import "GDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLDrive.h"

static NSString *const kKeychainItemName = @"Google Drive AirBitz";
static NSString *const kClientID = @"23790723117-ae9hg18f53mqk0gr6ufu5mbflsuu442o.apps.googleusercontent.com";
static NSString *const kClientSecret = @"2aTGAtZEjPN-WxYFFYSEwoYD";

@interface GDrive () <GTMOAuth2ViewControllerTouchDelegate>
{
	UIViewController *parentViewController;
	GTMOAuth2ViewControllerTouch *authController;
}

@property (nonatomic, retain) GTLServiceDrive *driveService;
@property (nonatomic, assign) id<GDriveDelegate> delegate;

@end

@implementation GDrive

+(id)CreateForViewController:(UIViewController *)vc
{
	GDrive *drive = [[GDrive alloc] initForViewController:vc];
	
	drive.delegate = (id<GDriveDelegate>)vc;
	
	if([drive isAuthorized])
	{
		if([drive.delegate respondsToSelector:@selector(GDrive:isAuthenticated:)])
		{
			[drive.delegate GDrive:drive isAuthenticated:YES];
		}
	}
	else
	{
		//bring up credential dialog
		[vc presentViewController:[drive createAuthController] animated:YES completion:^
		 {
			 if([drive.delegate respondsToSelector:@selector(GDriveAuthControllerPresented)])
			 {
				 [drive.delegate GDriveAuthControllerPresented];
			 }
			 CGRect frame = (drive->authController).view.frame;
			 frame.size.height -= 49.0; //make room for tab bar at bottom
			 (drive->authController).view.frame = frame;
			 
		 }];
	}
	return drive;
}

-(id)initForViewController:(UIViewController *)vc
{
	self = [super init];
	if(self)
	{
		// Initialize the drive service & load existing credentials from the keychain if available
		parentViewController = vc;
		self.driveService = [[GTLServiceDrive alloc] init];
		self.driveService.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
			clientID:kClientID
			clientSecret:kClientSecret];
			
		
	}
	return self;
}


// Helper to check if user is authorized
- (BOOL)isAuthorized
{
    return [((GTMOAuth2Authentication *)self.driveService.authorizer) canAuthorize];
}

// Creates the auth controller for authorizing access to Google Drive.
- (GTMOAuth2ViewControllerTouch *)createAuthController
{
    //GTMOAuth2ViewControllerTouch *authController;
    authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDriveFile
                                                                clientID:kClientID
                                                            clientSecret:kClientSecret
                                                        keychainItemName:kKeychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)];
	authController.delegate = self;
    return authController;
}

// Handle completion of the authorization process, and updates the Drive service
// with the new credentials.
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error
{
    if (error != nil)
    {
        [self showAlert:@"Authentication Error" message:error.localizedDescription];
        self.driveService.authorizer = nil;
		if([self.delegate respondsToSelector:@selector(GDrive:isAuthenticated:)])
		{
			[self.delegate GDrive:self isAuthenticated:NO];
		}
    }
    else
    {
		NSLog(@"Finished authentication successfully");
        self.driveService.authorizer = authResult;
		
		//dismiss the login credentials view controller
		[self->parentViewController dismissViewControllerAnimated:NO completion:nil];
        [viewController removeFromParentViewController];
		
		if([self.delegate respondsToSelector:@selector(GDrive:isAuthenticated:)])
		{
			[self.delegate GDrive:self isAuthenticated:YES];
		}
    }
}

// Helper for showing an alert
- (void)showAlert:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert;
    alert = [[UIAlertView alloc] initWithTitle: title
									   message: message
									  delegate: nil
							 cancelButtonTitle: @"OK"
							 otherButtonTitles: nil];
    [alert show];
}

// Helper for showing a wait indicator in a popup
- (UIAlertView*)showWaitIndicator:(NSString *)title
{
    UIAlertView *progressAlert;
    progressAlert = [[UIAlertView alloc] initWithTitle:title
                                               message:@"Please wait..."
                                              delegate:nil
                                     cancelButtonTitle:nil
                                     otherButtonTitles:nil];
    [progressAlert show];
	
    UIActivityIndicatorView *activityView;
    activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityView.center = CGPointMake(progressAlert.bounds.size.width / 2,
                                      progressAlert.bounds.size.height - 45);
	
    [progressAlert addSubview:activityView];
    [activityView startAnimating];
    return progressAlert;
}

- (void)uploadFile:(NSData *)fileData name:(NSString *)name mimeType:(NSString *)mimeType
{
    //NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    //[dateFormat setDateFormat:@"'Quickstart Uploaded File ('EEEE MMMM d, YYYY h:mm a, zzz')"];
	
    GTLDriveFile *file = [GTLDriveFile object];
    file.title = name; //[dateFormat stringFromDate:[NSDate date]];
    file.descriptionProperty = @"Uploaded from AirBitz";
    file.mimeType = mimeType;
	
    //NSData *data = UIImagePNGRepresentation((UIImage *)image);
    GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithData:fileData MIMEType:file.mimeType];
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:file
                                                       uploadParameters:uploadParameters];
	
    UIAlertView *waitIndicator = [self showWaitIndicator:@"Uploading to Google Drive"];
	
    [self.driveService executeQuery:query
				  completionHandler:^(GTLServiceTicket *ticket,
					GTLDriveFile *insertedFile, NSError *error)
		{
			[waitIndicator dismissWithClickedButtonIndex:0 animated:YES];
			if (error == nil)
			{
				NSLog(@"File ID: %@", insertedFile.identifier);
				[self showAlert:@"Google Drive" message:@"File saved!"];
				if([self.delegate respondsToSelector:@selector(GDrive:uploadSuccessful:)])
				{
					[self.delegate GDrive:self uploadSuccessful:YES];
				}
			}
			else
			{
				NSLog(@"An error occurred: %@", error);
				[self showAlert:@"Google Drive" message:@"Sorry, an error occurred!"];
				if([self.delegate respondsToSelector:@selector(GDrive:uploadSuccessful:)])
				{
					[self.delegate GDrive:self uploadSuccessful:NO];
				}
			}
		}];
}

-(void)dismissAuthenticationController
{
	//dismiss the login credentials view controller
	if(authController)
	{
		[self->parentViewController dismissViewControllerAnimated:NO completion:nil];
		[authController removeFromParentViewController];
		authController = nil;
	}
}

-(void)dealloc
{
	NSLog(@"Deallocating drive object");
}

-(void)GTMOAuth2ViewControllerTouchDismissed:(GTMOAuth2ViewControllerTouch *)controller
{
	[self dismissAuthenticationController];
}

@end




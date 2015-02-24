//
//  SignUpCameraController.m
//  AirBitz
//

#import <AVFoundation/AVFoundation.h>
#import "SignUpCameraController.h"
#import "SignUpManager.h"
#import "StylizedTextField.h"
#import "ABC.h"
#import "Util.h"

@interface SignUpCameraController ()
{
    BOOL *_requestedCamera;
}

@end

@implementation SignUpCameraController

- (IBAction)next
{
    if ([self haveRequestCamera]) {
        [self.manager next];
    } else {
        [self requestCameraAccess];
    }
}

- (BOOL)haveRequestCamera
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        return YES;
    } else if(authStatus == AVAuthorizationStatusDenied){
        return YES;
    } else if(authStatus == AVAuthorizationStatusRestricted){
        return YES;
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
        return NO;
    }
    return NO;
}

- (void)requestCameraAccess
{
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                // Thanks!
            } else {
                // Update so sad
            }
        }];
    } else {
        [self.manager next];
    }
}

@end

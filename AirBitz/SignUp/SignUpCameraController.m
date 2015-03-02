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

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self haveRequestCamera]) {
        [self.manager next];
    }

}

- (IBAction)next
{
    [self requestCameraAccess];
    [self.manager next];
}

- (BOOL)haveRequestCamera
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        return YES;
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
    }
}

@end

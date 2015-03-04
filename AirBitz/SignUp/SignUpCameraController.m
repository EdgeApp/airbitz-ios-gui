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
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                // Thanks!
            } else {
                // Update so sad
            }
        }];
    }
    [self.manager next];
}

@end

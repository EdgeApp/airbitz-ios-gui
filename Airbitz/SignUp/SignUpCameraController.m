//
//  SignUpCameraController.m
//  AirBitz
//

#import <AVFoundation/AVFoundation.h>
#import "SignUpCameraController.h"
#import "SignUpManager.h"
#import "StylizedTextField.h"
#import "Util.h"
#import "Theme.h"

@interface SignUpCameraController ()
{
    BOOL *_requestedCamera;
}
@property (weak, nonatomic) IBOutlet UILabel *infoText;

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

- (void)viewDidLoad
{
    NSString *tempText = signupCameraText;
    [Util replaceHtmlTags:&tempText];
    self.infoText.text = tempText;
}

@end

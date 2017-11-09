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
@property (weak, nonatomic) IBOutlet UILabel *cameraText;
@property (weak, nonatomic) IBOutlet UILabel *infoText;
@property (weak, nonatomic) IBOutlet UIButton *buttonNext;

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
    
    [self setThemeValues];
}

- (void)setThemeValues {
    self.cameraText.font = [UIFont fontWithName:[Theme Singleton].appFont size:17.0];
    self.cameraText.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.infoText.font = [UIFont fontWithName:[Theme Singleton].appFont size:15.0];
    self.infoText.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.buttonNext.titleLabel.font = [UIFont fontWithName:[Theme Singleton].appFont size:15.0];
    self.buttonNext.backgroundColor = [Theme Singleton].colorFirstAccent;
}

@end

//
//  SignUpManager.m
//  AirBitz
//

#import "SignUpManager.h"
#import "SignUpUsernameController.h"
#import "SignUpPasswordController.h"
#import "SignUpHandleController.h"
#import "SignUpCameraController.h"
#import "SignUpContactsController.h"
#import "SignUpWriteItController.h"
#import "Util.h"
#import <AddressBookUI/AddressBookUI.h>
#import <AVFoundation/AVFoundation.h>
#import "MainViewController.h"
#import "Theme.h"

#define FORCE_REQUEST_ACCESS_SCREENS 1

@interface SignUpManager () 
{
    UIViewController         *_current;
    SignUpUsernameController *_signupUsernameController;
    SignUpPasswordController *_signupPasswordController;
    SignUpHandleController   *_signupHandleController;
    SignUpContactsController *_signupContactController;
    SignUpCameraController   *_signupCameraController;
    SignUpWriteItController  *_signupWriteItController;
    UIViewController         *_parentController;
}

@property (nonatomic, assign)   BOOL                            bHasCameraAccess;
@property (nonatomic, assign)   BOOL                            bHasContactsAccess;


@end

@implementation SignUpManager

- (id)initWithController:(UIViewController *)parentController
{
    self = [super init];
    if (self) {
        _parentController = parentController;
    }
    return self;
}

- (void)startSignup
{
    _bHasCameraAccess = [self haveRequestCamera];
    _bHasContactsAccess = [self haveRequestedContacts];
    [MainViewController showNavBarAnimated:YES];
    [self launchUsernameController];
}

- (void)next
{
    if (_current == _signupUsernameController)
    {
        [self launchPasswordController];
    }
    else if (_current == _signupPasswordController)
    {
        [MainViewController changeNavBar:_signupUsernameController title:@"" side:NAV_BAR_LEFT button:false enable:false action:@selector(back:) fromObject:_signupUsernameController];
        if(!_bHasCameraAccess) {
            [self launchCameraController];
        }
        else if (!_bHasContactsAccess)
        {
            [self launchContactController];
        }
        else
        {
            [self launchWriteItController];
        }
    }
    else if (_current == _signupCameraController)
    {
        if(!_bHasContactsAccess)
        {
            [self launchContactController];
        }
        else
        {
            [self launchWriteItController];
        }
    }
    else if (_current == _signupContactController)
    {
        [self launchWriteItController];
    }
    else if (_current == _signupWriteItController)
    {
        [_signupUsernameController.view removeFromSuperview];
        [_signupUsernameController removeFromParentViewController];
        [_signupPasswordController.view removeFromSuperview];
        [_signupPasswordController removeFromParentViewController];
        [_signupHandleController.view removeFromSuperview];
        [_signupHandleController removeFromParentViewController];
        [_signupCameraController.view removeFromSuperview];
        [_signupCameraController removeFromParentViewController];
        [_signupContactController.view removeFromSuperview];
        [_signupContactController removeFromParentViewController];
        [MainViewController animateOut:_signupWriteItController withBlur:NO complete:^(void) {
            _signupUsernameController = nil;
            _current = nil;
        }];

        [self.delegate signupFinished];
    }
}

- (void)back:(id)sender
{
    if (_current == _signupUsernameController) {
        [MainViewController hideNavBarAnimated:YES];
        [MainViewController animateOut:_signupUsernameController withBlur:YES complete:^(void) {
            _signupUsernameController = nil;
            _current = nil;
            [self.delegate signupAborted];
        }];
    } else if (_current == _signupPasswordController) {
        [MainViewController animateOut:_signupPasswordController withBlur:NO complete:^(void) {
            _signupPasswordController = nil;
            _current = _signupUsernameController;
            _current.view.alpha = 1.0;
            [MainViewController animateFadeIn:_current.view];
        }];
    }
}

- (void)launchUsernameController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupUsernameController = (SignUpUsernameController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpUsernameController"];
    _signupUsernameController.manager = self;
    _current = _signupUsernameController;
    [MainViewController changeNavBarOwner:_signupUsernameController];
    [MainViewController changeNavBarTitle:_signupUsernameController title:NSLocalizedString(@"Sign Up", @"Sign Up title bar text")];
    [MainViewController changeNavBar:_signupUsernameController title:exitButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(back:) fromObject:self];
    [MainViewController animateView:_signupUsernameController withBlur:YES];
}

- (void)launchPasswordController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupPasswordController = (SignUpPasswordController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpPasswordController"];
    _signupPasswordController.manager = self;
    [MainViewController animateFadeOut:_current.view];
    _current = _signupPasswordController;
    [MainViewController animateView:_signupPasswordController withBlur:NO];
}

- (void)launchCameraController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupCameraController = (SignUpCameraController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpCameraController"];
    _signupCameraController.manager = self;
    [MainViewController animateFadeOut:_current.view];
    _current = _signupCameraController;
    [MainViewController animateView:_signupCameraController withBlur:NO];
}

- (void)launchContactController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupContactController = (SignUpContactsController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpContactsController"];
    _signupContactController.manager = self;
    [MainViewController animateFadeOut:_current.view];
    _current = _signupContactController;
    [MainViewController animateView:_signupContactController withBlur:NO];
}

- (void)launchWriteItController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupWriteItController = (SignUpWriteItController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpWriteItController"];
    _signupWriteItController.manager = self;
    [MainViewController animateFadeOut:_current.view];
    _current = _signupWriteItController;
    [MainViewController animateView:_signupWriteItController withBlur:NO];
}

- (BOOL)haveRequestCamera
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized && !FORCE_REQUEST_ACCESS_SCREENS) {
        return YES;
    }
    return NO;
}

- (BOOL)haveRequestedContacts
{
    ABAuthorizationStatus abAuthorizationStatus;

    abAuthorizationStatus = ABAddressBookGetAuthorizationStatus();

    if (abAuthorizationStatus == kABAuthorizationStatusAuthorized && !FORCE_REQUEST_ACCESS_SCREENS) {
        return YES;
    }

    return NO;

}



@end

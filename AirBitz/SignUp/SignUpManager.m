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
        goto usernameCtl;
    }
    else if (_current == _signupPasswordController)
    {
        goto passwordCtl;
    }
    else if (_current == _signupCameraController)
    {
        goto cameraCtl;
    }
    else if (_current == _signupContactController)
    {
        goto contactsCtl;
    }
    else if (_current == _signupWriteItController)
    {
        goto writeItCtl;
    }

    usernameCtl:
    [self launchPasswordController];
    return;

    passwordCtl:
    if (!_bHasCameraAccess)
    {
        [self launchCameraController];
        return;
    }

    cameraCtl:
    if (!_bHasContactsAccess)
    {
        [self launchContactController];
        return;
    }

    contactsCtl:
    [self launchWriteItController];
    return;

    writeItCtl:
    [_signupUsernameController.view removeFromSuperview];
    [_signupPasswordController.view removeFromSuperview];
    [_signupHandleController.view removeFromSuperview];
    [_signupCameraController.view removeFromSuperview];
    [_signupContactController.view removeFromSuperview];
    [MainViewController animateOut:_signupWriteItController.view withBlur:NO complete:^(void) {
        _signupUsernameController = nil;
        _current = nil;
    }];

    [self.delegate signupFinished];

    return;

}

- (void)back:(id)sender
{
    if (_current == _signupUsernameController) {
        [MainViewController hideNavBarAnimated:YES];
        [MainViewController animateOut:_signupUsernameController.view withBlur:YES complete:^(void) {
            _signupUsernameController = nil;
            _current = nil;
            [self.delegate signupAborted];
        }];
    } else if (_current == _signupPasswordController) {
        [MainViewController animateOut:_signupPasswordController.view withBlur:NO complete:^(void) {
            _signupPasswordController = nil;
            _current = _signupUsernameController;
            [_current viewWillAppear:true];
        }];
    }
}

- (void)launchUsernameController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupUsernameController = (SignUpUsernameController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpUsernameController"];
    _signupUsernameController.manager = self;
    _current = _signupUsernameController;
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBarTitle:self title:NSLocalizedString(@"Sign Up", @"Sign Up title bar text")];
    [MainViewController changeNavBar:self title:[Theme Singleton].exitButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(back:) fromObject:self];
    [MainViewController animateView:_signupUsernameController.view withBlur:YES];
}

- (void)launchPasswordController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupPasswordController = (SignUpPasswordController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpPasswordController"];
    _signupPasswordController.manager = self;
    _current = _signupPasswordController;
    [Util animateController:_signupPasswordController parentController:_signupUsernameController];
}

- (void)launchCameraController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupCameraController = (SignUpCameraController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpCameraController"];
    _signupCameraController.manager = self;
    _current = _signupCameraController;
    [Util animateController:_signupCameraController parentController:_parentController];
}

- (void)launchContactController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupContactController = (SignUpContactsController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpContactsController"];
    _signupContactController.manager = self;
    _current = _signupContactController;
    [Util animateController:_signupContactController parentController:_parentController];
}

- (void)launchWriteItController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupWriteItController = (SignUpWriteItController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpWriteItController"];
    _signupWriteItController.manager = self;
    _current = _signupWriteItController;
    [Util animateController:_signupWriteItController parentController:_signupPasswordController];
}

- (BOOL)haveRequestCamera
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        return YES;
    }
    return NO;
}

- (BOOL)haveRequestedContacts
{
    ABAuthorizationStatus abAuthorizationStatus;

    abAuthorizationStatus = ABAddressBookGetAuthorizationStatus();

    if (abAuthorizationStatus == kABAuthorizationStatusAuthorized) {
        return YES;
    }

    return NO;

}



@end

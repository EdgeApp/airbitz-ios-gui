//
//  SignUpManager.m
//  AirBitz
//

#import "SignUpManager.h"
#import "SignUpUsernameController.h"
#import "SignUpPINController.h"
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
#import "LocalSettings.h"

#define FORCE_REQUEST_ACCESS_SCREENS 1

@interface SignUpManager () 
{
    UIViewController         *_current;
    SignUpUsernameController *_signupUsernameController;
    SignUpPINController      *_signupPINController;
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
    _bAllowPINOnly = NO;
    self.strPIN = nil;

    if ([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusAvailable)
    {
        if ([LocalSettings controller].bLocalNotificationsAllowed)
        {
            _bAllowPINOnly = YES;
        }
    }
    
    [MainViewController showNavBarAnimated:YES];
    [self launchUsernameController];

}

- (void)next
{
    if (_current == _signupUsernameController)
    {
        if (_bAllowPINOnly)
        {
            [self launchPINController];
        }
        else
        {
            [self launchPasswordController];
        }
    }
    else if (_current == _signupPINController)
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
    } else if (_current == _signupPINController) {
        [MainViewController animateOut:_signupPINController withBlur:NO complete:^(void) {
            _signupPINController = nil;
            _current = _signupUsernameController;
            _current.view.alpha = 1.0;
            [MainViewController animateFadeIn:_current.view];
        }];
        [MainViewController changeNavBarOwner:_signupUsernameController];
        [MainViewController changeNavBar:_signupUsernameController title:exitButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(back:) fromObject:self];
    } else if (_current == _signupPasswordController) {
        if (self.bAllowPINOnly)
        {
            [MainViewController animateOut:_signupPasswordController withBlur:NO complete:^(void) {
                _signupPasswordController = nil;
                _current = _signupPINController;
                _current.view.alpha = 1.0;
                [MainViewController animateFadeIn:_current.view];
            }];
        }
        else
        {
            [MainViewController animateOut:_signupPasswordController withBlur:NO complete:^(void) {
                _signupPasswordController = nil;
                _current = _signupUsernameController;
                _current.view.alpha = 1.0;
                [MainViewController animateFadeIn:_current.view];
            }];
            [MainViewController changeNavBarOwner:_signupUsernameController];
            [MainViewController changeNavBar:_signupUsernameController title:exitButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(back:) fromObject:self];
        }
    } else if (_current == _signupContactController) {
        [MainViewController animateOut:_signupContactController withBlur:NO complete:^(void) {
            _signupContactController = nil;
            _current = _signupCameraController;
            _current.view.alpha = 1.0;
            [MainViewController animateFadeIn:_current.view];
        }];
        [MainViewController changeNavBarOwner:_signupCameraController];
        [MainViewController changeNavBar:_signupCameraController title:exitButtonText side:NAV_BAR_LEFT button:true enable:false action:@selector(back:) fromObject:self];
    } else if (_current == _signupWriteItController) {
        [MainViewController animateOut:_signupWriteItController withBlur:NO complete:^(void) {
            _signupWriteItController = nil;
            _current = _signupContactController;
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
    [MainViewController changeNavBar:_signupUsernameController title:exitButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
    [MainViewController animateView:_signupUsernameController withBlur:YES];
}

- (void)launchPINController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupPINController = (SignUpPINController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpPINController"];
    _signupPINController.manager = self;
    [MainViewController animateFadeOut:_current.view];
    _current = _signupPINController;
    [MainViewController changeNavBarOwner:_signupPINController];
    [MainViewController changeNavBar:_signupPINController title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(back:) fromObject:self];
    [MainViewController changeNavBar:_signupPINController title:exitButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
    [MainViewController animateView:_signupPINController withBlur:NO];
}

- (void)launchPasswordController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupPasswordController = (SignUpPasswordController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpPasswordController"];
    _signupPasswordController.manager = self;
    [MainViewController animateFadeOut:_current.view];
    _current = _signupPasswordController;
    [MainViewController animateView:_signupPasswordController withBlur:NO];
    [MainViewController changeNavBarOwner:_signupPasswordController];
    [MainViewController changeNavBar:_signupPasswordController title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(back:) fromObject:self];
    [MainViewController changeNavBar:_signupPasswordController title:exitButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
}

- (void)launchCameraController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupCameraController = (SignUpCameraController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpCameraController"];
    _signupCameraController.manager = self;
    [MainViewController animateFadeOut:_current.view];
    _current = _signupCameraController;
    [MainViewController animateView:_signupCameraController withBlur:NO];
    [MainViewController changeNavBarOwner:_signupCameraController];
    [MainViewController changeNavBar:_signupCameraController title:backButtonText side:NAV_BAR_LEFT button:true enable:false action:@selector(back:) fromObject:self];
    [MainViewController changeNavBar:_signupCameraController title:exitButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
}

- (void)launchContactController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupContactController = (SignUpContactsController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpContactsController"];
    _signupContactController.manager = self;
    [MainViewController animateFadeOut:_current.view];
    _current = _signupContactController;
    [MainViewController animateView:_signupContactController withBlur:NO];
    [MainViewController changeNavBarOwner:_signupContactController];
    [MainViewController changeNavBar:_signupContactController title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(back:) fromObject:self];
    [MainViewController changeNavBar:_signupContactController title:exitButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
}

- (void)launchWriteItController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupWriteItController = (SignUpWriteItController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpWriteItController"];
    _signupWriteItController.manager = self;
    [MainViewController animateFadeOut:_current.view];
    _current = _signupWriteItController;
    [MainViewController animateView:_signupWriteItController withBlur:NO];
    [MainViewController changeNavBarOwner:_signupWriteItController];
    [MainViewController changeNavBar:_signupWriteItController title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(back:) fromObject:self];
    [MainViewController changeNavBar:_signupWriteItController title:exitButtonText side:NAV_BAR_RIGHT button:true enable:false action:nil fromObject:self];
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

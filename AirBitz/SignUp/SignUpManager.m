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
#import "Util.h"

@interface SignUpManager () 
{
    UIViewController         *_current;
    SignUpUsernameController *_signupUsernameController;
    SignUpPasswordController *_signupPasswordController;
    SignUpHandleController   *_signupHandleController;
    SignUpContactsController *_signupContactController;
    SignUpCameraController   *_signupCameraController;
    UIViewController         *_parentController;
}

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
    [self launchUsernameController];
}

- (void)next
{
    if (_current == _signupUsernameController) {
        [self launchPasswordController];
    } else if (_current == _signupPasswordController) {
//        [self launchHandleController];
//    } else if (_current == _signupHandleController) {
        [self launchCameraController];
    } else if (_current == _signupCameraController) {
        [self launchContactController];
    } else if (_current == _signupContactController) {
        [_signupUsernameController.view removeFromSuperview];
        [_signupPasswordController.view removeFromSuperview];
        [_signupHandleController.view removeFromSuperview];
        [_signupCameraController.view removeFromSuperview];
        [Util animateOut:_signupContactController parentController:_parentController complete:^(void) {
            _signupUsernameController = nil;
            _current = nil;
        }];
    }
}

- (void)back
{
    if (_current == _signupUsernameController) {
        [Util animateOut:_signupUsernameController parentController:_parentController complete:^(void) {
            _signupUsernameController = nil;
            _current = nil;
        }];
    } else if (_current == _signupPasswordController) {
        [Util animateOut:_signupPasswordController parentController:_parentController complete:^(void) {
            _signupPasswordController = nil;
            _current = _signupUsernameController;
            [_current viewWillAppear:true];
        }];

//    } else if (_current == _signupHandleController) {
//        [Util animateOut:_signupHandleController parentController:_parentController complete:^(void) {
//            _signupHandleController = nil;
//            _current = _signupPasswordController;
//        }];
//    } else if (_current == _signupContactController) {
//        [Util animateOut:_signupContactController parentController:_parentController complete:^(void) {
//            _signupContactController = nil;
//            _current = _signupHandleController;
//        }];
//    } else if (_current == _signupCameraController) {
//        [Util animateOut:_signupCameraController parentController:_parentController complete:^(void) {
//            _signupCameraController = nil;
//            _current = _signupContactController;
//        }];
    }
}

- (void)launchUsernameController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupUsernameController = (SignUpUsernameController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpUsernameController"];
    _signupUsernameController.manager = self;
    _current = _signupUsernameController;
    [Util animateController:_signupUsernameController parentController:_parentController];
}

- (void)launchPasswordController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupPasswordController = (SignUpPasswordController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpPasswordController"];
    _signupPasswordController.manager = self;
    _current = _signupPasswordController;
    [Util animateController:_signupPasswordController parentController:_parentController];
}

- (void)launchHandleController
{
    UIStoryboard *accountCreate = [UIStoryboard storyboardWithName:@"AccountCreate" bundle: nil];
    _signupHandleController = (SignUpHandleController *)[accountCreate instantiateViewControllerWithIdentifier:@"SignUpHandleController"];
    _signupHandleController.manager = self;
    _current = _signupHandleController;
    [Util animateController:_signupHandleController parentController:_parentController];
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

@end

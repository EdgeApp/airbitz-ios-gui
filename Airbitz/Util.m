//
//  Util.m
//  AirBitz
//
//  Created by Adam Harris on 5/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "Util.h"
#import "CommonTypes.h"
#import "AirbitzViewController.h"
#import "Theme.h"

@implementation Util

+ (void)replaceHtmlTags:(NSString **) strContent;
{
    if (*strContent == NULL)
    {
        return;
    }

    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];

    NSString *versionbuild = [NSString stringWithFormat:@"%@ %@", version, build];

    NSMutableArray* searchList  = [[NSMutableArray alloc] initWithObjects:
            @"[[abtag APP_TITLE]]",
            @"[[abtag APP_STORE_LINK]]",
            @"[[abtag PLAY_STORE_LINK]]",
            @"[[abtag APP_DOWNLOAD_LINK]]",
            @"[[abtag APP_HOMEPAGE]]",
            @"[[abtag APP_LOGO_WHITE_LINK]]",
            @"[[abtag APP_DESIGNED_BY]]",
            @"[[abtag APP_COMPANY_LOCATION]]",
            @"[[abtag APP_SUPPORT_EMAIL]]",
            @"[[abtag APP_VERSION]]",
                    nil];

    NSMutableArray* replaceList = [[NSMutableArray alloc] initWithObjects:
            appTitle,
            appStoreLink,
            playStoreLink,
            appDownloadLink,
            appHomepage,
            appLogoWhiteLink,
            appDesignedBy,
            appCompanyLocation,
            supportEmail,
            versionbuild,
                    nil];

    for (int i=0; i<[searchList count];i++)
    {
        *strContent = [*strContent stringByReplacingOccurrencesOfString:[searchList objectAtIndex:i]
                                                             withString:[replaceList objectAtIndex:i]];
    }

}

// resizes a view that is one of the tab bar screens to the approriate size to avoid the toolbar
// display view is if the view has a sub-view that also does not include the top 'name of screen' bar
+ (void)resizeView:(UIView *)theView withDisplayView:(UIView *)theDisplayView
{
//    CGRect frame;
//
//    if (theView)
//    {
//        frame = theView.frame;
//        frame.size.height = SUB_SCREEN_HEIGHT;
//        theView.frame = frame;
//    }
//
//    if (theDisplayView)
//    {
//        frame = theDisplayView.frame;
//        frame.size.height = DISPLAY_AREA_HEIGHT;
//        theDisplayView.frame = frame;
//    }
}

+(CGRect)currentScreenBoundsDependOnOrientation
{

    CGRect screenBounds = [UIScreen mainScreen].bounds ;
    CGFloat width = CGRectGetWidth(screenBounds)  ;
    CGFloat height = CGRectGetHeight(screenBounds) ;
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;

    if(UIInterfaceOrientationIsPortrait(interfaceOrientation)){
        screenBounds.size = CGSizeMake(width, height);
    }else if(UIInterfaceOrientationIsLandscape(interfaceOrientation)){
        screenBounds.size = CGSizeMake(height, width);
    }
    return screenBounds ;
}

// creates the full name from an address book record
+ (NSString *)getNameFromAddressRecord:(ABRecordRef)person
{
    NSString *strFirstName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *strMiddleName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
    NSString *strLastName  = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);

    NSMutableString *strFullName = [[NSMutableString alloc] init];
    if (strFirstName)
    {
        if ([strFirstName length])
        {
            [strFullName appendString:strFirstName];
        }
    }
    if (strMiddleName)
    {
        if ([strMiddleName length])
        {
            if ([strFullName length])
            {
                [strFullName appendString:@" "];
            }
            [strFullName appendString:strMiddleName];
        }
    }
    if (strLastName)
    {
        if ([strLastName length])
        {
            if ([strFullName length])
            {
                [strFullName appendString:@" "];
            }
            [strFullName appendString:strLastName];
        }
    }

    // if we don't have a name yet, try the company
    if ([strFullName length] == 0)
    {
        NSString *strCompanyName  = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonOrganizationProperty);
        if (strCompanyName)
        {
            if ([strCompanyName length])
            {
                [strFullName appendString:strCompanyName];
            }
        }
    }

    return strFullName;
}

+ (void)callTelephoneNumber:(NSString *)telNum
{
    static UIWebView *webView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        webView = [UIWebView new];
    });
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:telNum]]];
}

+ (UIViewController *)animateIn:(NSString *)identifier parentController:(UIViewController *)parent
{
    return [Util animateIn:identifier storyboard:@"Main_iPhone" parentController:parent];
}

+ (UIViewController *)animateIn:(NSString *)identifier storyboard:(NSString *)storyboardName parentController:(UIViewController *)parent
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:identifier];
    return [Util animateController:controller parentController:parent];
}

+ (UIViewController *)animateController:(UIViewController *)controller parentController:(UIViewController *)parent
{
    CGRect frame = parent.view.bounds;
    frame.origin.x = frame.size.width;
    controller.view.frame = frame;
    [parent.view addSubview:controller.view];

    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [UIView animateWithDuration:0.35
                            delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                        animations:^
        {
            controller.view.frame = parent.view.bounds;
        }
                        completion:^(BOOL finished)
        {
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        }];
    return controller;
}

+ (void)animateOut:(UIViewController *)controller parentController:(UIViewController *)parent complete:(void(^)(void))cb
{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
        CGRect frame = parent.view.bounds;
        frame.origin.x = frame.size.width;
        controller.view.frame = frame;
    }
    completion:^(BOOL finished) {
        [controller.view removeFromSuperview];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        cb();
    }];
}

+ (void)animateControllerFadeOut:(UIViewController *)viewController
{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [viewController.view setAlpha:1.0];
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
                         [viewController.view setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         [viewController.view removeFromSuperview];
                         [viewController removeFromParentViewController];
                         [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                     }];
}

+ (void)animateControllerFadeIn:(UIViewController *)viewController
{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [viewController.view setAlpha:0.0];
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
                         [viewController.view setAlpha:1.0];
                     }
                     completion:^(BOOL finished) {
                         [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                     }];
}



+ (void)stylizeTextView:(UITextView *)textField
{
    textField.tintColor = [UIColor whiteColor];
    
    [textField.layer setBackgroundColor:[[[UIColor blackColor] colorWithAlphaComponent:0.3] CGColor]];
    [textField.layer setBorderColor:[[[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.5] colorWithAlphaComponent:1.0] CGColor]];
    [textField.layer setBorderWidth:0.7];
    
    //The rounded corner part, where you specify your view's corner radius:
    textField.layer.cornerRadius = 5;
    textField.clipsToBounds = YES;
    
}

+ (void)stylizeTextField:(UITextField *)textField
{
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    textField.leftView = paddingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.tintColor = [UIColor whiteColor];

    [textField.layer setBackgroundColor:[[[UIColor blackColor] colorWithAlphaComponent:0.3] CGColor]];
    [textField.layer setBorderColor:[[[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.5] colorWithAlphaComponent:1.0] CGColor]];
    [textField.layer setBorderWidth:1.0];
    
    //The rounded corner part, where you specify your view's corner radius:
    textField.layer.cornerRadius = 5;
    textField.clipsToBounds = YES;

}

+ (void)checkPasswordAsync:(NSString *)password withSelector:(SEL)selector controller:(UIViewController *)controller
{
    if (!password || [password length] == 0) {
        if ([[AppDelegate abc] passwordExists]) {
            [controller performSelectorOnMainThread:selector
                withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
        } else {
            [controller performSelectorOnMainThread:selector
                withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
        }
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            BOOL matched = [[AppDelegate abc] passwordOk:password];
            [controller performSelectorOnMainThread:selector
                withObject:[NSNumber numberWithBool:matched] waitUntilDone:NO];
        });
    }
}

+ (NSString *)urlencode:(NSString *)url
{
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    url = [url stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
    url = [url stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
    return [url stringByReplacingOccurrencesOfString:@"?" withString:@"%3F"];
}

+ (NSMutableDictionary *)getUrlParameters:(NSURL *)url
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *param in [[url query] componentsSeparatedByString:@"&"]) {
        NSArray *split = [param componentsSeparatedByString:@"="];
        if ([split count] > 1) {
            [params setValue:[split[1] stringByRemovingPercentEncoding] forKey:split[0]];
        }
    }
    return params;
}

+ (BOOL)isValidCategory:(NSString *)category
{
    return [category hasPrefix:NSLocalizedString(@"Expense", nil)]
            || [category hasPrefix:NSLocalizedString(@"Income", nil)]
            || [category hasPrefix:NSLocalizedString(@"Transfer", nil)]
            || [category hasPrefix:NSLocalizedString(@"Exchange", nil)];
}

+ (NSArray *)insertSubviewControllerWithConstraints:(AirbitzViewController *)parentViewController child:(AirbitzViewController *)childViewController belowSubView:(UIView *)belowView
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];

    [childViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    UIView *childView = childViewController.view;
    UIView *parentView = parentViewController.view;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(childView, parentView);
    NSAssert(viewsDictionary, @"viewsDictionary NULL");
    NSAssert(parentView, @"parent NULL");
    NSAssert(belowView, @"belowView NULL");

    [childViewController willMoveToParentViewController:parentViewController];
    [parentView insertSubview:childView belowSubview:belowView];
    [parentViewController addChildViewController:childViewController];
    [childViewController didMoveToParentViewController:parentViewController];

    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[childView]" options:0 metrics:nil views:viewsDictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[childView]" options:0 metrics:nil views:viewsDictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[parentView(==childView)]" options:0 metrics:nil views:viewsDictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[parentView(==childView)]" options:0 metrics:nil views:viewsDictionary]];

    [parentView addConstraints:constraints];
    [parentView layoutIfNeeded];
    childViewController.leftConstraint = constraints[0];

    return constraints;

}

+ (NSArray *)insertSubviewControllerWithConstraints:(AirbitzViewController *)parentViewController child:(AirbitzViewController *)childViewController aboveSubView:(UIView *)aboveView
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];

    [childViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    UIView *childView = childViewController.view;
    UIView *parentView = parentViewController.view;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(childView, parentView);
    NSAssert(viewsDictionary, @"viewsDictionary NULL");
    NSAssert(parentView, @"parent NULL");
    NSAssert(aboveView, @"aboveView NULL");

    [childViewController willMoveToParentViewController:parentViewController];
    [parentView insertSubview:childView aboveSubview:aboveView];
    [parentViewController addChildViewController:childViewController];
    [childViewController didMoveToParentViewController:parentViewController];

    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[childView]" options:0 metrics:nil views:viewsDictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[childView]" options:0 metrics:nil views:viewsDictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[parentView(==childView)]" options:0 metrics:nil views:viewsDictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[parentView(==childView)]" options:0 metrics:nil views:viewsDictionary]];

    [parentView addConstraints:constraints];
    [parentView layoutIfNeeded];
    childViewController.leftConstraint = constraints[0];

    return constraints;

}

+ (NSArray *)addSubviewControllerWithConstraints:(AirbitzViewController *)parentViewController child:(AirbitzViewController *)childViewController
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];

    [childViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    UIView *childView = childViewController.view;
    UIView *parentView = parentViewController.view;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(childView, parentView);
    NSAssert(viewsDictionary, @"viewsDictionary NULL");
    NSAssert(parentView, @"parent NULL");

    [childViewController willMoveToParentViewController:parentViewController];
    [parentView addSubview:childView];
    [parentViewController addChildViewController:childViewController];
    [childViewController didMoveToParentViewController:parentViewController];

    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[childView]" options:0 metrics:nil views:viewsDictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[childView]" options:0 metrics:nil views:viewsDictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[parentView(==childView)]" options:0 metrics:nil views:viewsDictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[parentView(==childView)]" options:0 metrics:nil views:viewsDictionary]];

    [parentView addConstraints:constraints];
    [parentView layoutIfNeeded];
    childViewController.leftConstraint = constraints[0];

    return constraints;

}

+ (NSArray *)addSubviewWithConstraints:(UIView *)parentView child:(UIView *)childView
{
    NSMutableArray *constraints = [[NSMutableArray alloc] init];

    [childView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(childView, parentView);
    NSAssert(viewsDictionary, @"viewsDictionary NULL");
    NSAssert(parentView, @"parent NULL");

    [parentView addSubview:childView];

    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[childView]" options:0 metrics:nil views:viewsDictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[childView]" options:0 metrics:nil views:viewsDictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[parentView(==childView)]" options:0 metrics:nil views:viewsDictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[parentView(==childView)]" options:0 metrics:nil views:viewsDictionary]];

    [parentView addConstraints:constraints];
    [parentView layoutIfNeeded];

    return constraints;

}

@end


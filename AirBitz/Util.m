//
//  Util.m
//  AirBitz
//
//  Created by Adam Harris on 5/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "Util.h"
#import "ABC.h"
#import "CommonTypes.h"

@implementation Util

+ (NSString *)errorMap:(const tABC_Error *)pError
{
    switch (pError->code)
    {
        case ABC_CC_AccountAlreadyExists:
            return NSLocalizedString(@"This account already exists.", nil);
        case ABC_CC_AccountDoesNotExist:
            return NSLocalizedString(@"We were unable to find your account. Be sure your username is correct.", nil);
        case ABC_CC_BadPassword:
            return NSLocalizedString(@"Invalid user name or password", nil);
        case ABC_CC_WalletAlreadyExists:
            return NSLocalizedString(@"Wallet already exists.", nil);
        case ABC_CC_InvalidWalletID:
            return NSLocalizedString(@"Wallet does not exist.", nil);
        case ABC_CC_URLError:
        case ABC_CC_ServerError:
            return NSLocalizedString(@"Unable to connect to Airbitz server. Please try again later.", nil);
        case ABC_CC_NoRecoveryQuestions:
            return NSLocalizedString(@"No recovery questions are available for this user", nil);
        case ABC_CC_NotSupported:
            return NSLocalizedString(@"This operation is not supported.", nil);
        case ABC_CC_InsufficientFunds:
            return NSLocalizedString(@"Insufficient funds", nil);
        case ABC_CC_Synchronizing:
            return NSLocalizedString(@"Synchronizing with the network.", nil);
        case ABC_CC_NonNumericPin:
            return NSLocalizedString(@"PIN must be a numeric value.", nil);
        case ABC_CC_InvalidPinWait:
        {
            NSString *description = [NSString stringWithUTF8String:pError->szDescription];
            if ([@"0" isEqualToString:description]) {
                return NSLocalizedString(@"Invalid PIN.", nil);
            } else {
                return [NSString stringWithFormat:
                            NSLocalizedString(@"Too many failed login attempts. Please try again in %@ seconds.", nil),
                            description];
            }
        }
        case ABC_CC_Error:
        case ABC_CC_NULLPtr:
        case ABC_CC_NoAvailAccountSpace:
        case ABC_CC_DirReadError:
        case ABC_CC_FileOpenError:
        case ABC_CC_FileReadError:
        case ABC_CC_FileWriteError:
        case ABC_CC_FileDoesNotExist:
        case ABC_CC_UnknownCryptoType:
        case ABC_CC_InvalidCryptoType:
        case ABC_CC_DecryptError:
        case ABC_CC_DecryptFailure:
        case ABC_CC_EncryptError:
        case ABC_CC_ScryptError:
        case ABC_CC_SysError:
        case ABC_CC_NotInitialized:
        case ABC_CC_Reinitialization:
        case ABC_CC_JSONError:
        case ABC_CC_MutexError:
        case ABC_CC_NoTransaction:
        case ABC_CC_ParseError:
        case ABC_CC_NoRequest:
        case ABC_CC_NoAvailableAddress:
        default:
            return NSLocalizedString(@"An error has occurred.", nil);
    }
}

+ (void)printABC_Error:(const tABC_Error *)pError
{
    if (pError)
    {
        if (pError->code != ABC_CC_Ok)
        {
            printf("Code: %d, Desc: %s, Func: %s, File: %s, Line: %d\n",
                   pError->code,
                   pError->szDescription,
                   pError->szSourceFunc,
                   pError->szSourceFile,
                   pError->nSourceLine
                   );
        }
        if (pError->code == ABC_CC_DecryptError
                    || pError->code == ABC_CC_DecryptFailure)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MAIN_RESET object:self];
        }
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


+ (void)freeStringArray:(char **)aszStrings count:(unsigned int)count
{
    if ((aszStrings != NULL) && (count > 0))
    {
        for (int i = 0; i < count; i++)
        {
            free(aszStrings[i]);
        }
        free(aszStrings);
    }
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
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    UIViewController *controller = [mainStoryboard instantiateViewControllerWithIdentifier:identifier];
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

+ (UIImage *)dataToImage:(const unsigned char *)data withWidth:(int)width andHeight:(int)height
{
	//converts raw monochrome bitmap data (each byte is a 1 or a 0 representing a pixel) into a UIImage
	char *pixels = malloc(4 * width * width);
	char *buf = pixels;
		
	for (int y = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++)
		{
			if (data[(y * width) + x] & 0x1)
			{
				//printf("%c", '*');
				*buf++ = 0;
				*buf++ = 0;
				*buf++ = 0;
				*buf++ = 255;
			}
			else
			{
				printf(" ");
				*buf++ = 255;
				*buf++ = 255;
				*buf++ = 255;
				*buf++ = 255;
			}
		}
		//printf("\n");
	}
	
	CGContextRef ctx;
	CGImageRef imageRef;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	ctx = CGBitmapContextCreate(pixels,
								(float)width,
								(float)height,
								8,
								width * 4,
								colorSpace,
								(CGBitmapInfo)kCGImageAlphaPremultipliedLast ); //documentation says this is OK
	CGColorSpaceRelease(colorSpace);
	imageRef = CGBitmapContextCreateImage (ctx);
	UIImage* rawImage = [UIImage imageWithCGImage:imageRef];
	
	CGContextRelease(ctx);
	CGImageRelease(imageRef);
	free(pixels);
	return rawImage;
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
        if ([CoreBridge passwordExists]) {
            [controller performSelectorOnMainThread:selector
                withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
        } else {
            [controller performSelectorOnMainThread:selector
                withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
        }
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            BOOL matched = [CoreBridge passwordOk:password];
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

@end

@implementation NSString (reverse)
 
+ (NSString *)safeStringWithUTF8String:(const char *)bytes;
{
    if (bytes) {
        return [NSString stringWithUTF8String:bytes];
    } else {
        return @"";
    }
}
 
@end

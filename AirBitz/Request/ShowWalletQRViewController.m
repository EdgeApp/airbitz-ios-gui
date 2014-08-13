//
//  ShowWalletQRViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "DDData.h"
#import "ShowWalletQRViewController.h"
#import "Notifications.h"
#import "ABC.h"
#import "Util.h"
#import "User.h"
#import "CommonTypes.h"
#import "CoreBridge.h"
#import "InfoView.h"

#define QR_CODE_TEMP_FILENAME @"qr_request.png"

#define QR_ATTACHMENT_WIDTH 100

typedef enum eAddressPickerType
{
    AddressPickerType_SMS,
    AddressPickerType_EMail
} tAddressPickerType;

@interface ShowWalletQRViewController () <ABPeoplePickerNavigationControllerDelegate, MFMessageComposeViewControllerDelegate,
                                          UIAlertViewDelegate, MFMailComposeViewControllerDelegate>
{
    tAddressPickerType          _addressPickerType;
}

@property (nonatomic, weak) IBOutlet UIImageView    *qrCodeImageView;
@property (nonatomic, weak) IBOutlet UILabel        *statusLabel;
@property (nonatomic, weak) IBOutlet UILabel        *amountLabel;
@property (nonatomic, weak) IBOutlet UILabel        *addressLabel;
@property (weak, nonatomic) IBOutlet UIView         *viewQRCodeFrame;
@property (weak, nonatomic) IBOutlet UIImageView    *imageBottomFrame;
@property (weak, nonatomic) IBOutlet UIButton       *buttonCancel;
@property (weak, nonatomic) IBOutlet UIButton       *buttonCopyAddress;

@property (nonatomic, copy)   NSString *strFullName;
@property (nonatomic, copy)   NSString *strPhoneNumber;
@property (nonatomic, copy)   NSString *strEMail;

@end

@implementation ShowWalletQRViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.

    [self updateDisplayLayout];

	self.qrCodeImageView.layer.magnificationFilter = kCAFilterNearest;
	self.qrCodeImageView.image = self.qrCodeImage;
	self.statusLabel.text = self.statusString;
	self.addressLabel.text = self.addressString;
    self.amountLabel.text = [CoreBridge formatSatoshi: self.amountSatoshi];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:NO]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action Methods

- (IBAction)CopyAddress
{
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	[pb setString:self.addressLabel.text];
}

- (IBAction)Cancel
{
	[self Back];
}

- (IBAction)Back
{
	self.view.alpha = 1.0;
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		self.view.alpha = 0.0;
	 }
                    completion:^(BOOL finished)
    {
        [self.delegate ShowWalletQRViewControllerDone:self];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SHOW_TAB_BAR object:[NSNumber numberWithBool:YES]];
}

- (IBAction)Info
{
	[self.view endEditing:YES];
    [InfoView CreateWithHTML:@"infoRequestQR" forView:self.view];

}

- (IBAction)email
{
    self.strFullName = @"";
    self.strEMail = @"";
    _addressPickerType = AddressPickerType_EMail;

    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Send Email", nil)
                          message:NSLocalizedString(@"Select Email from Contact List?", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"Yes", nil)
                          otherButtonTitles:NSLocalizedString(@"No, I'll type it manually", nil), nil];
    [alert show];
}

- (IBAction)SMS
{
    self.strPhoneNumber = @"";
    self.strFullName = @"";
    _addressPickerType = AddressPickerType_SMS;

    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Send SMS", nil)
                          message:NSLocalizedString(@"Select from Contact List?", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"Yes, Contacts", nil)
                          otherButtonTitles:NSLocalizedString(@"No, I'll type in manually", nil), nil];
    [alert show];
}


#pragma mark - Misc Methods

- (void)updateDisplayLayout
{
    // if we are on a smaller screen
    if (!IS_IPHONE5)
    {
        // be prepared! lots and lots of magic numbers here to jam the controls to fit on a small screen

        CGRect frame;

        frame = self.imageBottomFrame.frame;
        frame.size.height = 135.0;
        self.imageBottomFrame.frame = frame;

        self.buttonCancel.hidden = YES;
        /*
         
        frame = self.viewQRCodeFrame.frame;
        frame.origin.y = 67.0;
        self.viewQRCodeFrame.frame = frame;

        frame = self.qrCodeImageView.frame;
        frame.origin.y = self.viewQRCodeFrame.frame.origin.y + 8.0;
        self.qrCodeImageView.frame = frame;

        frame = self.imageBottomFrame.frame;
        frame.origin.y = self.viewQRCodeFrame.frame.origin.y + self.viewQRCodeFrame.frame.size.height + 2.0;
        frame.size.height = 165.0;
        self.imageBottomFrame.frame = frame;

        frame = self.statusLabel.frame;
        frame.origin.y = self.imageBottomFrame.frame.origin.y + 2.0;
        self.statusLabel.frame = frame;

        frame = self.amountLabel.frame;
        frame.origin.y = self.statusLabel.frame.origin.y + self.statusLabel.frame.size.height + 3.0;
        self.amountLabel.frame = frame;

        frame = self.addressLabel.frame;
        frame.origin.y = self.amountLabel.frame.origin.y + self.amountLabel.frame.size.height + 3.0;
        self.addressLabel.frame = frame;

        frame = self.buttonCancel.frame;
        frame.origin.y = self.addressLabel.frame.origin.y + self.addressLabel.frame.size.height + 3.0;
        self.buttonCancel.frame = frame;

        frame = self.buttonCopyAddress.frame;
        frame.origin.y = self.buttonCancel.frame.origin.y + self.buttonCancel.frame.size.height + 3.0;
        self.buttonCopyAddress.frame = frame;
*/
    }
}

- (void)sendEMail
{
    //NSLog(@"sendEMail to: %@ / %@", self.strFullName, self.strEMail);

    // if mail is available
    if ([MFMailComposeViewController canSendMail])
    {
        NSMutableString *strBody = [[NSMutableString alloc] init];
        NSString *amount = [CoreBridge formatSatoshi:self.amountSatoshi
                                          withSymbol:false
                                    overrideDecimals:8];
        // For sending requests, use 8 decimal places which is a BTC (not mBTC or uBTC amount)

        NSString *tempURI = self.uriString;

        NSRange tempRange = [tempURI rangeOfString:@"bitcoin:"];

        if (tempRange.location != NSNotFound) 
        {
            tempURI = [tempURI stringByReplacingCharactersInRange:tempRange withString:@"bitcoin://"];
        }

        [strBody appendString:@"<html><body>\n"];

        if ([User Singleton].bNameOnPayments)
        {
            [strBody appendString:NSLocalizedString(@"Bitcoin Request from ", nil)];
            [strBody appendFormat:@"%@", [User Singleton].fullName];
        }
        else
        {
            [strBody appendString:NSLocalizedString(@"Bitcoin Request", nil)];
        }
        [strBody appendString:@"<br>\n"];
        [strBody appendString:@"<br>\n"];
        [strBody appendString:NSLocalizedString(@"Please scan QR code or click on the link below to pay<br>\n",nil)];
        [strBody appendString:@"<br>\n"];
        [strBody appendFormat:@"<a href=\"%@\">", tempURI];
        [strBody appendString:NSLocalizedString(@"Click to Pay",nil)];
        [strBody appendFormat:@"</a>"];
        [strBody appendString:@"<br>\n"];
        [strBody appendString:@"<br>\n"];
        [strBody appendString:NSLocalizedString(@"Address: ",nil)];
        [strBody appendFormat:@"%@", self.addressString];
        [strBody appendString:@"<br>\n"];
        [strBody appendString:@"<br>\n"];
        [strBody appendString:NSLocalizedString(@"Amount: ",nil)];
        [strBody appendFormat:@"%@", amount];
        [strBody appendString:@"<br><br>\n"];

        UIImage *imageAttachment = [self imageWithImage:self.qrCodeImage scaledToSize:CGSizeMake(QR_ATTACHMENT_WIDTH, QR_ATTACHMENT_WIDTH)];
        NSData *imageData = [NSData dataWithData:UIImageJPEGRepresentation(imageAttachment, 1.0)];
        NSString *base64String = [imageData base64Encoded];
        [strBody appendString:[NSString stringWithFormat:@"<p><b><img alt='QRCode' title='QRCode' src='data:image/jpeg;base64,%@' /></b></p>", base64String]];

        [strBody appendString:@"</body></html>\n"];

        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];

        if ([self.strEMail length])
        {
            [mailComposer setToRecipients:[NSArray arrayWithObject:self.strEMail]];
        }

        [mailComposer setSubject:NSLocalizedString(@"Bitcoin Request", nil)];

        [mailComposer setMessageBody:strBody isHTML:YES];

        mailComposer.mailComposeDelegate = self;

        [self presentViewController:mailComposer animated:YES completion:nil];
        [self finalizeRequest:@"Email"];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Can't send e-mail"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)sendSMS
{
    //NSLog(@"sendSMS to: %@ / %@", self.strFullName, self.strPhoneNumber);

    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
	if ([MFMessageComposeViewController canSendText] && [MFMessageComposeViewController canSendAttachments])
	{
        NSMutableString *strBody = [[NSMutableString alloc] init];
        NSString *amount = [CoreBridge formatSatoshi:self.amountSatoshi
                                          withSymbol:false
                                    overrideDecimals:8];
        // For sending requests, use 8 decimal places which is a BTC (not mBTC or uBTC amount)

        NSString *tempURI = self.uriString;

        NSRange tempRange = [tempURI rangeOfString:@"bitcoin:"];

        if (tempRange.location != NSNotFound)
        {
            tempURI = [tempURI stringByReplacingCharactersInRange:tempRange withString:@"bitcoin://"];
        }
        
        if ([User Singleton].bNameOnPayments)
        {
            [strBody appendString:NSLocalizedString(@"Bitcoin Request from ", nil)];
            [strBody appendFormat:@"%@", [User Singleton].fullName];
        }
        else
        {
            [strBody appendString:NSLocalizedString(@"Bitcoin Request", nil)];
        }

        [strBody appendString:@"\n"];
        [strBody appendString:@"\n"];
        [strBody appendString:NSLocalizedString(@"Please scan QR code or click on the link below to pay\n",nil)];
        [strBody appendString:@"\n"];
        [strBody appendFormat:@"%@", tempURI];
        [strBody appendString:@"\n"];
        [strBody appendString:@"\n"];
        [strBody appendString:NSLocalizedString(@"Address: ",nil)];
        [strBody appendFormat:@"%@", self.addressString];
        [strBody appendString:@"\n"];
        [strBody appendString:@"\n"];
        [strBody appendString:NSLocalizedString(@"Amount: ",nil)];
        [strBody appendFormat:@"%@", amount];
        [strBody appendString:@"\n"];
        [strBody appendString:@"\n"];

        // create the attachment
        UIImage *imageAttachment = [self imageWithImage:self.qrCodeImage scaledToSize:CGSizeMake(QR_ATTACHMENT_WIDTH, QR_ATTACHMENT_WIDTH)];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:QR_CODE_TEMP_FILENAME];
        BOOL bAttached = [controller addAttachmentData:UIImagePNGRepresentation(imageAttachment) typeIdentifier:(NSString*)kUTTypePNG filename:filePath];
        if (!bAttached)
        {
            NSLog(@"Could not attach qr code");
        }

		controller.body = strBody;

        if (self.strPhoneNumber)
        {
            if ([self.strPhoneNumber length] != 0)
            {
                controller.recipients = @[self.strPhoneNumber];
            }
        }

		controller.messageComposeDelegate = self;

        [self presentViewController:controller animated:YES completion:nil];
        [self finalizeRequest:@"SMS"];
	}
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationNone);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - Address Book delegates

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [[peoplePicker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{

    self.strFullName = [Util getNameFromAddressRecord:person];

    if (_addressPickerType == AddressPickerType_SMS)
    {
        if (property == kABPersonPhoneProperty)
        {
            ABMultiValueRef multiPhones = ABRecordCopyValue(person, kABPersonPhoneProperty);
            for (CFIndex i = 0; i < ABMultiValueGetCount(multiPhones); i++)
            {
                if (identifier == ABMultiValueGetIdentifierAtIndex(multiPhones, i))
                {
                    NSString *strPhoneNumber = (__bridge_transfer NSString *) ABMultiValueCopyValueAtIndex(multiPhones, i);
                    self.strPhoneNumber = strPhoneNumber;
                    break;
                }
            }
            CFRelease(multiPhones);
        }

        [[peoplePicker presentingViewController] dismissViewControllerAnimated:YES completion:^{
            [self sendSMS];
        }];
    }
    else if (_addressPickerType == AddressPickerType_EMail)
    {
        if (property == kABPersonEmailProperty)
        {
            ABMultiValueRef multiEMails = ABRecordCopyValue(person, kABPersonEmailProperty);
            for (CFIndex i = 0; i < ABMultiValueGetCount(multiEMails); i++)
            {
                if (identifier == ABMultiValueGetIdentifierAtIndex(multiEMails, i))
                {
                    NSString *strEMail = (__bridge_transfer NSString *) ABMultiValueCopyValueAtIndex(multiEMails, i);
                    self.strEMail = strEMail;
                    break;
                }
            }
            CFRelease(multiEMails);
        }

        [[peoplePicker presentingViewController] dismissViewControllerAnimated:YES completion:^{
            [self sendEMail];
        }];
    }
    return NO;
}

- (void)finalizeRequest:(NSString *)type
{
    if (_strFullName) {
        _txDetails.szName = (char *)[_strFullName UTF8String];
    } else if (_strEMail) {
        _txDetails.szName = (char *)[_strEMail UTF8String];
    } else if (_strPhoneNumber) {
        _txDetails.szName = (char *)[_strPhoneNumber UTF8String];
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSDate *now = [NSDate date];

    NSMutableString *notes = [[NSMutableString alloc] init];
    [notes appendFormat:NSLocalizedString(@"%@ / %@ requested via %@ on %@.", nil),
                        [CoreBridge formatSatoshi:_txDetails.amountSatoshi],
                        [CoreBridge formatCurrency:_txDetails.amountCurrency withCurrencyNum:_currencyNum],
                        type,
                        [dateFormatter stringFromDate:now]];
    _txDetails.szNotes = (char *)[notes UTF8String];
    tABC_Error Error;
    // Update the Details
    if (ABC_CC_Ok != ABC_ModifyReceiveRequest([[User Singleton].name UTF8String],
                                              [[User Singleton].password UTF8String],
                                              [_walletUUID UTF8String],
                                              [_requestID UTF8String],
                                              &_txDetails,
                                              &Error))
    {
        [Util printABC_Error:&Error];
    }
    // Finalize this request so it isn't used elsewhere
    if (ABC_CC_Ok != ABC_FinalizeReceiveRequest([[User Singleton].name UTF8String],
                                                [[User Singleton].password UTF8String],
                                                [_walletUUID UTF8String],
                                                [_requestID UTF8String],
                                                &Error))
    {
        [Util printABC_Error:&Error];
    }
}

#pragma mark - MFMessageComposeViewController delegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
	switch (result)
    {
		case MessageComposeResultCancelled:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AirBitz"
                                                            message:@"SMS cancelled"
														   delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
			[alert show];
        }
			break;

		case MessageComposeResultFailed:
        {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AirBitz"
                                                            message:@"Error sending SMS"
														   delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
			[alert show];
        }
			break;

		case MessageComposeResultSent:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AirBitz"
                                                            message:@"SMS sent"
														   delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
			[alert show];
        }
			break;

		default:
			break;
	}

    [[controller presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Mail Compose Delegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    NSString *strTitle = NSLocalizedString(@"AirBitz", nil);
    NSString *strMsg = nil;

	switch (result)
    {
		case MFMailComposeResultCancelled:
            strMsg = NSLocalizedString(@"Email cancelled", nil);
			break;

		case MFMailComposeResultSaved:
            strMsg = NSLocalizedString(@"Email saved to send later", nil);
			break;

		case MFMailComposeResultSent:
            strMsg = NSLocalizedString(@"Email sent", nil);
			break;

		case MFMailComposeResultFailed:
		{
            strTitle = NSLocalizedString(@"Error sending Email", nil);
            strMsg = [error localizedDescription];
			break;
		}
		default:
			break;
	}

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle
                                                    message:strMsg
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];

    [[controller presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIAlertView delegates

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	// we only use the alert for selecting from contacts or not

    // if they wanted to select from contacts
    if (buttonIndex == 0)
    {
        [self performSelector:@selector(showAddressPicker) withObject:nil afterDelay:0.0];
    }
    else if (_addressPickerType == AddressPickerType_SMS)
    {
        [self performSelector:@selector(sendSMS) withObject:nil afterDelay:0.0];
    }
    else if (_addressPickerType == AddressPickerType_EMail)
    {
        [self performSelector:@selector(sendEMail) withObject:nil afterDelay:0.0];
    }
}


- (void)showAddressPicker
{
	[self.view endEditing:YES];

    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];

    picker.peoplePickerDelegate = self;

    if (_addressPickerType == AddressPickerType_SMS)
    {
        picker.displayedProperties = @[[NSNumber numberWithInt:kABPersonPhoneProperty]];
    }
    else
    {
        picker.displayedProperties = @[[NSNumber numberWithInt:kABPersonEmailProperty]];
    }

    [self presentViewController:picker animated:YES completion:nil];
    //[self.view.window.rootViewController presentViewController:picker animated:YES completion:nil];
}


@end

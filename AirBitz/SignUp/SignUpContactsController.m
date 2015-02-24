//
//  SignUpContactsController.m
//  AirBitz
//

#import <AddressBookUI/AddressBookUI.h>
#import "SignUpContactsController.h"

@implementation SignUpContactsController

- (IBAction)next
{
    if ([self haveRequestedContacts]) {
        [self.manager next];
    } else {
        [self requestContactAccess];
    }
}

- (BOOL)haveRequestedContacts
{
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        return NO;
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        return YES;
    } else {
        return YES;
    }
}

- (void)requestContactAccess
{
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
        if (granted) {
            // Update yay!!!
        } else {
            // Update bummer
        }
    });
}


@end

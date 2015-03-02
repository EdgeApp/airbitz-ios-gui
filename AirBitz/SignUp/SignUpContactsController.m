//
//  SignUpContactsController.m
//  AirBitz
//

#import <AddressBookUI/AddressBookUI.h>
#import "SignUpContactsController.h"

@implementation SignUpContactsController


- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self haveRequestedContacts]) {
        [self.manager next];
    }

}


- (IBAction)next
{
    [self requestContactAccess];

    [self.manager next];
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

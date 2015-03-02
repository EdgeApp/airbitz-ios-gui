//
//  SignUpContactsController.m
//  AirBitz
//

#import <AddressBookUI/AddressBookUI.h>
#import "SignUpContactsController.h"

@implementation SignUpContactsController


- (IBAction)next
{
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
        if (granted) {
            // Update yay!!!
        } else {
            // Update bummer
        }
    });

    [self.manager next];
}

- (void)requestContactAccess
{
}


@end

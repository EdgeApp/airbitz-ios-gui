//
//  SignUpContactsController.m
//  AirBitz
//

#import <AddressBookUI/AddressBookUI.h>
#import "SignUpContactsController.h"
#import "Util.h"
#import "Theme.h"

@interface SignUpContactsController ()
{
}
@property (weak, nonatomic) IBOutlet UILabel *infoText;

@end

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

- (void)viewDidLoad
{
    NSString *tempText = signupContactsText;
    [Util replaceHtmlTags:&tempText];
    self.infoText.text = tempText;
}


@end

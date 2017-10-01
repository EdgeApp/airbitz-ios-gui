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
@property (weak, nonatomic) IBOutlet UILabel *titleText;
@property (weak, nonatomic) IBOutlet UILabel *descriptionText;
@property (weak, nonatomic) IBOutlet UILabel *infoText;
@property (weak, nonatomic) IBOutlet UIButton *buttonNext;

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
    
    [self setThemeValues];
}

- (void)setThemeValues {
    self.titleText.font = [UIFont fontWithName:[Theme Singleton].appFont size:17.0];
    self.titleText.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.descriptionText.font = [UIFont fontWithName:[Theme Singleton].appFont size:16.0];
    self.descriptionText.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.infoText.font = [UIFont fontWithName:[Theme Singleton].appFont size:15.0];
    self.infoText.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.buttonNext.titleLabel.font = [UIFont fontWithName:[Theme Singleton].appFont size:15.0];
    self.buttonNext.backgroundColor = [Theme Singleton].colorFirstAccent;
}

@end

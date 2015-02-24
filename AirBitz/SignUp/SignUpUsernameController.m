//
//  SignUpUsernameController.m
//  AirBitz
//

#import "SignUpUsernameController.h"
#import "MinCharTextField.h"
#import "ABC.h"
#import "Util.h"

@interface SignUpUsernameController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet MinCharTextField *usernameField;

@end

@implementation SignUpUsernameController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	_usernameField.delegate = self;
    _usernameField.minimumCharacters = ABC_MIN_USERNAME_LENGTH;
    if (self.strUserName) {
        _usernameField.text = self.strUserName;
    }
}

#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == _usernameField) {
        [textField setSelectedTextRange:[textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.endOfDocument]];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return NO;
}

@end

//
//  SignUpHandleController.m
//  AirBitz
//

#import "SignUpHandleController.h"
#import "SignUpManager.h"
#import "StylizedTextField.h"

@interface SignUpHandleController ()

@property (nonatomic, weak) IBOutlet StylizedTextField *nicknameField;
@property (nonatomic, weak) IBOutlet StylizedTextField *firstNameField;
@property (nonatomic, weak) IBOutlet StylizedTextField *lastNameField;

@end

@implementation SignUpHandleController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

@end

//
//  SignUpPasswordController.m
//  AirBitz
//

#import "SignUpPasswordController.h"
#import "SignUpHandleController.h"
#import "MinCharTextField.h"
#import "ABC.h"
#import "Util.h"

@interface SignUpPasswordController ()
{
    SignUpHandleController  *_signupHandleController;
}

@property (nonatomic, weak) IBOutlet MinCharTextField *passwordField;
@property (nonatomic, weak) IBOutlet MinCharTextField *passwordConfirmField;
@property (nonatomic, weak) IBOutlet MinCharTextField *pinField;

@end

@implementation SignUpPasswordController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

@end

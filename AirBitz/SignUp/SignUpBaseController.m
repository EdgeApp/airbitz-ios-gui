//
//  SignUpBaseController.m
//  AirBitz
//

#import "SignUpBaseController.h"
#import "ABC.h"

@interface SignUpBaseController ()
@end

@implementation SignUpBaseController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (IBAction)next
{
    [self.manager next];
}

- (IBAction)back 
{
    [self.manager back];
}

@end

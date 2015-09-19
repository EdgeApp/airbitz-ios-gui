//
//  SignUpBaseContr.h
//  AirBitz
//

#import <UIKit/UIKit.h>
#import "SignUpManager.h"
#import "AirbitzViewController.h"

@interface SignUpBaseController : AirbitzViewController

@property (assign) SignUpManager *manager;

- (void)next;

@end

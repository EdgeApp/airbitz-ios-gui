//
//  SignUpBaseContr.h
//  AirBitz
//

#import <UIKit/UIKit.h>
#import "SignUpManager.h"

@interface SignUpBaseController : UIViewController

@property (assign) SignUpManager *manager;

- (void)next;

- (void)back;
@end

//
//  AddressRequestController.h
//  AirBitz
//

#import <UIKit/UIKit.h>

@protocol AddressRequestControllerDelegate;

@interface AddressRequestController : UIViewController

@property (assign) id<AddressRequestControllerDelegate> delegate;
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) NSURL *successUrl;
@property (strong, nonatomic) NSURL *errorUrl;
@property (strong, nonatomic) NSURL *cancelUrl;

@end


@protocol AddressRequestControllerDelegate <NSObject>

@required
-(void)AddressRequestControllerDone:(AddressRequestController *)vc;
@end

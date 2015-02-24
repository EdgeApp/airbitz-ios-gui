//
//  SignUpManager.h
//  AirBitz
//

#import <UIKit/UIKit.h>

@protocol SignUpManagerDelegate;

@interface SignUpManager : NSObject

@property (assign) id<SignUpManagerDelegate> delegate;
@property (nonatomic, copy)   NSString       *strUserName;

- (id)initWithController:(UIViewController *)parentController;
- (void)startSignup;
- (void)next;
- (void)back;

@end

@protocol SignUpManagerDelegate <NSObject>

@required

-(void)signupAborted;
-(void)signupFinished;

@end

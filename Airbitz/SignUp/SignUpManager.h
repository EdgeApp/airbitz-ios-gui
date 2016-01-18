//
//  SignUpManager.h
//  AirBitz
//

#import <UIKit/UIKit.h>

@protocol SignUpManagerDelegate;

@interface SignUpManager : NSObject

@property (assign) id<SignUpManagerDelegate> delegate;
@property (nonatomic, copy)     NSString                        *strInUserName;
@property (nonatomic, copy)     NSString                        *strUserName;
@property (nonatomic, copy)     NSString                        *strPassword;
@property (nonatomic, copy)     NSString                        *strPIN;
@property (nonatomic, assign)   BOOL                            bAllowPINOnly;

- (id)initWithController:(UIViewController *)parentController;
- (void)startSignup;
- (void)next;

@end

@protocol SignUpManagerDelegate <NSObject>

@required

-(void)signupAborted;
-(void)signupFinished;

@end

//
//  Theme.h
//  
//
//  Created by Paul Puey on 5/2/15.
//
//

#import <Foundation/Foundation.h>
#import "CommonTypes.h"

@interface Theme : NSObject

//@property (nonatomic, copy) NSString *name;
//@property (nonatomic, copy) NSString *password;

// User Settings
@property (nonatomic) UIColor *colorTextLink;
@property (nonatomic) UIColor *colorSendButton;
@property (nonatomic) UIColor *colorRequestButton;
@property (nonatomic) UIColor *colorSendButtonDisabled;
@property (nonatomic) UIColor *colorRequestButtonDisabled;
@property (nonatomic) CGFloat sendRequestButtonDisabled;
@property (nonatomic) UIColor *colorRequestTopTextField;
@property (nonatomic) UIColor *colorRequestBottomTextField;

@property (nonatomic) NSString *appFont;
@property (nonatomic) NSString *backButtonText;
@property (nonatomic) NSString *exitButtonText;
@property (nonatomic) NSString *helpButtonText;
@property (nonatomic) NSString *infoButtonText;
@property (nonatomic) NSString *deleteAccountWarning;
@property (nonatomic) CGFloat heightListings;
@property (nonatomic) CGFloat heightSearchClues;

//@property (nonatomic) int minutesAutoLogout;
//@property (nonatomic) int defaultCurrencyNum;
//@property (nonatomic) int64_t denomination;
//@property (nonatomic, copy) NSString* denominationLabel;
//@property (nonatomic) int denominationType;
//@property (nonatomic, copy) NSString* firstName;
//@property (nonatomic, copy) NSString* lastName;
//@property (nonatomic, copy) NSString* nickName;
//@property (nonatomic, copy) NSString* fullName;
//@property (nonatomic) bool bNameOnPayments;
//@property (nonatomic, copy) NSString* denominationLabelShort;
//@property (nonatomic) bool bDailySpendLimit;
//@property (nonatomic) int64_t dailySpendLimitSatoshis;
//@property (nonatomic) bool bSpendRequirePin;
//@property (nonatomic) int64_t spendRequirePinSatoshis;
//@property (nonatomic) bool bDisablePINLogin;
//@property (nonatomic) NSUInteger sendInvalidEntryCount;
//@property (nonatomic) NSUInteger sendState;
//@property (nonatomic) NSRunLoop *runLoop;
//@property (nonatomic) NSTimer *sendInvalidEntryTimer;
//@property (nonatomic) NSUInteger PINLoginInvalidEntryCount;
//@property (nonatomic) bool reviewNotified;
//@property (nonatomic) NSDate *firstLoginTime;
//@property (nonatomic) NSInteger loginCount;
//@property (nonatomic) NSInteger pinLoginCount;
//@property (nonatomic) BOOL needsPasswordCheck;
//@property (nonatomic, assign) NSInteger requestViewCount;
//@property (nonatomic, assign) NSInteger sendViewCount;
//@property (nonatomic, assign) NSInteger bleViewCount;
//@property (nonatomic) BOOL notifiedSend;
//@property (nonatomic) BOOL notifiedRequest;
//@property (nonatomic) BOOL notifiedBle;

+ (void)initAll;
+ (void)freeAll;
+ (Theme *)Singleton;
- (id)init;

@end

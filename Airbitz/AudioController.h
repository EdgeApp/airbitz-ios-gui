
#import <Foundation/Foundation.h>

@interface AudioController : NSObject

+ (void)initAll;
+ (void)freeAll;
+ (AudioController *)controller;

- (void)playPartialReceived;
- (void)playReceived;
- (void)playSent;

@end

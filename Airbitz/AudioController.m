
#import <AVFoundation/AVFoundation.h>

#import "AudioController.h"

static BOOL bInitialized = NO;

__strong static AudioController *singleton = nil;

@interface AudioController ()

@property (assign) SystemSoundID receiveSound;
@property (assign) SystemSoundID partialReceiveSound;
@property (assign) SystemSoundID sendSound;

@end

@implementation AudioController

#pragma mark - Static methods

+ (void)initAll
{
    if (NO == bInitialized) {
        singleton = [[AudioController alloc] init];
        bInitialized = YES;
    }
}

+ (void)freeAll
{
    if (YES == bInitialized) {
        bInitialized = NO;
    }
}

+ (AudioController *)controller
{
    return (singleton);
}

#pragma mark - Object Methods

- (id)init
{
    self = [super init];
    if (self) {
        AudioServicesCreateSystemSoundID(
            (__bridge CFURLRef)[self resourceUrl:@"BitcoinReceived"], &_receiveSound);
        AudioServicesCreateSystemSoundID(
            (__bridge CFURLRef)[self resourceUrl:@"BitcoinReceivedPartial"], &_partialReceiveSound);
        AudioServicesCreateSystemSoundID(
            (__bridge CFURLRef)[self resourceUrl:@"BitcoinSent"], &_sendSound);
    }
    return self;
}

- (NSURL *)resourceUrl:(NSString *)filepath
{
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:filepath ofType:@"mp3"];
    return [NSURL fileURLWithPath:soundPath];
}

- (void)playPartialReceived
{
    AudioServicesPlaySystemSound(self.partialReceiveSound);
}

- (void)playReceived
{
    AudioServicesPlaySystemSound(self.receiveSound);
}

- (void)playSent
{
    AudioServicesPlaySystemSound(self.sendSound);
}

@end

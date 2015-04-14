//
//  Plugin.h
//  AirBitz
//

#import <Foundation/Foundation.h>

@interface Plugin : NSObject

@property (nonatomic, copy)     NSString        *pluginId;
@property (nonatomic, copy)     NSString        *name;
@property (nonatomic, copy)     NSString        *sourceFile;
@property (nonatomic, copy)     NSString        *sourceExtension;
@property (nonatomic, copy)     NSDictionary    *env;

+ (void)initAll;
+ (void)freeAll;
+ (NSArray *)getPlugins;
+ (Plugin *)getPlugin:(NSString *)pluginId;

@end

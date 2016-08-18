//
//  Plugin.h
//  AirBitz
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Plugin : NSObject

@property (nonatomic, copy)     NSString        *pluginId;
@property (nonatomic, copy)     NSString        *provider;
@property (nonatomic, copy)     NSString        *country;
@property (nonatomic, copy)     NSString        *name;
@property (nonatomic, copy)     NSString        *sourceFile;
@property (nonatomic, copy)     NSString        *sourceExtension;
@property (nonatomic, copy)     NSString        *imageFile;
@property (nonatomic, copy)     NSString        *imageUrl;
@property (nonatomic, strong)   UIColor         *backgroundColor;
@property (nonatomic, strong)   UIColor         *textColor;
@property (nonatomic, copy)     NSDictionary    *env;

+ (void)initAll;
+ (void)freeAll;
+ (NSArray *)getBuySellPlugins;
+ (NSArray *)getGeneralPlugins;

@end

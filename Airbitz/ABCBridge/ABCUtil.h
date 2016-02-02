//
// Created by Paul P on 1/30/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define IS_IPHONE4 (([[UIScreen mainScreen] bounds].size.height < 568) ? YES : NO)
#define IS_IPHONE5 (([[UIScreen mainScreen] bounds].size.height > 567 && [[UIScreen mainScreen] bounds].size.height < 569) ? YES : NO)
#define IS_IPHONE6 (([[UIScreen mainScreen] bounds].size.height > 666 && [[UIScreen mainScreen] bounds].size.height < 668) ? YES : NO)
#define IS_IPHONE6_PLUS (([[UIScreen mainScreen] bounds].size.height > 735 && [[UIScreen mainScreen] bounds].size.height < 737) ? YES : NO)
#define IS_IPAD_MINI (([[UIScreen mainScreen] bounds].size.height > 737) ? YES : NO)

#define IS_MIN_IPHONE5 ([[UIScreen mainScreen] bounds].size.height >= 568)
#define IS_MIN_IPHONE6 ([[UIScreen mainScreen] bounds].size.height >= 667)
#define IS_MIN_IPHONE6_PLUS ([[UIScreen mainScreen] bounds].size.height >= 736)
#define IS_MIN_IPAD_MINI ([[UIScreen mainScreen] bounds].size.height > 737)

@class UIImage;

@interface ABCUtil : NSObject

+ (NSString *)platform;
+ (NSString *)platformString;
+ (NSString *)safeStringWithUTF8String:(const char *)bytes;
+ (void)replaceString:(char **)ppszValue withString:(const char *)szNewValue;
+ (void)freeStringArray:(char **)aszStrings count:(unsigned int)count;
+ (UIImage *)dataToImage:(const unsigned char *)data withWidth:(int)width andHeight:(int)height;

@end
//
// Created by Paul P on 1/30/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIImage;

@interface ABCUtil : NSObject

+ (NSString *)safeStringWithUTF8String:(const char *)bytes;
+ (void)replaceString:(char **)ppszValue withString:(const char *)szNewValue;
+ (void)freeStringArray:(char **)aszStrings count:(unsigned int)count;
+ (UIImage *)dataToImage:(const unsigned char *)data withWidth:(int)width andHeight:(int)height;

@end
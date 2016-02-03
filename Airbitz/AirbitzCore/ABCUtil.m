//
// Created by Paul P on 1/30/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import "ABCUtil.h"
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>



@implementation ABCUtil
{

}

+ (NSString *)safeStringWithUTF8String:(const char *)bytes;
{
    if (bytes) {
        return [NSString stringWithUTF8String:bytes];
    } else {
        return @"";
    }
}

// replaces the string in the given variable with a duplicate of another
+ (void)replaceString:(char **)ppszValue withString:(const char *)szNewValue
{
    if (ppszValue)
    {
        if (*ppszValue)
        {
            free(*ppszValue);
        }
        *ppszValue = strdup(szNewValue);
    }
}


+ (void)freeStringArray:(char **)aszStrings count:(unsigned int)count
{
    if ((aszStrings != NULL) && (count > 0))
    {
        for (int i = 0; i < count; i++)
        {
            free(aszStrings[i]);
        }
        free(aszStrings);
    }
}

+ (UIImage *)dataToImage:(const unsigned char *)data withWidth:(int)width andHeight:(int)height
{
    //converts raw monochrome bitmap data (each byte is a 1 or a 0 representing a pixel) into a UIImage
    char *pixels = malloc(4 * width * width);
    char *buf = pixels;

    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            if (data[(y * width) + x] & 0x1)
            {
                //printf("%c", '*');
                *buf++ = 0;
                *buf++ = 0;
                *buf++ = 0;
                *buf++ = 255;
            }
            else
            {
                printf(" ");
                *buf++ = 255;
                *buf++ = 255;
                *buf++ = 255;
                *buf++ = 255;
            }
        }
        //printf("\n");
    }

    CGContextRef ctx;
    CGImageRef imageRef;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    ctx = CGBitmapContextCreate(pixels,
            (float)width,
            (float)height,
            8,
            width * 4,
            colorSpace,
            (CGBitmapInfo)kCGImageAlphaPremultipliedLast ); //documentation says this is OK
    CGColorSpaceRelease(colorSpace);
    imageRef = CGBitmapContextCreateImage (ctx);
    UIImage* rawImage = [UIImage imageWithCGImage:imageRef];

    CGContextRelease(ctx);
    CGImageRelease(imageRef);
    free(pixels);
    return rawImage;
}

+ (NSString *)platform;
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    
    free(machine);
    
    return platform;
}

+ (NSString *)platformString;
{
    NSString *platform = [self platform];
    
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone8,1"])    return @"iPhone 6s Plus";
    if ([platform isEqualToString:@"iPhone8,2"])    return @"iPhone 6s";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPod7,1"])      return @"iPod Touch 6G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (CDMA)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (GSM)";
    if ([platform isEqualToString:@"iPad4,3"])      return @"iPad Air (CDMA)";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad Mini Retina (WiFi)";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad Mini Retina (Cellular)";
    if ([platform isEqualToString:@"iPad4,7"])      return @"iPad Mini 3 (WiFi)";
    if ([platform isEqualToString:@"iPad4,8"])      return @"iPad Mini 3 (Cellular)";
    if ([platform isEqualToString:@"iPad4,9"])      return @"iPad Mini 3 (Cellular)";
    if ([platform isEqualToString:@"iPad5,1"])      return @"iPad Mini 4 (WiFi)";
    if ([platform isEqualToString:@"iPad5,2"])      return @"iPad Mini 4 (Cellular)";
    if ([platform isEqualToString:@"iPad5,3"])      return @"iPad Air 2 (WiFi)";
    if ([platform isEqualToString:@"iPad5,4"])      return @"iPad Air 2 (Cellular)";
    if ([platform isEqualToString:@"iPad6,7"])      return @"iPad Pro (WiFi)";
    if ([platform isEqualToString:@"iPad6,8"])      return @"iPad Pro (Cellular)";
    if ([platform isEqualToString:@"i386"])         return @"Simulator x86 32 bit";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator x86 64 bit";
    
    return platform;
}



@end
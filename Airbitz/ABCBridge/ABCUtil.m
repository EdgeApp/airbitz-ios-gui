//
// Created by Paul P on 1/30/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import "ABCUtil.h"
#import <UIKit/UIKit.h>



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



@end
//
//  UIImage+Colorize.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "UIImage+Colorize.h"

@implementation UIImage (Colorize)

+ (UIImage *)colorizeImage:(UIImage *)image withColor:(UIColor *)color
{
	UIImage *colorizedImage = nil;
	if(image)
	{
		UIGraphicsBeginImageContext(image.size);
		
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);
		
		CGContextScaleCTM(context, 1, -1);
		CGContextTranslateCTM(context, 0, -area.size.height);
		
		CGContextSaveGState(context);
		CGContextClipToMask(context, area, image.CGImage);
		
		[color set];
		CGContextFillRect(context, area);
		
		CGContextRestoreGState(context);
		
		CGContextSetBlendMode(context, kCGBlendModeMultiply);
		
		CGContextDrawImage(context, area, image.CGImage);
		
		colorizedImage = UIGraphicsGetImageFromCurrentImageContext();
		
		UIGraphicsEndImageContext();
	}
	
    return colorizedImage;
}

@end

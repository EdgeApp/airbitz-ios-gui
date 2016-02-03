//
//  NSString+StripHTML.m
//  AirBitz
//
//  Created by Allan on 11/24/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+StripHTML.h"

@implementation NSString (StripHTML)

-(NSString *)stringByStrippingHTML
{
    NSRange r;
    NSString *s = [self copy];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}

@end

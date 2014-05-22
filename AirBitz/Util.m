//
//  Util.m
//  AirBitz
//
//  Created by Adam Harris on 5/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "Util.h"
#import "CommonTypes.h"

@implementation Util

+ (void)printABC_Error:(const tABC_Error *)pError
{
    if (pError)
    {
        if (pError->code != ABC_CC_Ok)
        {
            printf("Code: %d, Desc: %s, Func: %s, File: %s, Line: %d\n",
                   pError->code,
                   pError->szDescription,
                   pError->szSourceFunc,
                   pError->szSourceFile,
                   pError->nSourceLine
                   );
        }
    }
}

// resizes a view that is one of the tab bar screens to the approriate size to avoid the toolbar
// display view is if the view has a sub-view that also does not include the top 'name of screen' bar
+ (void)resizeView:(UIView *)theView withDisplayView:(UIView *)theDisplayView
{
    CGRect frame;

    if (theView)
    {
        frame = theView.frame;
        frame.size.height = SUB_SCREEN_HEIGHT;
        theView.frame = frame;
    }

    if (theDisplayView)
    {
        frame = theDisplayView.frame;
        frame.size.height = DISPLAY_AREA_HEIGHT;
        theDisplayView.frame = frame;
    }
}


@end

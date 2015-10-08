//
//  RibbonView.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/5/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TAG_RIBBON_VIEW	100

@interface RibbonView : UIView

@property (nonatomic, assign) NSString *string;

//specify a location of the top-left corner of the ribbon.  The X coordinate is generally a point on the right side of the screen.
//specify a string of text to display on the ribbon.
-(id)initAtLocation:(CGPoint)location WithString:(NSString *)string;

//call this to reset flag's position and cause it to animate back onscreen
-(void)flyIntoPosition;

//causes the ribbon to animate to the original starting point.  When the animation is complete, the ribbon will remove itself from its superview.
-(void)remove;

//utility function to convert meters to a string showing distance
+(NSString *)metersToDistance:(float)meters;
@end

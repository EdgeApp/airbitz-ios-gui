//
//  RibbonView.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/5/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//
//	Animates a little green ribbon.  Specify a starting location (generally a point on the right side of the screen)
//	and a string.  The ribbon will animate toward the left from the given starting point and will contain the text in the string.

#import "RibbonView.h"

@interface RibbonView ()
{
	CGPoint initialLocation;
}

@end

@implementation RibbonView

+ (NSString *)metersToDistance:(float)meters
{
    NSLocale *locale = [NSLocale currentLocale];
    BOOL isMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
    NSString *resultString = nil;

    if (isMetric) {
        if (meters < 1000.0) {
            if ((int) meters == 1) {
                resultString = @"1 meter";
            } else {
                resultString = [NSString stringWithFormat:@"%.0f meters", meters];
            }
        } else {
            float km = meters / 1000.0;
            if ((int)km == 1) {
                resultString = @"1 km";
            } else {
                resultString = [NSString stringWithFormat:@"%.2f km", km];
            }
        }
    } else {
        float feet = meters * 3.28084;
        if (feet < 1000.0) {
            if ((int)feet == 1) {
                resultString = @"1 foot";
            } else {
                resultString = [NSString stringWithFormat:@"%.0f feet", feet];
            }
        } else {
            if ((int)feet == 5280) {
                resultString = @"1 mile";
            } else {
                resultString = [NSString stringWithFormat:@"%.2f miles", feet / 5280.0];
            }
        }
    }
    return resultString;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code
    }
    return self;
}

-(void)setString:(NSString *)string
{
	for(UIView *view in self.subviews)
	{
		if([view isKindOfClass:[UILabel class]])
		{
			UILabel *label = (UILabel *)view;
			label.text = string;
		}
	}
}

-(void)flyIntoPosition
{
	CGRect frame = self.frame;
	frame.origin = initialLocation;
	self.frame = frame;
	[self animateOnScreen];
}

-(void)animateOnScreen
{
	[UIView animateWithDuration:0.25
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^
	 {
		 CGRect frame = self.frame;
		 frame.origin.x -= frame.size.width;
		 self.frame = frame;
	 }
					 completion:^(BOOL finished)
	 {
		 
	 }];
}

-(id)initAtLocation:(CGPoint)location WithString:(NSString *)string
{
	self = [super init];
	if(self)
	{
		initialLocation = location;
		UIImage *image = [UIImage imageNamed:@"ribbon"];
		UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
		[self addSubview:imageView];
		CGRect frame = imageView.frame;
		frame.origin.x = location.x;
		frame.origin.y = location.y;
		self.frame = frame;
		
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(17, 8, 63, 16)]; //position within ribbon image
		//label.backgroundColor = [UIColor redColor]; //in case we need to recheck alignment
		
		label.text = string;
		
		label.textColor = [UIColor whiteColor];
		label.minimumScaleFactor = 8.0/[UIFont labelFontSize];
		
		label.textAlignment	= NSTextAlignmentCenter;
		
		label.adjustsFontSizeToFitWidth = YES;
		
		label.font = [UIFont fontWithName:@"Montserrat-Bold" size:11.0];
		
		self.tag = TAG_RIBBON_VIEW;
		[self addSubview:label];
		
		[self animateOnScreen];
	}
	return self;
}

-(void)remove
{
	[UIView animateWithDuration:0.25
						  delay:0.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^
	 {
		 CGRect frame = self.frame;
		 frame.origin.x += frame.size.width;
		 self.frame = frame;
	 }
	 completion:^(BOOL finished)
	 {
		 [self removeFromSuperview];
	 }];
}

@end

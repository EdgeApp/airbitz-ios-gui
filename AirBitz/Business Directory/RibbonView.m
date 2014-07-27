//
//  RibbonView.m
//
//  Copyright (c) 2014, Airbitz
//  All rights reserved.
//
//  Redistribution and use in source and binary forms are permitted provided that
//  the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//  3. Redistribution or use of modified source code requires the express written
//  permission of Airbitz Inc.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the Airbitz Project.
//
//  See AUTHORS for contributing developers
//

//
//	Animates a little green ribbon.  Specify a starting location (generally a point on the right side of the screen)
//	and a string.  The ribbon will animate toward the left from the given starting point and will contain the text in the string.
//

#import "RibbonView.h"

@interface RibbonView ()
{
	CGPoint initialLocation;
}

@end

@implementation RibbonView

+(NSString *)metersToDistance:(float)meters
{
	//used to generate string that is displayed in distance ribbon
	float feet = meters * 3.28084;
	NSString *resultString = nil;
	
	if(feet < 1000.0)
	{
		//give result in feet
		if((int)feet == 1)
		{
			resultString = @"1 foot";
		}
		else
		{
			resultString = [NSString stringWithFormat:@"%.0f feet", feet];
		}
	}
	else
	{
		//give result in miles
		if((int)feet == 5280)
		{
			resultString = @"1 mile";
		}
		else
		{
			resultString = [NSString stringWithFormat:@"%.2f miles", feet / 5280.0];
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

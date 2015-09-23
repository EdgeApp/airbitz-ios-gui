//
//  ConfirmationSliderView.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/2/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "ConfirmationSliderView.h"

#define CONFIRMATION_THRESHOLD	0.25	/* how far from the left the slider has to move before it's a confirmation */

@interface ConfirmationSliderView ()
{
	CGPoint touchOffset;
	CGRect  originalButtonFrame;
	BOOL 	bAllowTouches;
}
@property (nonatomic, weak) IBOutlet UIImageView *button;
@property (nonatomic, weak) IBOutlet UILabel *confirmText;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinnerView;

@end

@implementation ConfirmationSliderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
	bAllowTouches = YES;
    self.spinnerView.hidden = YES;
    return self;
}

+ (ConfirmationSliderView *)CreateInsideView:(UIView *)parentView withDelegate:(id<ConfirmationSliderViewDelegate>)delegate
{
	ConfirmationSliderView *cv;
	
    cv = [[[NSBundle mainBundle] loadNibNamed:@"ConfirmationSliderView" owner:nil options:nil] objectAtIndex:0];
	[parentView addSubview:cv];
	cv.frame = parentView.bounds;
	cv.delegate = delegate;
	cv->originalButtonFrame = cv.button.frame;
	return cv;
}

-(void)resetIn:(NSTimeInterval)timeToReset
{
	bAllowTouches = YES;
    self.spinnerView.hidden = YES;
    [self.spinnerView startAnimating];
	[self animateToOriginalPositionWithDelay:timeToReset];
}

-(void)animateToOriginalPositionWithDelay:(NSTimeInterval)delay
{
	[UIView animateWithDuration:0.1
						  delay:delay
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 self.button.frame = originalButtonFrame;
		 self.confirmText.alpha = 1.0;
	 }
					 completion:^(BOOL finished)
	 {
		 
	 }];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (!bAllowTouches) return;

	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
	
	if(CGRectContainsPoint(self.button.frame, touchPoint))
	{
		touchOffset.x = touchPoint.x - self.button.frame.origin.x;
		touchOffset.y = touchPoint.y - self.button.frame.origin.y;
	}
	   
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (!bAllowTouches) return;

	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
	
	CGRect frame = self.button.frame;
	frame.origin.x = touchPoint.x - touchOffset.x;
	if(frame.origin.x < 0)
	{
		frame.origin.x = 0;
	}
	if(frame.origin.x > originalButtonFrame.origin.x)
	{
		frame.origin.x = originalButtonFrame.origin.x;
	}
	self.button.frame = frame;
	
	float maxDistance = originalButtonFrame.origin.x + (originalButtonFrame.size.width / 2.0) - (self.bounds.size.width * CONFIRMATION_THRESHOLD);
	float curDistance = frame.origin.x + (frame.size.width / 2.0) - (self.bounds.size.width * CONFIRMATION_THRESHOLD);
	
	float alpha = curDistance / maxDistance;
	if(alpha < 0) alpha = 0;
	
	self.confirmText.alpha = alpha;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (!bAllowTouches) return;

	if((self.button.frame.origin.x + (self.button.frame.size.width / 2.0)) > (self.bounds.size.width * CONFIRMATION_THRESHOLD))
	{
		//slide back
		[self animateToOriginalPositionWithDelay:0.0];
	}
	else
	{
		//continue sliding to the left
		[UIView animateWithDuration:0.1
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^
		 {
			 CGRect frame = self.button.frame;
			 frame.origin.x = 0.0;
			 self.button.frame = frame;
		 }
		 completion:^(BOOL finished)
		 {
			 bAllowTouches = NO;
             self.spinnerView.hidden = NO;
			 [self.delegate ConfirmationSliderDidConfirm:self];
		 }];
	}
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEnded:touches withEvent:event];
}

@end

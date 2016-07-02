//
//  DividerView.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/12/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//
/*  DividerView has two states:
	userControllable YES/NO
	
	When userControllable is YES:
		User can tap and drag DividerView
		DividerView will send touchEvents to delegate (for it to decide how to behave based on user actions)
		Vertical positioning is controlled by user
		
	When userControllable is NO:
		Touch events on DividerView are ignored
		Vertical positioning is controlled by delegate setting frame.origin
*/

#import "DividerView.h"
#import "Theme.h"

@interface DividerView ()


@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *dragbarView;
@property (nonatomic, weak) IBOutlet UIImageView *dividerbarView;

@end
@implementation DividerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib
{
	self.titleLabel.alpha = 1.0;
             self.dragbarView.hidden = true;
             self.dividerbarView.hidden = false;
	self.userInteractionEnabled = NO;
}

-(void)setUserControllable:(BOOL)userControllable
{
	_userControllable = userControllable;
	if(userControllable)
	{
		self.userInteractionEnabled = YES;
        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                              delay:[Theme Singleton].animationDelayTimeDefault
							options:UIViewAnimationOptionCurveLinear
						 animations:^
		 {
			 self.titleLabel.alpha = 0.0;
                         self.dragbarView.hidden = false;
                         self.dividerbarView.hidden = true;

		 }
		 completion:^(BOOL finished)
		 {
			 
		 }];
	}
	else
	{
		self.userInteractionEnabled = NO;
        [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                              delay:[Theme Singleton].animationDelayTimeDefault
							options:UIViewAnimationOptionCurveLinear
						 animations:^
		 {
			 self.titleLabel.alpha = 1.0;
             self.dragbarView.hidden = true;
             self.dividerbarView.hidden = false;
		 }
		 completion:^(BOOL finished)
		 {
			 
		 }];
	}
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([self.delegate respondsToSelector:@selector(DividerViewTouchesBegan:withEvent:)])
	{
		[self.delegate DividerViewTouchesBegan:touches withEvent:event];
	}
	//[super touchesBegan:touches withEvent:event];
	//[self.nextResponder touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([self.delegate respondsToSelector:@selector(DividerViewTouchesMoved:withEvent:)])
	{
		[self.delegate DividerViewTouchesMoved:touches withEvent:event];
	}
	//[super touchesMoved:touches withEvent:event];
	//[self.nextResponder touchesMoved:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([self.delegate respondsToSelector:@selector(DividerViewTouchesEnded:withEvent:)])
	{
		[self.delegate DividerViewTouchesEnded:touches withEvent:event];
	}
	//[super touchesEnded:touches withEvent:event];
	//[self.nextResponder touchesEnded:touches withEvent:event];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([self.delegate respondsToSelector:@selector(DividerViewTouchesCancelled:withEvent:)])
	{
		[self.delegate DividerViewTouchesCancelled:touches withEvent:event];
	}
	//[super touchesCancelled:touches withEvent:event];
	//[self.nextResponder touchesCancelled:touches withEvent:event];
}

@end
